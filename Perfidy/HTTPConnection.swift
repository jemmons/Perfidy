import Foundation
import FiniteGauntlet


class HTTPConnection : NSObject {
  struct HTTPConnectionCallbacks{
    var requestDidFinish:((req:NSURLRequest)->Void)?
    var responseDidFinish:(()->Void)?
  }
  var callbacks = HTTPConnectionCallbacks()
  let socket:GCDAsyncSocket
  private let _request:HTTPMessage
  var machine:StateMachine<HTTPConnection>!
  //  let response:HTTPMessage
  
  init(socket:GCDAsyncSocket){
    self.socket = socket
    _request = HTTPMessage()
    super.init()
    self.socket.setDelegate(self, delegateQueue: dispatch_get_main_queue())
    machine = StateMachine(initialState:.Ready, delegate:self)
    machine.state = .ReadingHead
  }
}



private extension HTTPConnection{
  var timeout:CFTimeInterval{ return 10.0 }
  
  func readHead(){
    socket.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout:timeout, tag:0)
  }
  
  
  func readBodyOfLength(length:UInt){
    //This is a no-op when «length» is 0.
    socket.readDataToLength(length, withTimeout:timeout, tag:0)
  }
}


extension HTTPConnection{ //GCDAsyncSocket delegate
  func socket(socket:GCDAsyncSocket, didReadData data:NSData, withTag tag:Int){
    switch machine.state{
    case .ReadingHead:
      _request.append(data)
      if _request.needsMoreHeader{
        machine.state = .ReadingHead //Could blow the stack, but probably not for average headers.
      } else{
        machine.state = .ReadingBody(_request.contentLength)
      }
    case .ReadingBody:
      _request.append(data) //We're assuming this only gets called once because we give it the lenght of the buffer.
      machine.state = .SendingResponse
    default:
      assertionFailure("HTTPConnection read data outside of a reading state")
    }
  }
}


extension HTTPConnection : StateMachineDelegateProtocol{
  enum State : StateMachineDataSourceProtocol{
    case Ready, ReadingHead, ReadingBody(Int), SendingResponse
    func shouldTransitionFrom(from:StateType, to:StateType) -> Should<StateType>{
      switch (from, to){
      case (.Ready, .ReadingHead):
        return .Continue
      case (.ReadingHead, ReadingHead):
        return .Continue
      case (.ReadingHead, .ReadingBody(let length)):
        //We have to short-circuit here because reading 0 length from the socket is a no-op (and thus will never cause the async callback to be fired, thus never transitioning to SendingResponse).
        return (length == 0) ? .Redirect(.SendingResponse) : .Continue
      case (.ReadingBody, .SendingResponse):
        return .Continue
      default:
        return .Abort
      }
    }
  }
  
  typealias StateType = State
  
  func didTransitionFrom(from: StateType, to: StateType) {
    switch to{
    case .ReadingHead:
      readHead()
    case .ReadingBody(let length):
      readBodyOfLength(UInt(length))
    case .SendingResponse:
      let req = NSMutableURLRequest()
      req.HTTPBody = _request.body
      callbacks.requestDidFinish?(req:req)
    default:
      break
    }
  }
}
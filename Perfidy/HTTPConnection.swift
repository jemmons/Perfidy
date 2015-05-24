import Foundation
import FiniteGauntlet


class HTTPConnection : NSObject {
  struct HTTPConnectionCallbacks{
    var requestDidFinish:((req:NSURLRequest)->Void)?
    var responseDidFinish:(()->Void)?
    var responseForEndpoint:((Endpoint)->BodyResponse?)?
  }
  var callbacks = HTTPConnectionCallbacks()
  var defaultStatusCode = 200
  private let socket:GCDAsyncSocket
  private var machine:StateMachine<HTTPConnection>!
  
  init(socket:GCDAsyncSocket){
    self.socket = socket
    super.init()
    self.socket.setDelegate(self, delegateQueue: dispatch_get_main_queue())
    machine = StateMachine(initialState:.Ready, delegate:self)
    machine.state = .ReadingHead(HTTPMessage())
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
  
  
  func respondToMessage(message:HTTPMessage){
    let endpoint = Endpoint(method:message.method, path:message.url?.path)
    let response = callbacks.responseForEndpoint?(endpoint) ?? BodyResponse(statusCode:defaultStatusCode)!
    machine.state = .WritingResponse(response.message)
  }
  
  
  func writeResponse(message:HTTPMessage){
    socket.writeData(message.data, withTimeout:timeout, tag:0)
  }
}


extension HTTPConnection{ //GCDAsyncSocket delegate
  func socket(socket:GCDAsyncSocket, didReadData data:NSData, withTag tag:Int){
    switch machine.state{
    case .ReadingHead(let message):
      message.append(data)
      if message.needsMoreHeader{
        machine.state = .ReadingHead(message) //Could blow the stack, but probably not for average headers.
      } else{
        machine.state = .ReadingBody(message)
      }
    case .ReadingBody(let message):
      message.append(data) //We're assuming this only gets called once because we give it the lenght of the buffer.
      machine.state = .ReadComplete(message)
    default:
      assertionFailure("HTTPConnection read data outside of a reading state")
    }
  }
  
  
  func socket(socket:GCDAsyncSocket, didWriteDataWithTag tag:Int){
    switch machine.state{
    case .WritingResponse:
      machine.state = .WriteComplete
    default:
      assertionFailure("HTTPConnection wrote data outside of a writing state")
    }
  }
}


extension HTTPConnection : StateMachineDelegateProtocol{
  enum State : StateMachineDataSourceProtocol{
    case Ready, ReadingHead(HTTPMessage), ReadingBody(HTTPMessage), ReadComplete(HTTPMessage), WritingResponse(HTTPMessage), WriteComplete
    func shouldTransitionFrom(from:StateType, to:StateType) -> Should<StateType>{
      switch (from, to){
      case (.Ready, .ReadingHead):
        return .Continue
      case (.ReadingHead, ReadingHead):
        return .Continue
      case (.ReadingHead, .ReadingBody(let message)):
        //We have to short-circuit here because reading 0 length from the socket is a no-op (and thus will never cause the async callback to be fired, thus never transitioning to SendingResponse).
        return (message.contentLength == 0) ? .Redirect(.ReadComplete(message)) : .Continue
      case (.ReadingBody, .ReadComplete):
        return .Continue
      case (.ReadComplete, .WritingResponse):
        return .Continue
      case (.WritingResponse, .WriteComplete):
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
    case .ReadingBody(let message):
      readBodyOfLength(UInt(message.contentLength))
    case .ReadComplete(let message):
      callbacks.requestDidFinish?(req:message.request)
      respondToMessage(message)
    case .WritingResponse(let message):
      writeResponse(message)
    case .WriteComplete:
      socket.disconnect()
      callbacks.responseDidFinish?()
    default:
      break
    }
  }
  
}
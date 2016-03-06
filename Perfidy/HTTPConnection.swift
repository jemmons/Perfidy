import Foundation
import Gauntlet
import Rebar


class HTTPConnection : NSObject {
  struct HTTPConnectionCallbacks{
    var whenFinishesRequest:((req:NSURLRequest)->Void)?
    var whenFinishesResponse:(()->Void)?
    var whenNeedsResponseForEndpoint:((Endpoint)->Response?)?
  }
  var callback = HTTPConnectionCallbacks()
  var defaultStatusCode = 200
  private let socket:GCDAsyncSocket
  private var machine:StateMachine<State>!
  
  init(socket:GCDAsyncSocket){
    self.socket = socket
    super.init()
    self.socket.setDelegate(self, delegateQueue: dispatch_get_main_queue())
    machine = configuredMachine
    machine.queueState(.ReadingHead(HTTPMessage()))
  }
}



private extension HTTPConnection{
  struct K {
    static let timeout: CFTimeInterval = 10.0
  }
  
  
  func readHead(){
    socket.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout:K.timeout, tag:0)
  }
  
  
  func readBodyOfLength(length:UInt){
    //This is a no-op when «length» is 0.
    socket.readDataToLength(length, withTimeout:K.timeout, tag:0)
  }
  
  
  func respondToMessage(message:HTTPMessage){
    let endpoint = Endpoint(method: message.method, path: message.url?.path)
    let response = callback.whenNeedsResponseForEndpoint?(endpoint) ?? Response(status: defaultStatusCode)!
    machine.queueState(.WritingResponse(response.message))
  }
  
  
  func writeResponse(message:HTTPMessage){
    socket.writeData(message.data, withTimeout:K.timeout, tag:0)
  }
}


extension HTTPConnection{ //GCDAsyncSocket delegate
  func socket(socket:GCDAsyncSocket, didReadData data:NSData, withTag tag:Int){
    switch machine.state{
    case .ReadingHead(let message):
      message.append(data)
      if message.needsMoreHeader{
        machine.queueState(.ReadingHead(message))
      } else{
        machine.queueState(.ReadingBody(message))
      }
    case .ReadingBody(let message):
      message.append(data) //We're assuming this only gets called once because we give it the lenght of the buffer.
      machine.queueState(.ReadComplete(message))
    default:
      assertionFailure("HTTPConnection has read data outside of a reading state")
    }
  }
  
  
  func socket(socket:GCDAsyncSocket, didWriteDataWithTag tag:Int){
    switch machine.state{
    case .WritingResponse:
      machine.queueState(.WriteComplete)
    default:
      assertionFailure("HTTPConnection wrote data outside of a writing state")
    }
  }
}


private extension HTTPConnection {
  enum State: StateType {
    case Ready
    case ReadingHead(HTTPMessage), ReadingBody(HTTPMessage), ReadComplete(HTTPMessage)
    case WritingResponse(HTTPMessage), WriteComplete

    func shouldTransitionFrom(from: State, to: State) -> Bool {
      switch (from, to) {
      case (.Ready, .ReadingHead),
      (.ReadingHead, .ReadingHead),
      (.ReadingHead, .ReadingBody),
      (.ReadingBody, .ReadComplete),
      (.ReadComplete, .WritingResponse),
      (.WritingResponse, .WriteComplete):
        return yes
      default:
        return no
      }
    }
  }
  
  
  var configuredMachine: StateMachine<State> {
    return thisAfter(StateMachine(initialState: State.Ready)) {
      $0.transitionHandler = { [unowned self] _, to in
        switch to{
        case .ReadingHead:
          self.readHead()
        case .ReadingBody(let message):
          guard message.contentLength != 0 else {
            //We have to short-circuit here because reading 0 length from the socket is a no-op (and thus will never cause the async callback to be fired, thus never transition to SendingResponse).
            self.machine.queueState(.ReadComplete(message))
            break
          }
          self.readBodyOfLength(UInt(message.contentLength))
        case .ReadComplete(let message):
          self.callback.whenFinishesRequest?(req:message.request)
          self.respondToMessage(message)
        case .WritingResponse(let message):
          self.writeResponse(message)
        case .WriteComplete:
          self.socket.disconnect()
          self.callback.whenFinishesResponse?()
        default:
          break
        }
      }
    }
  }
}

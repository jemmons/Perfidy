import Foundation

public class HTTPServer : NSObject{
  var socket:GCDAsyncSocket!
  var connections = [HTTPConnection]()
  var pathToResponseMap = [String:NSURLResponse]()
  
  public override init(){
    super.init()
    self.socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
  }
  
  
  public func errorFromStart() -> NSError?{
    var error:NSError?
    let success = self.socket.acceptOnPort(HTTPServer.port, error: &error)
    return success ? nil : error
  }
  
  
  public func start(){
    let error = errorFromStart()
    precondition(error == nil, error!.localizedDescription)
  }
  
  
  public func stop(){
    self.socket.disconnect()
  }

  
  public func addResponse(res:NSURLResponse, forPath path:String){
    pathToResponseMap[path] = res
  }
  
  
  func socket(socket:GCDAsyncSocket, didAcceptNewSocket newSocket:GCDAsyncSocket){
    let connection = HTTPConnection(socket: newSocket)
    connection.callbacks.requestDidFinish = {(req:NSURLRequest) in
      println(NSString(data: req.HTTPBody!, encoding: NSUTF8StringEncoding))
    }
    connections.append(connection)
  }

}



private extension HTTPServer{
  static var port:UInt16{
    return 10175 // Year of Paul Atreides's birth.
  }

  
}


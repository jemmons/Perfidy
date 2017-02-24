import Foundation



private enum Const {
  static let defaultStatusCode = 404
  static let defaultPort: UInt16 = 10175
}



/**
 A small, in-process HTTP server that can be spun up to validate received requests and provide faked responses.
 
 It can be explicitly created, started and stopped:
 
 ```
 let server = FakeServer()
 try! server.start()
 //do stuff with `server`
 server.stop()
 ```
 
 There's also a convenience method that takes a closure, useful for testing:
 
 ```
 FakeServer.runWith { server in
   //do stuff with `server`
 }
 ```
 */
public class FakeServer : NSObject{
  fileprivate var requests = [URLRequest]()
  
  fileprivate let port: UInt16
  fileprivate let defaultStatusCode:Int

  fileprivate var socket:GCDAsyncSocket!
  fileprivate var connections = [HTTPConnection]()
  fileprivate var routeToResponseMap = Dictionary<Route, Response>()
  fileprivate var routeToHandlerMap = Dictionary<Route, (URLRequest)->Void>()


  /**
   Creates a new server.

   * note: Even once created, the server is not listening for connections. It must be explicitly run by calling `start()` (or using the `runWith()` convenience method).
   
   * parameter port: The port the server will listen on once running. By default it will use port 10175.
   * parameter defaultStatusCode:
  */
  public init(port: UInt16 = Const.defaultPort, defaultStatusCode: Int = Const.defaultStatusCode){
    self.port = port
    self.defaultStatusCode = defaultStatusCode
    super.init()
    self.socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
  }
}



public extension FakeServer{
  static func runWith(port: UInt16 = Const.defaultPort, defaultStatusCode: Int = Const.defaultStatusCode, f: (FakeServer)->Void) {
    let server = FakeServer(port: port, defaultStatusCode: defaultStatusCode)
    try! server.start()
    defer {
      server.stop()
    }
    f(server)
  }

  
  func start() throws {
    try socket.accept(onPort: port)
  }
  
  
  func stop(){
    socket.disconnect()
    routeToResponseMap = [:]
    routeToHandlerMap = [:]
    requests = []
  }
  
  
  func add(_ route: Route, response: Response = 200, handler: @escaping (URLRequest) -> Void = {_ in}) {
    routeToResponseMap[route] = response
    routeToHandlerMap[route] = handler
  }
  
  
  func add(_ routesAndResponses: [(route: Route, response: Response)]) {
    routesAndResponses.forEach { add($0.route, response: $0.response) }
  }
  
  
  func add(_ routes: [Route]) {
    routes.forEach {
      add($0)
    }
  }
  
  
  func requestsForRoute(_ route: Route) -> [URLRequest] {
    return requests.filter { Route(method: $0.httpMethod, path: $0.url?.path) == route }
  }

  
  func countOfRequestsForRoute(_ route: Route)->Int{
    return requestsForRoute(route).count
  }
  
  
  func didRequestRoute(_ route: Route) -> Bool {
    let empty = requestsForRoute(route).isEmpty
    return !empty
  }
}



extension FakeServer: GCDAsyncSocketDelegate {
  public func socket(_ socket:GCDAsyncSocket, didAcceptNewSocket newSocket:GCDAsyncSocket){
    let connection = HTTPConnection(socket: newSocket, defaultStatusCode: defaultStatusCode)
    connection.delegate.didFinishRequest = {[unowned self] (req:URLRequest) in
      self.requests.append(req)
      self.routeToHandlerMap[Route(request: req)]?(req)
    }
    connection.delegate.responseForRoute = {[unowned self](route: Route) in
      return self.routeToResponseMap[route]
    }
    connection.delegate.didFinishResponse = {[unowned self, unowned connection] in
      if let i = self.connections.index(of: connection) {
        self.connections.remove(at: i)
      }
    }
    connections.append(connection)
  }
}

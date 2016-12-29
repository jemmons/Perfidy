import Foundation

public class FakeServer : NSObject{
  public var callback = FakeServerCallbacks()
  fileprivate var requests = [URLRequest]()
  
  fileprivate let port: UInt16
  fileprivate let defaultStatusCode:Int

  fileprivate var socket:GCDAsyncSocket!
  fileprivate var connections = [HTTPConnection]()
  fileprivate var endpointToResponseMap = Dictionary<Endpoint, Response>()
  fileprivate var endpointToHandlerMap = Dictionary<Endpoint, (URLRequest)->Void>()

  
  public init(port: UInt16 = 10175, defaultStatusCode: Int = 200){
    self.port = port
    self.defaultStatusCode = defaultStatusCode
    super.init()
    self.socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
  }
}



public extension FakeServer{
  struct FakeServerCallbacks{
    var whenRequestHandledByServer:((FakeServer)->Void)?
  }
  
  
  static func runWith(port: UInt16 = 10175, defaultStatusCode: Int = 200, f: (FakeServer)->Void) {
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
    endpointToResponseMap = [:]
    endpointToHandlerMap = [:]
    requests = []
  }
  
  
  func add(_ endpoint: Endpoint, response: Response? = nil, handler: @escaping (URLRequest) -> Void = {_ in}) {
    endpointToResponseMap[endpoint] = response
    endpointToHandlerMap[endpoint] = handler
  }
  
  
  func add(_ endpointsAndResponses: [(endpoint: Endpoint, response: Response)]) {
    endpointsAndResponses.forEach { add($0.endpoint, response:$0.response) }
  }
  
  
  func add(_ endpoints: [Endpoint]) {
    endpoints.forEach {
      add($0)
    }
  }
  
  
  func requestsForEndpoint(_ endpoint:Endpoint) -> [URLRequest] {
    return requests.filter { Endpoint(method: $0.httpMethod, path: $0.url?.path) == endpoint }
  }

  
  func countOfRequestsForEndpoint(_ endpoint:Endpoint)->Int{
    return requestsForEndpoint(endpoint).count
  }
  
  
  func didRequestEndpoint(_ endpoint: Endpoint) -> Bool {
    let empty = requestsForEndpoint(endpoint).isEmpty
    return !empty
  }
}



extension FakeServer: GCDAsyncSocketDelegate {
  public func socket(_ socket:GCDAsyncSocket, didAcceptNewSocket newSocket:GCDAsyncSocket){
    let connection = HTTPConnection(socket: newSocket)
    connection.defaultStatusCode = defaultStatusCode
    connection.callback.whenFinishesRequest = {[unowned self] (req:URLRequest) in
      self.requests.append(req)
      self.endpointToHandlerMap[Endpoint(request: req)]?(req)
    }
    connection.callback.whenNeedsResponseForEndpoint = {[unowned self](endpoint:Endpoint) in
      return self.endpointToResponseMap[endpoint]
    }
    connection.callback.whenFinishesResponse = {[unowned self, unowned connection] in
      if let i = self.connections.index(of: connection) {
        self.connections.remove(at: i)
      }
    }
    connections.append(connection)
  }
}

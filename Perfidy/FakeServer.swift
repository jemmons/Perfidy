import Foundation

public class FakeServer : NSObject{
  public var callback = FakeServerCallbacks()
  public var requests = [URLRequest]()
  
  fileprivate let port: UInt16
  fileprivate let defaultStatusCode:Int

  fileprivate var socket:GCDAsyncSocket!
  fileprivate var connections = [HTTPConnection]()
  fileprivate var endpointToResponseMap = Dictionary<Endpoint, Response>()
  fileprivate var endpointToHandlerMap = Dictionary<Endpoint, (URLRequest)->Void>()

  
  public init(port: UInt16 = 10175, defaultStatusCode:Int = 200){
    self.port = port
    self.defaultStatusCode = defaultStatusCode
    super.init()
    self.socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
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



public extension FakeServer{
  struct FakeServerCallbacks{
    var whenRequestHandledByServer:((FakeServer)->Void)?
  }
  

  public func start() throws {
    try socket.accept(onPort: port)
  }
  
  
  public func stop(){
    socket.disconnect()
  }
  
  
  public func add(_ response: Response?, endpoint: Endpoint, handler: @escaping (URLRequest) -> Void = {_ in}) {
    endpointToResponseMap[endpoint] = response
    endpointToHandlerMap[endpoint] = handler
  }
  
  
  public func add(_ responsesAndEndpoints: [(response: Response, endpoint: Endpoint)]) {
    responsesAndEndpoints.forEach { add($0.response, endpoint: $0.endpoint) }
  }
  
  
  public func requestsForEndpoint(_ endpoint:Endpoint) -> [URLRequest] {
    return requests.filter { Endpoint(method: $0.httpMethod, path: $0.url?.path) == endpoint }
  }

  
  public func countOfRequestsForEndpoint(_ endpoint:Endpoint)->Int{
    return requestsForEndpoint(endpoint).count
  }
  
  
  public func didRequestEndpoint(_ endpoint: Endpoint) -> Bool {
    let empty = requestsForEndpoint(endpoint).isEmpty
    return !empty
  }
}

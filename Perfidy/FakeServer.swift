import Foundation

public class FakeServer : NSObject{
  public var callback = FakeServerCallbacks()
  public var requests = [NSURLRequest]()
  
  private let port: UInt16
  private let defaultStatusCode:Int
  private var socket:GCDAsyncSocket!
  private var connections = [HTTPConnection]()
  private var endpointToResponseMap = [Endpoint: Response]()
  private var endpointToHandlerMap = Dictionary<Endpoint, (NSURLRequest)->Void>()

  
  public init(port: UInt16 = 10175, defaultStatusCode:Int = 200){
    self.port = port
    self.defaultStatusCode = defaultStatusCode
    super.init()
    self.socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
  }
  
  
  //This gets `respondsToSelector`'d by the async lib. It needs to be internal to be seen by it.
  func socket(socket:GCDAsyncSocket, didAcceptNewSocket newSocket:GCDAsyncSocket){
    let connection = HTTPConnection(socket: newSocket)
    connection.defaultStatusCode = defaultStatusCode
    connection.callback.whenFinishesRequest = {[unowned self] (req:NSURLRequest) in
      self.requests.append(req)
      self.endpointToHandlerMap[Endpoint(request: req)]?(req)
    }
    connection.callback.whenNeedsResponseForEndpoint = {[unowned self](endpoint:Endpoint) in
      return self.endpointToResponseMap[endpoint]
    }
    connection.callback.whenFinishesResponse = {[unowned self, unowned connection] in
      self.connections = self.connections.filter{ $0 != connection }
    }
    connections.append(connection)
  }
}


public extension FakeServer{
  struct FakeServerCallbacks{
    var whenRequestHandledByServer:((server:FakeServer)->Void)?
  }
  

  public func start() throws {
    try self.socket.acceptOnPort(port)
  }
  
  
  public func stop(){
    self.socket.disconnect()
  }
  
  
  public func add(response: Response?, endpoint: Endpoint, handler: (NSURLRequest) -> Void = {_ in}) {
    endpointToResponseMap[endpoint] = response
    endpointToHandlerMap[endpoint] = handler
  }
  
  
  public func add(responsesAndEndpoints: [(response: Response, endpoint: Endpoint)]) {
    responsesAndEndpoints.forEach { endpointToResponseMap[$0.endpoint] = $0.response }
  }
  
  
  public func didServeEndpoint(endpoint: Endpoint) -> Bool{
    return requestsForEndpoint(endpoint).isNotEmpty
  }
  
  
  public func requestsForEndpoint(endpoint:Endpoint)->[NSURLRequest]{
    return requests.filter { Endpoint(method: $0.HTTPMethod, path: $0.URL?.path) == endpoint }
  }

  
  public func countOfRequestsForEndpoint(endpoint:Endpoint)->Int{
    return requestsForEndpoint(endpoint).count
  }
}

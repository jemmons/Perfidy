import Foundation

public class FakeServer : NSObject{
  public var callback = FakeServerCallbacks()
  public var requests = [NSURLRequest]()
  
  private static let port = UInt16(10175) // Year of Paul Atreides's birth.
  private var socket:GCDAsyncSocket!
  private var connections = [HTTPConnection]()
  private var endpointToResponseMap = [Endpoint: Response]()
  private let defaultStatusCode:Int

  
  
  public init(statusCode:Int = 200){
    defaultStatusCode = statusCode
    super.init()
    self.socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
  }
  
  
  //This gets `respondsToSelector`'d by the async lib. It needs to be internal to be seen by it.
  func socket(socket:GCDAsyncSocket, didAcceptNewSocket newSocket:GCDAsyncSocket){
    let connection = HTTPConnection(socket: newSocket)
    connection.defaultStatusCode = defaultStatusCode
    connection.callback.whenFinishesRequest = {[unowned self] (req:NSURLRequest) in
      self.requests.append(req)
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
    try self.socket.acceptOnPort(FakeServer.port)
  }
  
  
  public func stop(){
    self.socket.disconnect()
  }
  
  
  public func add(response: Response, endpoint: Endpoint) {
    response.internalURL = NSURL(string: endpoint.path)
    endpointToResponseMap[endpoint] = response
  }
  
  
  public func add(responsesAndEndpoints: [(response: Response, endpoint: Endpoint)]) {
    responsesAndEndpoints.forEach { endpointToResponseMap[$0.endpoint] = $0.response }
  }
  
  
  public func requestsForPath(path:String)->[NSURLRequest]{
    return requests.filter{ $0.URL?.path ?? "" == path }
  }
  
  public func countOfRequestsForPath(path:String)->Int{
    return requestsForPath(path).count
  }
  
  public func didServePath(path:String)->Bool{
    return !requestsForPath(path).isEmpty
  }
  
  public func requestsForEndpoint(endpoint:Endpoint)->[NSURLRequest]{
    let requestsMatchingPath = requestsForPath(endpoint.path)
    return requestsMatchingPath.filter{ $0.HTTPMethod ?? "" == endpoint.method.rawValue}
  }
  
  public func countOfRequestsForEndpoint(endpoint:Endpoint)->Int{
    return requestsForEndpoint(endpoint).count
  }
  
  public func didServeEndpoint(endpoint:Endpoint)->Bool{
    return !requestsForEndpoint(endpoint).isEmpty
  }
}

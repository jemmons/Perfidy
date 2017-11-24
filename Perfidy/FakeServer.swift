import Foundation
import Medea


public class FakeServer : NSObject{
  public enum Constant {
    static public let defaultStatusCode = 404
  }
  
  public static let defaultURL: URL = URL(string: "http://localhost:10175")!
  public var url: URL {
    return URL(string: "http://localhost:\(port)")!
  }
  public var callback = FakeServerCallbacks()
  fileprivate var requests = [URLRequest]()
  
  fileprivate let port: UInt16
  fileprivate let defaultStatusCode:Int

  fileprivate var socket:GCDAsyncSocket!
  fileprivate var connections = [HTTPConnection]()
  fileprivate var routeToResponseMap = Dictionary<Route, Response>()
  fileprivate var routeToHandlerMap = Dictionary<Route, (URLRequest)->Void>()

  
  public init(port: UInt16 = 10175, defaultStatusCode: Int = Constant.defaultStatusCode){
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
  
  
  static func runWith(port: UInt16 = 10175, defaultStatusCode: Int = Constant.defaultStatusCode, f: (FakeServer)->Void) {
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

  
  func add(_ jsonArray: [JSONObject]) {
    let routesAndResponses: [(Route, Response)] = jsonArray.map { json in
      let route = Route(method: json["method"] as? String, path: json["path"] as? String)
      let response = Response(status: json["status"] as? Int, data: Helper.data(from: json["content"]))
      return (route, response)
    }
    
    add(routesAndResponses)
  }
  
  
  func add(fromFileName name: String, bundle: Bundle = Bundle.main) throws {
    guard let jsonArray = try JSONHelper.jsonArray(fromFileNamed: name, bundle: bundle) as? [JSONObject] else {
      throw FileError.malformed(name)
    }
    add(jsonArray)
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



private enum Helper {
  static func data(from content: Any?) -> Data? {
    switch content {
    case let obj as JSONObject:
      return try? JSONHelper.data(from: obj)
    case let arr as JSONArray:
      return try? JSONHelper.data(from: arr)
    case is NSNull:
      return nil
    case let any?:
      return String(describing: any).data(using: .utf8)
    case nil:
      return nil
    }
  }
}

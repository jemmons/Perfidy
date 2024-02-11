import Foundation
import NIO
import NIOHTTP1


public class FakeServer {
  private let routeManager = RouteManager()
  private let port: Int
  private let defaultStatus: Int
  private var group: EventLoopGroup?
  private var channel: Channel?
  
  
  public static let defaultURL: URL = URL(string: "http://localhost:\(Default.port)")!
  
  
  public init(port: Int = Default.port, defaultStatusCode: Int = Default.status) throws {
    self.port = port
    self.defaultStatus = defaultStatusCode
    try start()
  }
}



// MARK: - Public
public extension FakeServer {
  enum Error: LocalizedError {
    case fileNotFound(String), unreadable(URL), notArrayOfObjects
    
    public var errorDescription: String? {
      switch self {
      case .fileNotFound(let n):
        return "The file “\(n)” could not be found."
      case .unreadable(let url):
        return "Unable to open or read the file at \(url.absoluteString)."
      case .notArrayOfObjects:
        return "Expected an array of objects, but found some other JSON type."
      }
    }

    
    public var failureReason: String? {
      switch self {
      case .fileNotFound, .unreadable:
        return "File Error"
      case .notArrayOfObjects:
        return "JSON Error"
      }
    }
  }


  enum Default {
    public static let port = 10175
    public static let status = 404
  }
  
  
  var url: URL {
    return URL(string: "http://localhost:\(port)")!
  }
  
  
  func stop() {
    routeManager.clear()
    
    try? channel?.close().wait()
    channel = nil
    try? group?.syncShutdownGracefully()
    group = nil
  }
  
  
  func add(_ route: Route, response: Response = 200, handler: ((URLRequest) -> Void)? = nil) {
    routeManager.add(response: response, forRoute: route)
    if let someHandler = handler {
      routeManager.add(handler: someHandler, forRoute: route)
    }
  }
  
  
  func add(_ routesAndResponses: [(route: Route, response: Response)]) {
    routesAndResponses.forEach { routeManager.add(response: $0.response, forRoute: $0.route) }
  }
  
  
  func add(_ jsonArrayOfObjects: [JSONObject]) {
    let routesAndResponses: [(Route, Response)] = jsonArrayOfObjects.map { json in
      let route = Route(method: json["method"] as? String, path: json["path"] as? String)
      let response = Response(status: json["status"] as? Int, data: Helper.data(from: json["content"]))
      return (route, response)
    }
    
    add(routesAndResponses)
  }
  
  
  func add(fromFileName name: String, bundle: Bundle = Bundle.main) throws {
    guard let url = bundle.url(forResource: name, withExtension: "json") else {
      throw Error.fileNotFound(name + ".json")
    }
    guard let data = try? Data(contentsOf: url) else {
      throw Error.unreadable(url)
    }
    guard let jsonArrayOfObjects = try JSONSerialization.jsonObject(with: data, options: []) as? [JSONObject] else {
      throw Error.notArrayOfObjects
    }
    add(jsonArrayOfObjects)
  }
  
  
  func requests(for route: Route) -> [URLRequest] {
    return routeManager.requests(for: route)
  }
  
  
  @available(*, deprecated, renamed: "requests(for:)")
  func requestsForRoute(_ route: Route) -> [URLRequest] {
     return requests(for: route)
   }

   
  func numberOfRequests(for route: Route) -> Int {
    return requests(for: route).count
  }
  
  
  @available(*, deprecated, renamed: "numberOfRequests(for:)")
  func countOfRequestsForRoute(_ route: Route)->Int{
     return numberOfRequests(for: route)
   }
   
   
  func didRequest(route: Route) -> Bool {
    return !requests(for: route).isEmpty
  }
  
  
  @available(*, deprecated, renamed: "didRequest(route:)")
  func didRequestRoute(_ route: Route) -> Bool {
    return didRequest(route: route)
  }
}



private extension FakeServer {
  func start() throws {
    group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    channel = try Helper.doBootstrap(port: port, defaultStatus: defaultStatus, group: group!, delegate: routeManager)
  }
}



// MARK: - Helper
private enum Helper {
  static func doBootstrap(port: Int, defaultStatus: Int, group: EventLoopGroup, delegate: HTTPHandlerDelegate) throws -> Channel {
    do {
      return try ServerBootstrap(group: group)
        .serverChannelOption(ChannelOptions.backlog, value: 10)
        .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .childChannelInitializer { channel in
          channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
            let httpHandler = DelegateHTTPHandler(defaultStatus: defaultStatus)
            httpHandler.delegate = delegate
            return channel.pipeline.addHandler(httpHandler)
          }
      }
      .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
      .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
      .bind(host: "localhost", port: port).wait()
    } catch let e as IOError {
      switch e.errnoCode {
      case 48:
        throw NetworkError.portAlreadyInUse(port: port)
      default:
        throw UnknownNetworkError(ioError: e)
      }
    }
  }
  
  
  static func data(from content: Any?) -> Data? {
    switch content {
    case let obj as JSONObject:
      guard JSONSerialization.isValidJSONObject(obj) else {
        return nil
      }
      return try? JSONSerialization.data(withJSONObject: obj, options: [])
    case let arr as JSONArray:
      guard JSONSerialization.isValidJSONObject(arr) else {
        return nil
      }
      return try? JSONSerialization.data(withJSONObject: arr, options: [])
    case is NSNull:
      return nil
    case let any?:
      return Data(String(describing: any).utf8)
    case nil:
      return nil
    }
  }
}

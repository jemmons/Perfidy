import Foundation
import NIO
import NIOHTTP1
import Medea


public class FakeServer {
  private let routeManager = RouteManager()
  private let port: Int
  private let defaultStatus: Int
  
  
  public static let defaultURL: URL = URL(string: "http://localhost:\(Default.port)")!
  
  
  private var group: EventLoopGroup?
  private var channel: Channel?
  
  
  public init(port: Int = Default.port, defaultStatusCode: Int = Default.status) {
    self.port = port
    self.defaultStatus = defaultStatusCode
  }
}



// MARK: - Public
public extension FakeServer {
  enum Default {
    public static let port = 10175
    public static let status = 404
  }
  
  
  var url: URL {
    return URL(string: "http://localhost:\(port)")!
  }
  
  
  static func runWith(port: Int = Default.port, defaultStatusCode: Int = Default.status, ƒ: (FakeServer)->Void) {
    let server = FakeServer(port: port, defaultStatusCode: defaultStatusCode)
    try! server.start()
    defer {
      server.stop()
    }
    ƒ(server)
  }
  
  
  func start() throws {
    group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    channel = try Helper.doBootstrap(port: port, defaultStatus: defaultStatus, group: group!, delegate: routeManager)
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
  
  
  func requests(for route: Route) -> [URLRequest] {
    return routeManager.requests(for: route)
  }
  
  
  func numberOfRequests(for route: Route) -> Int {
    return requests(for: route).count
  }
  
  
  func didRequest(route: Route) -> Bool {
    return !requests(for: route).isEmpty
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
      return try? JSONHelper.data(from: obj)
    case let arr as JSONArray:
      return try? JSONHelper.data(from: arr)
    case is NSNull:
      return nil
    case let any?:
      return Data(String(describing: any).utf8)
    case nil:
      return nil
    }
  }
}

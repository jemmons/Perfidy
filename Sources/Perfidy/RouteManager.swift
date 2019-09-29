import Foundation



public class RouteManager {
  private var requests: [URLRequest] = []
  private var routeToResponse: [Route: Response] = [:]
  private var routeToHandler: [Route: (URLRequest)->Void] = [:]
}



public extension RouteManager {
  func clear() {
    requests = []
    routeToResponse = [:]
    routeToHandler = [:]
  }
  
  
  func add(response: Response, forRoute route: Route) {
    routeToResponse[route] = response
  }
  
  
  func add(handler: @escaping (URLRequest)->Void, forRoute route: Route) {
    routeToHandler[route] = handler
  }
  
  
  func requests(for route: Route) -> [URLRequest] {
    requests.filter { Route(request: $0) == route }
  }
}



extension RouteManager: HTTPHandlerDelegate {
  public func received(request: URLRequest) {
    // Called from the thread of NIO’s event loop.
    DispatchQueue.main.async {
      self.requests.append(request)
      self.routeToHandler[Route(request: request)]?(request)
    }
  }

  
  public func response(for route: Route) -> Response? {
    // Called from the thread of NIO’s event loop.
    return routeToResponse[route]
  }
}

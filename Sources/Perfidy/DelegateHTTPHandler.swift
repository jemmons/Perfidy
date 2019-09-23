import Foundation
import NIO
import NIOHTTP1



public protocol HTTPHandlerDelegate: class {
  func received(request: URLRequest)
  func response(for route: Route) -> Response?
}



class DelegateHTTPHandler: ChannelInboundHandler {
  typealias InboundIn = HTTPServerRequestPart
  typealias OutboundOut = HTTPServerResponsePart
  
  private let defaultStatus: Int
  private var head: HTTPRequestHead?
  private var body: ByteBuffer?
  weak public var delegate: HTTPHandlerDelegate?
 
  
  init(defaultStatus: Int) {
    self.defaultStatus = defaultStatus
  }
  
  
  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let req: HTTPServerRequestPart = unwrapInboundIn(data)
    switch req {
    case let .head(newHead):
      guard head == nil, body == nil else {
        fatalError("Trying to write HEAD into a non-empty handler.")
      }
      head = newHead
      
    case var .body(newBuffer):
      guard head != nil else {
        fatalError("Writing BODY into a handler with no HEAD.")
      }
      if body == nil {
        body = newBuffer
      } else {
        body?.writeBuffer(&newBuffer)
      }
      
    case .end:
      defer {
        head = nil
        body = nil
      }

      guard let someHead = head else {
        fatalError("Completed HTTP read with no HEAD.")
      }
      
      if let someRequest = try? URLRequest(requestHead: someHead, body: body) {
        delegate?.received(request: someRequest)
      }
      
      let route = Route(requestHead: someHead)
      let response = delegate?.response(for: route) ?? Response(status: defaultStatus, data: nil)

      sendResponse(context: context, response: response)
    }
  }
}



private extension DelegateHTTPHandler {
  func sendResponse(context: ChannelHandlerContext, response: Response) {
    // This will hang the connection when the (non-existent) status code "666" is to be sent. Useful for testing timeouts.
    guard response.status != 666 else {
      return
    }

    context.write(wrapOutboundOut(.head(makeHead(status: response.status, headers: response.headers))), promise: nil)
    if let someBody = response.body {
      context.write(wrapOutboundOut(.body(.byteBuffer(makeBody(context: context, data: someBody)))), promise: nil)
    }
    context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    context.channel.close(promise: nil)
    
  }
  
  
  func makeHead(status: Int, headers: [String: String]) -> HTTPResponseHead {
    let responseStatus = HTTPResponseStatus(statusCode: status)
    var responseHead = HTTPResponseHead(version: HTTPVersion.init(major: 1, minor: 1), status: responseStatus)
    responseHead.headers = HTTPHeaders(headers.map { $0 })
    
    return responseHead
  }
  
  
  func makeBody(context: ChannelHandlerContext, data: Data) -> ByteBuffer {
    var buf = context.channel.allocator.buffer(capacity: data.count)
    buf.writeBytes(data)
    
    return buf
  }
}


private extension URLRequest {
  enum Malformed: Error {
    case requestHead
  }
  
  
  init(requestHead: HTTPRequestHead, body: ByteBuffer?) throws {
    guard let url = URL(string: requestHead.uri) else {
      throw Malformed.requestHead
    }
    
    var req = URLRequest(url: url)
    req.httpMethod = requestHead.method.rawValue
    
    // In theory, `HTTPHeaders` should already be a collection with `Element = (String, String)`. But Swift can’t deduce the type of `S` unless I transform it into an `Array` here.
    let collection = requestHead.headers.map { $0 }
    req.allHTTPHeaderFields = Dictionary<String, String>(collection, uniquingKeysWith: { (first, _) in first })
    
    if let _buffer = body,
      let bytes = _buffer.getBytes(at: 0, length: _buffer.readableBytes) {
      req.httpBody = Data(bytes: bytes)
    }
    
    self = req
  }
}

import Foundation

extension NSURLRequest{
  static func requestWithMessage(message:CFHTTPMessageRef)->NSURLRequest{
    let request = NSMutableURLRequest()
    request.HTTPBody = CFHTTPMessageCopyBody(message).takeRetainedValue()
    request.HTTPMethod = CFHTTPMessageCopyRequestMethod(message).takeRetainedValue() as String
    request.URL = CFHTTPMessageCopyRequestURL(message).takeRetainedValue()
    return request.copy() as! NSURLRequest
  }
}



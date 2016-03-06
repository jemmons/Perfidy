import Foundation
import Rebar

extension NSURLRequest{
  static func requestWithMessage(message: CFHTTPMessageRef) -> NSURLRequest{
    return thisAfter(NSMutableURLRequest()) { rec in
      if let body = CFHTTPMessageCopyBody(message) {
        rec.HTTPBody = body.takeRetainedValue()
      }
      if let method = CFHTTPMessageCopyRequestMethod(message) {
        rec.HTTPMethod = method.takeRetainedValue() as String
      }
      if let url = CFHTTPMessageCopyRequestURL(message) {
        rec.URL = url.takeRetainedValue()
      }
    }
  }
}

import Foundation
import XCTest
import Perfidy


class RouteTests: XCTestCase {
  func testEquality() {
    XCTAssertEqual(Route(method: .get, path: "/foo"), Route(method: .get, path: "/foo"))
    XCTAssertEqual(Route(method: .head, path: "/foo"), Route(method: .head, path: "/foo"))
    XCTAssertEqual(Route(method: .get, path: "/bar"), Route(method: .get, path: "/bar"))
    XCTAssertNotEqual(Route(method: .get, path: "/foo"), Route(method: .get, path: "/bar"))
    XCTAssertNotEqual(Route(method: .get, path: "/foo"), Route(method: .head, path: "/foo"))
    XCTAssertNotEqual(Route(method: .get, path: "/foo"), Route(method: .head, path: "/bar"))
  }
  
  
  func testStringLiteral() {
    var subject: Route = "GET /foo"
    XCTAssertEqual(subject, Route(method: .get, path: "/foo"))
    
    subject = "/foo"
    XCTAssertEqual(subject, Route(method: .get, path: "/foo"))

    subject = "foo"
    XCTAssertEqual(subject, Route(method: .get, path: "/foo"))
    
    subject = "HEAD"
    XCTAssertEqual(subject, Route(method: .head, path: "/"))
    
    subject = "head"
    XCTAssertEqual(subject, Route(method: .head, path: "/"))
    
    subject = "HEAD   foo bar/baz"
    XCTAssertEqual(subject, Route(method: .head, path: "/foo+bar/baz"))

    subject = ""
    XCTAssertEqual(subject, Route(method: .get, path: "/"))
  }
  
  
  func testDefaults() {
    XCTAssertEqual(Route(), Route(method: .get, path: "/"))
    XCTAssertEqual(Route(method: nil as Verb?, path: nil), Route(method: .get, path: "/"))
    XCTAssertEqual(Route(method: nil as String?, path: nil), Route(method: .get, path: "/"))
  }
  
  
  func testDescription() {
    XCTAssertEqual(Route(method: .get, path: "/foo").description, "GET /foo")
  }
  
  
  func testStringLiteralConvertible() {
    XCTAssertEqual("/foo/bar", Route(method: .get, path: "/foo/bar"))
  }
}

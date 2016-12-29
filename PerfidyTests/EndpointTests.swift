import Foundation
import XCTest
import Perfidy


class EndpointTests: XCTestCase {
  func testEquality() {
    XCTAssertEqual(Endpoint(method: .get, path: "/foo"), Endpoint(method: .get, path: "/foo"))
    XCTAssertEqual(Endpoint(method: .head, path: "/foo"), Endpoint(method: .head, path: "/foo"))
    XCTAssertEqual(Endpoint(method: .get, path: "/bar"), Endpoint(method: .get, path: "/bar"))
    XCTAssertNotEqual(Endpoint(method: .get, path: "/foo"), Endpoint(method: .get, path: "/bar"))
    XCTAssertNotEqual(Endpoint(method: .get, path: "/foo"), Endpoint(method: .head, path: "/foo"))
    XCTAssertNotEqual(Endpoint(method: .get, path: "/foo"), Endpoint(method: .head, path: "/bar"))
  }
  
  
  func testDefaults() {
    XCTAssertEqual(Endpoint(), Endpoint(method: .get, path: "/"))
    XCTAssertEqual(Endpoint(method: nil as Verb?, path: nil), Endpoint(method: .get, path: "/"))
    XCTAssertEqual(Endpoint(method: nil as String?, path: nil), Endpoint(method: .get, path: "/"))
  }
  
  
  func testDescription() {
    XCTAssertEqual(Endpoint(method: .get, path: "/foo").description, "GET /foo")
  }
  
  
  func testStringLiteralConvertible() {
    XCTAssertEqual("/foo/bar", Endpoint(method: .get, path: "/foo/bar"))
  }
}

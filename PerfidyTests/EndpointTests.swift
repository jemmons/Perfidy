import Foundation
import XCTest
import Perfidy


class EndpointTests: XCTestCase {
  func testEquality() {
    XCTAssertEqual(Endpoint(method: .GET, path: "/foo"), Endpoint(method: .GET, path: "/foo"))
    XCTAssertEqual(Endpoint(method: .HEAD, path: "/foo"), Endpoint(method: .HEAD, path: "/foo"))
    XCTAssertEqual(Endpoint(method: .GET, path: "/bar"), Endpoint(method: .GET, path: "/bar"))
    XCTAssertNotEqual(Endpoint(method: .GET, path: "/foo"), Endpoint(method: .GET, path: "/bar"))
    XCTAssertNotEqual(Endpoint(method: .GET, path: "/foo"), Endpoint(method: .HEAD, path: "/foo"))
    XCTAssertNotEqual(Endpoint(method: .GET, path: "/foo"), Endpoint(method: .HEAD, path: "/bar"))
  }
  
  
  func testDefaults() {
    XCTAssertEqual(Endpoint(), Endpoint(method: .GET, path: "/"))
    XCTAssertEqual(Endpoint(method: Optional<Verb>(), path: nil), Endpoint(method: .GET, path: "/"))
    XCTAssertEqual(Endpoint(method: Optional<String>(), path: nil), Endpoint(method: .GET, path: "/"))
  }
  
  
  func testDescription() {
    XCTAssertEqual(Endpoint(method: .GET, path: "/foo").description, "GET /foo")
  }
  
  
  func testStringLiteralConvertible() {
    XCTAssertEqual("/foo/bar", Endpoint(method: .GET, path: "/foo/bar"))
  }
}
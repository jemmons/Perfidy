import Foundation
import XCTest
import Perfidy

class ResponseTests : XCTestCase{
  struct K {
    static let lengthKey = "Content-Length"
    static let typeKey = "Content-Type"
  }
  
  func testNoContent(){
    let subject = Response()
    XCTAssert(subject.data == nil)
    XCTAssert(subject.headers[K.lengthKey] == nil)
    XCTAssert(subject.headers[K.typeKey] == nil)
  }

  
  func testWithTextHTML(){
    let text = "foo"
    let subject = Response(text:text)
    XCTAssertEqual(subject.data, text.dataUsingEncoding(NSUTF8StringEncoding))
    XCTAssertEqual(subject.headers[K.lengthKey], "3")
    XCTAssertEqual(subject.headers[K.typeKey], "text/html")
  }
  
  
  func testContentHeaderOverride(){
    let headers = [K.lengthKey:"42", K.typeKey:"foo/bar"]
    let subject = Response(headers: headers, text:"foo")
    XCTAssertEqual(subject.headers[K.lengthKey], "42")
    XCTAssertEqual(subject.headers[K.typeKey], "foo/bar")
  }
}

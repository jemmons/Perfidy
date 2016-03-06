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
    XCTAssertNil(subject.body)
    XCTAssert(subject.headers[K.lengthKey] == nil)
    XCTAssert(subject.headers[K.typeKey] == nil)
  }

  
  func testWithTextHTML() {
    let text = "foo"
    let subject = Response(text:text)
    XCTAssertEqual(subject.body, text.dataUsingEncoding(NSUTF8StringEncoding))
    XCTAssertEqual(subject.headers[K.lengthKey], "3")
    XCTAssertEqual(subject.headers[K.typeKey], "text/html")
  }
  
  
  func testRawJSON() {
    let subject = try! Response(rawJSON: "{\"foo\"   :  \"bar\"  \n    }")
    XCTAssertEqual(String(data: subject.body!, encoding: NSUTF8StringEncoding), "{\"foo\":\"bar\"}")
    XCTAssertEqual(subject.headers[K.lengthKey], "13")
    XCTAssertEqual(subject.headers[K.typeKey], "application/json")
  }
  
  
  func testInvalidRawJSON() {
    do {
      let _ = try Response(rawJSON: "clearly not json")
    } catch {
      XCTAssert(true)
      return
    }
    XCTFail()
  }
  
  
  func testJSON() {
    let subject = try! Response(json: ["foo":"bar"])
    XCTAssertEqual(String(data: subject.body!, encoding: NSUTF8StringEncoding), "{\"foo\":\"bar\"}")
    XCTAssertEqual(subject.headers[K.lengthKey], "13")
    XCTAssertEqual(subject.headers[K.typeKey], "application/json")
  }
  
  
  func testInvalidJSON() {
    do {
      let _ = try Response(json: [42:"numbers can't be keys"])
    } catch {
      XCTAssert(true)
      return
    }
    XCTFail()
  }

  
  
  func testContentHeaderOverride(){
    let headers = [K.lengthKey:"42", K.typeKey:"foo/bar"]
    let subject = Response(headers: headers, text:"foo")
    XCTAssertEqual(subject.headers[K.lengthKey], "42")
    XCTAssertEqual(subject.headers[K.typeKey], "foo/bar")
  }
  
  
  func testStatusLiteral() {
    let subject: Response = 404
    XCTAssertEqual(subject.status, 404)
    XCTAssertNil(subject.body)
  }
  
  
  func testTextLiteral() {
    let subject: Response = "This is a test."
    XCTAssertEqual(subject.body, "This is a test.".dataUsingEncoding(NSUTF8StringEncoding))
    XCTAssertEqual(subject.headers[K.lengthKey], "15")
    XCTAssertEqual(subject.headers[K.typeKey], "text/html")
  }
  
  
  func testJSONLiteral() {
    let subject: Response = ["foo":"bar"]
    XCTAssertEqual(String(data: subject.body!, encoding: NSUTF8StringEncoding), "{\"foo\":\"bar\"}")
    XCTAssertEqual(subject.headers[K.lengthKey], "13")
    XCTAssertEqual(subject.headers[K.typeKey], "application/json")
  }
}

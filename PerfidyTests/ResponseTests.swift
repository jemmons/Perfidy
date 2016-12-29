import Foundation
import XCTest
import Perfidy



class ResponseTests : XCTestCase{
  let lengthKey = "Content-Length"
  let typeKey = "Content-Type"
  
  
  func testNoContent(){
    let subject = Response()
    XCTAssertNil(subject.body)
    XCTAssert(subject.headers[lengthKey] == nil)
    XCTAssert(subject.headers[typeKey] == nil)
  }

  
  func testWithTextHTML() {
    let text = "foo"
    let subject = Response(text:text)
    XCTAssertEqual(subject.body, text.data(using: .utf8))
    XCTAssertEqual(subject.headers[lengthKey], "3")
    XCTAssertEqual(subject.headers[typeKey], "text/html")
  }
  
  
  func testRawJSON() {
    let subject = try! Response(rawJSON: "{\"foo\"   :  \"bar\"  \n    }")
    XCTAssertEqual(String(data: subject.body!, encoding: String.Encoding.utf8), "{\"foo\":\"bar\"}")
    XCTAssertEqual(subject.headers[lengthKey], "13")
    XCTAssertEqual(subject.headers[typeKey], "application/json")
  }
  
  
  func testInvalidRawJSON() {
    let shouldThrow = expectation(description: "Should throw")
    do {
      let _ = try Response(rawJSON: "clearly not json")
    } catch {
      shouldThrow.fulfill()
    }
    waitForExpectations(timeout: 0.2, handler: nil)
  }
  
  
  func testJSON() {
    let subject = try! Response(json: ["foo":"bar"])
    XCTAssertEqual(String(data: subject.body!, encoding: String.Encoding.utf8), "{\"foo\":\"bar\"}")
    XCTAssertEqual(subject.headers[lengthKey], "13")
    XCTAssertEqual(subject.headers[typeKey], "application/json")
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
    let headers = [lengthKey:"42", typeKey:"foo/bar"]
    let subject = Response(headers: headers, text:"foo")
    XCTAssertEqual(subject.headers[lengthKey], "42")
    XCTAssertEqual(subject.headers[typeKey], "foo/bar")
  }
  
  
  func testStatusLiteral() {
    let subject: Response = 404
    XCTAssertEqual(subject.status, 404)
    XCTAssertNil(subject.body)
  }
  
  
  func testTextLiteral() {
    let subject: Response = "This is a test."
    XCTAssertEqual(subject.body, "This is a test.".data(using: .utf8))
    XCTAssertEqual(subject.headers[lengthKey], "15")
    XCTAssertEqual(subject.headers[typeKey], "text/html")
  }
  
  
  func testJSONLiteral() {
    let subject: Response = ["foo":"bar"]
    XCTAssertEqual(String(data: subject.body!, encoding: String.Encoding.utf8), "{\"foo\":\"bar\"}")
    XCTAssertEqual(subject.headers[lengthKey], "13")
    XCTAssertEqual(subject.headers[typeKey], "application/json")
  }
}

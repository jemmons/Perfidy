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
  
  
  func testRawJSON() throws {
    let subject = try Response(rawJSON: "{\"foo\":\"bar\"}")
    XCTAssertEqual(String(data: subject.body!, encoding: String.Encoding.utf8), "{\"foo\":\"bar\"}")
    XCTAssertEqual(subject.headers[lengthKey], "13")
    XCTAssertEqual(subject.headers[typeKey], "application/json")
    
    let shouldThrow = expectation(description: "malformed JSON")
    do { _ = try Response(rawJSON: "not json") } catch {
      shouldThrow.fulfill()
    }
    waitForExpectations(timeout: 1.0, handler: nil)
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
  
  
  func testJSONObject() throws {
    let subject = try Response(jsonObject: ["foo":"bar"])
    XCTAssertEqual(String(data: subject.body!, encoding: .utf8), "{\"foo\":\"bar\"}")
    XCTAssertEqual(subject.headers[lengthKey], "13")
    XCTAssertEqual(subject.headers[typeKey], "application/json")
  }
  
  
  func testJSONArray() throws {
    let subject = try Response(jsonArray: [1,2,3])
    XCTAssertEqual(String(data: subject.body!, encoding: .utf8), "[1,2,3]")
    XCTAssertEqual(subject.headers[lengthKey], "7")
    XCTAssertEqual(subject.headers[typeKey], "application/json")
  }
  
  
  func testInvalidJSON() {
    do {
      let _ = try Response(jsonObject: ["Invalid value object": Date()])
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
  
  
  func testJSONObjectLiteral() {
    let subject: Response = ["foo":"bar"]
    XCTAssertEqual(String(data: subject.body!, encoding: String.Encoding.utf8), "{\"foo\":\"bar\"}")
    XCTAssertEqual(subject.headers[lengthKey], "13")
    XCTAssertEqual(subject.headers[typeKey], "application/json")
  }
}

import Foundation
import XCTest
import Perfidy

class ResponseTests : XCTestCase{
  func testNoContent(){
    let subject = Response()
    XCTAssert(subject?.data == nil)
    XCTAssert(subject?.allHeaderFields[Response.contentLengthHeaderName] == nil)
  }

  
  func testWithContent(){
    let body = "foo"
    let subject = Response(body:body)
    XCTAssertEqual(subject!.data!, body.dataUsingEncoding(NSUTF8StringEncoding)!)
    if let contentLength = subject?.allHeaderFields[Response.contentLengthHeaderName] as? String{
      XCTAssertEqual(contentLength, "3")
    } else{
      XCTFail()
    }
  }
  
  
  func testContentLengthOverride(){
    let headers = [Response.contentLengthHeaderName:"42"]
    let subjectWithBody = Response(headers: headers, body:"foo")
    let subjectWithoutBody = Response(headers: headers)
    
    if let contentLengthWithBody = subjectWithBody?.allHeaderFields[Response.contentLengthHeaderName] as? String,
      contentLengthWithoutBody = subjectWithoutBody?.allHeaderFields[Response.contentLengthHeaderName] as? String{
        XCTAssertEqual(contentLengthWithBody, "42")
        XCTAssertEqual(contentLengthWithoutBody, "42")
    } else{
      XCTFail()
    }
  }
}

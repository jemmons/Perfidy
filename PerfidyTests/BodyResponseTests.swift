import Foundation
import XCTest
import Perfidy

class BodyResponseTests : XCTestCase{
  func testNoContent(){
    let subject = BodyResponse()
    XCTAssert(subject?.data == nil)
    XCTAssert(subject?.allHeaderFields[BodyResponse.contentLengthHeaderName] == nil)
  }

  
  func testWithContent(){
    let body = "foo"
    let subject = BodyResponse(body:body)
    XCTAssertEqual(subject!.data!, body.dataUsingEncoding(NSUTF8StringEncoding)!)
    if let contentLength = subject?.allHeaderFields[BodyResponse.contentLengthHeaderName] as? String{
      XCTAssertEqual(contentLength, "3")
    } else{
      XCTFail()
    }
  }
  
  
  func testContentLengthOverride(){
    let headers = [BodyResponse.contentLengthHeaderName:"42"]
    let subjectWithBody = BodyResponse(headerFields:headers, body:"foo")
    let subjectWithoutBody = BodyResponse(headerFields:headers)
    
    if let contentLengthWithBody = subjectWithBody?.allHeaderFields[BodyResponse.contentLengthHeaderName] as? String,
      contentLengthWithoutBody = subjectWithoutBody?.allHeaderFields[BodyResponse.contentLengthHeaderName] as? String{
        XCTAssertEqual(contentLengthWithBody, "42")
        XCTAssertEqual(contentLengthWithoutBody, "42")
    } else{
      XCTFail()
    }
  }
}

import XCTest
import Perfidy
import Medea



private enum K {
  static let account = ["id": "111",
                        "name": "Walker",
                        "money": "10.33"]
}



class FromFileTests: XCTestCase {
  
  func testMockInterface() {
    let server = FakeServer()
    try! server.add(fromFileName: "mockinterface", bundle: fetchFakeBundle())
    try! server.start()
    defer { server.stop() }
    
    let expectedGETResponse = expectation(description: "Waiting for GET response")
    let expectedPOSTResponse = expectation(description: "Waiting for POST response")
    let expectedPUTResponse = expectation(description: "Waiting for PUT response")
    
    session.resumeRequest("GET", "/api/account/111") { data, res, err in
      XCTAssertNil(err)
      XCTAssertEqual(res?.statusCode, 200)
      let json = try! JSONHelper.jsonObject(from: data!)
      XCTAssertEqual(json as! [String: String], K.account)
      expectedGETResponse.fulfill()
    }
    
    
    session.resumeRequest("POST", "/api/account") { data, res, err in
      XCTAssertNil(err)
      XCTAssertEqual(res?.statusCode, 201)
      let json = try! JSONHelper.jsonObject(from: data!)
      XCTAssertEqual(json as! [String: String], K.account)
      expectedPOSTResponse.fulfill()
    }

    
    session.resumeRequest("PUT", "/api/account/111/money") { data, res, err in
      XCTAssertNil(err)
      XCTAssertEqual(res?.statusCode, 204)
      XCTAssert(data!.isEmpty)
      expectedPUTResponse.fulfill()
    }
    
    wait(for: [expectedGETResponse, expectedPOSTResponse, expectedPUTResponse], timeout: 1)
  }
}


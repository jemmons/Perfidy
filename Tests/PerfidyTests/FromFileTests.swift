import XCTest
import Perfidy



private enum K {
  static let account = ["id": "111",
                        "name": "Walker",
                        "money": "10.33"]
}



class FromFileTests: XCTestCase {
  func testMockInterface() throws {
    let server = try FakeServer()
    defer { server.stop() }
    try server.add(fromFileName: "mockinterface", bundle: fetchFakeBundle())
    
    let expectedGETResponse = expectation(description: "Waiting for GET response")
    let expectedPOSTResponse = expectation(description: "Waiting for POST response")
    let expectedPUTResponse = expectation(description: "Waiting for PUT response")
    
    session.resumeRequest("GET", "/api/account/111") { data, res, err in
      XCTAssertNil(err)
      XCTAssertEqual(res?.statusCode, 200)
      let json = try! JSONDecoder().decode([String: String].self, from: data!)
      XCTAssertEqual(json, K.account)
      expectedGETResponse.fulfill()
    }
    
    
    session.resumeRequest("POST", "/api/account") { data, res, err in
      XCTAssertNil(err)
      XCTAssertEqual(res?.statusCode, 201)
      let json = try! JSONDecoder().decode([String: String].self, from: data!)
      XCTAssertEqual(json, K.account)
      expectedPOSTResponse.fulfill()
    }

    
    session.resumeRequest("PUT", "/api/account/111/money") { data, res, err in
      XCTAssertNil(err)
      XCTAssertEqual(res?.statusCode, 204)
      XCTAssert(data!.isEmpty)
      expectedPUTResponse.fulfill()
    }
    
    wait(for: [expectedGETResponse, expectedPOSTResponse, expectedPUTResponse], timeout: 10)
  }
}


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
    try! server.add(fromFileName: "mockinterface", bundle: Bundle(for: type(of: self)))
    try! server.start()
    defer { server.stop() }
    
    let expectedGETResponse = expectation(description: "Waiting for GET response")
    let expectedPOSTResponse = expectation(description: "Waiting for POST response")
    let expectedPUTResponse = expectation(description: "Waiting for PUT response")
    
    fakeHost.get("/api/account/111").json { res in
      if case let .success(.ok, .object(json)) = res {
        XCTAssertEqual(json as! [String: String], K.account)
        expectedGETResponse.fulfill()
      }
    }
    
    fakeHost.post("/api/account", params: .form([URLQueryItem(name: "foo", value: "bar")])).json { res in
      if case let .success(.created, .object(json)) = res {
        XCTAssertEqual(json as! [String: String], K.account)
        expectedPOSTResponse.fulfill()
      }
    }
    
    fakeHost.put("/api/account/111/money", params: .form([URLQueryItem(name: "foo", value: "bar")])).data { res in
      if case let .success(.noContent, _, data) = res {
        XCTAssert(data.isEmpty)
        expectedPUTResponse.fulfill()
      }
    }
    
    wait(for: [expectedGETResponse, expectedPOSTResponse, expectedPUTResponse], timeout: 1)
  }
}


import Foundation
import XCTest
import Perfidy
import Medea

class TestTests: XCTestCase {
  func testSaveForm() {
    let expectSave = expectation(description: "Saved")
    FakeServer.runWith { server in
      server.add("POST /form") { req in
        let jsonData = try! JSONHelper.data(from: ["first_name": "first","last_name": "last","age": "55"])
        XCTAssertEqual(req.httpBody, jsonData)
        expectSave.fulfill()
      }

      let subject = MockForm()
      subject.save()
      waitForExpectations(timeout: 2.0, handler: nil)
    }
  }
}

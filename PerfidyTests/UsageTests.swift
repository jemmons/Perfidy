import Foundation
import XCTest
import Perfidy
import Medea

class TestTests: XCTestCase {
  func testSaveForm() {
    let expectSave = expectation(description: "Saved")
    FakeServer.runWith { server in
      server.add("POST /form") { req in
        let json = try! JSONHelper.jsonObject(from: req.httpBody!) as! [String: String]
        XCTAssertEqual(json["first_name"], "first")
        XCTAssertEqual(json["last_name"], "last")
        XCTAssertEqual(json["age"], "55")
        XCTAssertEqual(json.count, 3)
        expectSave.fulfill()
      }

      let subject = MockForm()
      subject.save()
      waitForExpectations(timeout: 2.0, handler: nil)
    }
  }
}

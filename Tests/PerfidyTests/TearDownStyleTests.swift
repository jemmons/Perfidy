import XCTest
import Perfidy



class TearDownStyleTests: XCTestCase {
  let server = FakeServer()
  
  
  override func tearDown() {
    server.stop()
  }
  
  
  // Pretend we want to test an app that will update a mesasge...
  func testPostData() {
    let expectUpdateRequestSent = expectation(description: "Should send a request to update the message.")
    let expectConfirmation = expectation(description: "Should display update confirmation.")
    
    // Add the path the app would be posting to our fake server.
    server.add("PUT /message/1", response: 204) { request in
      // This closure will be executed with the response received by the server. Verify the expected properties have been sent by the app here.
      expectUpdateRequestSent.fulfill()
    }
    
    // Start the fake server.
    try! server.start()
    
    // Do what we have to in our app to update the message. For this example, we’re sending a request via `URLSession`.
    let session = URLSession(configuration: URLSessionConfiguration.default)
    var req = URLRequest(url: URL(string: "http://localhost:10175/message/1")!)
    req.httpMethod = "PUT"
    session.dataTask(with: req) { _, _, _ in
      // Check that the app properly updates its UI after receiving the response from the server.
      expectConfirmation.fulfill()
    }.resume()
    
    wait(for: [expectUpdateRequestSent, expectConfirmation], timeout: 1)
  }
}

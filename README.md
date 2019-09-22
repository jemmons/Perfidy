# Perfidy
#### Fake service for iOS testing.
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-success)](https://github.com/Apple/swift-package-manager)

Perfidy is tiny HTTP server implemented with SwiftNIO that you can spin up in your tests to fake out your API without hitting the network. This keeps your tests isolated and fast.

The syntax is, at least initially, pretty straight forward:

```swift
import Perfidy
let server = FakeServer()
server.start()
//...
server.stop()
```

Though the whole point is to run it in a test. Here’s what it looks like in an `XCTestCase`:

```swift
import XCTest
import Perfidy
import YourApp


class MessageTests: XCTestCase {
  // By default the fake server will listen to `localhost` on port `10175`.
  let server = FakeServer()
  
  override func tearDown() {
    // To maintain, isolation disconnect the server after every test.
    server.stop()
  }
  
  // Pretend we want to test an app that will update a mesasge...
  func testPostData() {
    // Network tests are, by their nature, async. Expectations are our friends!
    let expectUpdateRequestSent = expectation(description: "Should send a request to update the message.")
    let expectConfirmation = expectation(description: "Should display update confirmation.")
    
    // Add an endpoint to our fake server with the response we expect and a 
    // closure that gets called whenever a request is received.
    //
    // Our response here is a simple status code, but we can also specify that
    // JSON or arbitrary `Data` get returned in the body.
    server.add("PUT /message/1", response: 204) { request in
      // Verify the expected properties have been sent by the app here. Then:
      expectUpdateRequestSent.fulfill()
    }
    
    // Start the fake server. From now until `server.stop()` it’s listening for connections.
    try! server.start()
    
    // Do what we have to to make our app update a message. This will be “heard”
    // by our fake server, which will respond according to the endpoint we added
    // up above.
    MyApp.shared.updateMessage(title: "New Title")
    
    // Then check the app updated its UI after receiving the server response.
    // `NotificationCenter` can be useful for this.
    expectConfirmation.fulfill()
    
    wait(for: [expectUpdateRequestSent, expectConfirmation], timeout: 1)
  }
}
```

If you, like me, kinda hate `tearDown`, there’s also a trailing-closure version:

```swift
class MessageTests: XCTestCase {
  func testPostData() {
    let expectUpdateRequestSent = expectation(description: "Should send a request to update the message.")
    let expectConfirmation = expectation(description: "Should display update confirmation.")

    FakeServer.runWith { server in
      // The server is already running at this point. But we can still add endpoints.
      server.add("PUT /message/1", response: 204) { request in
        expectUpdateRequestSent.fulfill()
      }

      MyApp.shared.updateMessage(title: "New Title")
      
      // ...we get a notification from the app or something on update, then:
      expectConfirmation.fulfill()
      
      wait(for: [expectUpdateRequestSent, expectConfirmation], timeout: 1)
      
      // No need to call `stop` on the server. It stops on its own when leaving this scope. 
    }
  }
```

And there’s a lot more I haven’t documented yet 😰. Stuff like pointing to a single JSON file to load a whole bunch of endpoints with full responses in one go. If you have questions, don’t hesitate to [reach out](https://twitter.com/jemmons) for more details. It’s my fault for not writing faster. 

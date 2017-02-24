# Perfidy
#### Fake service for iOS testing.
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Perfidy is tiny HTTP server written in Swift. We can spin it up in our tests to fake out our API without hitting the network. This keeps our tests isolated and fast.


## Introduction

The syntax is, at least initially, pretty straight forward:

```swift
import Perfidy

let server = FakeServer()
server.add("/path/to/hit")
try! server.start()
// Do things that connect to http://localhost:10175/path/to/hit
server.stop()
```

Of course, outside of a test, this doesn't do much for us. Here's what it looks like in an XCTest:

```swift
import XCTest
import Perfidy
import MyApp

class MyTests : XCTestCase{
  var server = FakeServer()
  override func setUp() { try! server.start() }
  override func tearDown() { server.stop() }

  func testMyThings(){
    let shouldRespond = expectation(description: "responded")

    server.add("/path/to/hit")
    myApp.doThingThatHitsTheNetwork() { response in
      shouldRespond.fulfill()
    }

    waitForExpectations(timeout: 1.0, handler: nil)
  }
}
```

There's a very common pattern here: create a `FakeServer` object, fake out some endpoints, start it up, run some code, and shut it down. In fact, it's so common, Perfidy offers some conveniences for it:

```swift
func testMyThings(){
  let shouldRespond = expectation(description: "responded")

  FakeServer.runWith { server in
    server.add("/path/to/hit")
    myApp.doThingThatHitsTheNetwork() { response in
      shouldRespond.fulfill()
    }

    waitForExpectations(timeout: 1.0, handler: nil)
  }
}
```

This encapsulates the creation, running, and halting of the fake server, elimitating the need for `setUp` and `tearDown` methods in most common cases.

## Faking Endpoints

There are two reasons we might want to fake out an endpoint for our tests:

* We want to validate a request our app is sending to a server.
* We want to test an aspect of our app that depends on getting data from a server.

### Validate Requests
Endpoints can be added with a handler that gets called when a request is received. It can be used to validate the contents of the given request:

```swift
func testPostedData() {
  let postedData: Data = dataFromMyApp
  let shouldSend = expectation(description: "Sent data")

  FakeServer.runWith { server in
    server.add("POST /foo") { request in
      XCTAssertEqual(request.httpBody, dataFromMyApp)
      shouldSend.fulfill()
    }
    myApp.postData(dataFromMyApp)

    waitForExpectations(timeout: 1.0, handler: nil)
  }
}
```

### Fake Responses
Sometimes our app needs to get back specific data or errors from a server in order to exercise a code path. We can add endpoints that respond with arbitrary status codes, headers, strings, json, or even plain ol' bytes:

```swift
func testGetListings() {
  let shouldFetch = expectation(description: "Received data")
  
  FakeServer.runWith { server in
    server.add("/listings", response: fakeListingsJSON)
    myApp.loadListingsView {
      // Assert listing details here...
      shouldFetch.fulfill()
    }
  
    waitForExpectations(timeout: 1.0, handler: nil)
  }
}
```

Often a single unit of functionality will make many API calls in the course of running. Adding an array of responses is easy:

```swift
let endpoints = [
  ("/listing", listingJSON),
  ("/image",   imageData),
  ("/reviews", reviewJSON),
]

server.add(endpoints)
```

### …And Much More!
`add()` has a lot of flexibility in its syntax. These are all valid expressions, for example:

```swift
server.add("/foo")
server.add("POST /foo", response: 201) 
server.add(Route(method: .get, path:"/foo"), response: ["data": "hello"])
```

See the documentation for `Route` and `Response` for more examples.


## API
Full API documentation [can be found here](https://jemmons.github.io/Perfidy).


## Attribution

Perfidy makes use of networking code from the amazing [CocoaAsyncSocket project](https://github.com/robbiehanson/CocoaAsyncSocket). I used to write C socket libraries in the 90s. I can't tell you how happy I am not to have to do it again.

# Perfidy
#### Fake service for iOS testing.
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Perfidy is tiny HTTP server written in Swift that you can spin up in your tests to fake out your API without hitting the network. This keeps your tests isolated and fast.

The syntax is, at least initially, pretty straight forward:

```
import Perfidy
let server = FakeServer()
server.start()
//...
server.stop()
```

Of course, this doesn't server much of a purpose outside of a test. Here's what it looks like in XCTest:

```
import XCTest
import Perfidy
import YourApp
class MyTests : XCTestCase{
  var server = FakeServer()
  override func tearDown() { server.stop() }

  func testMyThings(){
let expectation = expectationWithDescription("Should hit service")
server.start()

  }
}
```

Perfidy makes use of networking code from the amazing [CocoaAsyncSocket project][2]. I used to write C socket libraries in the 90s. I can't tell you how happy I am not to have to do it again.


[2]:	https://github.com/robbiehanson/CocoaAsyncSocket

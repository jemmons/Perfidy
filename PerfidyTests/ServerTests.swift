import UIKit
import XCTest
import Perfidy
import Medea
import SessionArtist

class ServerTests: XCTestCase {
  func testTimeout() {
    let timeoutHost = Host(baseURL: FakeServer.defaultURL, timeout: 0.1)
    let shouldTimeOut = expectation(description: "times out")
    
    FakeServer.runWith { server in
      server.add("/", response: 666)
      
      timeoutHost.get("/").data { res in
        if case .failure(URLError.timedOut) = res {
          shouldTimeOut.fulfill()
        }
      }
      wait(for: [shouldTimeOut], timeout: 1)
    }
  }
  

  func testDefaultShouldConnect(){
    let expectResponse = expectation(description: "Response received.")
    FakeServer.runWith { _ in
      fakeHost.get("/").data { res in
        if case .success(404, _, _) = res {
          expectResponse.fulfill()
        }
      }
      wait(for: [expectResponse], timeout: 1)
    }
  }
  
  
  func testShouldErrorOnDuplicateConnections(){
    let shouldThrow = expectation(description: "Should throw")
    FakeServer.runWith { server in
      do {
        try server.start()
      } catch {
        XCTAssert((error as NSError).localizedDescription.contains("accept while connected"))
        shouldThrow.fulfill()
      }
      waitForExpectations(timeout: 2.0, handler: nil)
    }
  }

  
  func testStatusCodes(){
    let expect201 = expectation(description: "201 status code")
    let expect300 = expectation(description: "300 status code")
    let expect400 = expectation(description: "400 status code")
    let expect800 = expectation(description: "Nonexistant status code")

    FakeServer.runWith { server in
      server.add("/201", response: 201)
      server.add("/300", response: 300)
      server.add("/400", response: 400)
      server.add("/800", response: 800)

      fakeHost.get("/201").data { res in
        if case .success(201, _, _) = res {
          expect201.fulfill()
        }
      }

      fakeHost.get("/300").data { res in
        if case .success(300, _, _) = res {
          expect300.fulfill()
        }
      }

      fakeHost.get("/400").data { res in
        if case .success(400, _, _) = res {
          expect400.fulfill()
        }
      }

      fakeHost.get("/800").data { res in
        if case .failure(HTTPError.unknownCode(800)) = res {
          expect800.fulfill()
        }
      }

      wait(for: [expect201, expect300, expect400, expect800], timeout: 1)
    }
  }


  func testSetDefaultStatusCode(){
    let should500 = expectation(description: "should implicitly return 500 without specifying a response")

    FakeServer.runWith(defaultStatusCode: 500) { server in
      fakeHost.get("/foo/bar/baz").data { res in
        if case .success(500, _, _) = res {
          should500.fulfill()
        }
      }
      wait(for: [should500], timeout: 1)
    }
  }


  func testDefaultStatusCodeOfAddedRoute() {
    let should200 = expectation(description: "respond with a 200")
    FakeServer.runWith { server in
      server.add("/real/route")
      fakeHost.get("/real/route").data { res in
        if case .success(200, _, _) = res {
          should200.fulfill()
        }
      }
      wait(for: [should200], timeout: 1)
    }
  }


  func testHeaders() {
    let shouldReceive = expectation(description: "receive request with header")
    let shouldRespond = expectation(description: "respond")

    FakeServer.runWith { server in
      server.add("/", response: 200) { req in
        XCTAssertEqual(req.value(forHTTPHeaderField: "foo"), "bar")
        shouldReceive.fulfill()
      }

      fakeHost.get("/", headers: [.other("foo"): "bar"]).data { _ in
        shouldRespond.fulfill()
      }

      wait(for: [shouldReceive, shouldRespond], timeout: 1)
    }
  }


  func testRawJSONResponse(){
    let expectedResponse = expectation(description: "Should get response")

    FakeServer.runWith { server in
      let res = try! Response(status: 201, rawJSON:"{\"thing\":42}")
      server.add("/path", response: res)

      fakeHost.get("/path").jsonObject { res in
        if case let .success(201, json) = res {
          XCTAssertEqual(json["thing"] as! NSNumber, 42)
          expectedResponse.fulfill()
        }
      }

      wait(for: [expectedResponse], timeout: 1)
    }
  }


  func testJSONObjectResponse(){
    let expectedResponse = expectation(description: "Should get response")

    FakeServer.runWith { server in
      let res = try! Response(status: 202, jsonObject:["fred":"barney"])
      server.add("/path", response: res)

      fakeHost.get("/path").jsonObject { res in
        if case let .success(202, json) = res {
          XCTAssertEqual(json["fred"] as! String, "barney")
          expectedResponse.fulfill()
        }
      }

      wait(for: [expectedResponse], timeout: 1)
    }
  }


  func testJSONArrayResponse(){
    let expectResponse = expectation(description: "Should get response")

    FakeServer.runWith { server in
      let res = try! Response(status: 203, jsonArray:["fred","barney"])
      server.add("/some/path", response: res)

      fakeHost.get("/some/path").jsonArray { res in
        if case let .success(203, json) = res {
          XCTAssertEqual(json as! [String], ["fred","barney"])
          expectResponse.fulfill()
        }
      }

      wait(for: [expectResponse], timeout: 1)
    }
  }


  func testPostingData() {
    let expectSent = expectation(description: "Sent data")
    let expectReceived = expectation(description: "Received data")

    FakeServer.runWith { server in
      server.add("POST /") { req in
        XCTAssertEqual(req.allHTTPHeaderFields!["Content-Type"], "application/json")
        XCTAssertEqual(String(data: req.httpBody!, encoding: .utf8), "{\"foo\":\"bar\"}")
        expectReceived.fulfill()
      }

      let json = try! ValidJSONObject(["foo": "bar"])
      fakeHost.post("/", json: json).data { _ in
        expectSent.fulfill()
      }

      wait(for: [expectSent, expectReceived], timeout: 1)
    }
  }


  func testDefaultURL() {
    XCTAssertEqual(FakeServer.defaultURL.absoluteString, "http://localhost:10175")
  }


  func testFakeServerURL() {
    FakeServer.runWith(port: 11111) { server in
      XCTAssertEqual(server.url.absoluteString, "http://localhost:11111")
    }
  }
}


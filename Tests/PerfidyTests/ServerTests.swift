import XCTest
import Perfidy



class ServerTests: XCTestCase {
  func testTimeout() throws {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 1.0
    let quickTimeoutSession = URLSession(configuration: config)
    
    let shouldTimeOut = expectation(description: "times out")
    
    let server = try FakeServer()
    defer { server.stop() }
    server.add("/", response: 666)
      
    quickTimeoutSession.resumeRequest("GET", "/") { _, _, error in
      guard let someError = error as NSError? else {
        XCTFail()
        return
      }
      XCTAssertEqual(someError.code, URLError.timedOut.rawValue)
      XCTAssertEqual(someError.domain, URLError.errorDomain)
      shouldTimeOut.fulfill()
    }
    
    wait(for: [shouldTimeOut], timeout: 2)
  }
  

  func testDefaultShouldConnect() throws {
    let expectResponse = expectation(description: "Response received.")
    let server = try FakeServer()
    defer { server.stop() }
    session.resumeRequest("GET", "/") { data, res, error in
      XCTAssertEqual(res!.statusCode, 404)
      expectResponse.fulfill()
    }
    wait(for: [expectResponse], timeout: 1)
  }


  func testShouldErrorOnDuplicateConnections() throws {
    let shouldThrow = expectation(description: "Should throw")
    let server = try FakeServer()
    defer { server.stop() }
    do {
      let otherServer = try FakeServer()
    } catch NetworkError.portAlreadyInUse(let port) {
      XCTAssertEqual(port, 10175)
      shouldThrow.fulfill()
    } catch {
      XCTFail()
    }
    wait(for: [shouldThrow], timeout: 2)
  }


  func testStatusCodes() throws {
    let expect201 = expectation(description: "201 status code")
    let expect300 = expectation(description: "300 status code")
    let expect400 = expectation(description: "400 status code")
    let expect800 = expectation(description: "Nonexistant status code")

    let server = try FakeServer()
    defer { server.stop() }
    server.add("/201", response: 201)
    server.add("/300", response: 300)
    server.add("/400", response: 400)
    server.add("/800", response: 800)

    session.resumeRequest("GET", "/201") { _, res, _ in
      XCTAssertEqual(res!.statusCode, 201)
      expect201.fulfill()
    }
    
    session.resumeRequest("GET", "/300") { _, res, _ in
      XCTAssertEqual(res!.statusCode, 300)
      expect300.fulfill()
    }
    
    session.resumeRequest("GET", "/400") { _, res, _ in
      XCTAssertEqual(res!.statusCode, 400)
      expect400.fulfill()
    }

      
    session.resumeRequest("GET", "/800") { _, res, _ in
      XCTAssertEqual(res!.statusCode, 800)
      expect800.fulfill()
    }
    
    wait(for: [expect201, expect300, expect400, expect800], timeout: 1)
  }

  
  
  func testSetDefaultStatusCode() throws {
    let shouldBurn = expectation(description: "should implicitly return `defaultStatusCode` when no response given")
    
    let server = try FakeServer(defaultStatusCode: 541)
    defer { server.stop() }
    session.resumeRequest("GET", "/foo/bar/baz") { _, res, _ in
      XCTAssertEqual(res!.statusCode, 541)
      shouldBurn.fulfill()
    }
    wait(for: [shouldBurn], timeout: 1)
  }


  func testDefaultStatusCodeOfAddedRoute() throws {
    let should200 = expectation(description: "routes without status codes are assumed to be 200")
    let server = try FakeServer()
    defer { server.stop() }
    server.add("/real/route")
    session.resumeRequest("GET", "/real/route") { _, res, _ in
      XCTAssertEqual(res!.statusCode, 200)
      should200.fulfill()
    }
    wait(for: [should200], timeout: 1)
  }


  func testHeaders() throws {
    let shouldReceive = expectation(description: "receive request with header")
    let shouldRespond = expectation(description: "respond")

    let server = try FakeServer()
    defer { server.stop() }
    server.add("/", response: 200) { req in
      XCTAssertEqual(req.value(forHTTPHeaderField: "foo"), "bar")
      shouldReceive.fulfill()
    }

    session.resumeRequest("GET", "/", headers: ["foo": "bar"]) { _, res, error in
      XCTAssertNil(error)
      XCTAssertEqual(res!.statusCode, 200)
      shouldRespond.fulfill()
    }
    
    wait(for: [shouldReceive, shouldRespond], timeout: 1)
  }


  func testRawJSONResponse() throws {
    let expectedResponse = expectation(description: "Should get response")

    let server = try FakeServer()
    defer { server.stop() }
    server.add(
      "/path",
      response: try Response(status: 201, rawJSON:"{\"thing\":42}")
    )
      
    session.resumeRequest("GET", "/path") { data, res, _ in
      XCTAssertEqual(res?.statusCode, 201)
      let json = try! JSONDecoder().decode([String: Int].self, from: data!)
      XCTAssertEqual(json["thing"], 42)
      expectedResponse.fulfill()
    }

    wait(for: [expectedResponse], timeout: 1)
  }


  func testJSONObjectResponse() throws {
    let expectedResponse = expectation(description: "Should get response")

    let server = try FakeServer()
    defer { server.stop() }
    server.add(
      "/path",
      response: try Response(status: 202, jsonObject:["fred":"barney"])
    )

    session.resumeRequest("GET", "/path") { data, res, _ in
      XCTAssertEqual(res!.statusCode, 202)
      let json = try! JSONDecoder().decode([String: String].self, from: data!)
      XCTAssertEqual(json["fred"], "barney")
      expectedResponse.fulfill()
    }

    wait(for: [expectedResponse], timeout: 1)
  }


  func testJSONArrayResponse() throws {
    let expectResponse = expectation(description: "Should get response")

    let server = try FakeServer()
    defer { server.stop() }
    server.add(
      "/some/path",
      response: try Response(status: 203, jsonArray:["fred","barney"])
    )

    session.resumeRequest("GET", "/some/path") { data, res, _ in
      XCTAssertEqual(res!.statusCode, 203)
      let json = try! JSONDecoder().decode([String].self, from: data!)
      XCTAssertEqual(json, ["fred","barney"])
      expectResponse.fulfill()
    }
    
    wait(for: [expectResponse], timeout: 1)
  }


  func testPostingData() throws {
    let expectSent = expectation(description: "Sent data")
    let expectReceived = expectation(description: "Received data")

    let server = try FakeServer()
    defer { server.stop() }
    server.add("POST /") { req in
      XCTAssertEqual(String(data: req.httpBody!, encoding: .utf8), "{\"foo\":\"bar\"}")
      expectReceived.fulfill()
    }

    let data = try JSONEncoder().encode(["foo": "bar"])
    session.resumeRequest("POST", "/", body: data) { _, _, _ in
      expectSent.fulfill()
    }

    wait(for: [expectSent, expectReceived], timeout: 1)
  }


  func testDefaultURL() {
    XCTAssertEqual(FakeServer.defaultURL.absoluteString, "http://localhost:10175")
  }


  func testFakeServerURL() throws {
    let server = try FakeServer(port: 11111)
    defer { server.stop() }
    XCTAssertEqual(server.url.absoluteString, "http://localhost:11111")
  }
  
  
  func testFakeServerListensOnCustomPort() throws {
    let answerOnCustomPort = expectation(description: "should answer on custom port")
    let defaulPortFails = expectation(description: "default port is not available")
    let customServer = try FakeServer(port: 11111, defaultStatusCode: 200)
    defer { customServer.stop() }
    session.dataTask(with: URL(string: "http://localhost:11111/foo")!) { data, res, error in
      XCTAssertNil(error)
      XCTAssertEqual((res as? HTTPURLResponse)?.statusCode, 200)
      answerOnCustomPort.fulfill()
    }.resume()

    session.dataTask(with: URL(string: "http://localhost:10175/foo")!) { data, res, error in
      XCTAssertNil(data)
      XCTAssertNil(res)
      XCTAssert(URLError.cannotConnectToHost ~= error!)
      defaulPortFails.fulfill()
    }.resume()

    wait(for: [answerOnCustomPort, defaulPortFails], timeout: 1)
  }
}


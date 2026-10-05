import XCTest
@testable import uictl

final class UtilitiesTests: XCTestCase {
    func testParsePointValid() throws {
        let p = try parsePoint("10, -20.5")
        XCTAssertEqual(p.x, 10)
        XCTAssertEqual(p.y, -20.5)
    }

    func testParsePointRejectsMalformedInput() {
        for bad in ["", "1", "1,2,3", "a,b", "1,"] {
            XCTAssertThrowsError(try parsePoint(bad), "input: \(bad)")
        }
    }

    func testParseRectValid() throws {
        let r = try parseRect("1,2,300,400")
        XCTAssertEqual(r, CGRect(x: 1, y: 2, width: 300, height: 400))
    }

    func testParseRectRejectsMalformedInput() {
        for bad in ["", "1,2,3", "1,2,3,4,5", "1,2,x,4"] {
            XCTAssertThrowsError(try parseRect(bad), "input: \(bad)")
        }
    }

    func testResponses() {
        XCTAssertEqual(successResponse(1)["ok"] as? Bool, true)
        XCTAssertEqual(successResponse(1)["data"] as? Int, 1)
        XCTAssertEqual(errorResponse("boom")["ok"] as? Bool, false)
        XCTAssertEqual(errorResponse("boom")["error"] as? String, "boom")
    }

    func testJSONStringCompactIsSortedAndUnescaped() {
        XCTAssertEqual(jsonString(["b": 1, "a": "x/y"], pretty: false), "{\"a\":\"x/y\",\"b\":1}")
    }

    func testJSONStringFallsBackOnInvalidObject() {
        let out = jsonString(["bad": Date()], pretty: false)
        XCTAssertTrue(out.contains("failed to encode response"))
    }

    func testGeometryJSON() {
        XCTAssertEqual(CGPoint(x: 1, y: 2).jsonDict["x"] as? CGFloat, 1)
        let rect = CGRect(x: 1, y: 2, width: 3, height: 4).jsonDict
        XCTAssertEqual(rect["w"] as? CGFloat, 3)
        XCTAssertEqual(rect["h"] as? CGFloat, 4)
    }
}

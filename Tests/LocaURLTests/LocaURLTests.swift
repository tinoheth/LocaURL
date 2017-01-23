import XCTest
@testable import LocaURL

class LocaURLTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(LocaURL().text, "Hello, World!")
    }


    static var allTests : [(String, (LocaURLTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}

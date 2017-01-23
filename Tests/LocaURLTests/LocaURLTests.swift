import XCTest
@testable import LocaURL

class LocaURLTests: XCTestCase {

	let sampleURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("file.test")
	let sampleContent = "foo"

	override func setUp() {
		try? sampleContent.write(to: sampleURL, atomically: true, encoding: .utf8)
	}

	override func tearDown() {
		try? FileManager.default.removeItem(at: sampleURL)
	}

    func testType() {
		XCTAssert(sampleURL.isRegularFile)
		XCTAssertFalse(sampleURL.isDirectory)
    }

	func testCreated() {
		_ = try? String(contentsOf: sampleURL)
		let date = sampleURL.creationDate
		XCTAssertNotNil(date)
		let diff = date?.timeIntervalSinceNow ?? 0
		XCTAssertLessThan(diff, 0)
		XCTAssertGreaterThan(diff, -1)
	}

	func testModified() {
		_ = try? String(contentsOf: sampleURL)
		let date = sampleURL.contentModificationDate
		XCTAssertNotNil(date)
		let diff = date?.timeIntervalSinceNow ?? 0
		XCTAssertLessThan(diff, 0)
		XCTAssertGreaterThan(diff, -1)
	}

	func testAccessed() {
		_ = try? String(contentsOf: sampleURL)
		let date = sampleURL.contentAccessDateDate
		XCTAssertNotNil(date)
		let diff = date?.timeIntervalSinceNow ?? 0
		XCTAssertLessThan(diff, 0)
		XCTAssertGreaterThan(diff, -1)
	}

	func testNoDirectorySize() {
		let size = sampleURL.directorySize
		XCTAssertEqual(size, 0)
	}

	func testFileSize() {
		let size = sampleURL.fileSize
		XCTAssertEqual(size, sampleContent.characters.count)
	}

    static var allTests : [(String, (LocaURLTests) -> () throws -> Void)] {
        return [
        ]
    }
}

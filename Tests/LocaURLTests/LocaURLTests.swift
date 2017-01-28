import XCTest
@testable import LocaURL

extension Optional where Wrapped: Sequence {
	var elements: [Wrapped.Iterator.Element] {
		switch (self) {
		case .none:
		return []
		case .some(let o):
		return Array(o)
		}
	}
}

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

	func testDisplayName() {
		let dest = try! FileManager.default.url(for: FileManager.SearchPathDirectory.picturesDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
		guard let meta = dest.metadata else { return }
		for key in meta.attributes {
			print(meta.value(forAttribute: key) ?? "")
		}
//		let check = try! dest.getStringXAttribute(name: "kMDItemDisplayName")
//		print(check)
	}

	func testAllXattributes() {
		let dest = try! FileManager.default.url(for: FileManager.SearchPathDirectory.picturesDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
		print(dest.xAttributeKeys)
		let value = 42
		try! sampleURL.setXAttribute(value: value, for: sampleContent)
		let keys = sampleURL.xAttributeKeys
		XCTAssert(keys.contains(sampleContent))
	}

	func testIntXattribute() {
		let value = 42
		try! sampleURL.setXAttribute(value: value, for: sampleContent)
		let check: Int? = try? sampleURL.getXAttribute(name: sampleContent)
		XCTAssertEqual(check, value)
	}

	func testDateXattribute() {
		let value = Date()
		try! sampleURL.setXAttribute(value: value, for: sampleContent)
		let check: Date? = try? sampleURL.getXAttribute(name: sampleContent)
		XCTAssertEqual(check, value)
	}

//	func testDictionaryXattribute() {
//		var value: [String: Int]? = ["key": 23, "another": 12]
//		try! sampleURL.setXAttribute(value: value!, for: sampleContent)
//		let check: [String: Int]? = try? sampleURL.getXAttribute(name: sampleContent)
//		XCTAssertEqual(check!, value!)
//		value = nil
//		print(check as Any)
//	}
//
//	func testFailDictionaryXattribute() {
//		let value = ["key": 23, "another": self] as [String : Any]
//		try! sampleURL.setXAttribute(value: value, for: sampleContent)
//		let check: [String: Any]? = try? sampleURL.getXAttribute(name: sampleContent)
//		XCTAssertNil(check)
//	}
//
//	func testClassXattribute() {
//		let value = self
//		XCTAssertThrowsError(try sampleURL.setXAttribute(value: value, for: sampleContent))
//	}

    static var allTests : [(String, (LocaURLTests) -> () throws -> Void)] {
        return [
        ]
    }
}

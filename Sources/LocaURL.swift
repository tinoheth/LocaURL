//  Created by Tino Heth (locaURL@t-no.de) on 24.01.17.

import Foundation
import CoreServices

public extension URL {
	//MARK:- Properties based on common ressource values
	var isRegularFile: Bool {
		do {
			let container = try self.resourceValues(forKeys: [.isRegularFileKey])
			return container.isRegularFile ?? false
		} catch let error {
			print(error)
			return false
		}
	}

	var isDirectory: Bool {
		do {
			let container = try self.resourceValues(forKeys: [.isDirectoryKey])
			return container.isDirectory ?? false
		} catch let error {
			print(error)
			return false
		}
	}

	var isSymbolicLink: Bool {
		do {
			let container = try self.resourceValues(forKeys: [.isSymbolicLinkKey])
			return container.isSymbolicLink ?? false
		} catch let error {
			print(error)
			return false
		}
	}

	var isReadable: Bool {
		do {
			let container = try self.resourceValues(forKeys: [.isReadableKey])
			return container.isReadable ?? false
		} catch let error {
			print(error)
			return false
		}
	}

	var isWriteable: Bool {
		do {
			let container = try self.resourceValues(forKeys: [.isWritableKey])
			return container.isWritable ?? false
		} catch let error {
			print(error)
			return false
		}
	}

	var creationDate: Date? {
		if let value = try? resourceValues(forKeys: [.creationDateKey]) {
			return value.creationDate
		} else {
			return nil
		}
	}

	var contentAccessDateDate: Date? {
		get {
			if let value = try? resourceValues(forKeys: [.contentAccessDateKey]) {
				return value.contentAccessDate
			} else {
				return nil
			}
		}
	}

	var contentModificationDate: Date? {
		get {
			if let value = try? resourceValues(forKeys: [.contentModificationDateKey]) {
				return value.contentModificationDate
			} else {
				return nil
			}
		}
		set(value) {
			var container = URLResourceValues()
			container.contentModificationDate = value
			try? setResourceValues(container)
		}
	}

	mutating func setContentModificationDate(value: Date?) throws {
		var container = URLResourceValues()
		container.contentModificationDate = value
		try setResourceValues(container)
	}

	var fileSize: Int {
		if let value = try? resourceValues(forKeys: [.fileSizeKey]) {
			return value.fileSize ?? 0
		} else {
			return 0
		}
	}

	var directorySize: Int {
		var result = Int(0)
		for current in (try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: [URLResourceKey.fileSizeKey], options: [])) ?? [] {
			result += current.fileSize
		}
		return result
	}

	//MARK:- NSMetadataItem

	#if os(OSX)
	var metadata: NSMetadataItem? {
		return NSMetadataItem(url: self)
	}

	var displayName: String {
		return (metadata?.value(forAttribute: NSMetadataItemDisplayNameKey) as? String) ?? self.lastPathComponent
	}
	#endif

	//MARK:- XAttribute based metadata

	enum XAttributeKey: String {
		case finderCommentKey = "com.apple.metadata:kMDItemFinderComment"
		case itemDownloadedDateKey = "com.apple.metadata:kMDItemDownloadedDate"
		case itemWhereFromsKey = "com.apple.metadata:kMDItemWhereFroms"
	}

	/// Reads the comment from Finder, but writing seems only affect spotlight (not reflected in Finder)
	var finderComment: String {
		get {
			return (try? self.getPlistXAttribute(.finderCommentKey)) as? String ?? ""
		}
		set(value) {
			try? setPlistXAttribute(value: value, for: .finderCommentKey)
		}
	}

	var itemDownloadedDate: Date? {
		get {
			guard let value = ((try? self.getPlistXAttribute(.itemDownloadedDateKey)) as Any??), let dates = value as? [Date] else {
				return nil
			}
			return dates.first ?? nil
		}
		set(value) {
			try? setPlistXAttribute(value: [value], for: .itemDownloadedDateKey)
		}
	}

	var itemWhereFroms: [URL]? {
		get {
			do {
				let raw = try self.getPlistXAttribute(.itemWhereFromsKey)
				guard let strings = raw as? [String] else {
					return nil
				}
				return strings.compactMap {
					return URL(string: $0)
				}
			} catch {
				return nil
			}
		}
		set(value) {
			try? setPlistXAttribute(value: value, for: .itemWhereFromsKey)
		}
	}

	//MARK:- XAttribute basics

	var xAttributeKeys: [String] {
		var result = [String]()
		let options = Int32(XATTR_SHOWCOMPRESSION | XATTR_NOFOLLOW)
		let size = listxattr(path, nil, 0, options)
		if size > 0 {
			var data = Data(count: size)
			data.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) -> Void in
				let ptr = buffer.bindMemory(to: Int8.self)
				listxattr(path, ptr.baseAddress!, size, options)
			}
			result = data.split(separator: 0).compactMap {
				String(data: $0, encoding: .utf8)
			}
		}
		return result
	}

	func removeXAttribute(name: String) {
		removexattr(path, name, XATTR_NOFOLLOW)
	}

	/// Method to save struct data
	///
	/// - Parameters:
	///   - value: What to save
	///   - name: Key to store the data
	/// - Throws: noLocalURL or writeError
	func setXAttribute<T: TrivialStruct>(value: T, for name: String) throws {
		if isFileURL {
			var value = value
			try withUnsafePointer(to: &value) { (buffer) throws -> Void in
				if setxattr(self.path, name, buffer, MemoryLayout<T>.size, 0, 0) != 0 {
					throw XAttributeError.writeError(code: errno, description: errnoDescription(errno))
				}
			}
		} else {
			throw XAttributeError.noLocalURL
		}
	}

	func getXAttribute<T: TrivialStruct>(name: String) throws -> T {
		guard self.isFileURL else {
			throw XAttributeError.noLocalURL
		}
		let bufLength = getxattr(path, name, nil, 0, 0, 0)
		guard bufLength != -1 else {
			throw XAttributeError.readError(code: errno, description: errnoDescription(errno))
		}
		guard bufLength == MemoryLayout<T>.size else {
			throw XAttributeError.noLocalURL
		}
		let buf = UnsafeMutablePointer<T>.allocate(capacity: 1)
		defer { buf.deallocate() }
		guard getxattr(path, name, buf, bufLength, 0, 0) == bufLength else {
			throw XAttributeError.readError(code: errno, description: errnoDescription(errno))
		}
		return buf.pointee
	}

	//MARK:- Arbitrary data in plist format

	func getPlistXAttribute(name: String) throws -> Any? {
		guard let data = try? getXAttributeData(name: name) else { return nil }
		return try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
	}

	func setPlistXAttribute(value: Any?, name: String) throws {
		guard let value = value else {
			removeXAttribute(name: name)
			return
		}
		let data = try PropertyListSerialization.data(fromPropertyList: value, format: .binary, options: 0)
		try setXAttributeData(value: data, for: name)
	}

	func getPlistXAttribute(_ name: XAttributeKey) throws -> Any? {
		return try getPlistXAttribute(name: name.rawValue)
	}

	func setPlistXAttribute(value: Any?, for name: XAttributeKey) throws {
		guard let value = value else {
			removeXAttribute(name: name.rawValue)
			return
		}
		let data = try PropertyListSerialization.data(fromPropertyList: value, format: .binary, options: 0)
		try setXAttributeData(value: data, for: name.rawValue)
	}

	func setXAttributeData(value: Data, for name: String) throws {
		if self.isFileURL {
			try value.withUnsafeBytes() { (buffer) throws in
				if setxattr(self.path, name, buffer.baseAddress!, value.count, 0, 0) != 0 {
					throw XAttributeError.writeError(code: errno, description: errnoDescription(errno))
				}
				return
			}
		} else {
			throw XAttributeError.noLocalURL
		}
	}

	func getXAttributeData(name: String) throws -> Data {
		if self.isFileURL {
			let bufLength = getxattr(path, name, nil, 0, 0, 0)
			if bufLength == -1 {
				throw XAttributeError.readError(code: errno, description: errnoDescription(errno))
			} else {
				var data = Data(count: bufLength)
				try data.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) throws in
					if getxattr(path, name, buffer.baseAddress!, bufLength, 0, 0) < 0 {
						throw XAttributeError.readError(code: errno, description: errnoDescription(errno))
					}
				}
				return data
			}
		} else {
			throw XAttributeError.noLocalURL
		}
	}

	//MARK:- Special XAttribute types.
	// Convenience methods that free you from the need to declare the type you expect.
	func setStringXAttribute(value: String, for name: String) throws {
		if let data = value.data(using: String.Encoding.utf8, allowLossyConversion: false) {
			try setXAttributeData(value: data, for: name)
		} else {
			throw XAttributeError.couldNotTranslateToData
		}
	}

	func getStringXAttribute(name: String) throws -> String {
		let data = try getXAttributeData(name: name)
		if let string = String(data: data, encoding: String.Encoding.utf8) {
			return string
		}
		else {
			throw XAttributeError.couldNotTranslateToString
		}
	}

	func getBoolXAttribute(name: String) throws -> Bool {
		return try getXAttribute(name: name)
	}

	func getDateXAttribute(name: String) throws -> Date {
		return try getXAttribute(name: name)
	}
}

func errnoDescription(_ errno: Int32) -> String {
	return String(describing: strerror(errno))
}

public enum XAttributeError: Error {
	case noLocalURL
	case writeError(code: Int32, description: String)
	case readError(code: Int32, description: String)
	case couldNotTranslateToData
	case couldNotTranslateToString
	case wrongSizeOfstoredData(type: Any.Type)
	case unexpectedSizeOfReadValue(size: Int)
}

public protocol TrivialStruct {}

extension Bool: TrivialStruct {}
extension UInt8: TrivialStruct {}
extension Int8: TrivialStruct {}
extension UInt16: TrivialStruct {}
extension Int16: TrivialStruct {}
extension UInt32: TrivialStruct {}
extension Int32: TrivialStruct {}
extension UInt64: TrivialStruct {}
extension Int64: TrivialStruct {}
extension Int: TrivialStruct {}
extension Float32: TrivialStruct {}
extension Float64: TrivialStruct {}

extension Date: TrivialStruct {}

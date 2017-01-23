import Foundation

public extension URL {
	//MARK:- Properties based on common ressource values
	public var isRegularFile: Bool {
		do {
			let container = try self.resourceValues(forKeys: [.isRegularFileKey])
			return container.isRegularFile ?? false
		} catch let error {
			print(error)
			return false
		}
	}

	public var isDirectory: Bool {
		do {
			let container = try self.resourceValues(forKeys: [.isDirectoryKey])
			return container.isRegularFile ?? false
		} catch let error {
			print(error)
			return false
		}
	}

	public var isSymbolicLink: Bool {
		do {
			let container = try self.resourceValues(forKeys: [.isSymbolicLinkKey])
			return container.isRegularFile ?? false
		} catch let error {
			print(error)
			return false
		}
	}

	public var creationDate: Date? {
		if let value = try? resourceValues(forKeys: [.creationDateKey]) {
			return value.creationDate
		} else {
			return nil
		}
	}

	public var contentAccessDateDate: Date? {
		get {
			if let value = try? resourceValues(forKeys: [.contentAccessDateKey]) {
				return value.contentAccessDate
			} else {
				return nil
			}
		}
	}

	public var contentModificationDate: Date? {
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

	public mutating func setContentModificationDate(value: Date?) throws {
		var container = URLResourceValues()
		container.contentModificationDate = value
		try setResourceValues(container)
	}

	public var fileSize: Int {
		if let value = try? resourceValues(forKeys: [.fileSizeKey]) {
			return value.fileSize ?? 0
		} else {
			return 0
		}
	}

	public var directorySize: Int {
		var result = Int(0)
		for current in (try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: [URLResourceKey.fileSizeKey], options: [])) ?? [] {
			result += current.fileSize
		}
		return result
	}

	//MARK:- XAttribute basics
	public func setXAttribute<T>(value: T, for name: String) throws {
		var value = value
		let data = NSData(bytes: &value, length: MemoryLayout<T>.size)
		try setXAttributeData(value: data, for: name)
	}

	public func getXAttribute<T>(name: String) throws -> T {
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
		defer { buf.deallocate(capacity: 1) }
		guard getxattr(path, name, buf, bufLength, 0, 0) == bufLength else {
			throw XAttributeError.readError(code: errno, description: errnoDescription(errno))
		}
		return buf.pointee
	}

	public func getXAttributeOrDefault<T>(name: String, defaultValue: T) -> T {
		guard self.isFileURL else {
			return defaultValue
		}
		let bufLength = getxattr(path, name, nil, 0, 0, 0)
		guard bufLength != -1 else {
			return defaultValue
		}
		guard bufLength == MemoryLayout<T>.size else {
			return defaultValue
		}
		var result = defaultValue
		guard getxattr(path, name, &result, MemoryLayout<T>.size, 0, 0) == bufLength else {
			return defaultValue
		}
		return result
	}

	public func getXAttributeData(name: String) throws -> Data {
		if self.isFileURL {
			let bufLength = getxattr(path, name, nil, 0, 0, 0)
			if bufLength == -1 {
				throw XAttributeError.readError(code: errno, description: errnoDescription(errno))
			} else {
				var result = Data(capacity: bufLength)
				try result.withUnsafeMutableBytes { (buffer: UnsafeMutablePointer<UInt8>) -> Void in
					if getxattr(path, name, buffer, bufLength, 0, 0) < 0 {
						throw XAttributeError.readError(code: errno, description: errnoDescription(errno))
					}
				}
				return result
			}
		} else {
			throw XAttributeError.noLocalURL
		}
	}

	public func setXAttributeData(value: NSData, for name: String) throws {
		if self.isFileURL {
			if setxattr(self.path, name, value.bytes, value.length, 0, 0) != 0 {
				throw XAttributeError.writeError(code: errno, description: errnoDescription(errno))
			}
		} else {
			throw XAttributeError.noLocalURL
		}
	}

	//MARK:- Special XAttribute types
	public func setStringXAttribute(value: String, for key: String) throws {
		if let data = value.data(using: String.Encoding.utf8, allowLossyConversion: false) {
			try setXAttribute(value: data, for: key)
		} else {
			throw XAttributeError.couldNotTranslateToData
		}
	}

	public func getStringXAttribute(name: String) throws -> String {
		let data = try getXAttributeData(name: name)
		if let string = String(data: data, encoding: String.Encoding.utf8) {
			return string
		}
		else {
			throw XAttributeError.couldNotTranslateToString
		}
	}

//	public func setDateXAttribute(value: NSDate, for name: String) throws {
//		try setXAttribute(value.timeIntervalSinceReferenceDate, for: name)
//	}
//
//	public func getDateXAttribute(name: String) throws -> NSDate {
//		let t: NSTimeInterval = try getXAttribute(name)
//		return NSDate(timeIntervalSinceReferenceDate: t)
//	}

	public func getBoolXAttribute(name: String) throws -> Bool {
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

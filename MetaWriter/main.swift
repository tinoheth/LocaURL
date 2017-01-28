//
//  main.swift
//  MetaWriter
//
//  Created by Tino Heth on 24.01.17.
//
//

import Foundation

let key = "t-no.LocaURL"
let dateKey = "t-no.de.date"

let arguments = CommandLine.arguments

guard arguments.count >= 2 else {
	exit(EXIT_FAILURE)
}

let path = arguments[1]
var url = NSURL.fileURL(withPath: path)

print("URL is \(url)")

guard url.isReadable else {
	exit(EXIT_FAILURE)
}

print("xattributes:", url.xAttributeKeys)

print("Comment: \(url.finderComment)")

if let value = try? url.getXAttributeData(name: "com.apple.FinderInfo\u{01}") {
	print(value)
}

if let from = url.itemWhereFroms {
	print("Download source: \(from)")

	if let when = url.itemDownloadedDate {
		print("Date", when)
	}
}

//if let dict = try? url.getXAttribute(name: key) as [String: String], dict.count > 0 {
//	print(dict)
//}
//else
if let value: Int = try? url.getXAttribute(name: key) {
	print("Assigned int value", value)
}

if let date: Date = try? url.getXAttribute(name: dateKey) {
	print("Last run with current file: \(date)")
}

try! url.setXAttribute(value: Date(), for: dateKey)

if arguments.count == 3 {
	if let value = Int(arguments[2]) {
		try! url.setXAttribute(value: value, for: key)
	}
}

url.finderComment = "Manual"
//else if arguments.count >= 4 {
//	let dict = [arguments[2]: arguments[3]]
//	try! url.setXAttribute(value: dict, for: key)
//}
exit(EXIT_SUCCESS)

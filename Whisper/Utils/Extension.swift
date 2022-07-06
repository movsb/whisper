//
//  Extension.swift
//  Whisper
//
//  Created by Yang Tao on 2022/07/06.
//

import Foundation
import SwiftUI

extension Data {
	// https://stackoverflow.com/a/55092044/3628322
	func toTemporaryFile(fileName: String) throws -> URL {
		let data = self
		// Make the file path (with the filename) where the file will be loacated after it is created
		let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)

		do {
			// Write the file from data into the filepath (if there will be an error, the code jumps to the catch block below)
			try data.write(to: URL(fileURLWithPath: filePath))

			// Returns the URL where the new file is located in NSURL
			return URL(fileURLWithPath: filePath)

		} catch {
			fatalError("Error writing the file: \(error.localizedDescription)")
		}
	}
	func toTemporaryFileWithDateName() throws -> URL {
		let date = Date()
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
		let fileName = "Whisper-" + dateFormatter.string(from: date) + ".bin"
		return try self.toTemporaryFile(fileName: fileName)
	}
}

extension UIApplication {
	func endEditing() {
		sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
	}
}

// https://www.hackingwithswift.com/example-code/language/how-to-throw-errors-using-strings
extension String: LocalizedError {
	public var errorDescription: String? { return self }
}

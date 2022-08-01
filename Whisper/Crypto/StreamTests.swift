//
//  StreamTests.swift
//  WhisperTests
//
//  Created by Yang Tao on 2022/07/27.
//

import XCTest
import CryptoKit
@testable import Whisper

final class StreamTests: XCTestCase {
	func testStreamWriter() throws {
		let raw = "雪舞❄️&桃子🍑"
		let fileKey = try FileKey()
		let encDec = AesGcm(withFileKey: fileKey)
		
		let memoryWriter = MemoryWriter()
		let sw = StreamWriter(memoryWriter, block: encDec)
		
		try sw.write(raw, withLength: true)
		try sw.close()
		
		print([UInt8](memoryWriter.bytes()))
		
		let r = MemoryReader(data: memoryWriter.bytes())
		let sr = StreamReader(r, block: encDec)
		let s = try sr.readStringWithLength()
		print(s)
		
		if s != raw {
			throw "not equal"
		}
	}
}

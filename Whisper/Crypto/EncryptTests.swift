//
//  EncryptTests.swift
//  WhisperTests
//
//  Created by Yang Tao on 2022/07/01.
//

import XCTest
@testable import Whisper

final class EncryptTests: XCTestCase {
	func testNewPrivateKey() throws {
		let p = NewPrivateKey()
		print("Private Key:", p.String())
		print("Public Key:", p.publicKey.String())
	}
	func testEncryptFileKey() throws {
		let pri = NewPrivateKey()
		let pub = pri.publicKey
		let fileKey:[UInt8] = [8,1,2,3]
		let encrypted = try EncryptFileKey(sender: pri, receiver: pub, fileKey: fileKey)
		print(encrypted)
	}
	func testDecryptFileKey() throws {
		let pri = NewPrivateKey()
		let pub = pri.publicKey
		let fileKey:[UInt8] = [8,1,2,3]
		let encrypted = try EncryptFileKey(sender: pri, receiver: pub, fileKey: fileKey)
		let decrypted = try DecryptFileKey(receiver: pri, sender: pub, fileKey: encrypted)
		print(decrypted)
	}
	func testEncryptMessage() throws {
		let fileKey: [UInt8] = Array(repeating: 0, count: 32)
		let message = "雪儿"
		let encrypted = try EncryptMessage(fileKey: fileKey, message: message)
		print(encrypted)
	}
	func testDecryptMessage() throws {
		let fileKey: [UInt8] = Array(repeating: 0, count: 32)
		let message = "雪儿"
		let encrypted = try EncryptMessage(fileKey: fileKey, message: message)
		print(encrypted)
		
		let decrypted = try DecryptMessage(encrypted: encrypted, fileKey: fileKey)
		print(decrypted)
	}
}

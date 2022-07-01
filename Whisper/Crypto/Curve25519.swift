//
//  Curve25519.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/27.
//

import Foundation
import CryptoKit

typealias PublicKey = Curve25519.KeyAgreement.PublicKey
typealias PrivateKey = Curve25519.KeyAgreement.PrivateKey

extension PublicKey {
	func String() -> String {
		return self.rawRepresentation.base64EncodedString()
	}
	static func fromString(s: String) throws -> PublicKey {
		let data = Data(base64Encoded: s.trimmingCharacters(in: .whitespacesAndNewlines))
		let pubKey = try PublicKey(rawRepresentation: data!)
		return pubKey
	}
}

extension PrivateKey {
	func String() -> String {
		return self.rawRepresentation.base64EncodedString()
	}
}

func NewPrivateKey() -> PrivateKey {
	return Curve25519.KeyAgreement.PrivateKey()
}

func EncryptFileKey(sender: PrivateKey, receiver: PublicKey, fileKey: [UInt8]) throws -> [UInt8] {
	let sharedSecret = try sender.sharedSecretFromKeyAgreement(with: receiver)
	let symmetricKey = SymmetricKey(data: sharedSecret)
	let sealedBox = try AES.GCM.seal(fileKey, using: symmetricKey, nonce: AES.GCM.Nonce())
	return [UInt8](sealedBox.combined!) // 为什么合并会有空结果？
}

func DecryptFileKey(receiver: PrivateKey, sender: PublicKey, fileKey: [UInt8]) throws -> [UInt8] {
	let sharedSecret = try receiver.sharedSecretFromKeyAgreement(with: sender)
	let symetricKey = SymmetricKey(data: sharedSecret)
	let sealedBox = try AES.GCM.SealedBox(combined: fileKey)
	let opened = try AES.GCM.open(sealedBox, using: symetricKey)
	return [UInt8](opened)
}

func EncryptMessage(fileKey: [UInt8], message: String) throws -> [UInt8] {
	let bytes = Data(message.utf8)
	let symmetricKey = SymmetricKey(data: fileKey)
	let sealedBox = try AES.GCM.seal(bytes, using: symmetricKey)
	return [UInt8](sealedBox.combined!)
}

func DecryptMessage(encrypted: [UInt8], fileKey: [UInt8]) throws -> String {
	let sealedBox = try AES.GCM.SealedBox(combined: encrypted)
	let opened = try AES.GCM.open(sealedBox, using: SymmetricKey(data: fileKey))
	return String(data: opened, encoding: .utf8)!
}

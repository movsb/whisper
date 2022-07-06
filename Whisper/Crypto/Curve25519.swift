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

extension Data {
	static func fromBase64URL(b: String) -> Data? {
		var s = b.replacingOccurrences(of: "-", with: "+")
		s = s.replacingOccurrences(of: "_", with: "/")
		while s.count % 4 != 0 {
			s = s.appending("=")
		}
		guard let data = Data(base64Encoded: s) else {
			return nil
		}
		return data
	}
	func toBase64URL() -> String {
		var s = self.base64EncodedString()
		s = s.replacingOccurrences(of: "+", with: "-")
		s = s.replacingOccurrences(of: "/", with: "_")
		s = s.replacingOccurrences(of: "=", with: "")
		return s
	}
}

extension PublicKey {
	func String() -> String {
		return self.rawRepresentation.toBase64URL()
	}
	static func fromString(s: String) -> PublicKey? {
		guard let d = Data.fromBase64URL(b: s.trimmingCharacters(in: .whitespacesAndNewlines)) else {
			return nil
		}
		do {
			return try PublicKey(rawRepresentation: d)
		} catch {
			return nil
		}
	}
}

extension PrivateKey {
	func String() -> String {
		return self.rawRepresentation.toBase64URL()
	}
	static func fromString(s: String) -> PrivateKey? {
		guard let d = Data.fromBase64URL(b: s.trimmingCharacters(in: .whitespacesAndNewlines)) else {
			return nil
		}
		do {
			return try PrivateKey(rawRepresentation: d)
		} catch {
			return nil
		}
	}
}

func NewPrivateKey() -> PrivateKey {
	return Curve25519.KeyAgreement.PrivateKey()
}

func EncryptFileKey(sender: PrivateKey, receiver: PublicKey, fileKey: [UInt8]) throws -> Data {
	let sharedSecret = try sender.sharedSecretFromKeyAgreement(with: receiver)
	let symmetricKey = SymmetricKey(data: sharedSecret)
	let sealedBox = try AES.GCM.seal(fileKey, using: symmetricKey, nonce: AES.GCM.Nonce())
	return sealedBox.combined! // 为什么合并会有空结果？
}

func DecryptFileKey(receiver: PrivateKey, sender: PublicKey, fileKey: [UInt8]) throws -> Data {
	let sharedSecret = try receiver.sharedSecretFromKeyAgreement(with: sender)
	let symetricKey = SymmetricKey(data: sharedSecret)
	let sealedBox = try AES.GCM.SealedBox(combined: fileKey)
	let opened = try AES.GCM.open(sealedBox, using: symetricKey)
	return opened
}

func EncryptMessage(fileKey: [UInt8], message: String) throws -> Data {
	let bytes = Data(message.utf8)
	let symmetricKey = SymmetricKey(data: fileKey)
	let sealedBox = try AES.GCM.seal(bytes, using: symmetricKey, nonce: AES.GCM.Nonce())
	return sealedBox.combined!
}

func DecryptMessage(encrypted: [UInt8], fileKey: [UInt8]) throws -> String {
	let sealedBox = try AES.GCM.SealedBox(combined: encrypted)
	let opened = try AES.GCM.open(sealedBox, using: SymmetricKey(data: fileKey))
	return String(data: opened, encoding: .utf8)!
}

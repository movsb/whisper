//
//  Crypto.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/27.
//

import Foundation
import CryptoKit

// MARK: -

struct FileKey {
	// 256位，不能改。
	private let kFileKeySize = 32
	
	private var _data: Data
	
	init(_ data: Data) throws {
		if data.count != kFileKeySize {
			throw "invalid file key size"
		}
		self._data = data
	}
	
	init() throws {
		var bytes = [UInt8](repeating: 0, count: kFileKeySize)
		
		let status = SecRandomCopyBytes(kSecRandomDefault, kFileKeySize, &bytes)
		if status != errSecSuccess {
			throw "failed to generate random file key"
		}
		
		self._data = Data(bytes)
	}
	
	func data() -> Data {
		return _data
	}
}

// MARK: -

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
	// Base64, URL-Encoding, Without-Padding
	func toBase64URL() -> String {
		var s = self.base64EncodedString()
		s = s.replacingOccurrences(of: "+", with: "-")
		s = s.replacingOccurrences(of: "/", with: "_")
		s = s.replacingOccurrences(of: "=", with: "")
		return s
	}
}

// MARK: -

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

// MARK: -

struct Recipient {
	var p: PublicKey
	
	init(_ publicKey: PublicKey) throws {
		p = publicKey
	}
	
	func EncryptFileKey(_ fileKey: FileKey, using sender: PrivateKey) throws -> Data {
		let sharedSecret = try sender.sharedSecretFromKeyAgreement(with: p)
		
		// TODO 使用 hdkf
		let symmetricKey = SymmetricKey(data: sharedSecret)
		
		// 公钥是 32 字节，直接用了。
		let enc = AesGcm(symmetricKey)
		return try enc.Encrypt(fileKey.data())
	}
}

struct Identity {
	var p: PrivateKey
	
	init(_ privateKey: PrivateKey ) {
		p = privateKey
	}
	
	func DecryptFileKey(_ data: Data, using sender: PublicKey) throws -> FileKey {
		let sharedSecret = try p.sharedSecretFromKeyAgreement(with: sender)
		
		let symmetricKey = SymmetricKey(data: sharedSecret)
		
		// 私钥是 32 字节，直接用了。
		let dec = AesGcm(symmetricKey)
		let decrypted = try dec.Decrypt(data)
		return try FileKey(decrypted)
	}
}

// MARK: -

protocol BlockEncryptor {
	func Encrypt(_ data: Data) throws -> Data
}
protocol BlockDecryptor {
	func Decrypt(_ data: Data) throws -> Data
}

struct AesGcm: BlockEncryptor, BlockDecryptor {
	private var key: SymmetricKey
	
	init(_ symmetricKey: SymmetricKey) {
		self.key = symmetricKey
	}
	
	init(withFileKey fileKey: FileKey) {
		let key = SymmetricKey(data: fileKey.data())
		if key.bitCount != 256 {
			fatalError("AES.GCM requires 256-bit key")
		}
		self.init(key)
	}
	
	func Encrypt(_ data: Data) throws -> Data {
		let nonce = AES.GCM.Nonce()
		let sealed = try AES.GCM.seal(data, using: key, nonce: nonce)
		guard let combined = sealed.combined else {
			throw "sealed.combined is nil"
		}
		return combined
	}
	
	func Decrypt(_ data: Data) throws -> Data {
		let sealed = try AES.GCM.SealedBox(combined: data)
		return try AES.GCM.open(sealed, using: key)
	}
}

//
//  Encrypt.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/30.
//

import Foundation

// 256位
let kFileKeySize = 32

enum CryptError: Error {
	case Random
}

func NewFileKey() throws -> [UInt8] {
	var bytes = [UInt8](repeating: 0, count: kFileKeySize)
	
	let status = SecRandomCopyBytes(kSecRandomDefault, kFileKeySize, &bytes)
	if status == errSecSuccess {
		return bytes
	}
	
	throw CryptError.Random
}

struct Section {
	// 发送人的公钥
	var publicKey: PublicKey
	
	// 用共享密钥加密后的文件密钥
	var encryptedFileKey: [UInt8]
}

extension Section {
	func bytes() -> [UInt8] {
		var data = Data()
		data.append(self.publicKey.rawRepresentation)
		data.append(contentsOf: self.encryptedFileKey)
		return [UInt8](data)
	}
}

// 文件头
let kFileHeader = "Whipser/1.0\n"

struct File {
	// 文件头部标识
	var fileHeader: String
	
	// ·接收人列表
	var sections: [Section]
	
	// 已加密数据
	var data: Data
}

extension File {
	func bytes() -> [UInt8] {
		var data = Data()
		data.append(Data(self.fileHeader.utf8))
		data.append(contentsOf: [UInt8](arrayLiteral: UInt8(self.sections.count)))
		for s in self.sections {
			let secData = s.bytes()
			data.append(contentsOf: secData)
		}
		data.append(self.data)
		return [UInt8](data)
	}
	func base64() -> String {
		let data = Data(self.bytes())
		return data.base64EncodedString()
	}
}

func NewFile(sender: PrivateKey, recipients: [PublicKey], message: String) throws -> File {
	let fileKey = try NewFileKey()
	
	// TODO
	// 接收人的个数范围：(0, 255]
	
	var sections = [Section]()
	for r in recipients {
		let encryptedFileKey = try EncryptFileKey(sender: sender, receiver: r, fileKey: fileKey)
		let section = Section(publicKey: r, encryptedFileKey: encryptedFileKey)
		sections.append(section)
	}
	
	let data = try EncryptMessage(fileKey: fileKey, message: message)
	
	return File(fileHeader: kFileHeader, sections: sections, data: Data(data))
}

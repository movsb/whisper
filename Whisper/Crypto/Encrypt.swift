//
//  Encrypt.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/30.
//

import Foundation

let kFileKeySize = 16

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
	var encryptedFileKey: Data
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

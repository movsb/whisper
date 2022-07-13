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

struct Recipient {
	var p: PublicKey
	
	// 把对称密钥用公钥加密
	func encode(sender: PrivateKey, fileKey: [UInt8]) throws -> Data {
		return try EncryptFileKey(sender: sender, receiver: p, fileKey: fileKey)
	}
}

struct Identity {
	var p: PrivateKey
	
	// 从公钥加密的数据中提取出对称密钥
	func decode(sender: PublicKey, data: Data) throws -> [UInt8] {
		return try [UInt8](DecryptFileKey(receiver: p, sender: sender, fileKey: [UInt8](data)))
	}
}

// 文件头
public let kFileHeader = "Whipser/1.0\n"

let kMaxTitle = 1 << 10
let kMaxContent = 64 << 10
let kMaxFile = 1 << 20

struct File {
	// 文件头部标识
	var fileHeader: String
	
	// ·接收人列表
	var recipients: [PublicKey]
	
	var title: String
	var content: String
	
	var images: [URL]
	var videos: [URL]

	func encode(sender: PrivateKey, fileKey: [UInt8]) throws -> Data {
		var data = Data()
		data.append(Data(self.fileHeader.utf8))
		
		data.append(sender.publicKey.rawRepresentation)
		
		if recipients.count <= 0 {
			throw "接收设备不可为空"
		}
		data.append(contentsOf: [UInt8](arrayLiteral: UInt8(self.recipients.count)))
		for p in self.recipients {
			let recipient = Recipient(p: p)
			let rData = try recipient.encode(sender: sender, fileKey: fileKey)
			if rData.count > 255 {
				throw "Section 过大： \(rData.count)"
			}
			data.append(contentsOf: [UInt8](arrayLiteral: UInt8(rData.count)))
			data.append(rData)
		}
		
		if title.utf8.count > kMaxTitle {
			throw "标题内容过长。"
		}
		if content.utf8.count > kMaxContent {
			throw "正文内容过长。"
		}
		
		let combined = title + "\0" + content
		let encryptedMessage = try EncryptMessage(fileKey: fileKey, message: combined)
		let n: UInt32 = UInt32(encryptedMessage.count)
		let littleN = withUnsafeBytes(of: n.littleEndian) {Array($0)}
		data.append(littleN, count: littleN.count)
		data.append(encryptedMessage)
		
		data.writeUInt32(n: UInt32(images.count))
		for url in images {
			let d = try encodeFile(fileKey: fileKey, url: url)
			data.append(d)
		}
		data.writeUInt32(n: UInt32(videos.count))
		for url in videos {
			let d = try encodeFile(fileKey: fileKey, url: url)
			data.append(d)
		}
		
		return data
	}
	
	private func encodeFile(fileKey: [UInt8], url: URL) throws -> Data {
		let fileName = url.lastPathComponent
		let input = try Data(contentsOf: url)
		
		var output = Data()
		
		let encryptedFileName = try EncryptMessage(fileKey: fileKey, message: fileName)
		output.writeUInt32(n: UInt32(encryptedFileName.count))
		output.append(encryptedFileName)
		
		let encrypted = try EncryptData(fileKey: fileKey, data: input)
		output.writeUInt32(n: UInt32(encrypted.count))
		output.append(encrypted)
		
		return output
	}
	
	static private func decodeFile(fileKey: [UInt8], data: Data) throws -> (Data,String,Data) {
		guard var (d, n) = data.readUInt32() else {
			throw "文件不完整。"
		}
		if d.count < n {
			throw "文件不完整。"
		}
		let encryptedFileName = d[0..<n]
		let decryptedFileName = try DecryptData(data: encryptedFileName, fileKey: fileKey)
		guard let name = String(data: decryptedFileName, encoding: .utf8) else {
			throw "文件名编码不正确。"
		}
		d = d.advanced(by: Int(n))
		
		guard let (dd, nn) = d.readUInt32() else {
			throw "文件不完整。"
		}
		if dd.count < nn {
			throw "文件不完整"
		}
		let encryptedData = dd[0..<nn]
		let decryptedData = try DecryptData(data: encryptedData, fileKey: fileKey)
		return (dd.advanced(by: Int(nn)), name, decryptedData)
	}
	
	init(fileHeader: String, recipients: [PublicKey], title: String, content: String, images: [URL], videos: [URL]) {
		self.fileHeader = fileHeader
		self.recipients = recipients
		self.title = title
		self.content = content
		self.images = images
		self.videos = videos
	}
	
	static func decode(data: Data, recipient: PrivateKey) throws -> File {
		guard let fileHeaderEndPos = data.firstIndex(of: 10/* \n */) else {
			throw "文件格式不正确。"
		}
		let fileHeader = data[0...fileHeaderEndPos]
		guard let fileHeaderString = String(data: fileHeader, encoding: .utf8) else {
			throw "文件头不正确。"
		}
		if fileHeaderString != kFileHeader {
			throw "文件头不正确。"
		}
		var d = data.advanced(by: fileHeaderEndPos+1)
		
		// 发送人公钥
		if d.count < 32 {
			throw "文件格式不正确。"
		}
		let publicKeyBytes = [UInt8](d.subdata(in: Range(uncheckedBounds: (0, 32))))
		let publicKey = try PublicKey(rawRepresentation: publicKeyBytes)
		d = d.advanced(by: 32)
		
		// 读取所有的接收人
		if d.count < 1 {
			throw "文件格式不正确。"
		}
		let identity = Identity(p: recipient)
		var fileKey: [UInt8]? = nil
		let nRecipients = d.first!
		d = d.advanced(by: 1)
		for _ in 0..<nRecipients {
			if d.count < 1 {
				throw "文件格式不正确。"
			}
			let nData = Int(d.first!)
			d = d.advanced(by: 1)
			if d.count < nData {
				throw "文件格式不正确。"
			}
			let rData = d[0..<nData]
			let fk2 = try? identity.decode(sender: publicKey, data: rData)
			if fk2 != nil && fileKey != nil {
				throw "内部错误：私钥可解多次。"
			} else if fk2 != nil && fileKey == nil {
				fileKey = fk2
			}
			d = d.advanced(by: Int(nData))
		}
		
		if fileKey == nil {
			throw "你的私钥无法解密此文件。"
		}
		
		if d.count < 4 {
			throw "缺少内容数据。"
		}
		let nContent = UInt32(littleEndian: d[0..<4].withUnsafeBytes { $0.pointee })
		d = d.advanced(by: 4)
//		if d.count != nContent {
//			throw "缺少内容数据。"
//		}
		let encryptedMessage = d[0..<nContent]
		let combined = try DecryptMessage(encrypted: [UInt8](encryptedMessage), fileKey: fileKey!)
		let parts = combined.split(separator: "\0")
		let title = String(parts[0])
		var content = ""
		if parts.count == 2 {
			content = String(parts[1])
		}
		d = d.advanced(by: Int(nContent))
		
		var images: [URL] = []
		guard let (dd, nImages) = d.readUInt32() else {
			throw "文件不完整。"
		}
		d = dd
		for _ in 0..<nImages {
			let (dd, name, content) = try File.decodeFile(fileKey: fileKey!, data: d)
			let url = try content.toTemporaryFile(fileName: name)
			images.append(url)
			d = dd
		}
		
		var videos: [URL] = []
		guard let (dd, nVideos) = d.readUInt32() else {
			throw "文件不完整。"
		}
		d = dd
		for _ in 0..<nVideos {
			let (dd, name, content) = try File.decodeFile(fileKey: fileKey!, data: d)
			let url = try content.toTemporaryFile(fileName: name)
			videos.append(url)
			d = dd
		}
		
		if d.count > 0 {
			throw "文件有未处理的内容。"
		}
		
		return File(fileHeader: kFileHeader, recipients: [publicKey], title: title, content: content, images: images, videos: videos)
	}
}


extension Data {
	mutating func writeUInt32(n: UInt32) {
		let littleN = Swift.withUnsafeBytes(of: n.littleEndian) {Array($0)}
		self.append(littleN, count: littleN.count)
	}
	func readUInt32() -> (Data,UInt32)? {
		if self.count < 4 {
			return nil
		}
		let n = UInt32(littleEndian: self[0..<4].withUnsafeBytes { $0.pointee })
		let d = self.advanced(by: 4)
		return (d, n)
	}
}

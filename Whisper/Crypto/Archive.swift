//
//  Archive.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/30.
//

import Foundation
import CryptoKit

// 文件头
public let kFileHeader = "Whipser/1.0\n"

let kMaxTitle = 1 << 10
let kMaxContent = 1 << 20

struct File {
	// 接收人列表
	var recipients: [PublicKey]
	
	var title: String
	var content: String
	
	var images: [URL]
	var videos: [URL]
	
	init(recipients: [PublicKey], title: String, content: String, images: [URL], videos: [URL]) {
		self.recipients = recipients
		self.title = title
		self.content = content
		self.images = images
		self.videos = videos
	}
}

// MARK: - Arhive Reader & Writer.

struct ArchiveWriter {
	private var w: Writer
	private var sender: PrivateKey
	private var fileKey: FileKey
	
	init(_ w: Writer, sender: PrivateKey, fileKey: FileKey) {
		self.w = w
		self.sender = sender
		self.fileKey = fileKey
	}
	
	// 不会对文本长度、文件大小等做限制，需要在外部判断。
	func write(file: File) throws {
		// 文件头
		try w.write(kFileHeader, withLength: false)
		
		// 发送者公钥
		try w.write(sender.publicKey.rawRepresentation)
		
		// 接收设备个数
		if file.recipients.count <= 0 {
			throw "接收设备不可为空"
		}
		try w.write(file.recipients.count)
		
		// 用各设备公钥加密的 FileKey
		for p in file.recipients {
			let key = try Recipient(p).EncryptFileKey(fileKey, using: sender)
			try w.write(key, withLength: true)
		}
		
		// MARK: - 后面的数据（文本、图片、视频等）全部用流加密。
		
		let sw = StreamWriter(w, block: AesGcm(withFileKey: fileKey))
		
		// 标题
		try sw.write(file.title, withLength: true)
		
		// 文本
		try sw.write(file.content, withLength: true)
		
		// 图片
		try sw.write(file.images.count)
		for url in file.images {
			try encodeFile(sw, url: url)
		}
		
		// 视频
		try sw.write(file.videos.count)
		for url in file.videos {
			try encodeFile(sw, url: url)
		}
		
		try sw.close()
		
		// MARK: - 流数据结束
	}
	
	private func encodeFile(_ sw: StreamWriter, url: URL) throws {
		// 文件名
		let fileName = url.lastPathComponent
		try sw.write(fileName, withLength: true)
		
		// 文件内容
		let handle = try FileHandle(forReadingFrom: url)
		defer {
			// Call can throw, but errors cannot be thrown out of a defer body
			// 告诉我应该 try，但是又不让我 try。
			try? handle.close()
		}
		let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize!
		try sw.write(handle, maxBytes: fileSize, withLength: true)
	}
}

struct ArchiveReader {
	private var r: Reader
	private var identity: Identity
	
	init(_ r: Reader, identity: Identity) {
		self.r = r
		self.identity = identity
	}
	
	func read() throws -> File {
		// 文件头
		try readFileHeader()
		
		// 发送者公钥
		let senderBytes = try r.read(count: 32)
		let sender = try PublicKey(rawRepresentation: senderBytes)
		
		// 接收设备
		let fileKey = try readFileKey(sender: sender)

		let sr = StreamReader(r, block: AesGcm(withFileKey: fileKey))
		
		// 标题
		let title = try sr.readStringWithLength()
		
		// 文本
		let content = try sr.readStringWithLength()
		
		let tmpDirURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		try FileManager.default.createDirectory(at: tmpDirURL, withIntermediateDirectories: false)
		
		// 图片
		let images = try readFiles(sr, tmpDir: tmpDirURL, dirName: "images")
		
		// 视频
		let videos = try readFiles(sr, tmpDir: tmpDirURL, dirName: "videos")
		
		try sr.close()
		
		return File(recipients:[], title: title, content: content, images: images, videos: videos)
	}
	
	// TODO 限制最大读取长度
	private func readFileHeader() throws {
		var s = Data()
		while true {
			let b = try r.read(upToCount: 1)
			if b.count == 0 {
				break
			}
			s.append(b)
			if b[0] == 10 {
				break
			}
		}
		let h = String(data: s, encoding: .utf8)
		if h == nil || h! != kFileHeader {
			throw "无效的文件头"
		}
	}
	
	private func readFileKey(sender: PublicKey) throws -> FileKey {
		let devicesCount = try r.readUInt32()
		var fileKey: FileKey? = nil
		for _ in 0..<devicesCount {
			let encrypted = try r.readDataWithLength()
			let decodedFileKey = try? identity.DecryptFileKey(encrypted, using: sender)
			if decodedFileKey != nil {
				if fileKey != nil {
					throw "内部错误：私钥可解多次"
				}
				fileKey = decodedFileKey
			}
		}
		if fileKey == nil {
			throw "你的私钥无法解密此文件。"
		}
		return fileKey!
	}
	
	private func readFiles(_ sr: StreamReader, tmpDir: URL, dirName: String) throws -> [URL]{
		var urls = [URL]()
		let nFiles = try sr.readUInt32()
		let filesDir = tmpDir.appendingPathComponent(dirName)
		try FileManager.default.createDirectory(at: filesDir, withIntermediateDirectories: false)
		for _ in 0..<nFiles {
			let fileURL = try sr.readFileWithLength(toDir: filesDir)
			urls.append(fileURL)
		}
		return urls
	}
}

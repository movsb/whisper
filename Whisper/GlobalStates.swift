//
//  GlobalStates.swift
//  Whisper
//
//  Created by Yang Tao on 2022/07/05.
//

import Foundation
import UIKit

var appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.twofei.whisper.share")!
var appGroupUserDefaults = UserDefaults.init(suiteName: "group.com.twofei.whisper.share")!

class GlobalStates: ObservableObject {
	@Published var firstUse = false
	@Published var loggedin = false
	// 如果最后一次登录的用户人脸识别失败， 可再次重试。
	@Published var lastUserFailed = false
	@Published var messages: [Message] = []
	@Published var contacts: [Contact] = []
	@Published var failedMessages: [FailedMessage] = []
	@Published var userSettings = UserSettings()
	
	class UserSettings: ObservableObject, Codable {
		@Published var enableFaceID = false
		
		enum CodingKeys: CodingKey {
			case enableFaceID
		}
		
		init() {}
		
		required init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			enableFaceID = try container.decode(Bool.self, forKey: .enableFaceID)
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(enableFaceID, forKey: .enableFaceID)
		}
	}
	
	init() {}
	init(privateKey: PrivateKey) {
		self.privateKey = privateKey
		self.loggedin = true
	}
	
	var privateKey: PrivateKey?
	
	// 以公钥命名的用户目录，登录后立即调用。
	func createUserDir() throws {
		guard let _ = privateKey else {
			throw "未登录时没有帐号目录"
		}
		let user = try userDir()
		try FileManager.default.createDirectory(at: user, withIntermediateDirectories: true)
	}
	
	static private func createDir(url: URL) throws {
		try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
	}
	
	func userDir() throws -> URL {
		guard let _ = privateKey else {
			throw "未登录时没有帐号目录"
		}
		return GlobalStates.userDir(publicKey: privateKey!.publicKey)
	}
	
	// 可在未登录时调用。
	// 不一定存在。
	static func userDir(publicKey: PublicKey) -> URL {
		let doc = try! FileManager.default.url(for: .documentDirectory,
											   in: .userDomainMask, appropriateFor: nil, create: false)
		let users = doc.appendingPathComponent("users", isDirectory: true)
		let user = users.appendingPathComponent(publicKey.String())
		return user
	}
	
	// 可在未登录时调用。
	static func userDirExists(publicKey: PublicKey) -> Bool {
		let dir = userDir(publicKey: publicKey)
		return FileManager.default.fileExists(atPath: dir.path)
	}
	
	// 可在未登录时调用。
	static func loadUserPrivteKey(publicKey: PublicKey) -> PrivateKey {
		let userDir = GlobalStates.userDir(publicKey: publicKey)
		let privateKeyFile = userDir.appendingPathComponent("privateKey")
		let privateKeyString = String(decoding: try! Data(contentsOf: privateKeyFile), as: UTF8.self)
		let privateKey = PrivateKey.fromString(s: privateKeyString)
		return privateKey!
	}
	
	func saveUserPrivateKey() throws {
		let userDir = GlobalStates.userDir(publicKey: privateKey!.publicKey)
		let privateKeyFile = userDir.appendingPathComponent("privateKey")
		try Data(privateKey!.String().utf8).write(to: privateKeyFile)
	}
	
	func saveUserJson(name: String, data: Encodable) throws {
		let data = try JSONEncoder().encode(data)
		let outfile = try self.userDir().appendingPathComponent(name)
		try data.write(to: outfile)
	}
	
	func loadUserJson<T>(name: String, demo: T) throws -> T where T: Decodable {
		let fileURL = try self.userDir().appendingPathComponent(name)
		let file = try FileHandle(forReadingFrom: fileURL)
		return try JSONDecoder().decode(T.self, from: file.availableData)
	}
	
	// 上次登录的用户公钥
	static func lastUser() -> PublicKey? {
		guard let publicKeyString = appGroupUserDefaults.string(forKey: "currentUserPublicKey") else {
			return nil
		}
		guard let publicKey = PublicKey.fromString(s: publicKeyString) else {
			return nil
		}
		// TODO 应该确保目录存在。
		return publicKey
	}
	
	// 保存本次登录的用户
	func setLastUser() {
		appGroupUserDefaults.set(privateKey!.publicKey.String(), forKey: "currentUserPublicKey")
	}
	// 清空本次登录用户
	func removeLastUser() {
		appGroupUserDefaults.removeObject(forKey: "currentUserPublicKey")
	}
	
	func loadMessages() throws {
		do {
			messages = try loadUserJson(name: "messages.json", demo: [Message.example()])
		} catch CocoaError.fileNoSuchFile {
			messages = []
		}
		if let (failed, found) = try? loadInbox() {
			messages.insert(contentsOf: found, at: 0)
			updateFailedMessages(failed: failed)
		}
	}
	func loadContacts() throws {
		do {
			contacts = try loadUserJson(name: "contacts.json", demo: [Contact.example()])
		} catch CocoaError.fileNoSuchFile {
			contacts = []
		}
	}
	func loadSettings() throws {
		do {
			userSettings = try loadUserJson(name: "settings.json", demo: UserSettings())
		} catch CocoaError.fileNoSuchFile {
			userSettings = UserSettings()
		}
	}
	func saveContacts() throws {
		try saveUserJson(name: "contacts.json", data: contacts)
	}
	func saveMessages() throws {
		try saveUserJson(name: "messages.json", data: messages)
	}
	func saveSettings() throws {
		try saveUserJson(name: "settings.json", data: userSettings)
	}
	
	// 加载共享来的消息数据
	func loadInbox() throws -> ([FailedMessage], [Message]) {
		let usersDirURL = appGroupURL.appendingPathComponent("users")
		let userDirURL = usersDirURL.appendingPathComponent(privateKey!.publicKey.String()).appendingPathComponent("whispers")
		if !FileManager.default.fileExists(atPath: userDirURL.path) {
			return ([],[])
		}
		guard let entries = try? FileManager.default.contentsOfDirectory(atPath: userDirURL.path) else {
			return ([],[])
		}
		
		var failed: [FailedMessage] = []
		var messages: [Message] = []
		
		try entries.forEach { name in
			let pathURL = userDirURL.appendingPathComponent(name)
			if !FileManager.default.isReadableFile(atPath: pathURL.path) {
				return
			}
			let data = try Data(contentsOf: pathURL)
			var messageId: UUID? = nil
			do {
				let file = try File.decode(data: data, recipient: privateKey!)
				let message = Message(title: file.title, receipients: [privateKey!.publicKey.String()], content: file.content)
				messageId = message.id
				for url in file.images {
					let _ = try saveMessageImage(messageID: message.id, srcURL: url)
				}
				for url in file.videos {
					let _ = try saveMessageVideo(messageID: message.id, srcURL: url)
				}
				message.read = false
				messages.append(message)
				try? FileManager.default.removeItem(at: pathURL)
			} catch {
				if let id = messageId {
					try removeMessageDir(messageID: id)
				}
				failed.append(FailedMessage(name: pathURL.lastPathComponent, reason: error.localizedDescription))
			}
		}
		
		return (failed, messages)
	}
	// 从 AirDrop 来的文件在 Documents/Inbox 目录，没区分用户。
	// 简单做法：拷贝到 whispers 目录，然后 reload。
	func copyFromInbox(url: URL) throws {
		let usersDirURL = appGroupURL.appendingPathComponent("users")
		let userDirURL = usersDirURL.appendingPathComponent(privateKey!.publicKey.String()).appendingPathComponent("whispers")
		try FileManager.default.createDirectory(at: userDirURL, withIntermediateDirectories: true)
		let dstURL = userDirURL.appendingPathComponent(url.lastPathComponent)
		print("拷贝文件：", url, dstURL)
		try FileManager.default.moveItem(at: url, to: dstURL)
	}
	
	func updateFailedMessages(failed: [FailedMessage]) {
		failed.forEach { f in
			if !failedMessages.contains{ $0.name == f.name } {
				failedMessages.insert(f, at: 0)
			}
		}
	}
	
	func deleteFailedMessage(name: String) {
		let usersDirURL = appGroupURL.appendingPathComponent("users")
		let userDirURL = usersDirURL.appendingPathComponent(privateKey!.publicKey.String()).appendingPathComponent("whispers")
		let pathURL = userDirURL.appendingPathComponent(name)
		do {
			try FileManager.default.removeItem(at: pathURL)
		} catch {
			print(error.localizedDescription)
		}
	}
	
	// 消息附件管理
	func saveMessageImage(messageID: UUID, srcURL: URL) throws -> URL {
		let imagesDir = try userDir().appendingPathComponent("messages")
			.appendingPathComponent(messageID.uuidString)
			.appendingPathComponent("images")
		try GlobalStates.createDir(url: imagesDir)
		let dstURL = imagesDir.appendingPathComponent(srcURL.lastPathComponent)
		try FileManager.default.secureCopyItem(at: srcURL, to: dstURL)
		print("拷贝文件：", dstURL)
		if let fileSize = try? dstURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
			print("文件大小：", ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .binary))
		}
		return dstURL
	}
	func saveMessageImage(messageID: UUID, uiImage: UIImage) throws -> URL {
		let imagesDir = try userDir().appendingPathComponent("messages")
			.appendingPathComponent(messageID.uuidString)
			.appendingPathComponent("images")
		try GlobalStates.createDir(url: imagesDir)
		let dstURL = imagesDir.appendingPathComponent(UUID().uuidString + ".jpeg")
		guard let data = uiImage.jpegData(compressionQuality: 0.8) else {
			throw "无效 UIImage 图片"
		}
		try data.write(to: dstURL)
		print("拷贝文件：", dstURL)
		print("文件大小：\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .binary))")
		return dstURL
	}
	func saveMessageVideo(messageID: UUID, srcURL: URL) throws -> URL {
		let imagesDir = try userDir().appendingPathComponent("messages")
			.appendingPathComponent(messageID.uuidString)
			.appendingPathComponent("videos")
		try GlobalStates.createDir(url: imagesDir)
		let dstURL = imagesDir.appendingPathComponent(srcURL.lastPathComponent)
		try FileManager.default.secureCopyItem(at: srcURL, to: dstURL)
		print("拷贝视频文件：", dstURL)
		if let fileSize = try? dstURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
			print("视频文件大小：", ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .binary))
		}
		return dstURL
	}
	func loadMessageMedia(forImage: Bool, messageID: UUID) throws -> [URL] {
		let dir = try userDir().appendingPathComponent("messages")
			.appendingPathComponent(messageID.uuidString)
			.appendingPathComponent(forImage ? "images" : "videos")
		if !FileManager.default.fileExists(atPath: dir.path) {
			print("没有消息媒体文件")
			return []
		}
		let entries = try FileManager.default.contentsOfDirectory(atPath: dir.path)
		let fullPaths = entries.map{ dir.appendingPathComponent($0) }
		return fullPaths
	}
	// 删除消息目录
	func removeMessageDir(messageID: UUID) throws {
		let dir = try userDir().appendingPathComponent("messages").appendingPathComponent(messageID.uuidString)
		if FileManager.default.fileExists(atPath: dir.path) {
			try FileManager.default.removeItem(at: dir)
		}
	}
	
	// 清理登录状态
	func signOut() {
		removeLastUser()
		messages = []
		contacts = []
		failedMessages = []
		loggedin = false
	}
}

struct Limitations {
	static let maxNumberOfMessages = 15
	static let maxNumberOfImages = 5
	static let maxNumberOfVideos = 1
	static let maxNumberOfReceipients = 3
	static let maxNumberOfContacts = 15
	
	static let maxImageSize = 5 << 20
	static let maxVideoSize = 100 << 20
}

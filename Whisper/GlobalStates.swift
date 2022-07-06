//
//  GlobalStates.swift
//  Whisper
//
//  Created by Yang Tao on 2022/07/05.
//

import Foundation

var appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.twofei.whisper.share")!
var appGroupUserDefaults = UserDefaults.init(suiteName: "group.com.twofei.whisper.share")!

class GlobalStates: ObservableObject {
	@Published var loggedin = false
	@Published var messages: [Message] = []
	@Published var contacts: [Contact] = []
	@Published var failedMessages: [FailedMessage] = []
	
	var privateKey: PrivateKey?
	
	// 以公钥命名的用户目录，登录后立即调用。
	func createUserDir() throws {
		guard let _ = privateKey else {
			fatalError("未登录时没有用户目录")
		}
		let user = userDir()
		try FileManager.default.createDirectory(at: user, withIntermediateDirectories: true)
	}
	
	func userDir() -> URL {
		guard let _ = privateKey else {
			fatalError("未登录时没有用户目录")
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
	
	// 只是做个备份，没有它用。
	func saveUserPrivateKey() throws {
		let userDir = GlobalStates.userDir(publicKey: privateKey!.publicKey)
		let privateKeyFile = userDir.appendingPathComponent("privateKey")
		try Data(privateKey!.String().utf8).write(to: privateKeyFile)
	}
	
	func saveUserJson(name: String, data: Encodable) throws {
		let data = try JSONEncoder().encode(data)
		let outfile = self.userDir().appendingPathComponent(name)
		try data.write(to: outfile)
	}
	
	func loadUserJson<T>(name: String, demo: T) throws -> T where T: Decodable {
		let fileURL = self.userDir().appendingPathComponent(name)
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
	func saveContacts() throws {
		try saveUserJson(name: "contacts.json", data: contacts)
	}
	func saveMessages() throws {
		try saveUserJson(name: "messages.json", data: messages)
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
			do {
				let file = try File.decode(data: data, recipient: privateKey!)
				let message = Message(title: file.title, receipients: [privateKey!.publicKey.String()], content: file.content)
				message.read = false
				messages.append(message)
				try? FileManager.default.removeItem(at: pathURL)
			} catch {
				failed.append(FailedMessage(name: pathURL.lastPathComponent, reason: error.localizedDescription))
			}
		}
		
		return (failed, messages)
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
}

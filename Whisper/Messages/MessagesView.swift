//
//  MessagesView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI

class FailedMessage: Identifiable {
	var id = UUID()
	
	var name: String
	var reason: String
	
	init(name: String, reason: String) {
		self.name = name
		self.reason = reason
	}
}

class Message: Identifiable, Codable, ObservableObject {
	var id = UUID()
	
	@Published var title: String
	@Published var content: String
	@Published var read: Bool = true
	
	func reset() {
		id = UUID()
		title = ""
		content = ""
		read = false
	}
	
	convenience init() {
		self.init(title: "", content: "")
	}
	
	init(id: UUID = UUID(), title: String, content: String) {
		self.id = id
		self.title = title
		self.content = content
	}
	
	enum CodingKeys: CodingKey {
		case id
		case title
		case content
		case read
	}
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(UUID.self, forKey: .id)
		title = try container.decode(String.self, forKey: .title)
		content = try container.decode(String.self, forKey: .content)
		read = try container.decode(Bool.self, forKey: .read)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(title, forKey: .title)
		try container.encode(content, forKey: .content)
		try container.encode(read, forKey: .read)
	}
	
	
	static func example() -> Message {
		return Message(title: "title", content: "内容\n内容")
	}
	static func exampleUnread() -> Message {
		let m = Message(title: "title", content: "内容")
		m.read = false
		return m
	}
}

struct MessageRow: View {
	// 搞不懂为什么这里不能用 @Binding
	// 如果用，会出现红点不能清除的问题
	// read 为 true，但是在 onAppear 里面打印出来却是 false
	@ObservedObject var message: Message
	
	var body: some View {
		HStack {
			Image(systemName: message.read ? "" : "circle.fill")
				.resizable()
				.frame(width: 6, height: 6)
				.foregroundColor(.accentColor)
			Text(message.title)
			Spacer()
		}
	}
}

struct FailedMessageRow: View {
	@Binding var failed: FailedMessage
	var body: some View {
		HStack {
			Image(systemName: "circle.fill")
				.resizable()
				.frame(width: 6, height: 6)
				.foregroundColor(.red)
			VStack(alignment: .leading) {
				Text(failed.name)
				Text(failed.reason).font(.footnote).foregroundColor(.gray)
			}
		}
	}
}

struct MessagesView: View {
	@EnvironmentObject var globalStates: GlobalStates
	@Environment(\.scenePhase) var scenePhase
	
	@State private var alertMessage = ""
	@State private var showingAlert = false
	
	// 点击加号添加新消息时使用的。
	@State private var newMessage = Message()
	@State private var showingNewMessage = false
	
	var body: some View {
		NavigationView {
			Group {
				if globalStates.messages.isEmpty && globalStates.failedMessages.isEmpty {
					Text("没有消息")
						.foregroundColor(.gray)
				} else {
					List {
						ForEach($globalStates.failedMessages) { $message in
							FailedMessageRow(failed: $message)
						}
						.onDelete(perform: deleteFailed(at:))
						ForEach($globalStates.messages) { $message in
							NavigationLink {
								ComposeMessageView(message: $message)
							} label: {
								MessageRow(message: message)
							}
						}
						.onDelete(perform: delete(at:))
					}
				}
			}
			.navigationBarTitle("消息")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				Button(action: {
					if globalStates.shouldLimit() && globalStates.messages.count >= Limitations.maxNumberOfMessages {
						alertMessage = "您目前只能保存最多 \(Limitations.maxNumberOfMessages) 条消息。"
						showingAlert = true
						return
					}
					showingNewMessage = true
				}, label: {
					Image(systemName: "plus")
				})
				.fullScreenCover(isPresented: $showingNewMessage) {
					ComposeNewMessageView(message: $newMessage, onClose: closeNewMessage)
				}
			}
		}
		.currentDeviceNavigationViewStyle()
		.onOpenURL { url in
			print("OpenURL:", url)
			if url.path.contains("/Documents/Inbox/") {
				do {
					try globalStates.copyFromInbox(url: url)
					// 从后台被唤醒的时候会先执行这里，因为上述拷贝行为是同步的。
					// 因此无需 load，场景变成 active 的时候自然会 load。
					// loadInboxAsync()
				} catch {
					alertMessage = error.localizedDescription
					showingAlert = true
				}
			}
		}
		.onChange(of: scenePhase) { phase in
			if phase == .active {
				loadInboxAsync()
			}
		}
		.alert(isPresented: $showingAlert) {
			Alert(title: Text("错误"), message: Text(alertMessage))
		}
	}
	
	private func loadInboxAsync() {
		DispatchQueue.global(qos: .default).async {
			if let (failed, found) = try? globalStates.loadInbox() {
				DispatchQueue.main.async {
					// 避免刷新
					if found.count > 0 {
						globalStates.messages.insert(contentsOf: found, at: 0)
					}
					globalStates.updateFailedMessages(failed: failed)
					print("刷新消息，找到 \(found.count) 条消息")
					print("错误内容：\(failed)")
				}
			}
		}
	}
	
	// TODO 提示是否需要保存。
	private func closeNewMessage(keep: Bool) {
		showingNewMessage = false
		if keep {
			let m = Message(
				id: newMessage.id,
				title: newMessage.title,
				content: newMessage.content
			)
			globalStates.messages.insert(m, at: 0)
		}
		newMessage.reset()
	}
	
	private func delete(at offsets: IndexSet) {
		do {
			try offsets.forEach { i in
				let m = globalStates.messages[i]
				try globalStates.removeMessageDir(messageID: m.id)
			}
		} catch {
			alertMessage = error.localizedDescription
			showingAlert = true
			return
		}
		globalStates.messages.remove(atOffsets: offsets)
	}
	
	private func deleteFailed(at offsets: IndexSet) {
		offsets.forEach {
			globalStates.deleteFailedMessage(name: globalStates.failedMessages[$0].name)
		}
		globalStates.failedMessages.remove(atOffsets: offsets)
	}
}

struct MessagesView_Previews: PreviewProvider {
	@State static private var globalStates = GlobalStates()
    static var previews: some View {
        MessagesView()
			.environmentObject(globalStates)
			.onAppear {
				globalStates.messages.append(Message.example())
				globalStates.messages.append(Message.exampleUnread())
				globalStates.failedMessages.append(FailedMessage(name: "name1", reason: "失败"))
				globalStates.failedMessages.append(FailedMessage(name: "name2", reason: "失败"))
			}
    }
}

// 奇怪为什么需要自己定义 editMode？
struct ComposeNewMessageView: View {
	@State var editMode: EditMode = .active
	@Binding var message: Message
	
	let onClose: ((_ keep: Bool)->Void)?
	
	var body: some View {
		NavigationView {
			ComposeMessageView(message: $message, onClose: onClose)
				.environment(\.editMode, $editMode)
		}
	}
}

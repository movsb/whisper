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

class Message: Identifiable, Codable {
	var id = UUID()
	
	var title: String
	var receipients: [String]
	var content: String
	var read: Bool = true
	
	init(id: UUID = UUID(), title: String, receipients: [String], content: String) {
		self.id = id
		self.title = title
		self.receipients = receipients
		self.content = content
	}
	
	static func example() -> Message {
		return Message(title: "title", receipients: ["9qVe6CQfdzBYQ55DT_BMTkcMYB-dN-cB2wDh1mhjHgY"], content: "")
	}
	static func exampleUnread() -> Message {
		let m = Message(title: "title", receipients: ["9qVe6CQfdzBYQ55DT_BMTkcMYB-dN-cB2wDh1mhjHgY"], content: "")
		m.read = false
		return m
	}
}

struct MessageRow: View {
	@Binding var message: Message
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
								ComposeMessageView(message: $message, messageContacts: globalStates.contacts.filter{
									message.receipients.contains($0.publicKey)
								})
							} label: {
								MessageRow(message: $message)
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
					let message = Message(title: "新消息", receipients: [], content: "")
					message.read = false
					globalStates.messages.insert(message, at: 0)
				}, label: {
					Image(systemName: "plus")
				})
			}
		}
		.onChange(of: scenePhase) { phase in
			if phase == .active {
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
		}
		.alert(isPresented: $showingAlert) {
			Alert(title: Text("错误"), message: Text(alertMessage))
		}
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

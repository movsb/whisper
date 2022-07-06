//
//  MessagesView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI

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
		return Message(title: "title", receipients: ["9qVe6CQfdzBYQ55DT_BMTkcMYB-dN-cB2wDh1mhjHgY"], content: "content")
	}
	static func exampleUnread() -> Message {
		let m = Message(title: "title", receipients: ["9qVe6CQfdzBYQ55DT_BMTkcMYB-dN-cB2wDh1mhjHgY"], content: "content")
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

struct MessagesView: View {
	@EnvironmentObject var globalStates: GlobalStates
	
	// 自动刷新收件箱的消息。
	let refreshInboxTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
	
	var body: some View {
		NavigationView {
			Group {
				if globalStates.messages.isEmpty {
					Text("没有消息")
						.foregroundColor(.gray)
				} else {
					List {
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
					let message = Message(title: "无标题", receipients: [], content: "默认内容")
					globalStates.messages.insert(message, at: 0)
				}, label: {
					Image(systemName: "plus")
				})
			}
		}
		.onReceive(refreshInboxTimer) { _ in
			if let (failed, found) = try? globalStates.loadInbox() {
				globalStates.messages.insert(contentsOf: found, at: 0)
				print("刷新消息，找到 \(found.count) 条消息")
				print("错误内容：\(failed)")
			}
		}
    }
	
	private func delete(at offsets: IndexSet) {
		globalStates.messages.remove(atOffsets: offsets)
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
			}
    }
}

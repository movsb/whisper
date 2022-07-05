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
	
	init(id: UUID = UUID(), title: String, receipients: [String], content: String) {
		self.id = id
		self.title = title
		self.receipients = receipients
		self.content = content
	}
}

struct MessageRow: View {
	@Binding var message: Message
	var body: some View {
		HStack {
			Label(message.title, systemImage: "message.fill")
			Spacer()
		}
	}
}


struct MessagesView: View {
	@EnvironmentObject var globalStates: GlobalStates
	
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
    }
}

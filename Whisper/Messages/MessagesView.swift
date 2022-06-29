//
//  MessagesView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI

struct Message: Identifiable, Codable {
	var id = UUID()
	
	var title: String
	var receipients: [String]
	var content: String
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


class MessageStore: ObservableObject {
	@Published var messages: [Message] = []
	
	private static func fileURL() throws -> URL {
		try FileManager.default.url(for: .documentDirectory,
			in: .userDomainMask,
			appropriateFor: nil,
			create: false)
		.appendingPathComponent("messages.json")
	}
	
	static func load(completion: @escaping (Result<[Message], Error>)->Void) {
		DispatchQueue.global(qos: .background).async {
			do {
				let fileURL = try fileURL()
				guard let file = try? FileHandle(forReadingFrom: fileURL) else {
					DispatchQueue.main.async {
						completion(.success([]))
					}
					return
				}
				let messages = try JSONDecoder().decode([Message].self, from: file.availableData)
				DispatchQueue.main.async {
					completion(.success(messages))
				}
			} catch {
				DispatchQueue.main.async {
					completion(.failure(error))
				}
			}
		}
	}
	
	static func save(messages: [Message], completion: @escaping (Result<Int, Error>)->Void) {
		DispatchQueue.global(qos: .background).async {
			 do {
				 let data = try JSONEncoder().encode(messages)
				 let outfile = try fileURL()
				 try data.write(to: outfile)
				 DispatchQueue.main.async {
					 completion(.success(messages.count))
				 }
			 } catch {
				 DispatchQueue.main.async {
					 completion(.failure(error))
				 }
			 }
		 }
	}
}

struct MessagesView: View {
	@Binding var messages: [Message]
	@Binding var contacts: [Contact]
	
	var body: some View {
		NavigationView {
			List {
				ForEach($messages) { $message in
					NavigationLink {
						ComposeMessageView(message: $message, userContacts: $contacts, messageContacts: contacts.filter{
							message.receipients.contains($0.publicKey)
						})
					} label: {
						MessageRow(message: $message)
					}
				}
			}
			.navigationBarTitle("消息")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				Button(action: {
					let message = Message(title: "无标题", receipients: [], content: "默认内容")
					messages.insert(message, at: 0)
				}, label: {
					Image(systemName: "plus")
				})
			}
		}
    }
}

struct MessagesView_Previews: PreviewProvider {
	@State static private var messages = [
		Message(title: "消息1", receipients: ["p1"], content: "消息内容"),
		Message(title: "消息2", receipients: ["p2"], content: "消息内容"),
	]
	@State static private var contacts = [
		Contact(id: "1", name: "1", publicKey: "1")
	]
    static var previews: some View {
        MessagesView(messages: $messages, contacts: $contacts)
    }
}

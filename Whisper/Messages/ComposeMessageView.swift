//
//  ComposeMessageView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/28.
//

import SwiftUI

struct MiniContactView: View {
	@Binding var contact: Contact
	var body: some View {
		VStack {
			Image(systemName: "person")
				.resizable()
				.frame(width: 20, height: 20)
			Text(contact.name)
				.font(.footnote)
		}
	}
}

struct ComposeMessageView: View {
	@Binding var message: Message
	
	func shareButton() {
			let url = URL(string: "https://designcode.io")
			let activityController = UIActivityViewController(activityItems: [url!], applicationActivities: nil)
			UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
	}
	
	@Binding var userContacts: [Contact]
	@State var messageContacts: [Contact]
	
	@State private var contactsToShow: [Contact] = []
	@State private var showSelectContacts = false
	
	func setNewContacts(contacts: [Contact]) {
		messageContacts.removeAll()
		message.receipients.removeAll()
		for c in contacts {
			messageContacts.append(c)
			message.receipients.append(c.publicKey)
		}
		print("设置新联系人：", message.receipients)
	}
	
	var body: some View {
		ScrollView {
			VStack {
				HStack {
					Text("标题：").bold()
					Spacer()
				}
				TextEditor(text: $message.title)
					.lineLimit(1)
					.frame(height: 35)
					.overlay {
						RoundedRectangle(cornerRadius: 4)
							.stroke(lineWidth: 1)
					}
					.padding(.bottom)
				/// TextField 在这里会自动中文变英文，解决不了。
//				TextField("", text: $message.title)
//					.overlay {
//						RoundedRectangle(cornerRadius: 4)
//							.stroke(lineWidth: 0.5)
//					}
//					.padding(.bottom)
				HStack {
					Text("接收人：").bold()
					Spacer()
				}
				HStack {
					ScrollView(.horizontal) {
						HStack {
							ForEach($messageContacts) { $contact in
								MiniContactView(contact: $contact)
							}
						}
					}
					Button(action: {
						contactsToShow = userContacts + messageContacts.filter { elem in
							!userContacts.contains { $0.id == elem.id }
						}
						showSelectContacts = true
					}, label: {
						Image(systemName: "plus")
							.resizable()
							.frame(width: 20, height: 20)
					})
					.popover(isPresented: $showSelectContacts) {
						SelectContactsView(
							showPopover: $showSelectContacts,
							distinctContacts: contactsToShow,
							selectedContacts: contactsToShow.filter{message.receipients.contains($0.publicKey)},
							setNewContacts: setNewContacts(contacts:)
						)
					}
				}
				.padding(.bottom)
				HStack {
					Text("内容：").bold()
					Spacer()
				}
				TextEditor(text: $message.content)
					.lineLimit(10)
					.frame(height: 200)
					.overlay {
						RoundedRectangle(cornerRadius: 4)
							.stroke(lineWidth: 1)
					}
			}
			.padding()
			.navigationBarTitle("编辑消息")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				Button(action: shareButton, label: {
					Image(systemName: "square.and.arrow.up")
				})
			}
		}
    }
}

struct ComposeMessageView_Previews: PreviewProvider {
	@State static var messageX = Message(title: "Title1", receipients: ["p1"], content: "Content1")
	@State static var userContacts = [Contact(id: "1", name: "1", publicKey: "1")]
    static var previews: some View {
		ComposeMessageView(
			message: $messageX,
			userContacts: $userContacts,
			messageContacts: userContacts.filter{
				messageX.receipients.contains($0.publicKey)
			}
		)
    }
}

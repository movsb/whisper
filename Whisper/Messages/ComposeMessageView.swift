//
//  ComposeMessageView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/28.
//

import SwiftUI

struct MiniContactView: View {
	var contact: Contact
	var body: some View {
		VStack {
			Image(systemName: contact.avatar)
				.resizable()
				.frame(width: 20, height: 20)
			Text(contact.name)
				.font(.footnote)
		}
	}
}

struct ComposeMessageView: View {
	@EnvironmentObject var globalStates: GlobalStates
	
	@Binding var message: Message
	
	@State private var showingAlert = false
	@State private var alertMessage = ""
	
	func shareButton() {
		if message.receipients.count <= 0 {
			alertMessage = "请选择接收人"
			showingAlert = true
			return
		}
		
		let body = message.title + "\0" + message.content
		do {
			let file = try NewFile(
				sender: globalStates.privateKey!,
				recipients: message.receipients.map{PublicKey.fromString(s: $0)!},
				message: body
			)
			// TODO 删除临时文件。
			let fileURL = try Data(file.bytes()).toTemporaryFileWithDateName()
			let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
			UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
		} catch {
			fatalError(error.localizedDescription)
		}
	}
	
	@State var messageContacts: [Contact]
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
								MiniContactView(contact: contact)
							}
						}
					}
					Button(action: {
						UIApplication.shared.endEditing()
						showSelectContacts = true
					}, label: {
						Image(systemName: "plus")
							.resizable()
							.frame(width: 20, height: 20)
					})
					.popover(isPresented: $showSelectContacts) {
						SelectContactsView(
							showPopover: $showSelectContacts,
							distinctContacts: globalStates.contacts,
							selectedContacts: globalStates.contacts.filter{message.receipients.contains($0.publicKey)},
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
				Button(action: {
					UIApplication.shared.endEditing()
					shareButton()
				}, label: {
					Image(systemName: "square.and.arrow.up")
				})
			}
		}
		.alert(alertMessage, isPresented: $showingAlert) {
			Button("OK", role: .cancel) { }
		}
		.onTapGesture {
			UIApplication.shared.endEditing()
		}
	}
}

struct ComposeMessageView_Previews: PreviewProvider {
	@State static var message = Message(title: "Title1", receipients: ["p1"], content: "Content1")
	@State static var contacts = [Contact(name: "1", publicKey: "1")]
	@StateObject var globalStates = GlobalStates()
    static var previews: some View {
		ComposeMessageView(
			message: $message,
			messageContacts: contacts.filter{
				message.receipients.contains($0.publicKey)
			}
		)
    }
}

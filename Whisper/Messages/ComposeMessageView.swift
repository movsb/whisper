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
		if message.receipients.count > 5 {
			alertMessage = "不能选择超过 5 个联系人"
			showingAlert = true
			return
		}
		
		do {
			let recipients = globalStates.contacts.filter { contact in message.receipients.contains(contact.publicKey) }.map{PublicKey.fromString(s: $0.publicKey)!}
			let file = File(fileHeader: kFileHeader, recipients: recipients, title: message.title, content: message.content)
			let encoded = try file.encode(sender: globalStates.privateKey!, fileKey: try! NewFileKey())
			let fileURL = try encoded.toTemporaryFileWithDateName()
			let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
			UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
			// TODO 删除分享文件
			// try? FileManager.default.removeItem(at: fileURL)
		} catch {
			alertMessage = error.localizedDescription
			showingAlert = true
			return
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
				TextField("", text: $message.title)
					.padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
					.overlay {
						RoundedRectangle(cornerRadius: 4)
							.stroke(lineWidth: 1)
							.fill(.gray)
					}
					.padding(.bottom)
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
					.frame(height: 200)
					.overlay {
						RoundedRectangle(cornerRadius: 4)
							.stroke(lineWidth: 1)
							.fill(.gray)
					}
					.padding(.bottom)
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
		.onAppear {
			message.read = true
			messageContacts = globalStates.contacts.filter{message.receipients.contains($0.publicKey)}
		}
	}
}

struct ComposeMessageView_Previews: PreviewProvider {
	@State static var message = Message.example()
	@State static var contacts = [Contact.example()]
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

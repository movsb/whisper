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

extension UIApplication {
	func endEditing() {
		sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
	}
}

extension Data {
	// https://stackoverflow.com/a/55092044/3628322
	func toTemporaryFile(fileName: String) throws -> URL {
		let data = self
		// Make the file path (with the filename) where the file will be loacated after it is created
		let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)

		do {
			// Write the file from data into the filepath (if there will be an error, the code jumps to the catch block below)
			try data.write(to: URL(fileURLWithPath: filePath))

			// Returns the URL where the new file is located in NSURL
			return URL(fileURLWithPath: filePath)

		} catch {
			fatalError("Error writing the file: \(error.localizedDescription)")
		}
	}
	func toTemporaryFileWithDateName() throws -> URL {
		let date = Date()
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
		let fileName = "Whisper-" + dateFormatter.string(from: date) + ".bin"
		return try self.toTemporaryFile(fileName: fileName)
	}
}

struct ComposeMessageView: View {
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
			let file = try NewFile(sender: gPrivateKey, recipients: [gPrivateKey.publicKey], message: body)
			// TODO 删除临时文件。
			let fileURL = try Data(file.bytes()).toTemporaryFileWithDateName()
			let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
			UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
		} catch {
			fatalError(error.localizedDescription)
		}
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
		.alert(alertMessage, isPresented: $showingAlert) {
			Button("OK", role: .cancel) { }
		}
		.onTapGesture {
			UIApplication.shared.endEditing()
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

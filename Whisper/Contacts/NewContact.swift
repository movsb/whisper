//
//  NewContact.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/27.
//

import SwiftUI
import CryptoKit

struct NewContactView: View {
	@State private var name: String = ""
	@State private var pubKeyStr: String = ""
	@Binding var contact: Contact
	@Binding var contacts: [Contact]
	@Binding var showCreate: Bool
	@State private var showingAlert = false
	@State private var alertMessage: String = ""
	@FocusState private var nameFocused: Bool
	@FocusState private var pubKeyFocused: Bool
	
	private func onSubmit() {
		let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmedName == "" {
			alertMessage = "名字不应为空"
			showingAlert = true
			return
		}
		pubKeyStr = gPrivateKey.publicKey.String()
		do {
			let pubKey = try PublicKey.fromString(s: pubKeyStr)
			contact = Contact(id: pubKey.String(), name: name, publicKey: pubKey.String())
			contacts.append(contact)
			contact.id = UUID().uuidString
			showCreate = false
		} catch {
			alertMessage = "无效的公钥（\(error)）"
			showingAlert = true
			return
		}
	}
	
	var body: some View {
		VStack {
			HStack {
				Button("取消") {
					showCreate = false
				}
				Spacer()
				Text("添加联系人")
					.bold()
				Spacer()
				Button("完成") {
					onSubmit()
				}
				.alert(isPresented: $showingAlert) {
					Alert(title: Text("错误"), message: Text("\(alertMessage)"))
				}
			}
			.padding(.bottom)
			HStack {
				Image(systemName: "person").frame(width: 30).aspectRatio(contentMode: .fit)
				TextField("名字", text: $name)
					.padding(.vertical)
					.focused($nameFocused)
					.onSubmit {
						pubKeyFocused = true
					}
			}
			HStack {
				Image(systemName: "key").frame(width: 30).aspectRatio(contentMode: .fit)
				TextField("公钥", text: $pubKeyStr)
					.padding(.vertical)
					.focused($pubKeyFocused)
					.onSubmit {
						onSubmit()
					}
			}
			Spacer()
		}
		.padding()
		.onAppear {
			nameFocused = true
		}
	}
}


struct NewContactView_Previews: PreviewProvider {
	@State static var showCreate  = false
	@State static var contact = gContacts[0]
	@State static var contacts = gContacts
    static var previews: some View {
		NewContactView(contact: $contact, contacts: $contacts, showCreate: $showCreate)
    }
}

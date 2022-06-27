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
	
	var body: some View {
		VStack {
			HStack {
				Button("取消") {
					showCreate = false
				}
				Spacer()
				Text("添加联系人")
					.font(.title)
				Spacer()
				Button("完成") {
					if name == "" {
						alertMessage = "名字不应为空"
						showingAlert = true
						return
					}
					let test = Curve25519.KeyAgreement.PrivateKey().publicKey.rawRepresentation.base64EncodedString()
					print(test)
					pubKeyStr = test
					if let data = Data(base64Encoded: pubKeyStr) {
						do {
							let pubKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: data)
							contact = Contact(id: pubKey.rawRepresentation.base64EncodedString(), name: name, avatar: "person", publicKey: pubKey)
							contacts.append(contact)
							contact.id = UUID().uuidString
							showCreate = false
						} catch {
							alertMessage = "无效的公钥（\(error)）"
							showingAlert = true
							return
						}
					} else {
						alertMessage = "无效的公钥"
						showingAlert = true
						return
					}
				}
				.alert(isPresented: $showingAlert) {
					Alert(title: Text("错误"), message: Text("\(alertMessage)"))
				}
			}
			HStack {
				Image(systemName: "person").frame(width: 30).aspectRatio(contentMode: .fit)
				TextField("名字", text: $name)
					.padding(.vertical)
					.focused($nameFocused)
			}
			HStack {
				Image(systemName: "key").frame(width: 30).aspectRatio(contentMode: .fit)
				TextField("公钥", text: $pubKeyStr)
					.padding(.vertical)
					.focused($pubKeyFocused)
			}
			Spacer()
		}
		.padding()
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

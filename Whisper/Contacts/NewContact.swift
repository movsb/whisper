//
//  NewContact.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/27.
//

import SwiftUI
import CryptoKit
import SFSymbolsPicker

struct NewContactView: View {
	@State private var name: String = ""
	@State private var pubKeyStr: String = ""
	
	@State private var iconSelected: String = "person"
	@State private var editAvatar: Bool = false
	
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
		pubKeyStr = NewPrivateKey().publicKey.String()
		guard let pubKey = PublicKey.fromString(s: pubKeyStr) else {
			alertMessage = "无效的公钥"
			showingAlert = true
			return
		}
		contact = Contact(id: pubKey.String(), name: name, publicKey: pubKey.String(), avatar: iconSelected)
		contacts.append(contact)
		contact.id = UUID().uuidString
		showCreate = false
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
			
			Button(action: {
				editAvatar = true
			}, label: {
				Image(systemName: iconSelected)
					.resizable()
					.frame(width: 100, height: 100)
					.padding()
					.foregroundColor(.accentColor)
			})
			.sheet(isPresented: $editAvatar, content: {
				SFSymbolsView(iconSelected: $iconSelected, isPresented: $editAvatar)
			})
			
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

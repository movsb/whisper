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
			nameFocused = true
			return
		}
		// pubKeyStr = NewPrivateKey().publicKey.String()
		guard let pubKey = PublicKey.fromString(s: pubKeyStr) else {
			alertMessage = "无效的公钥"
			showingAlert = true
			pubKeyFocused = true
			return
		}
		
		// 重复判断
		if let _ = contacts.first(where: {$0.name == trimmedName}) {
			alertMessage = "已经存在同名的联系人"
			showingAlert = true
			nameFocused = true
			return
		}
		if let c = contacts.first(where: {$0.publicKey == pubKeyStr}) {
			alertMessage = "已经存在相同公钥的联系人（名字：\(c.name)）"
			showingAlert = true
			pubKeyFocused = true
			return
		}
		
		contact = Contact(name: trimmedName, publicKey: pubKey.String(), avatar: iconSelected)
		contacts.append(contact)
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
					.padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
					.overlay {
						RoundedRectangle(cornerRadius: 4)
							.stroke(lineWidth: 1)
							.fill(.gray)
					}
					.padding(.vertical)
					.focused($nameFocused)
					.onSubmit {
						pubKeyFocused = true
					}
			}
			HStack {
				Image(systemName: "key").frame(width: 30).aspectRatio(contentMode: .fit)
				TextField("公钥", text: $pubKeyStr)
					.padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
					.overlay {
						RoundedRectangle(cornerRadius: 4)
							.stroke(lineWidth: 1)
							.fill(.gray)
					}
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
	@State static var contact = Contact.example()
	@State static var contacts = [Contact.example()]
    static var previews: some View {
		NewContactView(contact: $contact, contacts: $contacts, showCreate: $showCreate)
    }
}

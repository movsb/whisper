//
//  ContentView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI
import CryptoKit

struct ContentView: View {
	@State var privateKey: Curve25519.KeyAgreement.PrivateKey
	@StateObject private var contactStore = ContactStore()
	@StateObject private var messageStore = MessageStore()
	@Binding var loggedIn: Bool
	@Environment(\.scenePhase) private var scenePhase
	
	let saveAction: ()->Void
	
	static private let gMessages = [
		Message(title: "消息1", receipients: ["p1"], content: "消息内容"),
		Message(title: "消息2", receipients: ["p2"], content: "消息内容"),
	]
	
	
	var body: some View {
		TabView {
			MessagesView(messages: $messageStore.messages, contacts: $contactStore.contacts)
				.tabItem {
					Label("消息", systemImage: "message")
				}
			ContactsView(contacts: $contactStore.contacts)
				.tabItem {
					Label("联系人", systemImage: "person.crop.circle")
				}
			SettingsView(loggedIn: $loggedIn, privateKey: $privateKey)
				.tabItem {
					Label("设置", systemImage: "gear")
				}
		}
		.onAppear {
			ContactStore.load { result in
				switch result {
				case .failure(let error):
					fatalError(error.localizedDescription)
				case .success(let contacts):
					contactStore.contacts = contacts
				}
			}
			MessageStore.load { result in
				switch result {
				case .failure(let error):
					fatalError(error.localizedDescription)
				case .success(let messages):
					messageStore.messages = messages
				}
			}
		}
		.onChange(of: scenePhase) { phase in
			if phase == .inactive {
				ContactStore.save(contacts: contactStore.contacts) { result in
					if case .failure(let error) = result {
						fatalError(error.localizedDescription)
					}
				}
				MessageStore.save(messages: messageStore.messages) { result in
					if case .failure(let error) = result {
						fatalError(error.localizedDescription)
					}
				}
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	@State static private var privateKey = NewPrivateKey()
	@State static private var loggedIn = true
    static var previews: some View {
		ContentView(privateKey: privateKey, loggedIn: $loggedIn, saveAction: {})
    }
}

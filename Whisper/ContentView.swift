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
	@Environment(\.scenePhase) private var scenePhase
	
	let saveAction: ()->Void
	
	var body: some View {
		TabView {
			MessagesView()
				.tabItem {
					Label("消息", systemImage: "message")
				}
			ContactsView(contacts: $contactStore.contacts)
				.tabItem {
					Label("联系人", systemImage: "person.crop.circle")
				}
			SettingsView(privateKey: $privateKey)
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
		}
		.onChange(of: scenePhase) { phase in
			if phase == .inactive {
				ContactStore.save(contacts: contactStore.contacts) { result in
					if case .failure(let error) = result {
						fatalError(error.localizedDescription)
					}
				}
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	@State static private var privateKey = Curve25519.KeyAgreement.PrivateKey()
    static var previews: some View {
		ContentView(privateKey: privateKey, saveAction: {})
    }
}

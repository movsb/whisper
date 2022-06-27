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
	
	var body: some View {
		TabView {
			MessagesView()
				.tabItem {
					Label("信息", systemImage: "message")
				}
			ContactsView()
				.tabItem {
					Label("联系人", systemImage: "person.crop.circle")
				}
			SettingsView(privateKey: $privateKey)
				.tabItem {
					Label("设置", systemImage: "gear")
				}
			
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	@State static private var privateKey = Curve25519.KeyAgreement.PrivateKey()
    static var previews: some View {
        ContentView(privateKey: privateKey)
    }
}

//
//  ContentView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI

struct ContentView: View {
	private let publicKey = "Public Key"
	private let privateKey = "Private Key"
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
			SettingsView(publicKey: publicKey, privateKey: privateKey)
				.tabItem {
					Label("设置", systemImage: "gear")
				}
			
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

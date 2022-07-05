//
//  ContentView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI
import CryptoKit

struct ContentView: View {
	@Environment(\.scenePhase) private var scenePhase
	@EnvironmentObject var globalStates: GlobalStates
	
	var body: some View {
		TabView {
			MessagesView()
				.tabItem {
					Label("消息", systemImage: "message")
				}
			ContactsView()
				.tabItem {
					Label("联系人", systemImage: "person.crop.circle")
				}
			SettingsView()
				.tabItem {
					Label("设置", systemImage: "gear")
				}
		}
		.onChange(of: scenePhase) { phase in
			if phase == .inactive {
				try! globalStates.saveMessages()
				try! globalStates.saveContacts()
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	@StateObject static private var globalStates = GlobalStates()
    static var previews: some View {
		ContentView()
			.environmentObject(globalStates)
    }
}

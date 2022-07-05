//
//  WhisperApp.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI


@main
struct WhisperApp: App {
	@StateObject var globalStates = GlobalStates()
	
	var body: some Scene {
		WindowGroup {
			WelcomeView()
				.environmentObject(globalStates)
				.onAppear {
					loadLastUser()
				}
		}
	}
	
	private func loadLastUser() {
		guard let publicKey = GlobalStates.lastUser() else {
			return
		}
		let privateKey = GlobalStates.loadUserPrivteKey(publicKey: publicKey)
		globalStates.privateKey = privateKey
		try! globalStates.loadMessages()
		try! globalStates.loadContacts()
		globalStates.loggedin = true
	}
}

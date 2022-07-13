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
					UITextView.appearance().backgroundColor = .clear
					loadLastUser(globalStates)
				}
		}
	}
	
}

func loadLastUser(_ globalStates: GlobalStates) {
	guard let publicKey = GlobalStates.lastUser() else {
		return
	}
	let privateKey = GlobalStates.loadUserPrivteKey(publicKey: publicKey)
	globalStates.privateKey = privateKey
	try! globalStates.loadMessages()
	try! globalStates.loadContacts()
	try! globalStates.loadSettings()
	
	if globalStates.userSettings.enableFaceID {
		Me.authenticate(succeeded: {
			DispatchQueue.main.async {
				globalStates.loggedin = true
				globalStates.lastUserFailed = false
			}
		}, failed: {
			DispatchQueue.main.async {
				globalStates.lastUserFailed = true
			}
		})
	} else {
		globalStates.loggedin = true
	}
}

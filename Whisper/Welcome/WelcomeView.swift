//
//  WelcomeView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/27.
//

import SwiftUI
import CryptoKit

struct WelcomeView: View {
	@EnvironmentObject var globalStates: GlobalStates
	
	@State var showingAlert = false
	@State var alertMessage = ""
	
	@State var showingAlertCreateFromPrivateKey = false
	
	var body: some View {
		if !globalStates.loggedin {
			VStack {
				Text("Whisper")
					.font(.largeTitle)
					.bold()
					.foregroundColor(.accentColor)
				Button("创建新帐号") {
					newUser()
				}
				.padding()
				Button("从私钥登录") {
					showingAlertCreateFromPrivateKey = true
				}
				.padding()
				if globalStates.lastUserFailed {
					Button("上次登录帐号") {
						loadLastUser(globalStates)
					}
					.padding()
				}
			}
			.alert(isPresented: $showingAlert) {
				Alert(title: Text("错误"), message: Text(alertMessage))
			}
			.alert(isPresented: $showingAlertCreateFromPrivateKey, TextAlert(
				title: "请输入你的私钥", message: "") { result in
					trySignin(result: result)
				})
		} else {
			ContentView()
		}
	}
	
	private func newUser() {
		globalStates.privateKey = NewPrivateKey()
		do {
			try globalStates.createUserDir()
			try globalStates.saveUserPrivateKey()
			globalStates.setLastUser()
		} catch {
			alertMessage = error.localizedDescription
			showingAlert = true
			globalStates.loggedin = false
//			globalStates.privateKey = nil
			return
		}
		
		globalStates.firstUse = true
		globalStates.loggedin = true
	}
	
	private func trySignin(result: String?) {
		guard let _ = result else {
			showingAlertCreateFromPrivateKey = false
			return
		}
		guard let privateKey = PrivateKey.fromString(s: result!) else {
			alertMessage = "无效的私钥"
			showingAlert = true
			return
		}
			
		if !GlobalStates.userDirExists(publicKey: privateKey.publicKey) {
			alertMessage = "不存在此帐号"
			showingAlert = true
			return
		}

		globalStates.privateKey = privateKey
		
		do {
			try globalStates.loadMessages()
			try globalStates.loadContacts()
			try globalStates.loadSettings()
		} catch {
			alertMessage = error.localizedDescription
			showingAlert = true
			globalStates.signOut()
			return
		}
		
		showingAlertCreateFromPrivateKey = false
		
		func welcomeBack() {
			globalStates.setLastUser()
			globalStates.loggedin = true
		}
		
		if globalStates.userSettings.enableFaceID {
			Me.authenticate(succeeded: {
				DispatchQueue.main.async {
					welcomeBack()
				}
			}, failed: {})
		} else {
			welcomeBack()
		}
	}
}

struct Welcome_Previews: PreviewProvider {
	@StateObject static private var globalStates = GlobalStates()
	static var previews: some View {
		WelcomeView()
			.environmentObject(globalStates)
	}
}

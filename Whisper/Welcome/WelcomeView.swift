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
				Text("欢迎").font(.title).bold()
					.padding()
				Text("Whisper")
					.font(.largeTitle)
					.bold()
					.foregroundColor(.accentColor)
				Button("创建新用户") {
					newUser()
				}
				.padding()
				Button("从私钥创建") {
					showingAlertCreateFromPrivateKey = true
				}
				.padding()
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
			globalStates.privateKey = nil
			return
		}
		
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
			alertMessage = "不存在此用户"
			showingAlert = true
			return
		}

		globalStates.privateKey = privateKey
		
		do {
			try globalStates.loadMessages()
			try globalStates.loadContacts()
		} catch {
			alertMessage = error.localizedDescription
			showingAlert = true
			return
		}
		
		showingAlertCreateFromPrivateKey = false
		
		globalStates.setLastUser()
		globalStates.loggedin = true
	}
}

struct Welcome_Previews: PreviewProvider {
	@StateObject static private var globalStates = GlobalStates()
	static var previews: some View {
		WelcomeView()
			.environmentObject(globalStates)
	}
}

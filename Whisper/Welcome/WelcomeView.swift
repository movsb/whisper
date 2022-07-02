//
//  WelcomeView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/27.
//

import SwiftUI
import CryptoKit

let gPrivateKey = PrivateKey.fromString(s: "WEesyIFj3BdDanc31GExMCdrFdseLGgMF5zbOGPkSXE=")!

struct WelcomeView: View {
	@State private var loggedin = false
	@State private var loginPrivateKey: PrivateKey = NewPrivateKey()
	var body: some View {
		if !loggedin {
			VStack {
				Text("欢迎").font(.title).bold()
					.padding()
				Text("Whisper")
					.font(.largeTitle)
					.bold()
					.foregroundColor(.accentColor)
				Button("创建新用户") {
					loginPrivateKey = NewPrivateKey()
					loggedin = true
				}
				.padding()
				Button("从私钥创建") {
					
				}
				.padding()
				Button("测试用户") {
					loginPrivateKey = gPrivateKey
					loggedin = true
				}
				.padding()
			}
		} else {
			ContentView(privateKey: loginPrivateKey, loggedIn: $loggedin, saveAction: {})
		}
    }
}

struct Welcome_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}

//
//  WelcomeView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/27.
//

import SwiftUI
import CryptoKit

struct WelcomeView: View {
	@State private var loggedin = false
	@State private var loginPrivateKey: Curve25519.KeyAgreement.PrivateKey?
	var body: some View {
		if !loggedin {
			VStack {
				Text("欢迎").font(.largeTitle).bold()
				Button("创建新用户") {
					loginPrivateKey = generateKeyPairs()
					print(loginPrivateKey!.rawRepresentation.base64EncodedString())
					loggedin = true
				}
				.padding()
				Button("从私钥创建") {
					
				}
				.padding()
				Button("访问钥匙串") {
					
				}
				.padding()
				Button("测试用户") {
					loginPrivateKey = try! Curve25519.KeyAgreement.PrivateKey(rawRepresentation: Data(base64Encoded: "WEesyIFj3BdDanc31GExMCdrFdseLGgMF5zbOGPkSXE=")!)
					loggedin = true
				}
				.padding()
			}
		} else {
			ContentView(privateKey: loginPrivateKey!, saveAction: {})
		}
    }
}

struct Welcome_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}

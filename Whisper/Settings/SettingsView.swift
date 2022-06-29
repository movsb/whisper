//
//  SettingsView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI
import CryptoKit

struct SettingsView: View {
	@Binding var privateKey: Curve25519.KeyAgreement.PrivateKey
	
	var body: some View {
		NavigationView {
			VStack {
				Image(systemName: "person.badge.key.fill")
					.resizable()
					.frame(width: 100, height: 100)
					.padding()
				VStack {
					Text("我的公钥")
						.font(.headline)
					Text(privateKey.publicKey.rawRepresentation.base64EncodedString())
						.padding()
					// https://stackoverflow.com/a/66903216/3628322
						.contextMenu(ContextMenu(menuItems: {
							Button("复制", action: {
								let s = privateKey.publicKey.rawRepresentation.base64EncodedString()
								UIPasteboard.general.string = s
							})
						}))
						.lineLimit(1)
					Text("我的私钥")
						.font(.headline)
					Text(privateKey.rawRepresentation.base64EncodedString())
						.padding()
						.contextMenu(ContextMenu(menuItems: {
							Button("复制", action: {
								let s = privateKey.rawRepresentation.base64EncodedString()
								UIPasteboard.general.string = s
							})
						}))
						.lineLimit(1)
				}
				Button("退出登录") {
					
				}
				Spacer()
			}
			.navigationTitle("设置")
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}

struct SettingsView_Previews: PreviewProvider {
	@State static private var privateKey = Curve25519.KeyAgreement.PrivateKey()
    static var previews: some View {
		SettingsView(privateKey: $privateKey)
    }
}

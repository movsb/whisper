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
			List {
				HStack {
					Spacer()
					Image(systemName: "person.badge.key.fill")
						.resizable()
						.frame(width: 100, height: 100)
						.padding()
					Spacer()
				}
				SwiftUI.Section {
					HStack {
						Text("我的公钥")
						Text(privateKey.publicKey.rawRepresentation.base64EncodedString())
							// https://stackoverflow.com/a/66903216/3628322
							.contextMenu(ContextMenu(menuItems: {
								Button("复制", action: {
									let s = privateKey.publicKey.rawRepresentation.base64EncodedString()
									UIPasteboard.general.string = s
								})
							}))
							.lineLimit(1)
					}
					HStack {
						Text("我的私钥")
						Text(privateKey.rawRepresentation.base64EncodedString())
							.contextMenu(ContextMenu(menuItems: {
								Button("复制", action: {
									let s = privateKey.rawRepresentation.base64EncodedString()
									UIPasteboard.general.string = s
								})
							}))
							.lineLimit(1)
					}
				}
				Button(action: {
					
				}, label: {
					HStack {
						Spacer()
						Text("退出登录")
							.foregroundColor(.red)
						Spacer()
					}
				})
			}
			.listStyle(.grouped)
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

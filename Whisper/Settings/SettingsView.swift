//
//  SettingsView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI
import CryptoKit

struct SettingsView: View {
	@Binding var loggedIn: Bool
	@Binding var privateKey: PrivateKey
	@State private var alertSignout = false
	
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
					alertSignout = true
				}, label: {
					HStack {
						Spacer()
						Text("退出登录")
							.foregroundColor(.red)
						Spacer()
					}
				})
				.alert(isPresented: $alertSignout) {
					Alert(
						title: Text("确认退出登录？"),
						message: Text("如果你忘记了私钥，你将不能登录此帐号。请在确认退出前妥善保管你的私钥。"),
						primaryButton: .destructive(Text("退出登录")) {
							loggedIn = false
						},
						secondaryButton: .cancel()
					)
				}
			}
			.listStyle(.grouped)
			.navigationTitle("设置")
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}

struct SettingsView_Previews: PreviewProvider {
	@State static private var privateKey = NewPrivateKey()
	@State static private var loggedIn = false
    static var previews: some View {
		SettingsView(loggedIn: $loggedIn, privateKey: $privateKey)
    }
}

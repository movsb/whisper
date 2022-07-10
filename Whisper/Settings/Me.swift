//
//  Me.swift
//  Whisper
//
//  Created by Yang Tao on 2022/07/10.
//

import SwiftUI

struct Me: View {
	@EnvironmentObject var globalStates: GlobalStates
	@State private var alertSignout = false

	var body: some View {
		VStack {
			HStack {
				Spacer()
				Image(systemName: "person.badge.key.fill")
					.resizable()
					.frame(width: 100, height: 100)
					.padding()
				Spacer()
			}
			List {
				HStack {
					Text("我的公钥")
					Text(globalStates.privateKey!.publicKey.String())
						// https://stackoverflow.com/a/66903216/3628322
						.contextMenu(ContextMenu(menuItems: {
							Button("复制", action: {
								let s = globalStates.privateKey!.publicKey.String()
								UIPasteboard.general.string = s
							})
						}))
						.lineLimit(1)
				}
				HStack {
					Text("我的私钥")
					Text(globalStates.privateKey!.String())
						.contextMenu(ContextMenu(menuItems: {
							Button("复制", action: {
								let s = globalStates.privateKey!.String()
								UIPasteboard.general.string = s
							})
						}))
						.lineLimit(1)
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
			}
			.alert(isPresented: $alertSignout) {
				Alert(
					title: Text("确认退出登录？"),
					message: Text("如果你忘记了私钥，你将不能登录此帐号。请在确认退出前妥善保管你的私钥。"),
					primaryButton: .destructive(Text("退出登录")) {
						signOut()
					},
					secondaryButton: .cancel()
				)
			}
		}
	}
	
	private func signOut() {
		try! globalStates.saveMessages()
		try! globalStates.saveContacts()
		globalStates.removeLastUser()
		globalStates.messages = []
		globalStates.contacts = []
		globalStates.failedMessages = []
		globalStates.loggedin = false
		// 这里不能清 privateKey，会崩溃。
	}
}

struct Me_Previews: PreviewProvider {
	@StateObject static private var globalStates = GlobalStates(privateKey: NewPrivateKey())

    static var previews: some View {
        Me()
			.environmentObject(globalStates)
    }
}
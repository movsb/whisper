//
//  SettingsView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI
import CryptoKit

struct SettingsView: View {
	@EnvironmentObject var globalStates: GlobalStates
	
	var body: some View {
		NavigationView {
			VStack {
				Text("Whisper")
					.font(.largeTitle)
					.fontWeight(.bold)
					.foregroundColor(.accentColor)
					.padding(EdgeInsets(top: 10, leading: 0, bottom: 1, trailing: 0))
				Text("Version: v1.0.0")
					.font(.footnote)
				Form {
					Section {
						NavigationLink(destination: {
							Me()
								.navigationTitle("我的帐号")
								.navigationBarTitleDisplayMode(.inline)
						}, label: {
							Text("我的帐号")
						})
						NavigationLink(destination: {
							PrivacyView()
								.navigationTitle("隐私政策")
								.navigationBarTitleDisplayMode(.inline)
								.padding()
						}, label: {
							Text("隐私政策")
						})
					}
				}
			}
		}
	}
}

struct SettingsView_Previews: PreviewProvider {
	@StateObject static private var globalStates = GlobalStates(privateKey: NewPrivateKey())
	static var previews: some View {
		SettingsView()
			.environmentObject(globalStates)
	}
}

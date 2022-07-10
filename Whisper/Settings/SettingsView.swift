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
						NavigationLink(destination: {
							techDetails
								.navigationTitle("技术细节")
								.navigationBarTitleDisplayMode(.inline)
								.padding()
						}, label: {
							Text("技术细节")
						})
					}
				}
			}
		}
	}
	
	private var techDetails: some View {
		ScrollView {
			Text("""
本应用使用 Curve25519 椭圆曲线进行公钥加密（256 位密钥大小），使用 AES 256 位 GCM 模式进行对称加密（考虑使用 Chacha20-Poly1305 替代），未使用 AEAD。
""")
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

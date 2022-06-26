//
//  SettingsView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI

struct SettingsView: View {
	@State var publicKey: String
	@State var privateKey: String
	
	var body: some View {
		ScrollView {
			Group {
				VStack {
					Text("我的")
					Text("公钥")
					TextEditor(text: $publicKey)
						.frame(height: 300)
						.border(.secondary, width: 1)
					Text("私钥")
					TextEditor(text: $privateKey)
						.frame(height: 300)
						.border(.secondary, width: 1)
				}
				Button("退出登录") {
					
				}
			}.padding()
		}
		.navigationTitle("设置")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(publicKey: "Public Key Here", privateKey: "Private Key Here")
    }
}

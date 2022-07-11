//
//  FirstUseView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/07/10.
//

import SwiftUI

struct FirstUseView: View {
    var body: some View {
		ScrollView {
			VStack {
				Text("欢迎使用")
					.font(.title)
					.fontWeight(.bold)
				Text("Whisper")
					.font(.title)
					.foregroundColor(.accentColor)
					.fontWeight(.bold)
					.padding(.bottom)
				
				makeItemView(
					icon: "person.crop.circle.badge.plus",
					title: "创建新帐号",
					content: "在您的设备和您的朋友的设备中创建新帐号并相互添加对方公钥到联系人列表中。"
				)
				makeItemView(
					icon: "plus.message",
					title: "创建新消息",
					content: "在您的设备上创建并编辑新消息。您可以为消息添加文本、图片与视频。"
				)
				makeItemView(
					icon: "square.and.arrow.up.circle",
					title: "与您的朋友们分享",
					content: "通过隔空投送（AirDrop）或者社交应用安全地分享给您的朋友，选择使用 Whisper 打开并阅读。"
				)
			}
		}
	}
	
	private func makeItemView(icon: String, title: String, content: String) -> some View {
		HStack {
			VStack {
				Image(systemName: icon)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.foregroundColor(.accentColor)
					.frame(width: 35)
				Spacer()
			}
			VStack {
				HStack {
					Text(title)
						.fontWeight(.bold)
						.frame(alignment: .leading)
					Spacer()
				}
				HStack {
					Text(content)
						.font(.subheadline)
					Spacer()
				}
			}
		}
		.padding(.bottom)
	}
}

struct FirstUseView_Previews: PreviewProvider {
    static var previews: some View {
        FirstUseView()
    }
}

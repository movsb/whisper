//
//  FirstUseView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/07/10.
//

import SwiftUI

struct FirstUseView: View {
	@Binding var show: Bool
	
    var body: some View {
		VStack {
			ScrollView {
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
					content: "在您的设备中创建新帐号，并可通过公钥添加另一设备到设备列表。"
				)
				makeItemView(
					icon: "plus.message",
					title: "创建新消息",
					content: "在您的设备上创建并编辑新消息。可以是文本、图片和视频。"
				)
				makeItemView(
					icon: "square.and.arrow.up.circle",
					title: "分享到设备",
					content: "在隔空投送（AirDrop）或其它应用中分享，然后使用 Whisper 打开并阅读。"
				)
			}
			Button(action: {
				show = false
			}
			, label: {
				Text("开始使用")
					.padding(15)
			})
		}
		.padding(EdgeInsets(top: 50, leading: 50, bottom: 50, trailing: 50))
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
	@State static private var show = true
    static var previews: some View {
        FirstUseView(show: $show)
    }
}

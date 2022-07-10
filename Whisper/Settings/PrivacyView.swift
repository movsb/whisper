//
//  Privacy.swift
//  Whisper
//
//  Created by Yang Tao on 2022/07/10.
//

import SwiftUI

struct PrivacyView: View {
	private let policy = """
网络：本应用不需要网络访问权限。

相册：本应用使用系统组件从相册选择照片，所以其无需申请相册访问权限。但是由于系统组件原因，选择照片或视频时，只能一次性选择一张。

拍照：需要访问照相机。

视频录制：需要访问麦克风。

帐号：所有帐号信息只保存在本设备中，不会与任何服务器同步。请妥善保存您的私钥（公钥无需保存）。
"""
    var body: some View {
		ScrollView {
			Text(policy)
			Spacer()
		}
    }
}

struct PrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyView()
    }
}

//
//  Privacy.swift
//  Whisper
//
//  Created by Yang Tao on 2022/07/10.
//

import SwiftUI

struct PrivacyView: View {
	private let policy = """
账号及安全：私钥不可公开，请务必严格保密，公钥可随意公开。

内容及同步：无任何服务器同步，所有信息仅保存于当前设备中。

相册访问权：不需要，仅通过系统组件选择照片，每次一张/段。

拍照及录制：需要访问相机/麦克风。

网络访问权：不联网，无需访问权。
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

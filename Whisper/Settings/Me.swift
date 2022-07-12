//
//  Me.swift
//  Whisper
//
//  Created by Yang Tao on 2022/07/10.
//

import SwiftUI
import LocalAuthentication

struct Me: View {
	@EnvironmentObject var globalStates: GlobalStates
	@State private var alertSignout = false
	
	@State private var enableFaceID = false
	
	init() {
	}
	
	static func biometricType() -> LABiometryType {
		let authContext = LAContext()
		let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
		return authContext.biometryType
	}
	
	static func biometricName() -> String {
		switch Me.biometricType() {
		case .faceID:
			return "FaceID"
		case .touchID:
			return "TouchID"
		default:
			return "None"
		}
	}
	
	static func authenticate(succeeded: @escaping ()->(), failed: @escaping ()->()) {
		let context = LAContext()
		var error: NSError?
		
		context.localizedFallbackTitle = ""
		
		// check whether biometric authentication is possible
		if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
			// it's possible, so go ahead and use it
			let reason = "启用以登录。"
			
			context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
				// authentication has now completed
				if success {
					// authenticated successfully
					print("验证成功")
					succeeded()
				} else {
					print("验证失败", authenticationError?.localizedDescription ?? "")
					failed()
					// there was a problem
				}
			}
		} else {
			print("错误：\(error?.localizedDescription ?? "未知")")
			failed()
		}
	}

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
			Form {
				Section(header: Text("帐号").padding(.top)) {
					HStack {
						Text("我的公钥")
						Text(globalStates.privateKey!.publicKey.String())
							.textSelection(.enabled)
							.lineLimit(1)
					}
					HStack {
						Text("我的私钥")
						Text(globalStates.privateKey!.String())
							.textSelection(.enabled)
							.lineLimit(1)
					}
				}
				if Me.biometricType() != .none {
					Section(header: Text("安全")) {
						Toggle(isOn: $enableFaceID) {
							Text("启用 " + Me.biometricName())
						}
						.onChange(of: enableFaceID) { enable in
							// 在初始化和验证失败的时候都会走到这里。
							if enable == globalStates.userSettings.enableFaceID {
								return
							}
							Me.authenticate(succeeded:{
								globalStates.userSettings.enableFaceID = enable
							}, failed: {
								DispatchQueue.main.async {
									enableFaceID.toggle()
								}
								print("人脸验证失败")
							})
						}
					}
				}
				Section {
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
			}
			.alert(isPresented: $alertSignout) {
				Alert(
					title: Text("确认退出登录？"),
					message: Text("如果你忘记了私钥，你将不能登录此帐号。请在确认退出前妥善保管你的私钥。"),
					primaryButton: .destructive(Text("退出登录")) {
						if globalStates.userSettings.enableFaceID {
							Me.authenticate(succeeded: {
								DispatchQueue.main.async {
									signOut()
								}
							}, failed: {})
						} else {
							signOut()
						}
					},
					secondaryButton: .cancel()
				)
			}
		}
		.onAppear {
			// https://stackoverflow.com/a/65739423/3628322
			enableFaceID = globalStates.userSettings.enableFaceID
		}
	}
	
	private func signOut() {
		try! globalStates.saveMessages()
		try! globalStates.saveContacts()
		try! globalStates.saveSettings()
		globalStates.signOut()
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

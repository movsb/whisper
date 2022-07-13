//
//  ShareViewController.swift
//  Sharing
//
//  Created by Yang Tao on 2022/07/03.
//

import SwiftUI
import UIKit

enum ShareError: Error {
	case unspecified
}

private let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.twofei.whisper.share")!
private let appGroupUserDefaults = UserDefaults.init(suiteName: "group.com.twofei.whisper.share")!


@objc (ShareViewController)
class ShareViewController: UIViewController {
	let container = UIHostingController(rootView: SwiftUIView(sharedData: SharedData()))
	private var sharedData: SharedData = SharedData()
	private var currentUserPublicKeyString = ""
	
	private func cancelRequest() {
		self.extensionContext!.cancelRequest(withError: ShareError.unspecified)
	}
	private func completeRequest() {
		self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
	}
	
	// https://www.youtube.com/watch?v=z_9EOGDw5uk
	private func setView() {
		addChild(container)
		view.addSubview(container.view)
		container.didMove(toParent: self)
		container.view!.backgroundColor = .clear
		
		container.view.translatesAutoresizingMaskIntoConstraints = false
		container.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
		container.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
		container.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
		container.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
	}
	
	private func showErrorAndExit(message: String) {
		sharedData.fn = cancelRequest
		sharedData.alertMessage = message
		sharedData.alertShowing = true
	}
		
	private func showErrorAndExitAsync(message: String) {
		return DispatchQueue.main.async {
			return self.showErrorAndExit(message: message)
		}
	}
	
	private func initialize() {
	}
		
	override func viewDidLoad() {
		super.viewDidLoad()
		
		sharedData = container.rootView.sharedData
		
		setView()
		
		guard let currentUserPublicKey = appGroupUserDefaults.string(forKey: "currentUserPublicKey") else {
			return showErrorAndExit(message: "请先创建新帐号或登录已有帐号后再进行此操作。")
		}
		currentUserPublicKeyString = currentUserPublicKey
		
		// 为什么这里总是 1 个？
		guard let item = extensionContext?.inputItems.first as? NSExtensionItem else {
			return showErrorAndExit(message: "错误的 ExtensionItem")
		}
		
		guard let attachments = item.attachments else {
			return showErrorAndExit(message: "未能取得附件。")
		}
		
		if attachments.count != 1 {
			return showErrorAndExit(message: "选择的文件过多，目前只支持处理 1 个文件。")
		}

		let knownTypes = ["public.data"]

		// 以避免复制数据后遇到报错，先行判断支持的类型。
		for attachment: NSItemProvider in attachments {
			for ty in knownTypes {
				if !attachment.hasItemConformingToTypeIdentifier(ty) {
					return showErrorAndExit(message: "包含不支持的文件类型。")
				}
			}
		}
		
		// 已经是全部支持的类型
		
		for attachment: NSItemProvider in attachments {
			for ty in knownTypes {
				if attachment.hasItemConformingToTypeIdentifier(ty) {
					switch ty {
					case "public.data":
						// TODO 官方文档说这里的 handler 是异步的
						// https://developer.apple.com/documentation/foundation/nsitemprovider/1403900-loaditem
						attachment.loadItem(forTypeIdentifier: ty, options: nil, completionHandler: { data, err in
							if let err {
								// TODO 清理共享目录。
								return self.showErrorAndExitAsync(message: "加载数据时出错：\(err.localizedDescription)")
							}
							self.loadItemCompletionHandler(data: data)
						})
						return
					default:
						return self.showErrorAndExitAsync(message: "内部错误（未处理的断言类型）")
					}
				}
			}
		}
		
		// 不应该走到这里来
		cancelRequest()
	}
	
	private func loadItemCompletionHandler(data: NSSecureCoding?) {
		let kMaxFileSize = 128 << 20
		
		guard let srcURL = data as? URL else {
			return showErrorAndExitAsync(message: "无法将数据转换成 URL 类型。")
		}
		guard let fileSize = try? srcURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
			return showErrorAndExitAsync(message: "无法取得文件大小")
		}
		if fileSize > kMaxFileSize {
			return showErrorAndExitAsync(message: "文件大小超过限制：\(fileSize) > \(kMaxFileSize)")
		}
		// 判断文件格式是否正确
		guard let fp = try? FileHandle(forReadingFrom: srcURL) else {
			return showErrorAndExitAsync(message: "无法读取文件内容")
		}
		let bytesToRead = min(64, fileSize)
		guard let data = try? fp.read(upToCount: bytesToRead) else {
			try? fp.close()
			return showErrorAndExitAsync(message: "无法读取文件内容")
		}
		try? fp.close()
		
		// TODO: 导不出来，直接写了。
		if !data.starts(with: "Whipser/1.0\n".utf8) {
			return showErrorAndExitAsync(message: "文件格式不正确。")
		}
		
		guard let shareDirectory = FileManager().containerURL(forSecurityApplicationGroupIdentifier: "group.com.twofei.whisper.share") else {
			return showErrorAndExitAsync(message: "无法取得共享目录")
		}
		
		// 只复制到当前用户目录，以防止复制后切换用户
		let usersDirURL = shareDirectory.appendingPathComponent("users")
		let userDirURL = usersDirURL.appendingPathComponent(currentUserPublicKeyString)
		let filesDir = userDirURL.appendingPathComponent("whispers")
		do {
			try FileManager.default.createDirectory(at: filesDir, withIntermediateDirectories: true)
		} catch {
			return showErrorAndExitAsync(message: "创建目录失败：\(error.localizedDescription)")
		}
		
		let srcName = srcURL.lastPathComponent
		let dstURL = filesDir.appendingPathComponent(srcName)
		
		// 如果文件名存在，则提示覆盖
		if FileManager.default.fileExists(atPath: dstURL.path) {
			DispatchQueue.main.async {
				self.sharedData.alertOverwriteMessage = "\(dstURL.lastPathComponent)"
				self.sharedData.alertOverWriteOKFn = { self.copy(srcURL: srcURL, dstURL: dstURL) }
				self.sharedData.alertOverWriteCancelFn = { self.cancelRequest() }
				self.sharedData.alertOverwrite = true
			}
			return
		}
		
		// 这里和覆盖时使用的不是同一个线程。行为似乎不一样（Share Extension 关不掉）。
		self.copy(srcURL: srcURL, dstURL: dstURL)
	}
	
	private func copy(srcURL: URL, dstURL: URL) {
		do {
			try FileManager.default.secureCopyItem(at: srcURL, to: dstURL)
		} catch {
			return showErrorAndExitAsync(message: "无法复制文件：\(error.localizedDescription)")
		}
		
		print("已复制到路径：\(dstURL)")
//		DispatchQueue.main.async {
//			self.sharedData.alertOpenWhisperOKFn = open
//			self.sharedData.alertOpenWhisperCancelFn = close
//			self.sharedData.alertOpenWhisper = true
//		}
		
		DispatchQueue.main.async {
			open()
		}
		
		func open() {
			let _ = openURL(URL(string: "whisper:refresh")!)
			self.completeRequest()
		}
		func close() {
			self.completeRequest()
		}
	}
	
	// https://stackoverflow.com/a/44499222/3628322
	@objc func openURL(_ url: URL) -> Bool {
		var responder: UIResponder? = self
		while responder != nil {
			if let application = responder as? UIApplication {
				return application.perform(#selector(openURL(_:)), with: url) != nil
			}
			responder = responder?.next
		}
		return false
	}
}

extension FileManager {
	// 安全复制文件
	// https://stackoverflow.com/a/48444782/3628322
	public func secureCopyItem(at srcURL: URL, to dstURL: URL) throws {
		if self.fileExists(atPath: dstURL.path) {
			try self.removeItem(at: dstURL)
		}
		try self.copyItem(at: srcURL, to: dstURL)
	}
}

class SharedData: ObservableObject {
	@Published var alertMessage = ""
	@Published var alertShowing = false
	@Published var fn: (() -> Void)?
	
	@Published var alertOpenWhisper = false
	@Published var alertOpenWhisperCancelFn: (() -> Void)?
	@Published var alertOpenWhisperOKFn: (() -> Void)?
	
	@Published var alertOverwrite = false
	@Published var alertOverwriteMessage = ""
	@Published var alertOverWriteCancelFn: (() -> Void)?
	@Published var alertOverWriteOKFn: (() -> Void)?
}

struct SwiftUIView: View {
	@ObservedObject var sharedData: SharedData
//	private let fuck = "如果此窗口没有关闭，请下拉关闭。"
	private let fuck = ""
	
	var body: some View {
		VStack {
			Text(fuck)
				.alert(Text(sharedData.alertMessage), isPresented: $sharedData.alertShowing) {
					Button("OK") {
						sharedData.alertShowing = false
						if let fn = sharedData.fn {
							fn()
						}
					}
				}
			Text("")
				.alert(isPresented: $sharedData.alertOpenWhisper, content: {
					Alert(title: Text("立即打开 Whisper 阅读新消息？"), message: Text(""), primaryButton: .default(Text("是")) {
						sharedData.alertOpenWhisper = false
						if let fn = sharedData.alertOpenWhisperOKFn {
							fn()
						}
					}, secondaryButton: .cancel(Text("否")) {
						sharedData.alertOverwrite = false
						if let fn = sharedData.alertOpenWhisperCancelFn {
							fn()
						}
					})
				})
			Text("")
				.alert(isPresented: $sharedData.alertOverwrite, content: {
					Alert(title: Text("文件已经存在，是否覆盖？"), message: Text(sharedData.alertOverwriteMessage), primaryButton: .destructive(Text("覆盖")) {
						sharedData.alertOverwrite = false
						if let fn = sharedData.alertOverWriteOKFn {
							fn()
						}
					}, secondaryButton: .cancel {
						sharedData.alertOverwrite = false
						if let fn = sharedData.alertOverWriteCancelFn {
							fn()
						}
					})
				})
		}
	}
}

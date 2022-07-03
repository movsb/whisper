//
//  X.swift
//  Sharing
//
//  Created by Yang Tao on 2022/07/03.
//

import SwiftUI
import UIKit

enum ShareError: Error {
	case unspecified
}


@objc (ShareViewController)
class ShareViewController: UIViewController {
	let container = UIHostingController(rootView: SwiftUIView(sharedData: SharedData()))
	private var sharedData: SharedData = SharedData()
	
	private func cancelRequest() {
		self.extensionContext!.cancelRequest(withError: ShareError.unspecified)
	}
	private func completeRequest() {
		self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
	}
	
	private func setView(full: Bool) {
		// https://www.youtube.com/watch?v=z_9EOGDw5uk
		self.addChild(self.container)
		self.view.addSubview(self.container.view)
		self.container.didMove(toParent: self)
		
		if full {
			self.container.view.translatesAutoresizingMaskIntoConstraints = false
			self.container.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
			self.container.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
			self.container.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
			self.container.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
		}
	}
	
	private func showErrorAndExit(message: String) {
		setView(full: false)
		sharedData.fn = cancelRequest
		sharedData.alertMessage = message
		sharedData.alertShowing = true
	}
		
	private func showErrorAndExitSync(message: String) {
		return DispatchQueue.main.sync {
			return showErrorAndExit(message: message)
		}
	}
		
	override func viewDidLoad() {
		super.viewDidLoad()
		
		sharedData = container.rootView.sharedData
		
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
								return self.showErrorAndExitSync(message: "加载数据时出错：\(err.localizedDescription)")
							}
						})
						return
					default:
						return self.showErrorAndExitSync(message: "内部错误（未处理的断言类型）")
					}
				}
			}
		}
		
		// 不应该走到这里来
		cancelRequest()
	}
	
	private func loadItemCompletionHandler(data: NSSecureCoding?) {
		let kMaxFileSize = 10 << 20

		guard let srcURL = data as? URL else {
			return showErrorAndExitSync(message: "无法将数据转换成 URL 类型。")
		}
		//showErrorAndExit(message: "已转换成 URL 类型。")
		guard let fileSize = try? srcURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
			return showErrorAndExitSync(message: "无法取得文件大小")
		}
		if fileSize > kMaxFileSize {
			return showErrorAndExitSync(message: "文件大小超过限制：\(fileSize) > \(kMaxFileSize)")
		}
		// 判断文件格式是否正确
		guard let data = try? Data(contentsOf: srcURL) else {
			return showErrorAndExitSync(message: "无法读取文件内容")
		}
		// TODO: 导不出来，直接写了。
		if !data.starts(with: "Whipser/1.0\n".utf8) {
			return showErrorAndExitSync(message: "文件格式不正确。")
		}
		
		guard let shareDirectory = FileManager().containerURL(forSecurityApplicationGroupIdentifier: "group.com.twofei.whisper.share") else {
			return showErrorAndExitSync(message: "无法取得共享目录")
		}
		let dstURL = shareDirectory.appendingPathComponent("share.bin")
		do {
			try FileManager.default.secureCopyItem(at: srcURL, to: dstURL)
		} catch {
			return showErrorAndExitSync(message: "无法复制文件：\(error.localizedDescription)")
		}
		return showErrorAndExitSync(message: "文件已复制")
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
	@Published var text: String = ""
	@Published var alertMessage = ""
	@Published var alertShowing = false
	@Published var fn: (() -> Void)?
	
	init() {
		
	}
}

struct SwiftUIView: View {
	@ObservedObject var sharedData: SharedData
	
	var body: some View {
		TextField("",text: $sharedData.text)
			.alert(isPresented: $sharedData.alertShowing, content: {
				Alert(title: Text("错误"), message: Text(sharedData.alertMessage), dismissButton: .cancel {
					if let fn = sharedData.fn {
						fn()
					}
				})
			})
	}
}

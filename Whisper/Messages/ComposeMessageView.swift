//
//  ComposeMessageView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/28.
//

import SwiftUI

struct MiniContactView: View {
	var contact: Contact
	var body: some View {
		VStack {
			Image(systemName: contact.avatar)
				.resizable()
				.frame(width: 20, height: 20)
			Text(contact.name)
				.font(.footnote)
		}
	}
}

struct ComposeMessageView: View {
	@EnvironmentObject var globalStates: GlobalStates
	
	@Binding var message: Message
	
	// 新消息页面的关闭按钮行为。
	@State var onClose: ((_ keep: Bool)->Void)? = nil
	@State private var showingKeepMessage = false
	
	@State private var showingAlert = false
	@State private var alertMessage = ""
	
	func shareButton() {
		if message.receipients.count <= 0 {
			alertMessage = "请选择接收设备"
			showingAlert = true
			return
		}
		if message.receipients.count > Limitations.maxNumberOfReceipients {
			alertMessage = "不能选择超过 \(Limitations.maxNumberOfReceipients) 个设备。"
			showingAlert = true
			return
		}
		
		do {
			let recipients = globalStates.contacts.filter { contact in message.receipients.contains(contact.publicKey) }.map{PublicKey.fromString(s: $0.publicKey)!}
			let file = File(fileHeader: kFileHeader, recipients: recipients, title: message.title, content: message.content, images: imageURLs, videos: videoURLs)
			let encoded = try file.encode(sender: globalStates.privateKey!, fileKey: try! NewFileKey())
			let fileURL = try encoded.toTemporaryFileWithDateName()
			print("文件大小：", encoded.count, fileURL)
			
			let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
			
			let scenes = UIApplication.shared.connectedScenes
			let windowScene = scenes.first as? UIWindowScene
			var viewController = windowScene?.windows.first?.rootViewController
			while let presented = viewController?.presentedViewController {
				viewController = presented
			}
			
			// iPad 上面这个是独立的弹窗，它需要有一定定点位置作为窗口停靠的参考。
			// https://stackoverflow.com/a/67214882/3628322
			if let controller = activityController.popoverPresentationController {
				if controller.sourceView == nil {
					print("popoverPresentationController is nil")
					controller.permittedArrowDirections = .unknown
					controller.sourceView = viewController?.view
					controller.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2.1, y: UIScreen.main.bounds.height / 2.3, width: 200, height: 200)
				}
			}
			
			viewController?.present(activityController, animated: true)
			
			// 删除会无法分享。
			// try? FileManager.default.removeItem(at: fileURL)
		} catch {
			alertMessage = error.localizedDescription
			showingAlert = true
			return
		}
	}
	
	@State var messageContacts: [Contact]
	@State private var showSelectContacts = false
	
	func setNewContacts(contacts: [Contact]) {
		messageContacts.removeAll()
		message.receipients.removeAll()
		for c in contacts {
			messageContacts.append(c)
			message.receipients.append(c.publicKey)
		}
		print("设置新设备：", message.receipients)
	}
	
	@FocusState private var titleFocused: Bool
	@Environment(\.editMode) private var editMode
	
	var body: some View {
		VStack {
			if isEditing() {
				TextField("标题", text: $message.title)
					.padding(8)
					.background(Color.gray.opacity(0.1))
					.cornerRadius(8)
					.padding(.vertical)
					.focused($titleFocused)
			} else {
				HStack {
					Text(message.title)
						.bold()
						.textSelection(.enabled)
						.font(.title2)
					Spacer()
				}
				.onAppear() {
					// 刚进入或者退出编辑模式
					initSelect()
				}
			}
			if isEditing() {
				makeContactsView()
			}
			makeContentView()
		}
		.padding([.leading, .bottom, .trailing])
		.navigationBarTitle(isEditing() ? "编辑消息" : "阅读消息")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItemGroup(placement: ToolbarItemPlacement.navigationBarLeading) {
				if let onClose = onClose {
					Button("Close") {
						showingKeepMessage = true
						UIApplication.shared.endEditing()
					}
					.alert(isPresented: $showingKeepMessage) {
						Alert(
							title: Text("是否需要将消息保存到消息列表？"),
							primaryButton: .default(Text("保存")) {
								onClose(true)
							},
							secondaryButton: .cancel {
								onClose(false)
							}
						)
					}
				}
			}
		}
		.toolbar {
			HStack {
				Button(action: {
					UIApplication.shared.endEditing()
					shareButton()
				}, label: {
					Image(systemName: "square.and.arrow.up")
				})
				.opacity(isEditing() ? 1 : 0)
				.disabled(!imagesLoaded || !videosLoaded)
				EditButton()
			}
		}
		.alert(alertMessage, isPresented: $showingAlert) {
			Button("OK", role: .cancel) { }
		}
		.onAppear {
			message.read = true
			print("标识消息为已读状态", message.read)
			messageContacts = globalStates.contacts.filter{message.receipients.contains($0.publicKey)}
			if onClose != nil {
				titleFocused = true
			}			// 预览时无效
			if let _ =  globalStates.privateKey {
				DispatchQueue.global(qos: .default).async {
					do {
						imageURLs = try globalStates.loadMessageMedia(forImage: true, messageID: message.id)
						DispatchQueue.main.async {
							imagesLoaded = true
							initSelect()
						}
						print("图片已加载")
					} catch {
						DispatchQueue.main.async {
							alertMessage = error.localizedDescription
							showingAlert = true
						}
					}
				}
				DispatchQueue.global(qos: .default).async {
					do {
						videoURLs = try globalStates.loadMessageMedia(forImage: false, messageID: message.id)
						DispatchQueue.main.async {
							videosLoaded = true
							initSelect()
						}
						print("视频已加载")
					} catch {
						DispatchQueue.main.async {
							alertMessage = error.localizedDescription
							showingAlert = true
						}
					}
				}
			}
		}
		Spacer()
	}
	
	private func makeContactsView() -> some View {
		Group {
			HStack {
				Text("接收设备：").bold()
				Spacer()
			}
			HStack {
				ScrollView(.horizontal) {
					HStack {
						ForEach($messageContacts) { $contact in
							MiniContactView(contact: contact)
						}
					}
				}
				Button(action: {
					UIApplication.shared.endEditing()
					showSelectContacts = true
				}, label: {
					Image(systemName: "plus")
						.resizable()
						.frame(width: 20, height: 20)
				})
				.popover(isPresented: $showSelectContacts) {
					SelectContactsView(
						showPopover: $showSelectContacts,
						distinctContacts: globalStates.contacts,
						selectedContacts: globalStates.contacts.filter{message.receipients.contains($0.publicKey)},
						setNewContacts: setNewContacts(contacts:)
					)
					.frame(minWidth: isPad() ? 350 : 0, minHeight: isPad() ? 450 : 0)
				}
			}
			.padding(.bottom)
		}
		.onTapGesture {
			UIApplication.shared.endEditing()
		}
	}
	
	@State private var imagesLoaded = false
	@State private var videosLoaded = false
	@FocusState private var contentFocused: Bool
	@State private var selectedContentKind: ContentKind = .文本
	
	private func initSelect() {
		guard imagesLoaded && videosLoaded else {
			return
		}
		
		if showKind(kind: selectedContentKind) {
			print("当前选中项有数据，无需切换选项")
			return
		}
		
		if showKind(kind: .文本) {
			selectedContentKind = .文本
			print("初始化为文本")
			return
		}
		if showKind(kind: .图片) {
			selectedContentKind = .图片
			print("初始化为图片")
			return
		}
		if showKind(kind: .视频) {
			selectedContentKind = .视频
			print("初始化为视频")
			return
		}
		print("啥也不初始化显示")
	}
	enum ContentKind: String, CaseIterable, Identifiable {
		case 文本, 图片, 视频
		var id: Self { self }
	}
	private func showing(kind: ContentKind) -> Bool {
		return selectedContentKind == kind && showKind(kind: kind)
	}
	private func kindText(kind: ContentKind) -> String {
		switch kind {
		case .文本:
			return "文本"
		case .图片:
			return "图片(\(imageURLs.count))"
		case .视频:
			return "视频(\(videoURLs.count))"
		}
	}
	private func showKind(kind: ContentKind) -> Bool {
		switch kind {
		case .文本:
			return !message.content.isEmpty || isEditing()
		case .图片:
			return imageURLs.count > 0 || isEditing()
		case .视频:
			return videoURLs.count > 0 || isEditing()
		}
	}
	private func shouldShowPicker() -> Bool {
		var n = showKind(kind: .文本) ? 1 : 0
		n += showKind(kind: .图片) ? 1 : 0
		n += showKind(kind: .视频) ? 1 : 0
		return n > 1
	}
	
	private func isEditing() -> Bool {
		return editMode?.wrappedValue.isEditing ?? false
	}
	
	private func makeContentView() -> some View {
		Group {
			if shouldShowPicker() {
				Picker("ContentKind", selection: $selectedContentKind) {
					ForEach(ContentKind.allCases) { contentKind in
						if showKind(kind: contentKind) {
							Text(kindText(kind:contentKind))
						}
					}
				}
				.pickerStyle(.segmented)
			}
			if showing(kind: .文本) {
				if isEditing() {
					TextEditor(text: $message.content)
						.padding(6)
						.frame(maxHeight: 2000)
						.background(Color.gray.opacity(0.1))
						.cornerRadius(8)
						.padding(.vertical)
						.focused($contentFocused)
				} else {
					ScrollView() {
						HStack {
							Text(message.content)
							Spacer()
						}
					}
				}
			} else if showing(kind: .图片) {
				ImagePickerView(forPhotos: true, done: doneSelectMedia, onDelete: {url in onDeleteMedia(forPhoto: true, url: url) },  mediaURLs: $imageURLs)
					.frame(minHeight: 100, maxHeight: 2000)
					.onAppear {
						titleFocused = false
					}
					.padding(.top)
			} else if showing(kind: .视频) {
				ImagePickerView(forPhotos: false, done: doneSelectMedia, onDelete: {url in onDeleteMedia(forPhoto: false, url: url)},  mediaURLs: $videoURLs)
					.frame(minHeight: 100, maxHeight: 2000)
					.onAppear {
						titleFocused = false
					}
					.padding(.top)
			}
		}
	}
	
	@State private var imageURLs: [URL] = []
	@State private var videoURLs: [URL] = []
	private func doneSelectMedia(isPhoto: Bool, maybeUrl: URL?, maybeUiImage: UIImage?) {
		// 需要在选择照片的弹窗关闭之后才能弹出告警框，所以使用了 async 方式。
		func canAdd(photo: Bool, url: URL?) -> Bool {
			if let url = url {
				if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
					let sizeString = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .binary)
					let maxSizeString = ByteCountFormatter.string(fromByteCount: photo ? Int64(Limitations.maxImageSize) : Int64(Limitations.maxVideoSize), countStyle: .binary)
					if photo && fileSize > Limitations.maxImageSize {
						DispatchQueue.main.async {
							alertMessage = "选择的图片文件过大：\(sizeString) > \(maxSizeString)"
							showingAlert = true
						}
						return false
					}
					if !photo && fileSize > Limitations.maxVideoSize {
						DispatchQueue.main.async {
							alertMessage = "选择的视频文件过大：\(sizeString) > \(maxSizeString)"
							showingAlert = true
						}
						return false
					}
				}
			}
			if photo {
				if imageURLs.count >= Limitations.maxNumberOfImages {
					DispatchQueue.main.async {
						alertMessage = "您目前只能添加最多 \(Limitations.maxNumberOfImages) 张图片。"
						showingAlert = true
					}
					return false
				}
			}
			if !photo && videoURLs.count >= Limitations.maxNumberOfVideos {
				DispatchQueue.main.async {
					alertMessage = "您目前只能添加最多 \(Limitations.maxNumberOfVideos) 条视频。"
					showingAlert = true
				}
				return false
			}
			return true
		}
		do {
			if let url = maybeUrl {
				if isPhoto {
					if !canAdd(photo: true, url: url) {
						return
					}
					let url = try globalStates.saveMessageImage(messageID: message.id, srcURL: url)
					imageURLs.append(url)
				} else {
					if !canAdd(photo: false, url: url) {
						return
					}
					let url = try globalStates.saveMessageVideo(messageID: message.id, srcURL: url)
					videoURLs.append(url)
				}
			}
			if let uiImage = maybeUiImage {
				if !canAdd(photo: true, url: nil) {
					return
				}
				let url = try globalStates.saveMessageImage(messageID: message.id, uiImage: uiImage)
				imageURLs.append(url)
			}
		} catch {
			alertMessage = error.localizedDescription
			showingAlert = true
		}
	}
	private func onDeleteMedia(forPhoto: Bool, url: URL) {
		do {
			try FileManager.default.removeItem(at: url)
			if forPhoto {
				imageURLs.removeAll(where: {$0 == url})
			} else {
				videoURLs.removeAll(where: {$0 == url})
			}
		} catch {
			alertMessage = error.localizedDescription
			showingAlert = true
		}
	}
}

struct ComposeMessageView_Previews: PreviewProvider {
	@State static var message = Message.example()
	@State static var contacts = [Contact.example()]
	@StateObject static var globalStates = GlobalStates()
	@State static var editMode: EditMode = .active
	static var previews: some View {
		NavigationView {
			ComposeMessageView(
				message: $message,
				messageContacts: contacts.filter{
					message.receipients.contains($0.publicKey)
				}
			)
			.environment(\.editMode, $editMode)
		}
		.onAppear {
			UITextView.appearance().backgroundColor = .clear
		}
		.environmentObject(globalStates)
	}
}

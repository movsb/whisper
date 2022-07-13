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
	@State var onClose: (()->Void)? = nil
	
	@State private var showingAlert = false
	@State private var alertMessage = ""
	
	func shareButton() {
		if message.receipients.count <= 0 {
			alertMessage = "请选择接收设备"
			showingAlert = true
			return
		}
		if message.receipients.count > 5 {
			alertMessage = "不能选择超过 5 个设备"
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
			UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
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
			if editMode?.wrappedValue.isEditing ?? false {
				TextField("标题", text: $message.title)
					.padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
					.overlay {
						RoundedRectangle(cornerRadius: 4)
							.stroke(lineWidth: 1)
							.fill(.gray)
					}
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
			}
			if editMode?.wrappedValue.isEditing ?? false {
				makeContactsView()
			}
			makeContentView()
		}
		.padding([.leading, .bottom, .trailing])
		.navigationBarTitle(editMode?.wrappedValue.isEditing ?? false ? "编辑消息" : "阅读消息")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItemGroup(placement: ToolbarItemPlacement.navigationBarLeading) {
				if let onClose {
					Button("Close") {
						onClose()
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
				.opacity(editMode?.wrappedValue.isEditing ?? false ? 1 : 0)
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
				}
			}
			.padding(.bottom)
		}
		.onTapGesture {
			UIApplication.shared.endEditing()
		}
	}
	
	// 其实不用 state 的，但是由于没写 init，会报错
	@State private var imagesLoaded = false
	@State private var videosLoaded = false
	@FocusState private var contentFocused: Bool
	@State private var selectedContentKind: ContentKind = .文本
	
	enum ContentKind: String, CaseIterable, Identifiable {
		case 文本, 图片, 视频
		var id: Self { self }
	}
	private func showing(kind: ContentKind) -> Bool {
		return selectedContentKind == kind
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
	
	private func makeContentView() -> some View {
		Group {
			Picker("ContentKind", selection: $selectedContentKind) {
				ForEach(ContentKind.allCases) { contentKind in
					Text(kindText(kind:contentKind))
				}
			}
			.pickerStyle(.segmented)
			if showing(kind: .文本) {
				if editMode?.wrappedValue.isEditing ?? false {
					TextEditor(text: $message.content)
						.frame(maxHeight: 2000)
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
		.onAppear {
			// 预览时无效
			guard let _ =  globalStates.privateKey else {
				return
			}
			DispatchQueue.global(qos: .default).async {
				do {
					imageURLs = try globalStates.loadMessageMedia(forImage: true, messageID: message.id)
					imagesLoaded = true
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
					videosLoaded = true
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
	
	@State private var imageURLs: [URL] = []
	@State private var videoURLs: [URL] = []
	private func doneSelectMedia(isPhoto: Bool, maybeUrl: URL?, maybeUiImage: UIImage?) {
		do {
			if let url = maybeUrl {
				if isPhoto {
					let url = try globalStates.saveMessageImage(messageID: message.id, srcURL: url)
					imageURLs.append(url)
				} else {
					let url = try globalStates.saveMessageVideo(messageID: message.id, srcURL: url)
					videoURLs.append(url)
				}
			}
			if let uiImage = maybeUiImage {
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
	@State static var editMode: EditMode = .inactive
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
		.environmentObject(globalStates)
	}
}

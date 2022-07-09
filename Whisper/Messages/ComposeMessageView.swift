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
	
	@State private var showingAlert = false
	@State private var alertMessage = ""
	
	@State private var image = ""
	
	func shareButton() {
		if message.receipients.count <= 0 {
			alertMessage = "请选择接收人"
			showingAlert = true
			return
		}
		if message.receipients.count > 5 {
			alertMessage = "不能选择超过 5 个联系人"
			showingAlert = true
			return
		}
		
		// TODO
		if !imagesLoaded {
			
		}
		if !videosLoaded {
			
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
		print("设置新联系人：", message.receipients)
	}
	
	enum ContentKind: String, CaseIterable, Identifiable {
		case 文本, 图片, 视频
		var id: Self { self }
	}
	
	private func showing(kind: ContentKind) -> Bool {
		return selectedContentKind == kind
	}
	
	@State private var selectedContentKind: ContentKind = .文本
	
	@FocusState private var titleFocused: Bool
	
	var body: some View {
		VStack {
//			HStack {
//				Text("标题：").bold()
//				Spacer()
//			}
			TextField("标题", text: $message.title)
				.padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
				.overlay {
					RoundedRectangle(cornerRadius: 4)
						.stroke(lineWidth: 1)
						.fill(.gray)
				}
				.padding(.bottom)
				.focused($titleFocused)
			makeContactsView()
			makeContentView()
		}
		.padding()
		.navigationBarTitle("编辑消息")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			Button(action: {
				UIApplication.shared.endEditing()
				shareButton()
			}, label: {
				Image(systemName: "square.and.arrow.up")
			})
		}
		.alert(alertMessage, isPresented: $showingAlert) {
			Button("OK", role: .cancel) { }
		}
//		.onTapGesture {
//			UIApplication.shared.endEditing()
//		}
		.onAppear {
			message.read = true
			print("标识消息为已读状态", message.read)
			messageContacts = globalStates.contacts.filter{message.receipients.contains($0.publicKey)}
		}
		Spacer()
	}
	
	private func makeContactsView() -> some View {
		Group {
			HStack {
				Text("接收人：").bold()
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
	private func makeContentView() -> some View {
		Group {
			Picker("ContentKind", selection: $selectedContentKind) {
				ForEach(ContentKind.allCases) { contentKind in
					Text(contentKind.rawValue.capitalized)
				}
			}
			.pickerStyle(.segmented)
			if showing(kind: .文本) {
				TextEditor(text: $message.content)
//					.overlay {
//						RoundedRectangle(cornerRadius: 4)
//							.stroke(lineWidth: 1)
//							.fill(.gray)
//					}
//					.padding(.bottom)
					.frame(maxHeight: 2000)
					.focused($contentFocused)
					.onAppear {
						// contentFocused = true
					}
			} else if showing(kind: .图片) {
				ImagePickerView(forPhotos: true, done: doneSelectMedia, onDelete: {url in onDeleteMedia(forPhoto: true, url: url) },  mediaURLs: $imageURLs)
					.frame(minHeight: 100, maxHeight: 2000)
					.onAppear {
						titleFocused = false
						guard !imagesLoaded else {
							return
						}
						do {
							imageURLs = try globalStates.loadMessageMedia(forImage: true, messageID: message.id)
						} catch {
							alertMessage = error.localizedDescription
							showingAlert = true
						}
						imagesLoaded = true
					}
					.padding(.top)
			} else if showing(kind: .视频) {
				ImagePickerView(forPhotos: false, done: doneSelectMedia, onDelete: {url in onDeleteMedia(forPhoto: false, url: url)},  mediaURLs: $videoURLs)
					.frame(minHeight: 100, maxHeight: 2000)
					.onAppear {
						titleFocused = false
						guard !videosLoaded else {
							return
						}
						do {
							videoURLs = try globalStates.loadMessageMedia(forImage: false, messageID: message.id)
						} catch {
							alertMessage = error.localizedDescription
							showingAlert = true
						}
						videosLoaded = true
					}
					.padding(.top)
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
    static var previews: some View {
		ComposeMessageView(
			message: $message,
			messageContacts: contacts.filter{
				message.receipients.contains($0.publicKey)
			}
		)
		.environmentObject(globalStates)
    }
}

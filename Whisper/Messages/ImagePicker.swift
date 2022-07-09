//
//  ImagePicker.swift
//  Whisper
//
//  Created by Yang Tao on 2022/07/08.
//

import SwiftUI
import PhotosUI
import AVKit

struct ImageItemView: View {
	private var isPhoto: Bool
	private var imageURL: URL
	
	private var uiImage = UIImage()
	private var avPlayer: AVPlayer?
	
	@State private var playingVideo = false
	@State private var previewingImage = false
	
	// @GestureState var press = false
	private var onDelete: () -> Void
	
	init(isPhoto: Bool, imageURL: URL, onDelete: @escaping ()->Void) {
		self.isPhoto = isPhoto
		self.imageURL = imageURL
		self.onDelete = onDelete
		
		if isPhoto {
			guard let data = try? Data(contentsOf: imageURL) else {
				print("加载图片文件出错。")
				return
			}
			guard let uiImage = UIImage(data: data) else {
				print("无效图片")
				return
			}
			
			self.uiImage = uiImage
		} else {
			if let thumbnail = generateThumbnail(path: imageURL) {
				self.uiImage = thumbnail
			}
			self.avPlayer = AVPlayer(url: imageURL)
		}
	}
	
	var body: some View {
		ZStack {
			Image(uiImage: uiImage)
				.resizable(resizingMode: .stretch)
				.onTapGesture {
					if isPhoto {
						previewingImage = true
					}
				}
			if !isPhoto {
				Button(action: {
					playingVideo = true
				}, label: {
					Image(systemName: "play.circle")
						.resizable()
						.frame(width: 35, height: 35)
						.foregroundColor(.white)
				})
			}
		}
		.border(.white, width: 1)
		.fullScreenCover(isPresented: $playingVideo) {
			VideoPlayer(player: avPlayer)
				.onAppear {
					avPlayer?.play()
				}
				.onDisappear {
					avPlayer?.pause()
					avPlayer?.seek(to: .zero, completionHandler: { _ in })
				}
				.ignoresSafeArea()
		}
		.fullScreenCover(isPresented: $previewingImage) {
			ZoomableScrollView {
				Image(uiImage: uiImage)
					.resizable()
					.aspectRatio(contentMode: .fit)
			}
			.ignoresSafeArea()
			.onTapGesture {
				previewingImage = false
			}
		}
		.contextMenu(ContextMenu(menuItems: {
			Button("删除", action: {
				onDelete()
			})
		}))
//		.gesture(LongPressGesture(minimumDuration: 0.5)
//			.updating($press) { currentState, gestureState, transaction in gestureState = currentState }
//			.onEnded { _ in
//				print("长按结束")
//			}
//		)
	}
	
	// https://stackoverflow.com/a/40987452/3628322
	func generateThumbnail(path: URL) -> UIImage? {
		do {
			let asset = AVURLAsset(url: path, options: nil)
			let imgGenerator = AVAssetImageGenerator(asset: asset)
			imgGenerator.appliesPreferredTrackTransform = true
			let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
			let thumbnail = UIImage(cgImage: cgImage)
			return thumbnail
		} catch let error {
			print("*** Error generating thumbnail: \(error.localizedDescription)")
			return nil
		}
	}
}

struct ImagePickerView: View {
	@State private var showSheet = false
	@State private var what = ImagePicker.What.selectPhoto
	
	var forPhotos: Bool = true
	var done: (_ isPhoto: Bool, _ url: URL?, _ uiImage: UIImage?) -> Void
	var onDelete: (_ url: URL) -> Void
	@Binding var mediaURLs: [URL]
	
	private let nGrid: Int = 3
	private let nSpacing: CGFloat = 1
	
	private func gridWidth(_ proxy: GeometryProxy) -> CGFloat {
		return (proxy.size.width - CGFloat(nGrid+1)*nSpacing) / CGFloat(nGrid)
	}
	
	private func createColumns(_ proxy: GeometryProxy) -> [GridItem] {
		let w = gridWidth(proxy)

		var items = [GridItem]()
		for _ in 0..<nGrid {
			items.append(GridItem(.fixed(w), spacing: nSpacing))
		}

		return items
	}
	
	var body: some View {
		VStack {
			GeometryReader { proxy in
				ScrollView {
					LazyVGrid(columns: createColumns(proxy), spacing: nSpacing) {
						ForEach(mediaURLs, id: \.self) { imageURL in
							ImageItemView(isPhoto: forPhotos, imageURL: imageURL, onDelete: {
								onDelete(imageURL)
							})
							.frame(maxHeight: gridWidth(proxy))
						}
					}
					.padding(EdgeInsets(top: 0, leading: nSpacing, bottom: 0, trailing: nSpacing))
				}
			}
			HStack {
				Button(action: {
					self.what = forPhotos ? .selectPhoto : .selectVideo
					showSheet = true
				}, label: {
					Image(systemName: "photo")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: 30)
				})
				Spacer().frame(width: 30)
				Button(action: {
					self.what = forPhotos ? .takePhoto : .captureVideo
					showSheet = true
				}, label: {
					Image(systemName: forPhotos ? "camera" : "video")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: 30)
				})
			}
			.fullScreenCover(isPresented: $showSheet) {
				ImagePicker(what: $what, done: myDone)
					.ignoresSafeArea()
			}
		}
	}
	
	private func myDone(url: URL?, uiImage: UIImage?) {
		done(forPhotos, url, uiImage)
	}
}

struct ImagePickerView_Previews: PreviewProvider {
	@State static private var images: [URL] = []
	@State static private var image = ""
	static private func done(isPhoto: Bool, url: URL?, uiImage: UIImage?) {
		
	}
	static private func onDelete(url: URL) {
		
	}
	static var previews: some View {
		ImagePickerView(done: done, onDelete: onDelete(url:), mediaURLs: $images)
	}
}

struct ImagePicker: UIViewControllerRepresentable {
	@Environment(\.presentationMode) private var presentationMode
	
	enum What {
		case takePhoto
		case selectPhoto
		case captureVideo
		case selectVideo
	}
	
	@Binding var what: What
	var done: (_ url: URL?, _ uiImage: UIImage?) -> Void
	
	// UIImagePickerController 可支持同时选择一张照片/视频，后面换用 PHPicker。
	// @Binding var selected: String

	func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
		let i = UIImagePickerController()
		
		i.delegate = context.coordinator
		i.allowsEditing = false
		
		switch what {
		case .takePhoto:
			i.sourceType = .camera
			i.cameraCaptureMode = .photo
		case .selectPhoto:
			i.sourceType = .photoLibrary
			i.imageExportPreset = .current
		case .captureVideo:
			i.sourceType = .camera
			i.mediaTypes = ["public.movie"]
			i.cameraCaptureMode = .video
			i.videoQuality = .typeHigh
		case .selectVideo:
			i.sourceType = .photoLibrary
			i.mediaTypes = ["public.movie"]
			i.videoQuality = .typeHigh
			
			// https://stackoverflow.com/a/48643954/3628322
			if #available(iOS 11.0, *) {
				i.videoExportPreset = AVAssetExportPresetPassthrough
			}
		}
		
		return i
	}

	func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {

	}

	func makeCoordinator() -> Coordinator {
		Coordinator(self, done)
	}

	final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
		var parent: ImagePicker
		var done: (_ url: URL?, _ uiImage: UIImage?) -> Void

		init(_ parent: ImagePicker, _ done: @escaping (_ url: URL?, _ uiImage: UIImage?) -> Void) {
			self.parent = parent
			self.done = done
		}
		
		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			parent.presentationMode.wrappedValue.dismiss()
			done(nil, nil)
			print("取消选择图片")
		}

		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
			var url: URL?
			var uiImage: UIImage?
			
			// 为什么图片和视频要分开成两个不同的 URL？
			
			// 相册是链接，拍照是 UIImage。
			if let imageURL = info[.imageURL] as? URL {
				url = imageURL
				print("imageURL:", imageURL.description)
			} else if let image = info[.originalImage] as? UIImage {
				uiImage = image
				print("选择了 UIImage")
			}
			
			if let mediaURL = info[.mediaURL] as? URL {
				url = mediaURL
				print("mediaURL:", mediaURL.description)
			}
			
			parent.presentationMode.wrappedValue.dismiss()
			
			done(url, uiImage)
			print("完成选择图片")
		}
	}
}

// https://stackoverflow.com/a/64110231/3628322
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
	private var content: Content

	init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}

	func makeUIView(context: Context) -> UIScrollView {
		// set up the UIScrollView
		let scrollView = UIScrollView()
		scrollView.delegate = context.coordinator  // for viewForZooming(in:)
		scrollView.maximumZoomScale = 20
		scrollView.minimumZoomScale = 1
		scrollView.bouncesZoom = true

		scrollView.showsHorizontalScrollIndicator = false
		scrollView.showsVerticalScrollIndicator = false

		// create a UIHostingController to hold our SwiftUI content
		let hostedView = context.coordinator.hostingController.view!
		hostedView.translatesAutoresizingMaskIntoConstraints = true
		hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		hostedView.frame = scrollView.bounds
		scrollView.addSubview(hostedView)

		return scrollView
	}

  func makeCoordinator() -> Coordinator {
	return Coordinator(hostingController: UIHostingController(rootView: self.content))
  }

  func updateUIView(_ uiView: UIScrollView, context: Context) {
	// update the hosting controller's SwiftUI content
	context.coordinator.hostingController.rootView = self.content
	assert(context.coordinator.hostingController.view.superview == uiView)
  }

  // MARK: - Coordinator

  class Coordinator: NSObject, UIScrollViewDelegate {
	var hostingController: UIHostingController<Content>

	init(hostingController: UIHostingController<Content>) {
	  self.hostingController = hostingController
	}

	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
	  return hostingController.view
	}
  }
}

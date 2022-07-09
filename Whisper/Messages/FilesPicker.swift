//
//  FilesPicker.swift
//  Whisper
//
//  Created by Yang Tao on 2022/07/07.
//

import Foundation
import SwiftUI

/*
struct ProjectDocumentPicker: UIViewControllerRepresentable {
	@ObservedObject var reportsViewModel: ProjectReportViewModel
	@Binding var added: Bool
	func makeUIViewController(context: Context) -> some UIViewController {
		let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.text,.pdf])
		controller.allowsMultipleSelection = false
		controller.shouldShowFileExtensions = true
		controller.delegate = context.coordinator
		return controller
	}
	func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
		
	}
	func makeCoordinator() -> DocumentPickerCoordinator {
		DocumentPickerCoordinator(projectVM: reportsViewModel, added: $added)
	}
	
}
class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
	@ObservedObject var reportsViewModel: ProjectReportViewModel
	@Binding var added: Bool

	init(projectVM: ProjectReportViewModel, added: Binding<Bool> ) {
		reportsViewModel = projectVM
		self._added = added
	}
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		guard let url = urls.first else {
			return
		}
		reportsViewModel.addURLS(pickedURL: url)
		added = true
	}
	
}
*/

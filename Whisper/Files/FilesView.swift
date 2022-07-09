//
//  FilesView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/07/07.
//

import SwiftUI

class MyFile: Identifiable {
	var id = UUID()
	var isDir: Bool
	var name: String
	var path: URL
	var size: UInt
	
	init(isDir: Bool, name: String, path: URL, size: UInt) {
		self.isDir = isDir
		self.name = name
		self.path = path
		self.size = size
	}
	
	static func example() -> MyFile {
		return MyFile(isDir: true, name: "Dir1", path: URL(fileURLWithPath: "/tmp"), size: 0)
	}
	static func examples() -> [MyFile] {
		return [
			MyFile(isDir: true, name: "Dir1", path: URL(fileURLWithPath: "/tmp/dir1"), size: 0),
			MyFile(isDir: true, name: "Dir2", path: URL(fileURLWithPath: "/tmp/dir2"), size: 0),
			MyFile(isDir: false, name: "File1", path: URL(fileURLWithPath: "/tmp/file1"), size: 10),
		]
	}
}

struct FileView: View {
	@Binding var file: MyFile
	var body: some View {
		HStack {
			if file.isDir {
				Image(systemName: "folder")
					.resizable()
					.frame(width: 20, height: 20)
			} else {
				Image(systemName: "doc")
					.resizable()
					.frame(width: 20, height: 20)
			}
			Text(file.name)
		}
	}
}

struct FileView_Previews: PreviewProvider {
	@State static private var file = MyFile.example()
	static var previews: some View {
		FileView(file: $file)
	}
}

struct PreviewView: View {
	@Binding var file: MyFile
	var body: some View {
		Text("预览")
	}
}

struct PreviewView_Previews: PreviewProvider {
	@State static private var file = MyFile.example()
	static var previews: some View {
		PreviewView(file: $file)
	}
}

struct FilesView: View {
	@Binding var file: MyFile
	@State private var examples = MyFile.examples()
	var body: some View {
		NavigationView {
			List {
				ForEach($examples) { $file in
					if file.isDir {
						NavigationLink(destination: {
							FilesView(file: $file)
						}, label: {
							FileView(file: $file)
						})
					} else {
						FileView(file: $file)
					}
				}
			}
			
		}
    }
}

struct FilesView_Previews: PreviewProvider {
	@State static private var file = MyFile(isDir: true, name: "/", path: URL(fileURLWithPath: "/"), size: 0)
	static var previews: some View {
		FilesView(file: $file)
    }
}

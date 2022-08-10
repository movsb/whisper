//
//  SelectContactsView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/29.
//

import SwiftUI

struct ContactWithSelectionView: View {
	let contact: Contact
	let onChange: (_ value: Bool) -> Void
	
	@State private var selected = false
	
	var body: some View {
		HStack {
			Image(systemName: contact.avatar)
				.resizable()
				.frame(width: 20, height: 20)
			Text(contact.name)
			Spacer()
			Button(action: {
				selected.toggle()
				onChange(selected)
			}, label: {
				Image(systemName: selected ? "checkmark.circle.fill" : "circle")
					.resizable()
					.frame(width: 25, height: 25)
			})
		}
	}
}

struct ContactWithSelectionView_Previews: PreviewProvider {
	@State static private var contact = Contact(name: "Name", publicKey: "pk")
	static private func onChange(value: Bool) {
		print(value)
	}
	static var previews: some View {
		ContactWithSelectionView(contact: contact, onChange: onChange(value:))
	}
}

struct SelectContactsView: View {
	@Environment(\.dismiss) private var dismiss
	
	@State var contacts: [Contact]
	@State private var selectedContacts = [Contact]()
	
	var onSend: (_ contacts: [Contact]) -> Void
	
	func onChange(_ pubKey: String) -> (Bool) -> Void {
		{ (value: Bool) in
			if value {
				self.selectedContacts.append(self.contacts.first(where: {$0.publicKey == pubKey})!)
			} else {
				self.selectedContacts.removeAll(where: {$0.publicKey == pubKey})
			}
		}
	}
	
	var body: some View {
		VStack {
			HStack {
				Button("取消") {
					selectedContacts.removeAll()
					dismiss()
				}
				Spacer()
				Text("选择接收设备")
					.font(.title3)
					.bold()
				Spacer()
				Button("发送") {
					dismiss()
				}
				.disabled(selectedContacts.isEmpty)
			}
			.padding([.top, .leading, .trailing])
			VStack {
				if contacts.isEmpty {
					Spacer()
					Text("没有设备")
						.foregroundColor(.gray)
					Spacer()
				} else {
					List(contacts) { contact in
						ContactWithSelectionView(
							contact: contact,
							onChange: onChange(contact.publicKey)
						)
					}
				}
			}
		}
		.onDisappear {
			DispatchQueue.main.async {
				if !selectedContacts.isEmpty {
					onSend(selectedContacts)
				}
			}
		}
	}
}

struct SelectContactsView_Previews: PreviewProvider {
	@State static private var contacts = [
		Contact(name: "Name1", publicKey: "pk1"),
		Contact(name: "Name2", publicKey: "pk2"),
		Contact(name: "Name3", publicKey: "pk3"),
	]
	static private func onSend(_ contacts: [Contact]) {
		print(contacts)
	}
	static var previews: some View {
		SelectContactsView(contacts: contacts, onSend: onSend(_:))
	}
}

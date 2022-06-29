//
//  SelectContactsView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/29.
//

import SwiftUI

//class ContactWithSelection {
//	var contact: Contact
//	var selected: Bool
//
//	init(contact: Contact, selected: Bool) {
//		self.contact = contact
//		self.selected = selected
//	}
//}

struct ContactWithSelectionView: View {
	let contact: Contact
	let onChange: (_ value: Bool) -> Void
	
	@State var selected: Bool
	
	init(contact: Contact, onChange: @escaping (_: Bool) -> Void, selected: Bool) {
		self.contact = contact
		self.onChange = onChange
		self.selected = selected
		print("初始化 ContactWithSelectionView", contact, selected)
	}
	
	var body: some View {
		HStack {
			Button(action: {
				selected.toggle()
				onChange(selected)
			}, label: {
				Image(systemName: selected ? "checkmark.circle.fill" : "circle")
					.resizable()
					.frame(width: 25, height: 25)
			})
			Text(contact.name)
		}
	}
}

struct ContactWithSelectionView_Previews: PreviewProvider {
	@State static private var contact = Contact(id: "adf", name: "Name", publicKey: "pk")
	static private func onChange(value: Bool) {
		print(value)
	}
	static var previews: some View {
		ContactWithSelectionView(contact: contact, onChange: onChange(value:), selected: false)
	}
}

struct SelectContactsView: View {
	@Binding private var showPopover: Bool
	@State private var distinctContacts: [Contact]
	@State private var selectedContacts: [Contact]
	
	let setNewContacts: ([Contact]) -> Void
	
	init(showPopover: Binding<Bool>, distinctContacts: [Contact], selectedContacts: [Contact], setNewContacts:@escaping (_ contacts: [Contact]) -> Void) {
		self._showPopover = showPopover
		self.setNewContacts = setNewContacts
		self.distinctContacts = distinctContacts
		self.selectedContacts = selectedContacts
		
		print("初始化 SelectContactsView", distinctContacts, selectedContacts)
	}
	
	typealias _OnChange = (Bool) -> Void
	func onChange(_ pubKey: String) -> _OnChange {
		{ (value: Bool) in
			if value {
				self.selectedContacts.append(self.distinctContacts.first(where: {$0.publicKey == pubKey})!)
			} else {
				self.selectedContacts.removeAll(where: {$0.publicKey == pubKey})
			}
			print(self.selectedContacts)
		}
	}
	
	var body: some View {
		VStack {
			HStack {
				Button("取消") {
					showPopover = false
				}
				Spacer()
				Text("选择接收人")
					.bold()
				Spacer()
				Button("完成") {
					setNewContacts(selectedContacts)
					showPopover = false
				}
			}
			.padding([.top, .leading, .trailing])
			
			List(distinctContacts) { contact in
				ContactWithSelectionView(
					contact: contact,
					onChange: onChange(contact.publicKey),
					selected: includes(contacts: selectedContacts, contact: contact)
				)
			}
		}
		.onAppear() {
		}
	}
}

func includes(contacts: [Contact], contact: Contact) -> Bool {
	print("判断存在性", contacts, contact)
	return contacts.contains(where: {$0.publicKey == contact.publicKey})
}

struct SelectContactsView_Previews: PreviewProvider {
	@State static private var contacts = [
		Contact(id: "1", name: "Name1", publicKey: "pk1"),
		Contact(id: "2", name: "Name2", publicKey: "pk2"),
		Contact(id: "3", name: "Name3", publicKey: "pk3"),
	]
	static private var selctedContacts = [
		Contact(id: "2", name: "Name2", publicKey: "pk2"),
	]
	static private func setNewContacts(contacts: [Contact]) {
		print(contacts)
	}
	@State static private var showPopover = false
	
	static var previews: some View {
		SelectContactsView(showPopover: $showPopover, distinctContacts: contacts, selectedContacts: selctedContacts, setNewContacts: setNewContacts(contacts:))
	}
}

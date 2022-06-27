//
//  ContactList.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI
import CryptoKit

struct ContactsList: View {
	@State var showCreate: Bool = false
	@State var newContact: Contact = Contact(id: UUID().uuidString, name: "", avatar: "", publicKey: p1.publicKey)
	@State var contacts = gContacts
	
	var body: some View {
		NavigationView {
			List {
				ForEach($contacts) { $contact in
					NavigationLink {
						ContactDetailsView(contact: $contact)
					} label: {
						ContactRow(contact: contact)
					}
				}
			}
			.navigationBarTitle("联系人")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				Button(action: {
					showCreate = true
				}, label: {
					Image(systemName: "plus")
				})
				.popover(isPresented: $showCreate) {
					NewContactView(contact: $newContact, contacts: $contacts, showCreate: $showCreate)
				}
			}
		}
	}
}

struct ContactsList_Previews: PreviewProvider {
	static var previews: some View {
		ContactsList()
	}
}

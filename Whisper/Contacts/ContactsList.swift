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
	@State var newContact: Contact = Contact(name: "", publicKey: "")
	@EnvironmentObject var globalStates: GlobalStates
	
	var body: some View {
		NavigationView {
			Group {
				if globalStates.contacts.isEmpty {
					Text("没有设备")
						.foregroundColor(.gray)
				} else {
					List {
						ForEach($globalStates.contacts) { $contact in
							NavigationLink {
								ContactDetailsView(contact: $contact)
							} label: {
								ContactRow(contact: contact)
							}
						}
						.onDelete(perform: delete)
					}
				}
			}
			.navigationBarTitle("设备")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				Button(action: {
					showCreate = true
				}, label: {
					Image(systemName: "plus")
				})
				.popover(isPresented: $showCreate) {
					NewContactView(contact: $newContact, contacts: $globalStates.contacts, showCreate: $showCreate)
						.frame(minWidth: isPad() ? 350 : 0, minHeight: isPad() ? 350 : 0)
				}
			}
		}
	}
	
	private func delete(at offsets: IndexSet) {
		globalStates.contacts.remove(atOffsets: offsets)
	}
}

struct ContactsList_Previews: PreviewProvider {
	@State static private var globalStates = GlobalStates()
	static var previews: some View {
		ContactsList()
			.environmentObject(globalStates)
	}
}

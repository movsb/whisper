//
//  ContactList.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI

struct ContactsList: View {
	@State var contacts: [Contact]
	var body: some View {
		NavigationView {
			List(contacts) { contact in
				NavigationLink {
					ContactDetailsView(contact: contact)
				} label: {
					ContactRow(contact: contact)
				}
			}
			.navigationBarTitle("联系人")
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}

struct ContactsList_Previews: PreviewProvider {
	static var previews: some View {
		ContactsList(contacts: contacts)
	}
}

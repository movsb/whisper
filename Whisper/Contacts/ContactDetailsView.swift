//
//  ContactView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI

struct ContactDetailsView: View {
	@Binding var contact: Contact
	var body: some View {
		VStack {
			HStack {
				Spacer()
				Image(systemName: "person")
					.resizable()
					.frame(width: 100, height: 100)
					.padding()
				Spacer()
			}
			List {
				SwiftUI.Section {
					HStack {
						Text("名字")
						Spacer()
						Text(contact.name)
					}
					HStack {
						Text("公钥")
						Spacer()
						Text(contact.publicKey)
							.contextMenu(ContextMenu(menuItems: {
								Button("复制", action: {
									let s = contact.publicKey
									UIPasteboard.general.string = s
								})
							}))
							.lineLimit(1)
					}
				}
			}
			.listStyle(.grouped)
		}
		.navigationTitle("详情")
    }
}

struct ContactView_Previews: PreviewProvider {
	@State static private var contact = gContacts[0]
	static var previews: some View {
		ContactDetailsView(contact: $contact)
	}
}

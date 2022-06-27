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
			Image(systemName: contact.avatar)
				.resizable()
				.frame(width: 100, height: 100)
				.padding()
			VStack {
				Text("他/她的公钥")
					.font(.headline)
				Text(contact.publicKey.rawRepresentation.base64EncodedString())
					.padding()
					.contextMenu(ContextMenu(menuItems: {
						Button("复制", action: {
							let s = contact.publicKey.rawRepresentation.base64EncodedString()
							UIPasteboard.general.string = s
						})
					}))
					.lineLimit(1)
			}
			Spacer()
		}
    }
}

struct ContactView_Previews: PreviewProvider {
	@State static private var contact = gContacts[0]
	static var previews: some View {
		ContactDetailsView(contact: $contact)
	}
}

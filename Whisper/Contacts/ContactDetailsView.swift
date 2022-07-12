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
				Image(systemName: contact.avatar)
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
							.textSelection(.enabled)
							.lineLimit(1)
					}
				}
			}
		}
		.navigationTitle("详情")
    }
}

struct ContactView_Previews: PreviewProvider {
	@State static private var contact = Contact.example()
	static var previews: some View {
		ContactDetailsView(contact: $contact)
	}
}

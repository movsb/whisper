//
//  ContactView.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI

struct ContactDetailsView: View {
	@State var contact: Contact
    var body: some View {
		VStack {
			Image(systemName: contact.avatar)
				.resizable()
				.frame(width: 50, height: 50)
			Text(contact.name)
			Text("公钥")
			TextEditor(text: $contact.publicKey)
				.border(.secondary, width: 1)
			Spacer()
		}
		.padding()
    }
}

struct ContactView_Previews: PreviewProvider {
    static var previews: some View {
		ContactDetailsView(contact: contacts[0])
    }
}

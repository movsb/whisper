//
//  ContactRow.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI

struct ContactRow: View {
	@State var contact: Contact
    var body: some View {
		HStack {
			Label(contact.name, systemImage: contact.avatar)
			Spacer()
		}
		.padding()
    }
}

struct ContactRow_Previews: PreviewProvider {
    static var previews: some View {
        ContactRow(contact: gContacts[0])
    }
}

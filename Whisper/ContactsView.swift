//
//  Contacts.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI

struct Contact : Identifiable {
	var id: String
	
	var name: String
	var avatar: String
	var publicKey: String
}

let contacts: [Contact] = [
	Contact(id: "ipad", name: "iPad", avatar: "ipad", publicKey: "ipad pub key"),
	Contact(id: "iphone", name: "iPhone", avatar: "iphone", publicKey: "iphone pub key"),
]

struct ContactsView: View {
    var body: some View {
        ContactsList(contacts: contacts)
    }
}

struct ContactsView_Previews: PreviewProvider {
    static var previews: some View {
        ContactsView()
    }
}

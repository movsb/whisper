//
//  Contacts.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI
import CryptoKit

struct Contact : Identifiable {
	var id: String
	
	var name: String
	var avatar: String
	var publicKey: Curve25519.KeyAgreement.PublicKey
}

let p1 = Curve25519.KeyAgreement.PrivateKey()
let p2 = Curve25519.KeyAgreement.PrivateKey()

var gContacts: [Contact] = [
	Contact(id: p1.publicKey.rawRepresentation.base64EncodedString(), name: "iPad", avatar: "ipad", publicKey: p1.publicKey),
	Contact(id: p2.publicKey.rawRepresentation.base64EncodedString(), name: "iPhone", avatar: "iphone", publicKey: p2.publicKey),
]

struct ContactsView: View {
    var body: some View {
        ContactsList()
    }
}

struct ContactsView_Previews: PreviewProvider {
    static var previews: some View {
        ContactsView()
    }
}

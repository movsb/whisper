//
//  Contacts.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI
import CryptoKit

class Contact : Identifiable, Codable {
	var id = UUID()
	var name: String
	var publicKey: String
	var avatar: String
	
	init(id: UUID = UUID(), name: String, publicKey: String, avatar: String = "person") {
		self.id = id
		self.name = name
		self.publicKey = publicKey
		self.avatar = avatar
	}
	
	static func example() -> Contact {
		return Contact(name: "example", publicKey: "9qVe6CQfdzBYQ55DT_BMTkcMYB-dN-cB2wDh1mhjHgY")
	}
}

struct ContactsView: View {
	@EnvironmentObject var globalStates: GlobalStates
    var body: some View {
        ContactsList()
    }
}

struct ContactsView_Previews: PreviewProvider {
	@State static private var globalStates = GlobalStates()
    static var previews: some View {
        ContactsView()
			.environmentObject(globalStates)
    }
}

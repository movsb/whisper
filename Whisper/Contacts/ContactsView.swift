//
//  Contacts.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/26.
//

import SwiftUI
import CryptoKit

struct Contact : Identifiable, Codable, Hashable {
	var id = UUID()
	
	var name: String
	var publicKey: String
	var avatar: String = "person"
	
	init(name: String, publicKey: String) {
		self.init(name: name, publicKey: publicKey, avatar: "person")
	}
	
	init(name: String, publicKey: String, avatar: String) {
		self.id = UUID()
		self.name = name
		self.publicKey = publicKey
		self.avatar = avatar
	}
}

class ContactStore: ObservableObject {
	@Published var contacts: [Contact] = []
	
	private static func fileURL() throws -> URL {
		try FileManager.default.url(for: .documentDirectory,
			in: .userDomainMask,
			appropriateFor: nil,
			create: false)
		.appendingPathComponent("contacts.data")
	}
	
	static func load(completion: @escaping (Result<[Contact], Error>)->Void) {
		DispatchQueue.global(qos: .background).async {
			do {
				let fileURL = try fileURL()
				guard let file = try? FileHandle(forReadingFrom: fileURL) else {
					DispatchQueue.main.async {
						completion(.success([]))
					}
					return
				}
				let contacts = try JSONDecoder().decode([Contact].self, from: file.availableData)
				DispatchQueue.main.async {
					completion(.success(contacts))
				}
			} catch {
				DispatchQueue.main.async {
					completion(.failure(error))
				}
			}
		}
	}
	
	static func save(contacts: [Contact], completion: @escaping (Result<Int, Error>)->Void) {
		DispatchQueue.global(qos: .background).async {
			 do {
				 let data = try JSONEncoder().encode(contacts)
				 let outfile = try fileURL()
				 try data.write(to: outfile)
				 DispatchQueue.main.async {
					 completion(.success(contacts.count))
				 }
			 } catch {
				 DispatchQueue.main.async {
					 completion(.failure(error))
				 }
			 }
		 }
	}
}


let p1 = Curve25519.KeyAgreement.PrivateKey()
let p2 = Curve25519.KeyAgreement.PrivateKey()
let p1p = p1.publicKey.String()
let p2p = p2.publicKey.String()

var gContacts: [Contact] = [
	Contact(name: "iPad", publicKey: p1p),
	Contact(name: "iPhone", publicKey: p2p),
]

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

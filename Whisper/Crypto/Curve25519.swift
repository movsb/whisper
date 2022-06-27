//
//  Curve25519.swift
//  Whisper
//
//  Created by Yang Tao on 2022/06/27.
//

import Foundation
import CryptoKit

func generateKeyPairs() -> Curve25519.KeyAgreement.PrivateKey {
	return Curve25519.KeyAgreement.PrivateKey()
}

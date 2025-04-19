//
//  KeychainService.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//


import Foundation
import Security

class KeychainService {
	static let shared = KeychainService()
	// Passe den Service-Namen an deine App an (oft Bundle Identifier)
	private let serviceName = Bundle.main.bundleIdentifier ?? "com.siewertsolutions.InkassoApp"
	private let accountName = "apiBearerToken" // Eindeutiger Account-Name für den Token

	private init() {}

	@discardableResult // Macht den Rückgabewert optional nutzbar
	func saveToken(_ token: String) -> Bool {
		guard let data = token.data(using: .utf8) else {
			print("Keychain Error: Could not convert token to data.")
			return false
		}

		// Query zum Suchen/Aktualisieren/Hinzufügen
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: serviceName,
			kSecAttrAccount as String: accountName,
		]

		// Attribute zum Speichern
		let attributes: [String: Any] = [
			kSecValueData as String: data,
			// Setze Zugriffskontrolle - z.B. nur wenn Gerät entsperrt ist
			kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
		]

		// Zuerst versuchen zu aktualisieren
		var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

		if status == errSecItemNotFound {
			// Wenn nicht gefunden, neu hinzufügen
			var addQuery = query
			addQuery.merge(attributes) { (_, new) in new } // Füge Attribute hinzu
			status = SecItemAdd(addQuery as CFDictionary, nil)
		} else if status != errSecSuccess {
            // Anderen Fehler beim Update loggen
            print("Keychain Error: Update failed with status \(status)")
        }

        if status == errSecSuccess {
            print("Keychain: Token saved successfully.")
            return true
        } else {
            print("Keychain Error: Save/Add failed with status \(status)")
            return false
        }
	}

	func loadToken() -> String? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: serviceName,
			kSecAttrAccount as String: accountName,
			kSecReturnData as String: kCFBooleanTrue!, // Wir wollen die Daten zurück
			kSecMatchLimit as String: kSecMatchLimitOne, // Nur ein Ergebnis
		]

		var item: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &item)

		guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                print("Keychain: Token not found.")
            } else {
                print("Keychain Error: Load failed with status \(status)")
            }
			return nil // Nicht gefunden oder Fehler
		}

        guard let data = item as? Data else {
            print("Keychain Error: Could not cast item to Data.")
            return nil
        }

		let token = String(data: data, encoding: .utf8)
        // print("Keychain: Token loaded successfully.") // Ggf. für Debugging
        return token
	}

	@discardableResult // Macht den Rückgabewert optional nutzbar
	func deleteToken() -> Bool {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: serviceName,
			kSecAttrAccount as String: accountName,
		]

		let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
             print("Keychain: Token deleted or was not found.")
            return true
        } else {
            print("Keychain Error: Delete failed with status \(status)")
            return false
        }
	}
}

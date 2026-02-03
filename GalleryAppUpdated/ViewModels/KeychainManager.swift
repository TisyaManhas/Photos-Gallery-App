import Foundation
import Security

final class KeychainManager {

static let shared = KeychainManager()
private init() {}

func savePassword(_ password: String, for username: String) -> Bool {
    guard let passwordData = password.data(using: .utf8) else { return false }
    
    deletePassword(for: username)   // Delete existing password first; no duplicates
    
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: username, // "What's the identifier?"
        kSecValueData as String: passwordData, // "What's the actual data to store?"
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked //"When can this be accessed?"
    ]
    
    let status = SecItemAdd(query as CFDictionary, nil)  // function to add item to Keychain ; converts swift dictionary to c-style dictionary ; CFDictionary= Core Foundation Dictionary
    //second parameter=nil ; no need to return it
    return status == errSecSuccess
    // if errSecSuccess=0; Successful
}

// Retrieve Password
func getPassword(for username: String) -> String? {
    // String? = might return nil if not found
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: username,
        kSecReturnData as String: true, // "Should we return the actual data?"
        kSecMatchLimit as String: kSecMatchLimitOne // Only return first match
    ]
    
    var result: AnyObject? // AnyObject? = optional, can be any object type
    let status = SecItemCopyMatching(query as CFDictionary, &result) // "Copy" = retrieve a copy of the item
    
    guard status == errSecSuccess,
          let passwordData = result as? Data, // Convert result to Data type
          let password = String(data: passwordData, encoding: .utf8) else { // Convert Data (bytes) back to String
        return nil
    }
    
    return password
}

// Delete Password
func deletePassword(for username: String) -> Bool {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: username
    ]
    
    let status = SecItemDelete(query as CFDictionary) // function to delete from KeyChain
    return status == errSecSuccess || status == errSecItemNotFound
}

// Update Password
func updatePassword(_ newPassword: String, for username: String) -> Bool { //updatePassword already handles both cases (with fallback)
    guard let passwordData = newPassword.data(using: .utf8) else { return false }
    
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: username
    ]
    
    let attributes: [String: Any] = [
        kSecValueData as String: passwordData
    ]
    
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    
    // If item doesn't exist, create it
    if status == errSecItemNotFound {
        return savePassword(newPassword, for: username)
    }
    
    return status == errSecSuccess
}

// Check if Password Exists
func passwordExists(for username: String) -> Bool {
    return getPassword(for: username) != nil
}

}

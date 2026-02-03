import Foundation

final class AuthStorage {

private static let key = "stored_usernames"  // Only store usernames in UserDefaults

static func saveAccount(_ account: UserAccount) {
   // Save password to Keychain (secure)
   _ = KeychainManager.shared.savePassword(account.password, for: account.username)
    // _ = means no care about the return value.
    
   // Save only username to UserDefaults
   var usernames = fetchUsernames()
   if !usernames.contains(account.username) {
       usernames.append(account.username)
       UserDefaults.standard.set(usernames, forKey: key)
   }
}

static func fetchUsernames() -> [String] {
   return UserDefaults.standard.stringArray(forKey: key) ?? []
}

static func accountExists(username: String) -> UserAccount? {
   let usernames = fetchUsernames()
   
   guard usernames.contains(username),
         let password = KeychainManager.shared.getPassword(for: username) else {
       return nil
   }
   
   return UserAccount(username: username, password: password)
}

static func deleteAccount(username: String) {
   // Delete password from Keychain
   _ = KeychainManager.shared.deletePassword(for: username)
   
   // Remove username from UserDefaults
   var usernames = fetchUsernames()
   usernames.removeAll { $0 == username }
   UserDefaults.standard.set(usernames, forKey: key)
}

}

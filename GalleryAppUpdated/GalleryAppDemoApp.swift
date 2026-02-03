import SwiftUI
import SwiftData

@main
struct GalleryAppDemoApp: App {
    
    // Swift Data container
    let modelContainer: ModelContainer
    
    init() {
        // Settinh up Swift Data first
        do {
            modelContainer = try ModelContainer( //app's database manager
                for: User.self,
                FavoriteImage.self,
                SearchHistoryItem.self
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        
        // then setup API Key in Keychain
        setupAPIKey()
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView()
        }
        .modelContainer(modelContainer)
    }
    
    private func setupAPIKey() {
        if KeychainManager.shared.getPassword(for: "unsplash_api_key") == nil {
            _ = KeychainManager.shared.savePassword(
                "bHm2JB230A1Ay5OvSfzrdarQCU4ipSg9CUM4msZO4P8",
                for: "unsplash_api_key"
            )
            print("API Key saved to Keychain")
        }
    }
}


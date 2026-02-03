/*
 This is a ViewModel that:

Manages image search functionality
Handles pagination (infinite scroll)
Caches search results
Tracks search history per user
Communicates with Unsplash API
*/

import Foundation
import SwiftUI
import Combine

@MainActor // // UI updates MUST happen on main thread
class ImageSearchViewModel: ObservableObject {

// SINGLETON INSTANCE (for navigation persistence)
    // When navigating between views:
    // LoginView → SearchView → DetailView → Back to SearchView
static let shared = ImageSearchViewModel()

// UI State
@Published var images: [UnsplashImage] = [] // Automatically notifies SwiftUI when value changes
@Published var isLoadingMore = false // UI flag (shows loading indicator to user)

// Pagination
private var currentPage = 1
private let perPage = 20
private var isLoading = false // Internal flag (prevents duplicate requests)
private var currentQuery = ""

// Cache results per query
private var cachedResults: [String: [UnsplashImage]] = [:] // A dictionary that stores previous search results

// Per-user search history
// Key: username, Value: last 4 searches
    
//@Published -> So SwiftUI can display history in UI
@Published private var histories: [String: [String]] = [:] // Each user has their own history
    
// Reset results (for new login)
//  Clears search state when user logs out/in
func resetResults() {
    images.removeAll()
    currentPage = 1
    isLoadingMore = false
    currentQuery = ""
    // Do NOT clear histories → history persists
}

// Search History (per user)
func getHistory(for username: String) -> [String] {
    histories[username] ?? [] // never nil, always an array
}

private func addToHistory(_ query: String, for username: String) {
    var userHistory = histories[username] ?? []
    
    // to ensure no duplicate
    userHistory.removeAll { $0 == query }
    
    // Insert new query at front
    userHistory.insert(query, at: 0)
    
    // Keep last 4 queries
    if userHistory.count > 4 {
        userHistory = Array(userHistory.prefix(4))
    }
    
    histories[username] = userHistory
}

// Search Images
func searchImages(query: String, for username: String) async {
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines) // Clean Input
    guard !trimmedQuery.isEmpty else { return } // Validate Input
    
    currentQuery = trimmedQuery
    
    // Add to user-specific history
    addToHistory(trimmedQuery, for: username)
    
    // Restore from cache if exists
    if let cached = cachedResults[trimmedQuery] {
        images = cached
        currentPage = (cached.count / perPage) + 1
        return
    }
    
    // New search → clear images and start from page 1
    images.removeAll()
    currentPage = 1
    
    await loadMoreImages()
}

// Infinite Scroll
//  Retrieve API key from Keychain
func loadMoreImages() async {
    guard !isLoading, !currentQuery.isEmpty else { return }
    
    isLoading = true // prevent new requests
    isLoadingMore = true // show spinner in UI
    
    // Retrieve API key from Keychain
    guard let apiKey = KeychainManager.shared.getPassword(for: "unsplash_api_key") else {
        print("API Key not found in Keychain")
        isLoading = false
        isLoadingMore = false
        return
    }
    
    let urlString =
    "https://api.unsplash.com/search/photos" +
    "?query=\(currentQuery)" +
    "&page=\(currentPage)" +
    "&per_page=\(perPage)" +
    "&client_id=\(apiKey)"
    
    guard let url = URL(string: urlString) else {
        isLoading = false
        isLoadingMore = false
        return
    }
    
    /*
     Sends HTTP GET request to Unsplash
     Waits for response (await)
     Returns tuple: (Data, URLResponse)
     We only need data, ignore response with _
     */
    do {
        let (data, _) = try await URLSession.shared.data(from: url) // fetching data takes time, hence await
        let response = try JSONDecoder().decode(UnsplashSearchResponse.self, from: data)
        
        images.append(contentsOf: response.results)
        // .results helps to give answer in same data type(i.e arrays)

        
        // Update cache
        cachedResults[currentQuery] = images
        currentPage += 1
        
    } catch {
        print("Error fetching images:", error)
    }
    
    isLoading = false
    isLoadingMore = false
}

}

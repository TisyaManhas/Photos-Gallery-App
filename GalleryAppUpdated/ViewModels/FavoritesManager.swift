import Foundation
import Combine

final class FavoritesManager: ObservableObject {

static let shared = FavoritesManager()

private init() {
    loadFavorites()
}

// Key: username, Value: Array of image IDs (ordered by when added)
@Published private(set) var userFavorites: [String: [String]] = [:]

private var imageCache: [UnsplashImage] = [] // Full image data cache

private let favoritesKey = "user_favorites" // image id
private let imageCacheKey = "favorites_image_cache"

// Check if image is favorite
func isFavorite(_ imageId: String, for username: String) -> Bool {
    return userFavorites[username]?.contains(imageId) ?? false
}

// Toggle favorite
func toggleFavorite(_ image: UnsplashImage, for username: String) {
    print("toggleFavorite called for image: \(image.id), user: \(username)")
    
    // Initialize user's favorites array if it doesn't exist
    if userFavorites[username] == nil {
        userFavorites[username] = []
        print("Created new favorites array for user: \(username)")
    }
    
    // Check if image is already favorited
    if let favorites = userFavorites[username], favorites.contains(image.id) {
        // Remove from favorites
        print("Removing from favorites")
        userFavorites[username]?.removeAll { $0 == image.id }
        imageCache.removeAll { $0.id == image.id }
    } else {
        // Add to favorites at the beginning (most recent first)
        print("Adding to favorites")
        userFavorites[username]?.insert(image.id, at: 0)
        
        // Only add if not already in cache
        if !imageCache.contains(where: { $0.id == image.id }) {
            imageCache.insert(image, at: 0)
        }
    }
    
    print("Current favorites for \(username): \(userFavorites[username]?.count ?? 0) items")
    saveFavorites()
    print("Favorites saved!")
    
    // Force UI update
    objectWillChange.send()
}

// MARK: - Get favorite images for user (most recent first)
func getFavorites(for username: String) -> [UnsplashImage] {
    guard let favoriteIds = userFavorites[username] else { return [] }
    
    // Map IDs to images while maintaining order (most recent first)
    return favoriteIds.compactMap { id in
        imageCache.first { $0.id == id }
    }
}

// MARK: - Persistence
private func saveFavorites() {
    // Save favorite IDs (already in array format)
    if let data = try? JSONEncoder().encode(userFavorites) {
        UserDefaults.standard.set(data, forKey: favoritesKey)
    }
    
    // Save image cache as array
    if let imageData = try? JSONEncoder().encode(imageCache) {
        UserDefaults.standard.set(imageData, forKey: imageCacheKey)
    }
}

private func loadFavorites() {
    // Load favorite IDs
    if let data = UserDefaults.standard.data(forKey: favoritesKey),
       let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
        userFavorites = decoded
    }
    
    // Load image cache as array
    if let imageData = UserDefaults.standard.data(forKey: imageCacheKey),
       let decoded = try? JSONDecoder().decode([UnsplashImage].self, from: imageData) {
        imageCache = decoded
    }
}

}

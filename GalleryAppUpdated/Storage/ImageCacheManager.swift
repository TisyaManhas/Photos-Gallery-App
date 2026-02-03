import UIKit // For UIImage (image handling)
import CryptoKit // For SHA256 (hashing URLs)
//SHA256 converts URL to valid filenames

// A class that manages two types of image storage: temporary cache and permanent favorites.
final class ImageCacheManager {

static let shared = ImageCacheManager()
private init() {}

private let maxCachedImages = 20
private let cacheFolderName = "ImageCache"
private let favoritesFolderName = "FavoritesCache"

// Temporary cache directory (can be cleared by iOS)
private var cacheDirectory: URL {
    let caches = FileManager.default.urls(
        for: .cachesDirectory, // System Cache folder, the cache directory
        in: .userDomainMask // User's domain (not system-wide), in app's sandbox
    ).first!
    /* Takes first URL from array
     Force unwrap (!) because we know it exists
     */
    
    let dir = caches.appendingPathComponent(cacheFolderName)
    
    // This block ensures the image cache folder exists before saving files into it.
    if !FileManager.default.fileExists(atPath: dir.path) {
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )
    }
    return dir
}

// Permanent favorites directory (won't be cleared by iOS)
private var favoritesDirectory: URL {
    let documents = FileManager.default.urls(
        for: .documentDirectory, // never deleted
        in: .userDomainMask
    ).first!
    
    let dir = documents.appendingPathComponent(favoritesFolderName)
    
    if !FileManager.default.fileExists(atPath: dir.path) {
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )
    }
    return dir
}

// File Path for temporary cache
private func fileURL(for urlString: String) -> URL {
    let fileName = sha256(urlString) // hashed
    return cacheDirectory.appendingPathComponent(fileName)
}

// File Path for favorites
private func favoriteFileURL(for imageId: String) -> URL {
    return favoritesDirectory.appendingPathComponent("\(imageId).jpg") // no hashing because imageId is unique, short and clean
    // jpeg is smaller, better for photos
}

private func sha256(_ string: String) -> String { // This converts any string → safe filename.
    let data = Data(string.utf8)
    // computers hash bytes, .utf8-> swift string to bytes
    // bytes-> Data; Cryptographic functions work on bytes, not strings.
    let hash = SHA256.hash(data: data)
    // .utf8 returns a String.UTF8View
    // SHA256 expects Data
    // here, String.UTF8View → Data
    return hash.map { String(format: "%02x", $0) }.joined() // This line converts each byte of the SHA256 digest into a two-character hexadecimal string and joins them into a single filename-safe string.
    //width= 2; hex-safe
    //joined-> one continuos string
}

// MARK: - Temporary Cache

func loadImage(from urlString: String) -> UIImage? {
    let fileURL = fileURL(for: urlString)
    return UIImage(contentsOfFile: fileURL.path)
}

func saveImage(_ image: UIImage, for urlString: String) {
    enforceLimit()
    // Checks how many images are already cached
    // Deletes the oldest image if the limit is reached
    
    let fileURL = fileURL(for: urlString)
    guard let data = image.pngData() else { return } // converts UIImage to Raw Data
    
    try? data.write(to: fileURL)
    //Open (or create) a file at fileURL
    //Write all bytes from data into that file
    //Close the file
}

private func enforceLimit() {
// Keeps only the most recently used images in cache and deletes the oldest one when the limit is exceeded
// Implements a disk-based LRU cache by deleting the least recently modified file when the cache exceeds its size limit.
    let files = (try? FileManager.default.contentsOfDirectory(
    at: cacheDirectory,
    includingPropertiesForKeys: [.contentModificationDateKey], // tells the last modified time of each file
    options: .skipsHiddenFiles // Ignores .DS_Store and hidden system junk
    )) ?? []
    // If anything fails → don’t crash
    // Just treat it as an empty cache
    
    guard files.count >= maxCachedImages else { return }
    
    let sorted = files.sorted {
        let d1 = try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        let d2 = try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        return (d1 ?? .distantPast) < (d2 ?? .distantPast) // if the date is old, it gets deleted first
        // no date, then consider to be very old (defence mechanism)
    }
    
    if let oldest = sorted.first {
        try? FileManager.default.removeItem(at: oldest) // Only one file is removed per call.
        // in sorting the first one is oldest and last is latest
    }
}

// Favorites Storage

// Save favorite image permanently
func saveFavoriteImage(_ image: UIImage, for imageId: String) -> Bool {
    let fileURL = favoriteFileURL(for: imageId)
    
    // Use JPEG with 85% quality for better compression
    guard let data = image.jpegData(compressionQuality: 0.85) else {
        print(" Failed to convert image to JPEG data")
        return false
    }
    
    do {
        try data.write(to: fileURL) // Creates file if missing, else overwrites
        let sizeKB = data.count / 1024
        print(" Saved favorite image: \(imageId) (\(sizeKB) KB)")
        return true
    } catch {
        print("Failed to save favorite image: \(error)")
        return false
    }
}

// Load favorite image from permanent storage
func loadFavoriteImage(for imageId: String) -> UIImage? {
    let fileURL = favoriteFileURL(for: imageId)
    
    if let image = UIImage(contentsOfFile: fileURL.path) { // reads files, Decodes JPEG → UIImage
        print("Loaded favorite image from disk: \(imageId)")
        return image
    } else {
        print("Favorite image not found on disk: \(imageId)")
        return nil
    }
}

// Delete favorite image from permanent storage
func deleteFavoriteImage(for imageId: String) -> Bool {
    let fileURL = favoriteFileURL(for: imageId)
    
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
        print("Favorite image doesn't exist: \(imageId)")
        return false
    }
    
    do {
        try FileManager.default.removeItem(at: fileURL)
        print("Deleted favorite image: \(imageId)")
        return true
    } catch {
        print("Failed to delete favorite image: \(error)")
        return false
    }
}

// Check if favorite image exists
func favoriteImageExists(for imageId: String) -> Bool {
    let fileURL = favoriteFileURL(for: imageId)
    return FileManager.default.fileExists(atPath: fileURL.path)
}

// Get total size of favorites cache
func getFavoritesCacheSize() -> Int64 {
    // Calculate total disk space used by favorites.
    let files = (try? FileManager.default.contentsOfDirectory( // contentsOfDirectory → returns [URL]; Each URL = one favorite image file
        at: favoritesDirectory,
        includingPropertiesForKeys: [.fileSizeKey], // each file's size
        options: .skipsHiddenFiles
    )) ?? []
    
    /*
     total = 0
     for file in files {
         total += fileSize
     }
     */
    let totalSize: Int64 = files.reduce(0) { total, fileURL in
        let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        // resourceValues → file metadata
        // .fileSizeKey → file size in bytes
        return total + Int64(fileSize) //Int-> Int64
    }
    
    return totalSize
}

}

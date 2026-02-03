import Foundation

struct UnsplashSearchResponse: Codable {
let results: [UnsplashImage]
}

struct UnsplashImage: Identifiable, Codable, Hashable, Equatable {
let id: String
let description: String?
let altDescription: String?
let createdAt: String
let urls: UnsplashImageURLs
let user: UnsplashUser

enum CodingKeys: String, CodingKey {
    case id
    case description
    case altDescription = "alt_description"
    case createdAt = "created_at"
    case urls
    case user
}

// Hashable conformance
func hash(into hasher: inout Hasher) {
    hasher.combine(id)
}

// Equatable conformance
static func == (lhs: UnsplashImage, rhs: UnsplashImage) -> Bool {
    lhs.id == rhs.id
}
}

struct UnsplashImageURLs: Codable, Hashable {
let small: String
let regular: String
}

struct UnsplashUser: Codable, Hashable {
let name: String
}

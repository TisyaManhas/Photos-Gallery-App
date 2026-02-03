import Foundation
import SwiftData

@Model
final class User {
@Attribute(.unique) var username: String
var email: String
var createdAt: Date

// Relationships
@Relationship(deleteRule: .cascade) var favorites: [FavoriteImage] = []
@Relationship(deleteRule: .cascade) var searchHistory: [SearchHistoryItem] = []

init(username: String, email: String) {
    self.username = username
    self.email = email
    self.createdAt = Date()
}

}

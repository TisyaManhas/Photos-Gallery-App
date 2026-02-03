import Foundation
import SwiftData

@Model
final class SearchHistoryItem {
var query: String
var searchedAt: Date
var resultCount: Int

// Relationship back to user
var user: User?

init(query: String, resultCount: Int = 0, user: User? = nil) {
    self.query = query
    self.searchedAt = Date()
    self.resultCount = resultCount
    self.user = user
}

}


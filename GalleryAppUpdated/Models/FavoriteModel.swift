import Foundation
import SwiftData

@Model
final class FavoriteImage {
var imageId: String
var imageURL: String
var thumbnailURL: String
var photographerName: String
var imageDescription: String?
var addedAt: Date

// Relationship back to user
var user: User?

init(imageId: String, imageURL: String, thumbnailURL: String, photographerName: String, imageDescription: String? = nil, user: User? = nil) {
    self.imageId = imageId
    self.imageURL = imageURL
    self.thumbnailURL = thumbnailURL
    self.photographerName = photographerName
    self.imageDescription = imageDescription
    self.addedAt = Date()
    self.user = user
}

}


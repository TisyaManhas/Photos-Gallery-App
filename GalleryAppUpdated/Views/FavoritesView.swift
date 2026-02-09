//
//  FavoritesView.swift
//  GalleryAppDemo
//
//  Created by Tisya Manhas on 21/01/26.
//

//import SwiftUI
//import SwiftData
//
//struct FavoritesView: View {
//    let user: User
//    
//    @Environment(\.modelContext) private var modelContext
//    
//    var body: some View {
//        NavigationStack{
//            // Main VStack that holds the title and the scrollable content
//            VStack(spacing: 0) {
//                // --- Custom "Favorites" Title (like ProfileView) ---
//                HStack {
//                    Text("Favorites")
//                        .font(.system(size: 34, weight: .bold))
//                        .foregroundColor(.primary)
//                    Spacer()
//                }
//                .padding(.horizontal, 16) // Consistent horizontal padding
//                .padding(.top, 8) // Minimal top padding to respect safe area
//                .padding(.bottom, 8) // Padding below the title
//                
//                ScrollView {
//                    if user.favorites.isEmpty {
//                        VStack {
//                            Spacer() // Pushes content down from the top of the ScrollView
//                        
//                            
//                            Image(systemName: "heart.fill")
//                                .font(.system(size: 70))
//                                .foregroundColor(.pink)
//                                .padding(.bottom, 16)
//                            Text("No favorites yet")
//                                .font(.title2)
//                                .fontWeight(.semibold)
//                                .padding(.bottom, 8)
//                            Text("Tap the heart icon on images\nto save them here")
//                                .font(.body)
//                                .foregroundColor(.secondary)
//                                .multilineTextAlignment(.center)
//                                .padding(.horizontal, 40)
//                            
//                            Spacer() // Pushes content up from the bottom of the ScrollView
//                        }
//                        .padding(.top, 50)
//                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Make empty state VStack fill ScrollView
//                    } else {
//                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 4)], spacing: 4) {
//                            ForEach(user.favorites.sorted(by: { $0.addedAt > $1.addedAt })) { favorite in
//                                FavoriteImageCard(favorite: favorite, user: user)
//                            }
//                        }
//                        .padding(.horizontal, 4)
//                        .padding(.top, 4)
//                        .padding(.bottom, 100)
//                    }
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure ScrollView fills remaining space
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity) // *** THIS IS THE CRUCIAL CHANGE ***
//            .background(Color(.systemBackground).ignoresSafeArea())
//            .navigationBarHidden(true)
//            .navigationBarTitleDisplayMode(.inline)
//        }
//        .navigationBarHidden(true)
//    }
//}

import SwiftUI
import SwiftData

struct FavoritesView: View {
    let user: User
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // --- Custom "Favorites" Title (like ProfileView) ---
                HStack {
                    VStack(alignment: .leading, spacing: 4) { // VStack to stack title and count
                        Text("Favorites")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                        
                        // --- NEW: Favorites Count Subtitle ---
                        Text(user.favorites.count == 1 ? "1 Photo" : "\(user.favorites.count) Photos")
                            .font(.subheadline) // Smaller font for subtitle
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary) // Secondary color for less emphasis
                    }
                    Spacer()
                }
                .padding(.horizontal, 16) // Consistent horizontal padding
                .padding(.top, 8) // Minimal top padding to respect safe area
                .padding(.bottom, 8) // Padding below the title/subtitle block
                
                ScrollView {
                    // Use GeometryReader to ensure content fills available height
                    GeometryReader { geometry in
                        if user.favorites.isEmpty {
                            VStack {
                                Spacer() // Pushes content down from top
                                
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(.pink)
                                    .padding(.bottom, 16)
                                Text("No favorites yet")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.bottom, 8)
                                Text("Tap the heart icon on images\nto save them here")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                Spacer() // Pushes content up from bottom
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height) // Make VStack fill GeometryReader's frame
                        } else {
                            // Non-empty state: LazyVGrid
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 4)], spacing: 12) {
                                ForEach(user.favorites.sorted(by: { $0.addedAt > $1.addedAt })) { favorite in
                                    FavoriteImageCard(favorite: favorite, user: user)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.top, 4)
                            .padding(.bottom, 100) // Keep for tab bar clearance
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Crucial for title position fix
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - FavoriteImageCard (Updated for consistent styling)
struct FavoriteImageCard: View {
    let favorite: FavoriteImage
    let user: User
    
    @Environment(\.modelContext) private var modelContext
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Make the entire card clickable
            NavigationLink {
                ImageDetailView(image: convertToUnsplashImage(), user: user)
            } label: {
                VStack(alignment: .leading, spacing: 4) { // Reduced spacing within the card
                    Group {
                        if let loadedImage {
                            Image(uiImage: loadedImage)
                                .resizable()
                        } else if isLoading {
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                )
                        } else {
                            // Fallback: try to load from network if not in storage
                            CachedAsyncImage(urlString: favorite.thumbnailURL)
                        }
                    }
                    .scaledToFill()
                    // Adapts to grid item size, ensuring min height for aspect ratio
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)) // Smaller corner radius
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 0.5)
                    )

                    Text("by \(truncatedName(favorite.photographerName))")
                        .font(.caption2.bold()) // Smaller font for dense grid
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4) // Added horizontal padding for text
                }
            }
            
            // Remove button (heart icon)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    removeFavorite()
                }
            } label: {
                ZStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18)) // Smaller heart icon
                        .foregroundColor(.red)
                }
                .frame(width: 32, height: 32) // Smaller button size
                .background(Circle().fill(.ultraThinMaterial))
                .shadow(radius: 2)
            }
            .padding(6) // Reduced padding around the button
            .buttonStyle(PlainButtonStyle())
        }
        .task {
            loadFavoriteImage()
        }
    }
    
    private func loadFavoriteImage() {
        isLoading = true
        // Load from permanent storage
        if let image = ImageCacheManager.shared.loadFavoriteImage(for: favorite.imageId) {
            loadedImage = image
            print("Loaded favorite from permanent storage: \(favorite.imageId)")
        } else {
            print("Favorite image not found in storage, will load from network: \(favorite.imageId)")
            // The Group in body handles this fallback to CachedAsyncImage if loadedImage is nil
        }
        isLoading = false
    }
    
    private func removeFavorite() {
        user.favorites.removeAll { $0.id == favorite.id }
        // Delete from permanent storage
        _ = ImageCacheManager.shared.deleteFavoriteImage(for: favorite.imageId)
        // Delete from Swift Data
        modelContext.delete(favorite)
        try? modelContext.save()
        
        print("Removed favorite: \(favorite.imageId)")
    }
    
    // Convert FavoriteImage to UnsplashImage format
    private func convertToUnsplashImage() -> UnsplashImage {
        return UnsplashImage(
            id: favorite.imageId,
            description: favorite.imageDescription,
            altDescription: favorite.imageDescription,
            createdAt: ISO8601DateFormatter().string(from: favorite.addedAt),
            urls: UnsplashImageURLs(
                small: favorite.thumbnailURL,
                regular: favorite.imageURL
            ),
            user: UnsplashUser(name: favorite.photographerName)
        )
    }
    
    private func truncatedName(_ name: String) -> String {
        let words = name.split(separator: " ")
        return words.prefix(2).joined(separator: " ")
    }
}


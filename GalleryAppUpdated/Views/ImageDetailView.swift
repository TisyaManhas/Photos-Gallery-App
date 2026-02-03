import SwiftUI
import SwiftData
import UIKit

// String Extension for Capitalizing First Letter
extension String {
    func capitalizedFirstLetter() -> String {
        guard let first = self.first else { return self }
        return String(first).uppercased() + self.dropFirst()
    }
}

// Helper struct to wrap UIActivityViewController for SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ImageDetailView: View {
    let image: UnsplashImage
    let user: User
    
    @Environment(\.modelContext) private var modelContext
    @State private var isDownloading = false
    @State private var showingOptionsMenu = false
    @State private var isShowingShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CachedAsyncImage(urlString: image.urls.regular)
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.6)
                    .clipped()

                VStack(alignment: .leading, spacing: 16) {
                    // --- CHANGED: Applied .capitalizedFirstLetter() to the description text ---
                    Text((image.altDescription ?? image.description ?? "Untitled Image").capitalizedFirstLetter())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(3)

                    Divider()

                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                        Text("By \(image.user.name)")
                            .font(.body)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text(formattedDate(image.createdAt))
                            .font(.body)
                    }
                    
                    Spacer()
                        .frame(height: 24)
                    
                    HStack(spacing: 12) {
                        Button {
                            isShowingShareSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                        
                        Button {
                            Task {
                                await toggleFavorite()
                            }
                        } label: {
                            HStack {
                                if isDownloading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Downloading...")
                                } else {
                                    Image(systemName: isFavorite() ? "heart.fill" : "heart")
                                    Text(isFavorite() ? "Remove" : "Favorite")
                                }
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isFavorite() ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isDownloading)
                    }
                    .padding(.horizontal, 0)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .ignoresSafeArea(edges: .top)
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        if let url = URL(string: image.urls.regular) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("View on Unsplash", systemImage: "link.circle")
                    }
                    
                    Button {
                        UIPasteboard.general.string = image.urls.regular
                    } label: {
                        Label("Copy Link", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("Options", isPresented: $showingOptionsMenu, actions: {
            Button("View on Unsplash") {
                if let url = URL(string: image.urls.regular) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Copy Link") {
                UIPasteboard.general.string = image.urls.regular
            }
            Button("Cancel", role: .cancel) { }
        })
        .sheet(isPresented: $isShowingShareSheet) {
            if let url = URL(string: image.urls.regular) {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private func isFavorite() -> Bool {
        user.favorites.contains(where: { $0.imageId == image.id })
    }
    
    private func toggleFavorite() async {
        if let existingFavorite = user.favorites.first(where: { $0.imageId == image.id }) {
            user.favorites.removeAll { $0.id == existingFavorite.id }
            _ = ImageCacheManager.shared.deleteFavoriteImage(for: image.id)
            modelContext.delete(existingFavorite)
            try? modelContext.save()
            print("Removed from favorites")
        } else {
            isDownloading = true
            print("Downloading image for favorites...")
            
            if let downloadedImage = await downloadImage(from: image.urls.regular) {
                let saveSuccess = ImageCacheManager.shared.saveFavoriteImage(
                    downloadedImage,
                    for: image.id
                )
                
                if saveSuccess {
                    let favorite = FavoriteImage(
                        imageId: image.id,
                        imageURL: image.urls.regular,
                        thumbnailURL: image.urls.small,
                        photographerName: image.user.name,
                        imageDescription: image.description ?? image.altDescription,
                        user: user
                    )
                    modelContext.insert(favorite)
                    user.favorites.append(favorite)
                    try? modelContext.save()
                    print("Added to favorites")
                }
            }
            
            isDownloading = false
        }
    }
    
    private func downloadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Download failed: \(error)")
            return nil
        }
    }

    private func formattedDate(_ isoDate: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoDate) else {
            return "Unknown date"
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
}

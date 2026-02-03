import SwiftUI
import SwiftData

struct SearchView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @State private var query = ""
    @StateObject private var vm = ImageSearchViewModel.shared
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Title
                HStack {
                    Text("Search")
                        .font(.system(size: 34, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)

                // Search Bar + History
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        TextField("Search", text: $query)
                            .focused($isSearchFocused)
                            .submitLabel(.search)
                            .onSubmit { performSearch(query) }

                        if !query.isEmpty {
                            Button {
                                query = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button("Search") {
                            performSearch(query)
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal, 11)
                    .padding(.bottom, 0)

                    // Search History Dropdown
                    let history = vm.getHistory(for: user.username)
                    if isSearchFocused && !history.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(history, id: \.self) { item in
                                Button {
                                    query = item
                                    performSearch(item)
                                } label: {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(.secondary)
                                        Text(item)
                                        Spacer()
                                        Image(systemName: "arrow.up.backward")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)

                                if item != history.last {
                                    Divider().padding(.leading, 44)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .shadow(radius: 8)
                        )
                        .padding(.horizontal, 16)
                        .offset(y: -6)
                        .zIndex(1)
                    }
                }

                // Results Header
                if !vm.images.isEmpty {
                    HStack {
                        Text("Top Results")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // Content
                ScrollView {
                    if vm.images.isEmpty && !vm.isLoadingMore {
                        VStack {
                            Spacer(minLength: 200)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("Search for images")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 120), spacing: 4)],
                            spacing: 12
                        ) {
                            ForEach(vm.images.indices, id: \.self) { index in
                                ImageCard(image: vm.images[index], user: user)
                                    .onAppear {
                                        // ✅ Correct infinite scroll trigger
                                        if index == vm.images.count - 1 {
                                            Task {
                                                await vm.loadMoreImages()
                                            }
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 4)

                        if vm.isLoadingMore {
                            ProgressView().padding()
                        }
                    }
                }
            }
            //(modifiers belong to VSTACK)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Helpers

    private func performSearch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSearchFocused = false
        Task {
            await vm.searchImages(query: trimmed, for: user.username)
            addToSearchHistory(trimmed)
        }
    }

    private func addToSearchHistory(_ query: String) {
        guard !user.searchHistory.contains(where: { $0.query == query }) else { return }
        let item = SearchHistoryItem(query: query, user: user)
        modelContext.insert(item)
        user.searchHistory.append(item)
        try? modelContext.save()
    }
}

// MARK: - ImageCard (Slightly adjusted for tighter grid and heart icon size)
struct ImageCard: View {
    let image: UnsplashImage
    let user: User

    @Environment(\.modelContext) private var modelContext
    @State private var isDownloading = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink {
                ImageDetailView(image: image, user: user)
            } label: {
                VStack(alignment: .leading, spacing: 4) { // Reduced spacing within the card
                    CachedAsyncImage(urlString: image.urls.small)
                        .scaledToFill()
                        // Adapts to grid item size, ensuring min height for aspect ratio
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)) // Slightly smaller corner radius for tighter look
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.secondary.opacity(0.12), lineWidth: 0.5)
                        )

                    Text("by \(truncatedPhotographerName(image.user.name))")
                        .font(.caption2.bold()) // Slightly smaller font for dense grid
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4) // Added horizontal padding for text
                }
            }

            // --- Favorite Button with Download Progress (Intact) ---
            Button {
                Task {
                    await toggleFavorite()
                }
            } label: {
                ZStack {
                    Image(systemName: isFavorite() ? "heart.fill" : "heart")
                        .font(.system(size: 18)) // Slightly smaller heart icon
                        .foregroundColor(isFavorite() ? .red : .white)
                        .opacity(isDownloading ? 0 : 1)

                    if isDownloading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7) // Slightly smaller progress indicator
                    }
                }
                .frame(width: 32, height: 32) // Slightly smaller button size
                .background(Circle().fill(.ultraThinMaterial))
                .shadow(radius: 2)
            }
            .padding(6) // Reduced padding around the button
            .disabled(isDownloading)
        }
    }

    // --- Existing Helper Functions ---
    private func isFavorite() -> Bool {
        user.favorites.contains(where: { $0.imageId == image.id })
    }

    private func toggleFavorite() async {
        if let existingFavorite = user.favorites.first(where: { $0.imageId == image.id }) {
            // REMOVE FROM FAVORITES
            user.favorites.removeAll { $0.id == existingFavorite.id }
            modelContext.delete(existingFavorite)
            _ = ImageCacheManager.shared.deleteFavoriteImage(for: image.id)
            try? modelContext.save()
            print("Removed from favorites: \(image.id)")
        } else {
            // ADD TO FAVORITES
            isDownloading = true
            print("Downloading image for favorites: \(image.id)")
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
                    print("Added to favorites: \(image.id)")
                } else {
                    print("Failed to save favorite image")
                }
            } else {
                print("Failed to download image")
            }
            isDownloading = false
        }
    }

    private func downloadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return nil
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("Downloaded image: Status \(httpResponse.statusCode), Size: \(data.count / 1024) KB")
            }
            guard let image = UIImage(data: data) else {
                print("Failed to create UIImage from data")
                return nil
            }
            return image
        } catch {
            print("Failed to download image: \(error.localizedDescription)")
            return nil
        }
    }

    private func truncatedPhotographerName(_ name: String) -> String {
        let words = name.split(separator: " ")
        return words.prefix(2).joined(separator: " ")
    }
}

import SwiftUI
struct CachedAsyncImage: View {

let urlString: String

@State private var image: UIImage?

var body: some View {
    Group {
        if let image {
            Image(uiImage: image)
                .resizable()
        } else {
            Rectangle()
                .fill(Color(.systemGray6))
                .overlay(
                    ProgressView()
                )
        }
    }
    .task(id: urlString) {
        image = nil
        await loadImage()
    }
}

private func loadImage() async {
    // Disk cache
    if let cached = ImageCacheManager.shared.loadImage(from: urlString) {
        image = cached
        return
    }

    // Network
    guard let url = URL(string: urlString) else { return }

    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        if let img = UIImage(data: data) {
            image = img
            ImageCacheManager.shared.saveImage(img, for: urlString)
        }
    } catch {
        // offline → do nothing
    }
}

}

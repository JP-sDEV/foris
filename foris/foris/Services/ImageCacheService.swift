import SwiftUI
import UIKit
import Combine

/// Service for caching and loading images with placeholder support
/// Provides efficient image loading with memory and disk caching
final class ImageCacheService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ImageCacheService()
    
    // MARK: - Cache Configuration
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    private let session = URLSession.shared
    private let maxMemoryCacheSize = 100 * 1024 * 1024 // 100MB
    private let maxDiskCacheSize = 500 * 1024 * 1024 // 500MB
    
    // MARK: - Initialization
    
    private init() {
        // Setup disk cache directory
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("ImageCache")
        
        // Create cache directory if needed
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // Configure memory cache
        memoryCache.totalCostLimit = maxMemoryCacheSize
        memoryCache.countLimit = 200
        
        // Setup memory warning observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Setup background task observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cleanupDiskCache),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Loads an image from URL with caching
    /// - Parameter url: The image URL
    /// - Returns: Publisher that emits the loaded image
    func loadImage(from url: URL) -> AnyPublisher<UIImage?, Never> {
        let cacheKey = url.absoluteString
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: cacheKey as NSString) {
            return Just(cachedImage).eraseToAnyPublisher()
        }
        
        // Check disk cache
        if let diskImage = loadFromDisk(key: cacheKey) {
            // Store in memory cache for faster access
            memoryCache.setObject(diskImage, forKey: cacheKey as NSString)
            return Just(diskImage).eraseToAnyPublisher()
        }
        
        // Download from network
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .compactMap { UIImage(data: $0) }
            .handleEvents(receiveOutput: { [weak self] image in
                self?.cache(image: image, forKey: cacheKey)
            })
            .catch { _ in Just(nil) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Preloads images for better performance
    /// - Parameter urls: Array of image URLs to preload
    func preloadImages(_ urls: [URL]) {
        for url in urls {
            _ = loadImage(from: url)
                .sink { _ in }
        }
    }
    
    /// Clears all cached images
    func clearCache() {
        clearMemoryCache()
        clearDiskCache()
    }
    
    /// Gets the current cache size
    func getCacheSize() -> (memory: Int, disk: Int) {
        let memorySize = memoryCache.totalCostLimit
        let diskSize = getDiskCacheSize()
        return (memory: memorySize, disk: diskSize)
    }
    
    // MARK: - Private Methods
    
    private func cache(image: UIImage, forKey key: String) {
        // Store in memory cache
        let cost = Int(image.size.width * image.size.height * 4) // Approximate memory cost
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
        
        // Store in disk cache
        saveToDisk(image: image, key: key)
    }
    
    private func saveToDisk(image: UIImage, key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        let fileURL = diskCacheURL.appendingPathComponent(filename)
        
        DispatchQueue.global(qos: .background).async {
            try? data.write(to: fileURL)
        }
    }
    
    private func loadFromDisk(key: String) -> UIImage? {
        let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        let fileURL = diskCacheURL.appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    @objc private func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    private func clearDiskCache() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            try? FileManager.default.removeItem(at: self.diskCacheURL)
            try? FileManager.default.createDirectory(at: self.diskCacheURL, withIntermediateDirectories: true)
        }
    }
    
    @objc private func cleanupDiskCache() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.performDiskCacheCleanup()
        }
    }
    
    private func performDiskCacheCleanup() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) else {
            return
        }
        
        let currentSize = files.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + size
        }
        
        if currentSize > maxDiskCacheSize {
            // Sort files by modification date (oldest first)
            let sortedFiles = files.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                return date1 < date2
            }
            
            var sizeToRemove = currentSize - maxDiskCacheSize
            
            for fileURL in sortedFiles {
                guard sizeToRemove > 0 else { break }
                
                if let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                    try? FileManager.default.removeItem(at: fileURL)
                    sizeToRemove -= fileSize
                }
            }
        }
    }
    
    private func getDiskCacheSize() -> Int {
        guard let files = try? FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        return files.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + size
        }
    }
}

// MARK: - Cached Image View

/// SwiftUI view that displays cached images with placeholder support
struct CachedImageView: View {
    
    // MARK: - Properties
    
    let url: URL?
    let placeholder: Image
    let contentMode: ContentMode
    let animation: Animation?
    
    @StateObject private var imageLoader = ImageLoader()
    
    // MARK: - Initialization
    
    /// Initialize with URL and placeholder
    /// - Parameters:
    ///   - url: Image URL to load
    ///   - placeholder: Placeholder image to show while loading
    ///   - contentMode: Content mode for the image
    ///   - animation: Optional animation for image appearance
    init(
        url: URL?,
        placeholder: Image = Image(systemName: "photo"),
        contentMode: ContentMode = .fit,
        animation: Animation? = .easeIn(duration: 0.3)
    ) {
        self.url = url
        self.placeholder = placeholder
        self.contentMode = contentMode
        self.animation = animation
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else {
                placeholder
                    .foregroundColor(.secondary)
                    .aspectRatio(contentMode: contentMode)
            }
        }
        .onAppear {
            if let url = url {
                imageLoader.loadImage(from: url)
            }
        }
        .onChange(of: url) { newURL in
            if let newURL = newURL {
                imageLoader.loadImage(from: newURL)
            } else {
                imageLoader.cancel()
            }
        }
        .animation(animation, value: imageLoader.image != nil)
    }
}

// MARK: - Image Loader

private class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    private var cancellable: AnyCancellable?
    
    func loadImage(from url: URL) {
        guard image == nil else { return }
        
        isLoading = true
        
        cancellable = ImageCacheService.shared.loadImage(from: url)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loadedImage in
                self?.image = loadedImage
                self?.isLoading = false
            }
    }
    
    func cancel() {
        cancellable?.cancel()
        image = nil
        isLoading = false
    }
}

// MARK: - Convenience Initializers

extension CachedImageView {
    /// Creates a cached image view for avatars
    static func avatar(url: URL?, size: CGFloat = 40) -> some View {
        CachedImageView(
            url: url,
            placeholder: Image(systemName: "person.circle.fill"),
            contentMode: .fill
        )
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
    
    /// Creates a cached image view for post images
    static func postImage(url: URL?) -> some View {
        CachedImageView(
            url: url,
            placeholder: Image(systemName: "photo.fill"),
            contentMode: .fill
        )
        .clipped()
    }
    
    /// Creates a cached image view for thumbnails
    static func thumbnail(url: URL?, size: CGSize) -> some View {
        CachedImageView(
            url: url,
            placeholder: Image(systemName: "photo"),
            contentMode: .fill
        )
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

// MARK: - View Modifiers

extension View {
    /// Adds image caching to any view
    func cachedImage(url: URL?) -> some View {
        self.overlay(
            CachedImageView(url: url)
        )
    }
    
    /// Adds avatar image with caching
    func avatarImage(url: URL?, size: CGFloat = 40) -> some View {
        self.overlay(
            CachedImageView.avatar(url: url, size: size)
        )
    }
}

// MARK: - Image Placeholder Generator

struct ImagePlaceholderGenerator {
    
    /// Generates a placeholder image with initials
    static func generateInitialsPlaceholder(
        initials: String,
        size: CGSize = CGSize(width: 100, height: 100),
        backgroundColor: Color = .accentColor,
        textColor: Color = .white
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Fill background
            UIColor(backgroundColor).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw initials
            let font = UIFont.systemFont(ofSize: size.width * 0.4, weight: .medium)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(textColor)
            ]
            
            let text = initials.uppercased()
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    /// Generates a gradient placeholder
    static func generateGradientPlaceholder(
        size: CGSize = CGSize(width: 100, height: 100),
        colors: [Color] = [.blue, .purple]
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgColors = colors.map { UIColor($0).cgColor }
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors as CFArray, locations: nil)!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }
    }
}

// MARK: - Preview Provider

#Preview("Cached Image View") {
    VStack(spacing: 20) {
        // Avatar examples
        HStack(spacing: 16) {
            CachedImageView.avatar(url: URL(string: "https://example.com/avatar1.jpg"))
            CachedImageView.avatar(url: URL(string: "https://example.com/avatar2.jpg"))
            CachedImageView.avatar(url: URL(string: "https://example.com/avatar3.jpg"))
        }
        
        // Post image example
        CachedImageView.postImage(url: URL(string: "https://example.com/post-image.jpg"))
            .frame(height: 200)
            .cornerRadius(12)
        
        // Thumbnail examples
        HStack(spacing: 12) {
            CachedImageView.thumbnail(
                url: URL(string: "https://example.com/thumb1.jpg"),
                size: CGSize(width: 80, height: 80)
            )
            .cornerRadius(8)
            
            CachedImageView.thumbnail(
                url: URL(string: "https://example.com/thumb2.jpg"),
                size: CGSize(width: 80, height: 80)
            )
            .cornerRadius(8)
            
            CachedImageView.thumbnail(
                url: URL(string: "https://example.com/thumb3.jpg"),
                size: CGSize(width: 80, height: 80)
            )
            .cornerRadius(8)
        }
    }
    .padding()
}

#Preview("Placeholder Examples") {
    VStack(spacing: 20) {
        Text("Generated Placeholders")
            .font(.title2)
            .fontWeight(.semibold)
        
        HStack(spacing: 16) {
            Image(uiImage: ImagePlaceholderGenerator.generateInitialsPlaceholder(
                initials: "JD",
                size: CGSize(width: 60, height: 60)
            ))
            .clipShape(Circle())
            
            Image(uiImage: ImagePlaceholderGenerator.generateInitialsPlaceholder(
                initials: "AB",
                size: CGSize(width: 60, height: 60),
                backgroundColor: .green
            ))
            .clipShape(Circle())
            
            Image(uiImage: ImagePlaceholderGenerator.generateGradientPlaceholder(
                size: CGSize(width: 60, height: 60),
                colors: [.orange, .red]
            ))
            .clipShape(Circle())
        }
    }
    .padding()
}
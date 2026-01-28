//
//  CachedAsyncImage.swift
//  HaliSahaApp
//
//  Önbellekli asenkron görsel yükleme komponenti
//  V4: @StateObject kaldırıldı, .task(id:) ile kesin çözüm
//
//  Created by Mehmet Mert Mazıcı on 27.01.2026.
//

import SwiftUI

// MARK: - Cached Async Image (FINAL VERSION)
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    
    // MARK: - Properties
    let url: String?
    let targetSize: CGSize?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    
    // State - @StateObject YOK, sadece @State
    @State private var loadedImage: UIImage?
    @State private var isLoading: Bool = false
    @State private var hasFailed: Bool = false
    
    // MARK: - Init
    init(
        url: String?,
        targetSize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.targetSize = targetSize
        self.content = content
        self.placeholder = placeholder
    }
    
    // MARK: - Body
    var body: some View {
        contentView
            // KRİTİK: .task(id:) URL değişince otomatik iptal edip yeniden başlatır
            .task(id: url) {
                await loadImage()
            }
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        if let image = loadedImage {
            content(Image(uiImage: image))
        } else if hasFailed {
            failedView
        } else {
            placeholder()
        }
    }
    
    // MARK: - Failed View
    private var failedView: some View {
        placeholder()
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                    Text("Yüklenemedi")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            .onTapGesture {
                // Tekrar dene
                Task {
                    await loadImage()
                }
            }
    }
    
    // MARK: - Load Image
    private func loadImage() async {
        // State'leri sıfırla
        loadedImage = nil
        hasFailed = false
        isLoading = true
        
        guard let url = url, !url.isEmpty else {
            hasFailed = true
            isLoading = false
            return
        }
        
        // Debug log
        print("📥 Loading image for URL: \(url.prefix(80))...")
        
        do {
            try Task.checkCancellation()
            
            let image = try await ImageCacheService.shared.getImage(
                from: url,
                size: targetSize
            )
            
            try Task.checkCancellation()
            
            // Başarılı
            loadedImage = image
            isLoading = false
            print("✅ Image loaded successfully")
            
        } catch is CancellationError {
            print("⚠️ Image load cancelled")
            // İptal edildi, sessizce çık
        } catch {
            print("❌ Image load failed: \(error.localizedDescription)")
            hasFailed = true
            isLoading = false
        }
    }
}

// MARK: - Convenience Init
extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: String?, targetSize: CGSize? = nil) {
        self.init(
            url: url,
            targetSize: targetSize,
            content: { $0 },
            placeholder: { ProgressView() }
        )
    }
}

// MARK: - Facility Image View
struct FacilityImageView: View {
    
    let url: String?
    let size: CGSize
    let cornerRadius: CGFloat
    var placeholder: String = "sportscourt.fill"
    
    var body: some View {
        CachedAsyncImage(
            url: url,
            targetSize: size
        ) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } placeholder: {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "2E7D32").opacity(0.3), Color(hex: "1B5E20").opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.width, height: size.height)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: placeholder)
                            .font(.system(size: min(size.width, size.height) * 0.25))
                            .foregroundColor(Color(hex: "2E7D32").opacity(0.5))
                        
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(Color(hex: "2E7D32"))
                    }
                }
                .shimmering()
        }
    }
}

// MARK: - Shimmer Effect Modifier
struct ShimmerModifier: ViewModifier {
    
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                }
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        FacilityImageView(
            url: nil,
            size: CGSize(width: 100, height: 100),
            cornerRadius: 12
        )
        
        FacilityImageView(
            url: "https://picsum.photos/200",
            size: CGSize(width: 200, height: 150),
            cornerRadius: 16
        )
    }
    .padding()
}

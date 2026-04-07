//
//  ImageGalleryView.swift
//  HaliSahaApp
//
//  Kaydırılabilir fotoğraf galerisi
//  V4: .task(id:) ile kesin çözüm
//
//  Created by Mehmet Mert Mazıcı on 27.01.2026.
//

import SwiftUI

// MARK: - Image Gallery View
struct ImageGalleryView: View {
    
    // MARK: - Properties
    let images: [String]
    let height: CGFloat
    let cornerRadius: CGFloat
    var placeholder: String = "sportscourt.fill"
    
    @State private var selectedIndex: Int = 0
    @State private var showFullScreen: Bool = false
    
    // Boş URL'leri filtrele
    private var validImages: [String] {
        images.filter { !$0.isEmpty }
    }
    
    // MARK: - Init
    init(
        images: [String],
        height: CGFloat = 200,
        cornerRadius: CGFloat = 16,
        placeholder: String = "sportscourt.fill"
    ) {
        self.images = images
        self.height = height
        self.cornerRadius = cornerRadius
        self.placeholder = placeholder
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if validImages.isEmpty {
                placeholderView
            } else {
                galleryView
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenImageViewer(
                images: validImages,
                selectedIndex: $selectedIndex,
                isPresented: $showFullScreen
            )
        }
    }
    
    // MARK: - Gallery View
    private var galleryView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(validImages.enumerated()), id: \.element) { index, imageURL in
                    GalleryImageCell(
                        url: imageURL,
                        height: height,
                        cornerRadius: cornerRadius
                    ) {
                        selectedIndex = index
                        showFullScreen = true
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            
            // Custom Page Indicator
            if validImages.count > 1 {
                pageIndicator
            }
        }
    }
    
    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<min(validImages.count, 5), id: \.self) { index in
                Circle()
                    .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.5))
                    .frame(width: index == selectedIndex ? 8 : 6, height: index == selectedIndex ? 8 : 6)
                    .animation(.easeInOut(duration: 0.2), value: selectedIndex)
            }
            
            if validImages.count > 5 {
                Text("+\(validImages.count - 5)")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.bottom, 12)
    }
    
    // MARK: - Placeholder View
    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "2E7D32"), Color(hex: "1B5E20")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: placeholder)
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(height: height)
    }
}

// MARK: - Gallery Image Cell
private struct GalleryImageCell: View {
    let url: String
    let height: CGFloat
    let cornerRadius: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        CachedAsyncImage(
            url: url,
            targetSize: CGSize(width: UIScreen.main.bounds.width, height: height * 2)
        ) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(height: height)
                .clipped()
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
        } placeholder: {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.2))
                ProgressView()
                    .scaleEffect(1.2)
            }
            .frame(height: height)
        }
    }
}

// MARK: - Compact Image Gallery (Kartlar için)
struct CompactImageGallery: View {
    
    let images: [String]
    let size: CGFloat
    var placeholder: String = "sportscourt.fill"
    
    @State private var showFullScreen = false
    @State private var selectedIndex = 0
    
    // Boş URL'leri filtrele
    private var validImages: [String] {
        images.filter { !$0.isEmpty }
    }
    
    var body: some View {
        ZStack {
            if validImages.isEmpty {
                placeholderView
            } else {
                imageView
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenImageViewer(
                images: validImages,
                selectedIndex: $selectedIndex,
                isPresented: $showFullScreen
            )
        }
    }
    
    private var imageView: some View {
        // Debug log
        let _ = print("🖼️ CompactImageGallery rendering with URL: \(validImages.first?.prefix(50) ?? "nil")...")
        
        return CachedAsyncImage(
            url: validImages.first,
            targetSize: CGSize(width: size * 2, height: size * 2)
        ) { image in
            ZStack(alignment: .bottomTrailing) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Fotoğraf sayısı badge'i
                if validImages.count > 1 {
                    imageBadge
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedIndex = 0
                showFullScreen = true
            }
        } placeholder: {
            loadingPlaceholder
        }
    }
    
    private var imageBadge: some View {
        Text("+\(validImages.count - 1)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .padding(6)
    }
    
    private var loadingPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: "2E7D32").opacity(0.1))
            .frame(width: size, height: size)
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: placeholder)
                        .font(.system(size: size * 0.25))
                        .foregroundColor(Color(hex: "2E7D32").opacity(0.5))
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
    }
    
    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "2E7D32").opacity(0.1))
            
            Image(systemName: placeholder)
                .font(.system(size: size * 0.3))
                .foregroundColor(Color(hex: "2E7D32").opacity(0.5))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview
#Preview("Image Gallery") {
    VStack(spacing: 20) {
        ImageGalleryView(
            images: [],
            height: 200,
            cornerRadius: 16
        )
        
        ImageGalleryView(
            images: ["https://picsum.photos/400/300", "https://picsum.photos/400/301"],
            height: 200,
            cornerRadius: 16
        )
    }
    .padding()
}

#Preview("Compact Gallery") {
    HStack(spacing: 12) {
        CompactImageGallery(images: [], size: 80)
        CompactImageGallery(images: ["https://picsum.photos/200"], size: 80)
        CompactImageGallery(
            images: ["https://picsum.photos/200", "https://picsum.photos/201", "https://picsum.photos/202"],
            size: 80
        )
    }
    .padding()
}

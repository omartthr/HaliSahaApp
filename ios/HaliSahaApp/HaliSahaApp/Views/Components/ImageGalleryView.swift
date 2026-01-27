//
//  ImageGalleryView.swift
//  HaliSahaApp
//
//  Kaydırılabilir fotoğraf galerisi
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
            if images.isEmpty {
                placeholderView
            } else {
                galleryView
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenImageViewer(
                images: images,
                selectedIndex: $selectedIndex,
                isPresented: $showFullScreen
            )
        }
    }
    
    // MARK: - Gallery View
    private var galleryView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageURL in
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            loadingView
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: height)
                                .clipped()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedIndex = index
                                    showFullScreen = true
                                }
                        case .failure:
                            failureView
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            
            // Sayfa göstergesi
            if images.count > 1 {
                pageIndicator
            }
            
            // Tam ekran butonu
            fullScreenButton
        }
    }
    
    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<images.count, id: \.self) { index in
                Circle()
                    .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: selectedIndex)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.bottom, 12)
    }
    
    // MARK: - Full Screen Button
    private var fullScreenButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    showFullScreen = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(12)
            }
            Spacer()
        }
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
    
    // MARK: - Loading View
    private var loadingView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.2))
            
            ProgressView()
                .scaleEffect(1.2)
        }
        .frame(height: height)
    }
    
    // MARK: - Failure View
    private var failureView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.2))
            
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("Yüklenemedi")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Compact Image Gallery (Küçük galeri - Kartlar için)
struct CompactImageGallery: View {
    
    let images: [String]
    let size: CGFloat
    var placeholder: String = "sportscourt.fill"
    
    @State private var showFullScreen = false
    @State private var selectedIndex = 0
    
    var body: some View {
        ZStack {
            if images.isEmpty {
                placeholderView
            } else {
                imageView
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenImageViewer(
                images: images,
                selectedIndex: $selectedIndex,
                isPresented: $showFullScreen
            )
        }
    }
    
    private var imageView: some View {
        AsyncImage(url: URL(string: images.first ?? "")) { phase in
            switch phase {
            case .empty:
                loadingView
            case .success(let image):
                ZStack(alignment: .bottomTrailing) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Fotoğraf sayısı badge'i
                    if images.count > 1 {
                        Text("+\(images.count - 1)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .padding(6)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedIndex = 0
                    showFullScreen = true
                }
            case .failure:
                placeholderView
            @unknown default:
                EmptyView()
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
    
    private var loadingView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
            
            ProgressView()
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview
#Preview("Image Gallery") {
    VStack(spacing: 20) {
        ImageGalleryView(
            images: [
                "https://picsum.photos/800/600",
                "https://picsum.photos/800/601",
                "https://picsum.photos/800/602"
            ],
            height: 200
        )
        
        ImageGalleryView(
            images: [],
            height: 200
        )
    }
    .padding()
}

#Preview("Compact Gallery") {
    HStack(spacing: 16) {
        CompactImageGallery(
            images: [
                "https://picsum.photos/200",
                "https://picsum.photos/201",
                "https://picsum.photos/202"
            ],
            size: 100
        )
        
        CompactImageGallery(
            images: [],
            size: 100
        )
    }
    .padding()
}
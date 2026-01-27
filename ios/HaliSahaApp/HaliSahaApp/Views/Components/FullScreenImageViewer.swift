//
//  FullScreenImageViewer.swift
//  HaliSahaApp
//
//  Tam ekran fotoğraf görüntüleyici
//
//  Created by Mehmet Mert Mazıcı on 27.01.2026.
//

import SwiftUI

// MARK: - Full Screen Image Viewer
struct FullScreenImageViewer: View {
    
    // MARK: - Properties
    let images: [String]
    @Binding var selectedIndex: Int
    @Binding var isPresented: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    @GestureState private var magnifyBy: CGFloat = 1.0
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Arka plan
            Color.black
                .ignoresSafeArea()
            
            // Fotoğraf TabView
            TabView(selection: $selectedIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageURL in
                    ZoomableImageView(imageURL: imageURL)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // Üst bar
            VStack {
                HStack {
                    // Sayfa göstergesi
                    Text("\(selectedIndex + 1) / \(images.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    // Kapat butonu
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()
                .padding(.top, 44)
                
                Spacer()
            }
        }
        .statusBarHidden(true)
    }
}

// MARK: - Zoomable Image View
struct ZoomableImageView: View {
    
    let imageURL: String
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale < 1 {
                                        withAnimation {
                                            scale = 1
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                    if scale <= 1 {
                                        withAnimation {
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                if scale > 1 {
                                    scale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2
                                }
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    
                case .failure:
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Fotoğraf yüklenemedi")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    FullScreenImageViewer(
        images: [
            "https://picsum.photos/800/600",
            "https://picsum.photos/800/601",
            "https://picsum.photos/800/602"
        ],
        selectedIndex: .constant(0),
        isPresented: .constant(true)
    )
}
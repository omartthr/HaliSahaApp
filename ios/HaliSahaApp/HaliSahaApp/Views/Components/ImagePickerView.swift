//
//  ImagePickerView.swift
//  HaliSahaApp
//
//  Fotoğraf seçme ve önizleme bileşeni
//  DÜZELTİLMİŞ VERSİYON: Index sorunları ve silme mekanizması düzeltildi
//
//  Created by Mehmet Mert Mazıcı on 27.01.2026.
//

import SwiftUI
import PhotosUI

// MARK: - Image Item Model (YENİ - Güvenli ID tabanlı yaklaşım)
struct SelectedImageItem: Identifiable, Equatable {
    let id: UUID
    let image: UIImage
    
    init(image: UIImage) {
        self.id = UUID()
        self.image = image
    }
    
    static func == (lhs: SelectedImageItem, rhs: SelectedImageItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Multi Image Picker (DÜZELTİLDİ)
struct MultiImagePicker: View {
    
    // MARK: - Bindings
    @Binding var selectedImages: [UIImage]
    @Binding var existingImageURLs: [String]
    
    // MARK: - Properties
    let maxImages: Int
    let title: String
    
    // MARK: - State
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoading = false
    @State private var imageItems: [SelectedImageItem] = []
    
    // MARK: - Init
    init(
        selectedImages: Binding<[UIImage]>,
        existingImageURLs: Binding<[String]> = .constant([]),
        maxImages: Int = 5,
        title: String = "Fotoğraflar"
    ) {
        self._selectedImages = selectedImages
        self._existingImageURLs = existingImageURLs
        self.maxImages = maxImages
        self.title = title
    }
    
    // MARK: - Computed
    private var totalImages: Int {
        imageItems.count + existingImageURLs.count
    }
    
    private var canAddMore: Bool {
        totalImages < maxImages
    }
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            imagesGridView
            loadingView
            infoTextView
        }
        .onAppear {
            // İlk yüklemede imageItems'ı senkronize et
            syncImageItems()
        }
        .onChange(of: selectedImages) { _, newImages in
            // Dışarıdan değişiklik olursa senkronize et
            if imageItems.map({ $0.image }) != newImages {
                syncImageItems()
            }
        }
        .onChange(of: selectedItems) { _, newItems in
            Task {
                await loadImages(from: newItems)
            }
        }
    }
    
    // MARK: - Sync Image Items
    private func syncImageItems() {
        imageItems = selectedImages.map { SelectedImageItem(image: $0) }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Text("\(totalImages)/\(maxImages)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Images Grid View
    private var imagesGridView: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            // Mevcut URL'ler
            ForEach(existingImageURLs, id: \.self) { url in
                ExistingImageCell(url: url) {
                    deleteExistingImage(url: url)
                }
            }
            
            // Yeni seçilen fotoğraflar (DÜZELTİLDİ - ID tabanlı)
            ForEach(imageItems) { item in
                SelectedImageCell(image: item.image) {
                    deleteSelectedImage(item: item)
                }
            }
            
            // Ekleme butonu
            if canAddMore {
                addButtonView
            }
        }
    }
    
    // MARK: - Delete Existing Image (DÜZELTİLDİ)
    private func deleteExistingImage(url: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            existingImageURLs.removeAll { $0 == url }
        }
    }
    
    // MARK: - Delete Selected Image (DÜZELTİLDİ - ID tabanlı)
    private func deleteSelectedImage(item: SelectedImageItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            // ID ile güvenli silme
            imageItems.removeAll { $0.id == item.id }
            
            // selectedImages'ı güncelle
            selectedImages = imageItems.map { $0.image }
        }
    }
    
    // MARK: - Add Button View
    private var addButtonView: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: maxImages - totalImages,
            matching: .images,
            photoLibrary: .shared()
        ) {
            AddImageButton()
        }
    }
    
    // MARK: - Loading View
    @ViewBuilder
    private var loadingView: some View {
        if isLoading {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Fotoğraflar yükleniyor...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Info Text View
    private var infoTextView: some View {
        Text("En fazla \(maxImages) fotoğraf ekleyebilirsiniz. İlk fotoğraf kapak resmi olarak kullanılacaktır.")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    // MARK: - Load Images
    private func loadImages(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        
        await MainActor.run { isLoading = true }
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    if totalImages < maxImages {
                        let newItem = SelectedImageItem(image: image)
                        imageItems.append(newItem)
                        selectedImages.append(image)
                    }
                }
            }
        }
        
        await MainActor.run {
            selectedItems.removeAll()
            isLoading = false
        }
    }
}

// MARK: - Selected Image Cell
struct SelectedImageCell: View {
    let image: UIImage
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Delete Button
            deleteButton
        }
    }
    
    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .red)
        }
        .offset(x: 6, y: -6)
    }
}

// MARK: - Existing Image Cell (DÜZELTİLDİ)
struct ExistingImageCell: View {
    let url: String
    let onDelete: () -> Void
    
    @State private var loadState: ExistingImageLoadState = .loading
    
    private enum ExistingImageLoadState {
        case loading
        case loaded(UIImage)
        case failed
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            imageContent
            deleteButton
        }
        // View reuse fix
        .id(url)
        .task(id: url) {
            await loadImage()
        }
    }
    
    @ViewBuilder
    private var imageContent: some View {
        switch loadState {
        case .loading:
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay { ProgressView() }
        case .loaded(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        case .failed:
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.secondary)
                }
        }
    }
    
    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .red)
        }
        .offset(x: 6, y: -6)
    }
    
    private func loadImage() async {
        do {
            let image = try await ImageCacheService.shared.getImage(
                from: url,
                size: CGSize(width: 200, height: 200)
            )
            await MainActor.run {
                loadState = .loaded(image)
            }
        } catch {
            await MainActor.run {
                loadState = .failed
            }
        }
    }
}

// MARK: - Add Image Button
struct AddImageButton: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color(hex: "2E7D32"), style: StrokeStyle(lineWidth: 2, dash: [8]))
            .frame(width: 100, height: 100)
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "2E7D32"))
                    
                    Text("Ekle")
                        .font(.caption)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }
    }
}

// MARK: - Single Image Picker (Profil fotoğrafı için)
struct SingleImagePicker: View {
    @Binding var selectedImage: UIImage?
    @Binding var existingImageURL: String?
    
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let url = existingImageURL, !url.isEmpty {
                    CachedAsyncImage(
                        url: url,
                        targetSize: CGSize(width: 240, height: 240)
                    ) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } placeholder: {
                        placeholderImage
                    }
                } else {
                    placeholderImage
                }
            }
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Fotoğraf Seç")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "2E7D32"))
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                        existingImageURL = nil
                    }
                }
            }
        }
    }
    
    private var placeholderImage: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 120, height: 120)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
            }
    }
}

// MARK: - Preview
#Preview("Multi Image Picker") {
    struct PreviewWrapper: View {
        @State private var images: [UIImage] = []
        @State private var urls: [String] = []
        
        var body: some View {
            Form {
                Section {
                    MultiImagePicker(
                        selectedImages: $images,
                        existingImageURLs: $urls,
                        maxImages: 5,
                        title: "Tesis Fotoğrafları"
                    )
                }
            }
        }
    }
    
    return PreviewWrapper()
}

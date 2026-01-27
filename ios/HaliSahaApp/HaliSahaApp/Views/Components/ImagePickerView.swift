// filepath: Views/Components/ImagePickerView.swift
//
//  ImagePickerView.swift
//  HaliSahaApp
//
//  Fotoğraf seçme ve önizleme bileşeni
//
//  Created by Mehmet Mert Mazıcı on 27.01.2026.
//

import SwiftUI
import PhotosUI

// MARK: - Multi Image Picker
struct MultiImagePicker: View {
    
    @Binding var selectedImages: [UIImage]
    @Binding var existingImageURLs: [String]
    
    let maxImages: Int
    let title: String
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoading = false
    
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
    
    private var totalImages: Int {
        selectedImages.count + existingImageURLs.count
    }
    
    private var canAddMore: Bool {
        totalImages < maxImages
    }
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            imagesGridView
            loadingView
            infoTextView
        }
        .onChange(of: selectedItems) { _, newItems in
            Task {
                await loadImages(from: newItems)
            }
        }
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
            existingImagesView
            selectedImagesView
            addButtonIfNeeded
        }
    }
    
    // MARK: - Existing Images
    private var existingImagesView: some View {
        ForEach(existingImageURLs, id: \.self) { url in
            ExistingImageCell(url: url) {
                withAnimation {
                    existingImageURLs.removeAll { $0 == url }
                }
            }
        }
    }
    
    // MARK: - Selected Images
    private var selectedImagesView: some View {
        ForEach(Array(selectedImages.indices), id: \.self) { index in
            SelectedImageCell(image: selectedImages[index]) {
                withAnimation {
                    // Burada bir kontrol eklemek güvenliği artırır
                    if index < selectedImages.count {
                        selectedImages.remove(at: index)
                    }
                }
            }
        }
    }
    
    // MARK: - Add Button If Needed
    @ViewBuilder
    private var addButtonIfNeeded: some View {
        if canAddMore {
            addButtonView
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
        isLoading = true
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    if selectedImages.count + existingImageURLs.count < maxImages {
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
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.red))
            }
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - Existing Image Cell
struct ExistingImageCell: View {
    let url: String
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .failure:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.red))
            }
            .offset(x: 6, y: -6)
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
            // Preview
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let url = existingImageURL, !url.isEmpty {
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
                
                // Camera overlay
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .opacity(0.001) // Sadece tıklanabilir alan olarak
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

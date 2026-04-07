//
//  EditPitchView.swift
//  HaliSahaApp
//
//  Saha Düzenleme Formu
//
//  Created by Mehmet Mert Mazıcı on 25.01.2026.
//

import SwiftUI
import PhotosUI

// MARK: - Edit Pitch View
struct EditPitchView: View {
    
    // MARK: - Properties
    let pitch: Pitch
    let facilityId: String
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditPitchViewModel
    
    // MARK: - Init
    init(pitch: Pitch, facilityId: String) {
        self.pitch = pitch
        self.facilityId = facilityId
        _viewModel = StateObject(wrappedValue: EditPitchViewModel(pitch: pitch, facilityId: facilityId))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // Durum
                statusSection
                
                // Fotoğraflar - YENİ SECTION
                imagesSection
                
                // Temel Bilgiler
                basicInfoSection
                
                // Saha Özellikleri
                pitchPropertiesSection
                
                // Fiyatlandırma
                pricingSection
                
                // Tehlikeli Bölge
                dangerZone
            }
            .navigationTitle("Sahayı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        Task {
                            await viewModel.updatePitch()
                            if viewModel.saveSuccess {
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
            .alert("Hata", isPresented: $viewModel.showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Sahayı Sil", isPresented: $viewModel.showDeleteConfirm) {
                Button("İptal", role: .cancel) {}
                Button("Sil", role: .destructive) {
                    Task {
                        await viewModel.deletePitch()
                        dismiss()
                    }
                }
            } message: {
                Text("Bu sahayı silmek istediğinizden emin misiniz?")
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text(viewModel.loadingMessage)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }
            }
        }
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        Section {
            Toggle(isOn: $viewModel.isActive) {
                Label(
                    viewModel.isActive ? "Aktif" : "Pasif",
                    systemImage: viewModel.isActive ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
            }
            .tint(Color(hex: "2E7D32"))
        } footer: {
            Text("Pasif sahalar rezervasyona kapatılır.")
        }
    }
    
    // MARK: - Images Section (YENİ)
    private var imagesSection: some View {
        Section {
            MultiImagePicker(
                selectedImages: $viewModel.newImages,
                existingImageURLs: $viewModel.existingImages,
                maxImages: 3,
                title: "Saha Fotoğrafları"
            )
        } header: {
            Text("Fotoğraflar")
        }
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        Section("Temel Bilgiler") {
            TextField("Saha Adı", text: $viewModel.name)
                .textInputAutocapitalization(.words)
            
            TextField("Açıklama (Opsiyonel)", text: $viewModel.description, axis: .vertical)
                .lineLimit(2...4)
        }
    }
    
    // MARK: - Pitch Properties Section
    private var pitchPropertiesSection: some View {
        Section("Saha Özellikleri") {
            // Saha Türü
            Picker("Saha Türü", selection: $viewModel.pitchType) {
                ForEach(PitchType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon)
                        .tag(type)
                }
            }
            
            // Zemin Türü
            Picker("Zemin Türü", selection: $viewModel.surfaceType) {
                ForEach(SurfaceType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            
            // Saha Boyutu
            Picker("Saha Boyutu", selection: $viewModel.size) {
                ForEach(PitchSize.allCases, id: \.self) { size in
                    Text(size.displayName).tag(size)
                }
            }
            
            // Kapasite
            HStack {
                Text("Maksimum Kapasite")
                Spacer()
                Text("\(viewModel.capacity) kişi")
                    .foregroundColor(.secondary)
                Stepper("", value: $viewModel.capacity, in: 10...20)
                    .labelsHidden()
            }
        }
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        Section {
            // Gündüz Fiyatı
            HStack {
                Label("Gündüz (08-18)", systemImage: "sun.max.fill")
                Spacer()
                TextField("Fiyat", value: $viewModel.daytimePrice, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("₺/saat")
                    .foregroundColor(.secondary)
            }
            
            // Akşam Fiyatı
            HStack {
                Label("Akşam (18-00)", systemImage: "moon.fill")
                Spacer()
                TextField("Fiyat", value: $viewModel.eveningPrice, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("₺/saat")
                    .foregroundColor(.secondary)
            }
            
            // Hafta Sonu Çarpanı
            HStack {
                Label("Hafta Sonu", systemImage: "calendar")
                Spacer()
                Picker("", selection: $viewModel.weekendMultiplier) {
                    Text("Aynı Fiyat").tag(1.0)
                    Text("+%10").tag(1.1)
                    Text("+%20").tag(1.2)
                    Text("+%30").tag(1.3)
                    Text("+%50").tag(1.5)
                }
                .pickerStyle(.menu)
            }
            
            // Kapora Yüzdesi
            HStack {
                Label("Kapora", systemImage: "percent")
                Spacer()
                Picker("", selection: $viewModel.depositPercentage) {
                    Text("%10").tag(0.10)
                    Text("%20").tag(0.20)
                    Text("%30").tag(0.30)
                    Text("%50").tag(0.50)
                    Text("%100").tag(1.0)
                }
                .pickerStyle(.menu)
            }
        } header: {
            Text("Fiyatlandırma")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mevcut Fiyat Özeti:")
                    .fontWeight(.medium)
                Text("Gündüz: \(viewModel.daytimePrice.asShortCurrency)/saat")
                Text("Akşam: \(viewModel.eveningPrice.asShortCurrency)/saat")
                Text("Hafta sonu: \(viewModel.weekendMultiplier == 1.0 ? "Aynı" : "+%\(Int((viewModel.weekendMultiplier - 1) * 100))")")
            }
            .font(.caption)
        }
    }
    
    // MARK: - Danger Zone
    private var dangerZone: some View {
        Section {
            Button(role: .destructive) {
                viewModel.showDeleteConfirm = true
            } label: {
                HStack {
                    Spacer()
                    Label("Sahayı Sil", systemImage: "trash.fill")
                    Spacer()
                }
            }
        } header: {
            Text("Tehlikeli Bölge")
        } footer: {
            Text("Bu sahayı silmek aktif rezervasyonları da iptal edecektir.")
        }
    }
}

// MARK: - Edit Pitch ViewModel
@MainActor
final class EditPitchViewModel: ObservableObject {
    
    // Original
    let pitch: Pitch
    let facilityId: String
    
    // Images - YENİ
    @Published var newImages: [UIImage] = []
    @Published var existingImages: [String] = []
    private var originalImages: [String] = []
    
    // Basic Info
    @Published var name: String
    @Published var description: String
    
    // Properties
    @Published var pitchType: PitchType
    @Published var surfaceType: SurfaceType
    @Published var size: PitchSize
    @Published var capacity: Int
    @Published var isActive: Bool
    
    // Pricing
    @Published var daytimePrice: Double
    @Published var eveningPrice: Double
    @Published var weekendMultiplier: Double
    @Published var depositPercentage: Double
    
    // State
    @Published var isLoading = false
    @Published var loadingMessage = "Kaydediliyor..."
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var saveSuccess = false
    @Published var showDeleteConfirm = false
    
    // Services
    private let adminService = AdminService.shared
    private let storageService = StorageService.shared
    
    // MARK: - Init
    init(pitch: Pitch, facilityId: String) {
        self.pitch = pitch
        self.facilityId = facilityId
        
        // Images
        self.existingImages = pitch.images
        self.originalImages = pitch.images
        
        // Basic Info
        self.name = pitch.name
        self.description = pitch.description ?? ""
        
        // Properties
        self.pitchType = pitch.pitchType
        self.surfaceType = pitch.surfaceType
        self.size = pitch.size
        self.capacity = pitch.capacity
        self.isActive = pitch.isActive
        
        // Pricing
        self.daytimePrice = pitch.pricing.daytimePrice
        self.eveningPrice = pitch.pricing.eveningPrice
        self.weekendMultiplier = pitch.pricing.weekendMultiplier
        self.depositPercentage = pitch.pricing.depositPercentage
    }
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        daytimePrice > 0 &&
        eveningPrice > 0
    }
    
    // MARK: - Update Pitch
    func updatePitch() async {
        guard let pitchId = pitch.id else {
            errorMessage = "Saha ID bulunamadı"
            showError = true
            return
        }
        
        isLoading = true
        loadingMessage = "Güncelleniyor..."
        
        do {
            // 1. Silinen fotoğrafları kaldır
            let deletedImages = originalImages.filter { !existingImages.contains($0) }
            if !deletedImages.isEmpty {
                loadingMessage = "Eski fotoğraflar siliniyor..."
                try await storageService.deleteImages(at: deletedImages)
            }
            
            // 2. Yeni fotoğrafları yükle
            var allImageURLs = existingImages
            if !newImages.isEmpty {
                loadingMessage = "Yeni fotoğraflar yükleniyor..."
                let newURLs = try await storageService.uploadPitchImages(
                    newImages,
                    facilityId: facilityId,
                    pitchId: pitchId
                )
                allImageURLs.append(contentsOf: newURLs)
            }
            
            // 3. Pricing
            let pricing = PitchPricing(
                daytimePrice: daytimePrice,
                eveningPrice: eveningPrice,
                weekendMultiplier: weekendMultiplier,
                depositPercentage: depositPercentage,
                currency: "TRY"
            )
            
            // 4. Güncellenmiş saha
            var updatedPitch = pitch
            updatedPitch.name = name.trimmingCharacters(in: .whitespaces)
            updatedPitch.description = description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces)
            updatedPitch.pitchType = pitchType
            updatedPitch.surfaceType = surfaceType
            updatedPitch.size = size
            updatedPitch.capacity = capacity
            updatedPitch.isActive = isActive
            updatedPitch.pricing = pricing
            updatedPitch.images = allImageURLs
            
            // 5. Firebase güncelle
            loadingMessage = "Kaydediliyor..."
            try await adminService.updatePitch(updatedPitch, facilityId: facilityId)
            
            saveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Delete Pitch
    func deletePitch() async {
        guard let pitchId = pitch.id else { return }
        
        isLoading = true
        loadingMessage = "Saha siliniyor..."
        
        do {
            // Fotoğrafları sil
            try await storageService.deletePitchImages(facilityId: facilityId, pitchId: pitchId)
            
            // Sahayı sil
            try await adminService.deletePitch(pitchId: pitchId, facilityId: facilityId)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - Preview
#Preview {
    EditPitchView(pitch: Pitch.mockPitch, facilityId: "facility123")
}

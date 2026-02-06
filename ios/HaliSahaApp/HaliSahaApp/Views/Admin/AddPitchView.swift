//
//  AddPitchView.swift
//  HaliSahaApp
//
//  Yeni Saha Ekleme Formu
//
//  Created by Mehmet Mert Mazıcı on 25.01.2026.
//

import SwiftUI
import PhotosUI

// MARK: - Add Pitch View
struct AddPitchView: View {
    
    // MARK: - Properties
    let facilityId: String
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddPitchViewModel
    
    // MARK: - Init
    init(facilityId: String) {
        self.facilityId = facilityId
        _viewModel = StateObject(wrappedValue: AddPitchViewModel(facilityId: facilityId))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // Fotoğraflar - YENİ SECTION
                imagesSection
                
                // Temel Bilgiler
                basicInfoSection
                
                // Saha Özellikleri
                pitchPropertiesSection
                
                // Fiyatlandırma
                pricingSection
            }
            .navigationTitle("Yeni Saha")
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
                            await viewModel.savePitch()
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
    
    // MARK: - Images Section (YENİ)
    private var imagesSection: some View {
        Section {
            MultiImagePicker(
                selectedImages: $viewModel.selectedImages,
                maxImages: 3,
                title: "Saha Fotoğrafları"
            )
        } header: {
            Text("Fotoğraflar")
        } footer: {
            Text("Sahanın fotoğraflarını ekleyin (opsiyonel).")
        }
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        Section {
            TextField("Saha Adı", text: $viewModel.name)
                .textInputAutocapitalization(.words)
            
            TextField("Açıklama (Opsiyonel)", text: $viewModel.description, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text("Temel Bilgiler")
        } footer: {
            Text("Örn: Saha A, 1 Nolu Saha, Kapalı Saha")
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
                    VStack(alignment: .leading) {
                        Text(size.displayName)
                        Text(size.dimensions)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(size)
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
                Text("Örnek Hesaplama:")
                    .fontWeight(.medium)
                Text("Akşam saatinde hafta sonu: \(calculateExamplePrice()) ₺/saat")
                Text("Kapora: \(calculateExampleDeposit()) ₺")
            }
            .font(.caption)
        }
    }
    
    // MARK: - Helpers
    private func calculateExamplePrice() -> String {
        let price = viewModel.eveningPrice * viewModel.weekendMultiplier
        return String(format: "%.0f", price)
    }
    
    private func calculateExampleDeposit() -> String {
        let price = viewModel.eveningPrice * viewModel.weekendMultiplier
        let deposit = price * viewModel.depositPercentage
        return String(format: "%.0f", deposit)
    }
}

// MARK: - Add Pitch ViewModel
@MainActor
final class AddPitchViewModel: ObservableObject {
    
    // Facility
    let facilityId: String
    
    // Images - YENİ
    @Published var selectedImages: [UIImage] = []
    
    // Basic Info
    @Published var name = ""
    @Published var description = ""
    
    // Properties
    @Published var pitchType: PitchType = .outdoor
    @Published var surfaceType: SurfaceType = .syntheticGrass
    @Published var size: PitchSize = .fiveASide
    @Published var capacity: Int = 14
    
    // Pricing
    @Published var daytimePrice: Double = 500
    @Published var eveningPrice: Double = 700
    @Published var weekendMultiplier: Double = 1.2
    @Published var depositPercentage: Double = 0.20
    
    // State
    @Published var isLoading = false
    @Published var loadingMessage = "Kaydediliyor..."
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var saveSuccess = false
    
    // Services
    private let adminService = AdminService.shared
    private let storageService = StorageService.shared
    
    // MARK: - Init
    init(facilityId: String) {
        self.facilityId = facilityId
    }
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        daytimePrice > 0 &&
        eveningPrice > 0
    }
    
    // MARK: - Save Pitch
    func savePitch() async {
        isLoading = true
        loadingMessage = "Saha oluşturuluyor..."
        
        let pricing = PitchPricing(
            daytimePrice: daytimePrice,
            eveningPrice: eveningPrice,
            weekendMultiplier: weekendMultiplier,
            depositPercentage: depositPercentage,
            currency: "TRY"
        )
        
        var pitch = Pitch(
            facilityId: facilityId,
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
            pitchType: pitchType,
            surfaceType: surfaceType,
            size: size,
            capacity: capacity,
            images: [],
            pricing: pricing,
            isActive: true
        )
        
        do {
            // Sahayı oluştur
            let pitchId = try await adminService.createPitch(pitch, facilityId: facilityId)
            
            // Fotoğrafları yükle
            if !selectedImages.isEmpty {
                loadingMessage = "Fotoğraflar yükleniyor..."
                
                let imageURLs = try await storageService.uploadPitchImages(
                    selectedImages,
                    facilityId: facilityId,
                    pitchId: pitchId
                )
                
                // Saha belgesini fotoğraf URL'leriyle güncelle
                loadingMessage = "Tamamlanıyor..."
                try await adminService.updatePitchImages(
                    pitchId: pitchId,
                    facilityId: facilityId,
                    images: imageURLs
                )
            }
            
            saveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - Preview
#Preview {
    AddPitchView(facilityId: "facility123")
}

//
//  EditFacilityView.swift
//  HaliSahaApp
//
//  Tesis Düzenleme Formu
//
//  Created by Mehmet Mert Mazıcı on 25.01.2026.
//

import SwiftUI
import MapKit
import PhotosUI

// MARK: - Edit Facility View
struct EditFacilityView: View {
    
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditFacilityViewModel
    
    // MARK: - Init
    init(facility: Facility) {
        _viewModel = StateObject(wrappedValue: EditFacilityViewModel(facility: facility))
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
                
                // İletişim
                contactSection
                
                // Konum
                locationSection
                
                // Özellikler
                amenitiesSection
                
                // Çalışma Saatleri
                operatingHoursSection
                
                // Tehlikeli Bölge
                dangerZone
            }
            .navigationTitle("Tesisi Düzenle")
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
                            await viewModel.updateFacility()
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
            .alert("Tesisi Sil", isPresented: $viewModel.showDeleteConfirm) {
                Button("İptal", role: .cancel) {}
                Button("Sil", role: .destructive) {
                    Task {
                        await viewModel.deleteFacility()
                        dismiss()
                    }
                }
            } message: {
                Text("Bu tesisi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
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
            .sheet(isPresented: $viewModel.showLocationPicker) {
                LocationPickerView(
                    coordinate: $viewModel.coordinate,
                    address: $viewModel.address
                )
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
            Text("Pasif tesisler müşterilere gösterilmez.")
        }
    }
    
    // MARK: - Images Section (YENİ)
    private var imagesSection: some View {
        Section {
            MultiImagePicker(
                selectedImages: $viewModel.newImages,
                existingImageURLs: $viewModel.existingImages,
                maxImages: 5,
                title: "Tesis Fotoğrafları"
            )
        } header: {
            Text("Fotoğraflar")
        } footer: {
            Text("Silinen fotoğraflar kalıcı olarak kaldırılacaktır.")
        }
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        Section("Temel Bilgiler") {
            TextField("Tesis Adı", text: $viewModel.name)
            
            TextField("Vergi Numarası", text: $viewModel.taxNumber)
                .keyboardType(.numberPad)
            
            TextEditor(text: $viewModel.description)
                .frame(minHeight: 80)
        }
    }
    
    // MARK: - Contact Section
    private var contactSection: some View {
        Section("İletişim") {
            TextField("Telefon", text: $viewModel.phone)
                .keyboardType(.phonePad)
            
            TextField("E-posta (Opsiyonel)", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
        }
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        Section("Konum") {
            TextField("Adres", text: $viewModel.address, axis: .vertical)
                .lineLimit(2...4)
            
            Button {
                viewModel.showLocationPicker = true
            } label: {
                Map(position: $viewModel.mapPosition, interactionModes: []) {
                    Marker(viewModel.name, coordinate: viewModel.coordinate)
                        .tint(Color(hex: "2E7D32"))
                }
                .frame(height: 150)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "2E7D32").opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.caption2)
                                Text("Konumu değiştirmek için tıklayın")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .padding(8)
                        }
                    }
                )
            }
            .buttonStyle(.plain)
            
            Button {
                viewModel.useCurrentLocation()
            } label: {
                Label("Mevcut Konumu Kullan", systemImage: "location.fill")
            }
        }
    }
    
    // MARK: - Amenities Section
    private var amenitiesSection: some View {
        Section("Özellikler") {
            Toggle(isOn: $viewModel.amenities.hasParking) {
                Label("Otopark", systemImage: "car.fill")
            }
            
            Toggle(isOn: $viewModel.amenities.hasShower) {
                Label("Duş", systemImage: "drop.fill")
            }
            
            Toggle(isOn: $viewModel.amenities.hasLockerRoom) {
                Label("Soyunma Odası", systemImage: "door.left.hand.closed")
            }
            
            Toggle(isOn: $viewModel.amenities.hasCafe) {
                Label("Kafe/Büfe", systemImage: "cup.and.saucer.fill")
            }
            
            Toggle(isOn: $viewModel.amenities.hasEquipmentRental) {
                Label("Ekipman Kiralama", systemImage: "sportscourt")
            }
            
            Toggle(isOn: $viewModel.amenities.isIndoor) {
                Label("Kapalı Alan", systemImage: "house.fill")
            }
            
            Toggle(isOn: $viewModel.amenities.hasLighting) {
                Label("Aydınlatma", systemImage: "lightbulb.fill")
            }
            
            Toggle(isOn: $viewModel.amenities.hasHeating) {
                Label("Isıtma", systemImage: "flame.fill")
            }
            
            Toggle(isOn: $viewModel.amenities.hasWifi) {
                Label("Wi-Fi", systemImage: "wifi")
            }
        }
        .tint(Color(hex: "2E7D32"))
    }
    
    // MARK: - Operating Hours Section
    private var operatingHoursSection: some View {
        Section("Çalışma Saatleri") {
            OperatingHourEditRow(
                day: "Pazartesi",
                openTime: $viewModel.mondayOpen,
                closeTime: $viewModel.mondayClose
            )
            
            OperatingHourEditRow(
                day: "Salı",
                openTime: $viewModel.tuesdayOpen,
                closeTime: $viewModel.tuesdayClose
            )
            
            OperatingHourEditRow(
                day: "Çarşamba",
                openTime: $viewModel.wednesdayOpen,
                closeTime: $viewModel.wednesdayClose
            )
            
            OperatingHourEditRow(
                day: "Perşembe",
                openTime: $viewModel.thursdayOpen,
                closeTime: $viewModel.thursdayClose
            )
            
            OperatingHourEditRow(
                day: "Cuma",
                openTime: $viewModel.fridayOpen,
                closeTime: $viewModel.fridayClose
            )
            
            OperatingHourEditRow(
                day: "Cumartesi",
                openTime: $viewModel.saturdayOpen,
                closeTime: $viewModel.saturdayClose
            )
            
            OperatingHourEditRow(
                day: "Pazar",
                openTime: $viewModel.sundayOpen,
                closeTime: $viewModel.sundayClose
            )
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
                    Label("Tesisi Sil", systemImage: "trash.fill")
                    Spacer()
                }
            }
        } header: {
            Text("Tehlikeli Bölge")
        } footer: {
            Text("Tesisi silmek tüm sahaları ve geçmiş rezervasyonları da silecektir.")
        }
    }
}

// MARK: - Edit Facility ViewModel
@MainActor
final class EditFacilityViewModel: ObservableObject {
    
    // Original
    let facility: Facility
    
    // Images - YENİ
    @Published var newImages: [UIImage] = []
    @Published var existingImages: [String] = []
    private var originalImages: [String] = []
    
    // Basic Info
    @Published var name: String
    @Published var taxNumber: String
    @Published var description: String
    
    // Contact
    @Published var phone: String
    @Published var email: String
    
    // Location
    @Published var address: String
    @Published var coordinate: CLLocationCoordinate2D {
        didSet {
            mapPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
    @Published var mapPosition: MapCameraPosition
    
    // Status
    @Published var isActive: Bool
    
    // Amenities
    @Published var amenities: FacilityAmenities
    
    // Operating Hours
    @Published var mondayOpen: String
    @Published var mondayClose: String
    @Published var tuesdayOpen: String
    @Published var tuesdayClose: String
    @Published var wednesdayOpen: String
    @Published var wednesdayClose: String
    @Published var thursdayOpen: String
    @Published var thursdayClose: String
    @Published var fridayOpen: String
    @Published var fridayClose: String
    @Published var saturdayOpen: String
    @Published var saturdayClose: String
    @Published var sundayOpen: String
    @Published var sundayClose: String
    
    // State
    @Published var isLoading = false
    @Published var loadingMessage = "Kaydediliyor..."
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var saveSuccess = false
    @Published var showDeleteConfirm = false
    @Published var showLocationPicker = false
    
    // Services
    private let adminService = AdminService.shared
    private let storageService = StorageService.shared
    private let locationManager = LocationManager.shared
    
    // MARK: - Init
    init(facility: Facility) {
        self.facility = facility
        
        // Images
        self.existingImages = facility.images
        self.originalImages = facility.images
        
        // Basic Info
        self.name = facility.name
        self.taxNumber = facility.taxNumber
        self.description = facility.description
        
        // Contact
        self.phone = facility.phone
        self.email = facility.email ?? ""
        
        // Location
        self.address = facility.address
        let coord = CLLocationCoordinate2D(latitude: facility.latitude, longitude: facility.longitude)
        self.coordinate = coord
        self.mapPosition = .region(MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
        
        // Status
        self.isActive = facility.isActive
        
        // Amenities
        self.amenities = facility.amenities
        
        // Operating Hours
        self.mondayOpen = facility.operatingHours.mondayOpen
        self.mondayClose = facility.operatingHours.mondayClose
        self.tuesdayOpen = facility.operatingHours.tuesdayOpen
        self.tuesdayClose = facility.operatingHours.tuesdayClose
        self.wednesdayOpen = facility.operatingHours.wednesdayOpen
        self.wednesdayClose = facility.operatingHours.wednesdayClose
        self.thursdayOpen = facility.operatingHours.thursdayOpen
        self.thursdayClose = facility.operatingHours.thursdayClose
        self.fridayOpen = facility.operatingHours.fridayOpen
        self.fridayClose = facility.operatingHours.fridayClose
        self.saturdayOpen = facility.operatingHours.saturdayOpen
        self.saturdayClose = facility.operatingHours.saturdayClose
        self.sundayOpen = facility.operatingHours.sundayOpen
        self.sundayClose = facility.operatingHours.sundayClose
    }
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !taxNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        (existingImages.count + newImages.count) > 0 // En az 1 fotoğraf
    }
    
    // MARK: - Update Facility
    func updateFacility() async {
        guard let facilityId = facility.id else {
            errorMessage = "Tesis ID bulunamadı"
            showError = true
            return
        }
        
        isLoading = true
        loadingMessage = "Güncelleniyor..."
        
        // Değişen alanları tespit et
        let nameChanged = facility.name != name.trimmingCharacters(in: .whitespaces)
        let phoneChanged = facility.phone != phone.trimmingCharacters(in: .whitespaces)
        let addressChanged = facility.address != address.trimmingCharacters(in: .whitespaces)
        
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
                let newURLs = try await storageService.uploadFacilityImages(newImages, facilityId: facilityId)
                allImageURLs.append(contentsOf: newURLs)
            }
            
            // 3. Operating Hours
            let operatingHours = OperatingHours(
                mondayOpen: mondayOpen,
                mondayClose: mondayClose,
                tuesdayOpen: tuesdayOpen,
                tuesdayClose: tuesdayClose,
                wednesdayOpen: wednesdayOpen,
                wednesdayClose: wednesdayClose,
                thursdayOpen: thursdayOpen,
                thursdayClose: thursdayClose,
                fridayOpen: fridayOpen,
                fridayClose: fridayClose,
                saturdayOpen: saturdayOpen,
                saturdayClose: saturdayClose,
                sundayOpen: sundayOpen,
                sundayClose: sundayClose
            )
            
            // 4. Güncellenmiş tesis
            var updatedFacility = facility
            updatedFacility.name = name.trimmingCharacters(in: .whitespaces)
            updatedFacility.description = description.trimmingCharacters(in: .whitespaces)
            updatedFacility.taxNumber = taxNumber.trimmingCharacters(in: .whitespaces)
            updatedFacility.phone = phone.trimmingCharacters(in: .whitespaces)
            updatedFacility.email = email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces)
            updatedFacility.address = address.trimmingCharacters(in: .whitespaces)
            updatedFacility.latitude = coordinate.latitude
            updatedFacility.longitude = coordinate.longitude
            updatedFacility.amenities = amenities
            updatedFacility.operatingHours = operatingHours
            updatedFacility.isActive = isActive
            updatedFacility.images = allImageURLs
            
            // 5. Firebase güncelle
            loadingMessage = "Kaydediliyor..."
            try await adminService.updateFacility(updatedFacility)
            
            // 6. Denormalized data güncelle
            if nameChanged || phoneChanged || addressChanged {
                try await adminService.updateDenormalizedFacilityData(
                    facilityId: facilityId,
                    newName: nameChanged ? updatedFacility.name : nil,
                    newPhone: phoneChanged ? updatedFacility.phone : nil,
                    newAddress: addressChanged ? updatedFacility.address : nil
                )
            }
            
            saveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Delete Facility
    func deleteFacility() async {
        guard let facilityId = facility.id else { return }
        
        isLoading = true
        loadingMessage = "Tesis siliniyor..."
        
        do {
            // Fotoğrafları sil
            try await storageService.deleteFacilityImages(facilityId: facilityId)
            
            // TODO: Firebase'den tesisi sil
            // try await adminService.deleteFacility(facilityId: facilityId)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Use Current Location
    func useCurrentLocation() {
        if let location = locationManager.userLocation {
            coordinate = location
            mapPosition = .region(MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            locationManager.requestPermission()
        }
    }
}

// MARK: - Preview
#Preview {
    EditFacilityView(facility: Facility.mockFacility)
}

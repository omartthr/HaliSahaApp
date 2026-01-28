//
//  AddFacilityView.swift
//  HaliSahaApp
//
//  Yeni Tesis Ekleme Formu
//
//  Created by Mehmet Mert Mazıcı on 25.01.2026.
//


import SwiftUI
import MapKit
import PhotosUI

// MARK: - Add Facility View
struct AddFacilityView: View {
    
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddFacilityViewModel()
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
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
            }
            .navigationTitle("Yeni Tesis")
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
                            await viewModel.saveFacility()
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
            .sheet(isPresented: $viewModel.showLocationPicker) {
                LocationPickerView(
                    coordinate: $viewModel.coordinate,
                    address: $viewModel.address
                )
            }
        }
    }
    
    // MARK: - Images Section (YENİ)
    private var imagesSection: some View {
        Section {
            MultiImagePicker(
                selectedImages: $viewModel.selectedImages,
                maxImages: 5,
                title: "Tesis Fotoğrafları"
            )
        } header: {
            Text("Fotoğraflar")
        } footer: {
            Text("Tesisinizin fotoğraflarını ekleyin. İlk fotoğraf kapak resmi olarak kullanılacaktır.")
        }
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        Section {
            TextField("Tesis Adı", text: $viewModel.name)
            
            TextField("Vergi Numarası", text: $viewModel.taxNumber)
                .keyboardType(.numberPad)
            
            TextEditor(text: $viewModel.description)
                .frame(minHeight: 80)
                .overlay(alignment: .topLeading) {
                    if viewModel.description.isEmpty {
                        Text("Tesis hakkında açıklama...")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
        } header: {
            Text("Temel Bilgiler")
        } footer: {
            Text("Tesis adı ve vergi numarası zorunludur.")
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
        Section {
            TextField("Adres", text: $viewModel.address, axis: .vertical)
                .lineLimit(2...4)
            
            // Mini Harita - Tıklanabilir
            Button {
                viewModel.showLocationPicker = true
            } label: {
                Map(position: $viewModel.mapPosition, interactionModes: []) {
                    Marker(viewModel.name.isEmpty ? "Tesis Konumu" : viewModel.name, coordinate: viewModel.coordinate)
                        .tint(Color(hex: "2E7D32"))
                }
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "2E7D32").opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    // Tap to select indicator
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.caption2)
                                Text("Konum seçmek için tıklayın")
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
        } header: {
            Text("Konum")
        } footer: {
            Text("Haritaya tıklayarak konum seçebilir veya mevcut konumunuzu kullanabilirsiniz.")
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
            
            Toggle(isOn: $viewModel.amenities.hasFirstAid) {
                Label("İlk Yardım", systemImage: "cross.case.fill")
            }
            
            Toggle(isOn: $viewModel.amenities.hasShuttleService) {
                Label("Servis", systemImage: "bus.fill")
            }
            
            Toggle(isOn: $viewModel.amenities.hasVideoRecording) {
                Label("Video Kayıt", systemImage: "video.fill")
            }
        }
        .tint(Color(hex: "2E7D32"))
    }
    
    // MARK: - Operating Hours Section
    private var operatingHoursSection: some View {
        Section {
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
            
            Button("Tüm Günleri Aynı Yap") {
                viewModel.applyToAllDays()
            }
            .foregroundColor(Color(hex: "2E7D32"))
        } header: {
            Text("Çalışma Saatleri")
        }
    }
}

// MARK: - Add Facility ViewModel
@MainActor
final class AddFacilityViewModel: ObservableObject {
    
    // Images - YENİ
    @Published var selectedImages: [UIImage] = []
    
    // Basic Info
    @Published var name = ""
    @Published var taxNumber = ""
    @Published var description = ""
    
    // Contact
    @Published var phone = ""
    @Published var email = ""
    
    // Location
    @Published var address = ""
    @Published var coordinate = CLLocationCoordinate2D(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude
    ) {
        didSet {
            mapPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
    @Published var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: AppConstants.defaultLatitude,
            longitude: AppConstants.defaultLongitude
        ),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    ))
    @Published var showLocationPicker = false
    
    // Amenities
    @Published var amenities = FacilityAmenities()
    
    // Operating Hours
    @Published var mondayOpen = "09:00"
    @Published var mondayClose = "23:00"
    @Published var tuesdayOpen = "09:00"
    @Published var tuesdayClose = "23:00"
    @Published var wednesdayOpen = "09:00"
    @Published var wednesdayClose = "23:00"
    @Published var thursdayOpen = "09:00"
    @Published var thursdayClose = "23:00"
    @Published var fridayOpen = "09:00"
    @Published var fridayClose = "23:00"
    @Published var saturdayOpen = "09:00"
    @Published var saturdayClose = "00:00"
    @Published var sundayOpen = "09:00"
    @Published var sundayClose = "22:00"
    
    // State
    @Published var isLoading = false
    @Published var loadingMessage = "Kaydediliyor..."
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var saveSuccess = false
    
    // Services
    private let adminService = AdminService.shared
    private let storageService = StorageService.shared
    private let locationManager = LocationManager.shared
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !taxNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedImages.isEmpty // En az 1 fotoğraf zorunlu
    }
    
    // MARK: - Save Facility
    func saveFacility() async {
        isLoading = true
        loadingMessage = "Tesis oluşturuluyor..."
        
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
        
        // Önce tesisi oluştur (fotoğrafsız)
        var facility = Facility(
            ownerId: FirebaseService.shared.currentUserId ?? "",
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            taxNumber: taxNumber.trimmingCharacters(in: .whitespaces),
            phone: phone.trimmingCharacters(in: .whitespaces),
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces),
            address: address.trimmingCharacters(in: .whitespaces),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            images: [],
            amenities: amenities,
            operatingHours: operatingHours,
            status: .pending
        )
        
        do {
            // Tesisi oluştur
            let facilityId = try await adminService.createFacility(facility)
            
            // Fotoğrafları yükle
            if !selectedImages.isEmpty {
                loadingMessage = "Fotoğraflar yükleniyor..."
                
                let imageURLs = try await storageService.uploadFacilityImages(
                    selectedImages,
                    facilityId: facilityId
                )
                
                // Tesis belgesini fotoğraf URL'leriyle güncelle
                loadingMessage = "Tamamlanıyor..."
                try await adminService.updateFacilityImages(facilityId: facilityId, images: imageURLs)
            }
            
            saveSuccess = true
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
    
    // MARK: - Apply To All Days
    func applyToAllDays() {
        tuesdayOpen = mondayOpen
        tuesdayClose = mondayClose
        wednesdayOpen = mondayOpen
        wednesdayClose = mondayClose
        thursdayOpen = mondayOpen
        thursdayClose = mondayClose
        fridayOpen = mondayOpen
        fridayClose = mondayClose
        saturdayOpen = mondayOpen
        saturdayClose = mondayClose
        sundayOpen = mondayOpen
        sundayClose = mondayOpen
    }
}

// MARK: - Operating Hour Row (Editable)
struct OperatingHourEditRow: View {
    let day: String
    @Binding var openTime: String
    @Binding var closeTime: String
    
    private let times = stride(from: 0, to: 24, by: 1).map { hour in
        String(format: "%02d:00", hour)
    }
    
    var body: some View {
        HStack {
            Text(day)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Picker("Açılış", selection: $openTime) {
                ForEach(times, id: \.self) { time in
                    Text(time).tag(time)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            
            Text("-")
                .foregroundColor(.secondary)
            
            Picker("Kapanış", selection: $closeTime) {
                ForEach(times, id: \.self) { time in
                    Text(time).tag(time)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }
}

// MARK: - Preview
#Preview {
    AddFacilityView()
}

//
//  AdminFacilitiesView.swift
//  HaliSahaApp
//
//  Admin Tesis Yönetimi
//
//  Created by Mehmet Mert Mazıcı on 24.01.2026.
//

import SwiftUI

// MARK: - Admin Facilities View
struct AdminFacilitiesView: View {
    
    @StateObject private var viewModel = AdminFacilitiesViewModel()
    @State private var showAddFacility = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Tesisler yükleniyor...")
                        .padding()
                } else if viewModel.facilities.isEmpty {
                    // Boş durum
                    VStack(spacing: 16) {
                        Image(systemName: "sportscourt")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Henüz Tesis Eklemediniz")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("İlk tesisinizi ekleyerek başlayın")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            showAddFacility = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Tesis Ekle")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "2E7D32"))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(viewModel.facilities) { facility in
                        NavigationLink {
                            AdminFacilityDetailView(facility: facility)
                        } label: {
                            AdminFacilityListCard(facility: facility)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Add Button (eğer tesis varsa)
                if !viewModel.facilities.isEmpty {
                    Button {
                        showAddFacility = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Yeni Tesis Ekle")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Color(hex: "2E7D32"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "2E7D32"), style: StrokeStyle(lineWidth: 2, dash: [8]))
                        )
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Tesislerim")
        .sheet(isPresented: $showAddFacility) {
            AddFacilityView()
        }
        .refreshable {
            await viewModel.refreshFacilities()
        }
        .alert("Hata", isPresented: $viewModel.showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            await viewModel.loadFacilities()
        }
    }
}

// MARK: - Admin Facilities ViewModel
@MainActor
final class AdminFacilitiesViewModel: ObservableObject {
    @Published var facilities: [Facility] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let adminService = AdminService.shared
    
    func loadFacilities() async {
        isLoading = true
        errorMessage = ""
        
        do {
            facilities = try await adminService.fetchMyFacilities()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            facilities = [] // Hata durumunda boş liste
        }
        
        isLoading = false
    }
    
    func refreshFacilities() async {
        await loadFacilities()
    }
}

// MARK: - Admin Facility List Card
struct AdminFacilityListCard: View {
    let facility: Facility
    
    @State private var showFullScreenImages = false
    @State private var selectedImageIndex = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                // Facility Image - Güncellendi
                CompactImageGallery(
                    images: facility.images,
                    size: 70,
                    placeholder: "sportscourt.fill"
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(facility.name)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(facility.status.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(facility.status.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(facility.status.color.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Text(facility.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(facility.formattedRating)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "text.bubble")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(facility.totalReviews)")
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Quick Stats
            HStack(spacing: 0) {
                QuickStat(value: "2", label: "Saha", icon: "sportscourt")
                
                Divider()
                    .frame(height: 30)
                
                QuickStat(value: "24", label: "Bu Ay", icon: "calendar")
                
                Divider()
                    .frame(height: 30)
                
                QuickStat(value: "12.5K", label: "Gelir", icon: "turkishlirasign")
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8)
    }
}

struct QuickStat: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Admin Facility Detail View
struct AdminFacilityDetailView: View {
    
    let facility: Facility
    @StateObject private var viewModel: AdminFacilityDetailViewModel
    
    // Sheet States
    @State private var showEditFacility = false
    @State private var showAddPitch = false
    @State private var showEditPitch = false
    @State private var showEditHours = false
    @State private var selectedPitchForEdit: Pitch?
    
    init(facility: Facility) {
        self.facility = facility
        _viewModel = StateObject(wrappedValue: AdminFacilityDetailViewModel(facility: facility))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Fotoğraf Galerisi - YENİ
                imageGallerySection
                
                // Facility Info Card
                facilityInfoCard
                
                // Quick Actions
                quickActions
                
                // Pitches Section
                pitchesSection
                
                // Stats Section
                statsSection
                
                // Operating Hours
                operatingHoursSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(facility.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEditFacility = true
                } label: {
                    Text("Düzenle")
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }
        }
        // MARK: - Sheets
        .sheet(isPresented: $showEditFacility) {
            EditFacilityView(facility: facility)
        }
        .sheet(isPresented: $showAddPitch) {
            AddPitchView(facilityId: facility.id ?? "")
        }
        .sheet(isPresented: $showEditPitch) {
            if let pitch = selectedPitchForEdit {
                EditPitchView(pitch: pitch, facilityId: facility.id ?? "")
            }
        }
        .sheet(isPresented: $showEditHours) {
            OperatingHoursEditSheet(facility: facility) {
                // Refresh after save
                Task {
                    await viewModel.loadPitches()
                }
            }
        }
        .task {
            await viewModel.loadPitches()
        }
        // selectedPitchForEdit değiştiğinde sheet'i aç
        .onChange(of: selectedPitchForEdit) { _, newValue in
            if newValue != nil {
                showEditPitch = true
            }
        }
    }
    
    // MARK: - Image Gallery Section (YENİ)
    private var imageGallerySection: some View {
        ImageGalleryView(
            images: facility.images,
            height: 220,
            cornerRadius: 16,
            placeholder: "sportscourt.fill"
        )
    }
    
    // MARK: - Facility Info Card
    private var facilityInfoCard: some View {
        VStack(spacing: 16) {
            // Info - Fotoğraf kısmı kaldırıldı, galeri ayrı section oldu
            VStack(alignment: .leading, spacing: 12) {
                // Status Badge
                HStack {
                    Text(facility.status.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(facility.status.color)
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    // Rating
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                        Text(facility.formattedRating)
                            .fontWeight(.semibold)
                        Text("(\(facility.totalReviews))")
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
                
                // Address
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(Color(hex: "2E7D32"))
                    Text(facility.address)
                        .font(.subheadline)
                }
                
                // Phone
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(Color(hex: "2E7D32"))
                    Text(facility.phone)
                        .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Quick Actions
    private var quickActions: some View {
        HStack(spacing: 12) {
            NavigationLink {
                AdminBookingsView()
            } label: {
                AdminActionButton(
                    icon: "list.clipboard",
                    title: "Rezervasyonlar",
                    color: .blue
                )
            }
            
            NavigationLink {
                AdminReportsView()
            } label: {
                AdminActionButton(
                    icon: "chart.bar",
                    title: "Raporlar",
                    color: .purple
                )
            }
            
            Button {
                // QR Scanner
            } label: {
                AdminActionButton(
                    icon: "qrcode.viewfinder",
                    title: "QR Tara",
                    color: Color(hex: "2E7D32")
                )
            }
        }
    }
    
    // MARK: - Pitches Section
    private var pitchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sahalar")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showAddPitch = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Ekle")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "2E7D32"))
                }
            }
            
            ForEach(viewModel.pitches) { pitch in
                PitchManagementCard(pitch: pitch) {
                    // Edit pitch - Sheet'i aç
                    selectedPitchForEdit = pitch
                } onDelete: {
                    Task {
                        await viewModel.deletePitch(pitch)
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bu Ay İstatistikler")
                .font(.headline)
            
            HStack(spacing: 12) {
                StatBox(
                    title: "Rezervasyon",
                    value: "24",
                    change: "+12%",
                    isPositive: true
                )
                
                StatBox(
                    title: "Gelir",
                    value: "12.5K ₺",
                    change: "+8%",
                    isPositive: true
                )
            }
            
            HStack(spacing: 12) {
                StatBox(
                    title: "Doluluk",
                    value: "%68",
                    change: "+5%",
                    isPositive: true
                )
                
                StatBox(
                    title: "İptal",
                    value: "3",
                    change: "-2",
                    isPositive: true
                )
            }
        }
    }
    
    // MARK: - Operating Hours Section
    private var operatingHoursSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Çalışma Saatleri")
                    .font(.headline)
                
                Spacer()
                
                Button("Düzenle") {
                    showEditHours = true
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "2E7D32"))
            }
            
            VStack(spacing: 8) {
                OperatingHourRow(day: "Pazartesi - Cuma", hours: "\(facility.operatingHours.mondayOpen) - \(facility.operatingHours.mondayClose)")
                OperatingHourRow(day: "Cumartesi", hours: "\(facility.operatingHours.saturdayOpen) - \(facility.operatingHours.saturdayClose)")
                OperatingHourRow(day: "Pazar", hours: "\(facility.operatingHours.sundayOpen) - \(facility.operatingHours.sundayClose)")
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Operating Hours Edit Sheet
struct OperatingHoursEditSheet: View {
    
    let facility: Facility
    var onSave: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: OperatingHoursEditViewModel
    
    init(facility: Facility, onSave: (() -> Void)? = nil) {
        self.facility = facility
        self.onSave = onSave
        _viewModel = StateObject(wrappedValue: OperatingHoursEditViewModel(facility: facility))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Hafta İçi") {
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
                }
                
                Section("Hafta Sonu") {
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
                
                Section {
                    Button("Tüm Günleri Aynı Yap") {
                        viewModel.applyToAllDays()
                    }
                    .foregroundColor(Color(hex: "2E7D32"))
                }
            }
            .navigationTitle("Çalışma Saatleri")
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
                            await viewModel.saveHours()
                            onSave?()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.isLoading)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }
            }
            .alert("Hata", isPresented: $viewModel.showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Operating Hours Edit ViewModel
@MainActor
final class OperatingHoursEditViewModel: ObservableObject {
    
    private let facility: Facility
    private let adminService = AdminService.shared
    
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
    @Published var showError = false
    @Published var errorMessage = ""
    
    init(facility: Facility) {
        self.facility = facility
        
        // Mevcut saatleri yükle
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
        sundayClose = mondayClose
    }
    
    func saveHours() async {
        guard let facilityId = facility.id else {
            errorMessage = "Tesis ID bulunamadı"
            showError = true
            return
        }
        
        isLoading = true
        
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
        
        var updatedFacility = facility
        updatedFacility.operatingHours = operatingHours
        updatedFacility.updatedAt = Date()
        
        do {
            try await adminService.updateFacility(updatedFacility)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - Admin Facility Detail ViewModel
@MainActor
final class AdminFacilityDetailViewModel: ObservableObject {
    
    @Published var pitches: [Pitch] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let facility: Facility
    private let adminService = AdminService.shared
    
    init(facility: Facility) {
        self.facility = facility
    }
    
    func loadPitches() async {
        guard let facilityId = facility.id else { return }
        
        isLoading = true
        
        do {
            pitches = try await adminService.fetchPitches(for: facilityId)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            pitches = []
        }
        
        isLoading = false
    }
    
    func deletePitch(_ pitch: Pitch) async {
        guard let pitchId = pitch.id, let facilityId = facility.id else { return }
        
        do {
            try await adminService.deletePitch(pitchId: pitchId, facilityId: facilityId)
            await loadPitches() // Listeyi yenile
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Supporting Views

struct AdminActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 8)
    }
}

struct PitchManagementCard: View {
    let pitch: Pitch
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Pitch Image - YENİ
            CompactImageGallery(
                images: pitch.images,
                size: 60,
                placeholder: "sportscourt"
            )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(pitch.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Status Badge
                    Text(pitch.isActive ? "Aktif" : "Pasif")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(pitch.isActive ? Color(hex: "2E7D32") : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pitch.isActive ? Color(hex: "2E7D32").opacity(0.1) : Color(.systemGray5))
                        .cornerRadius(8)
                }
                
                HStack(spacing: 8) {
                    Label(pitch.size.displayName, systemImage: "person.2")
                    Label(pitch.pitchType.displayName, systemImage: pitch.pitchType == .indoor ? "house" : "sun.max")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Text("\(pitch.pricing.daytimePrice.asShortCurrency) - \(pitch.pricing.eveningPrice.asShortCurrency)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "2E7D32"))
            }
            
            Spacer()
            
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Düzenle", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Sil", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                Text(change)
                    .font(.caption)
            }
            .foregroundColor(isPositive ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct OperatingHourRow: View {
    let day: String
    let hours: String
    
    var body: some View {
        HStack {
            Text(day)
                .font(.subheadline)
            Spacer()
            Text(hours)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "2E7D32"))
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AdminFacilitiesView()
    }
}

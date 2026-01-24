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
                ForEach(viewModel.facilities) { facility in
                    NavigationLink {
                        AdminFacilityDetailView(facility: facility)
                    } label: {
                        AdminFacilityListCard(facility: facility)
                    }
                    .buttonStyle(.plain)
                }
                
                // Add Button
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
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Tesislerim")
        .sheet(isPresented: $showAddFacility) {
            AddFacilityView()
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
    
    private let adminService = AdminService.shared
    
    func loadFacilities() async {
        isLoading = true
        facilities = adminService.loadMockAdminFacilities()
        isLoading = false
    }
}

// MARK: - Admin Facility List Card
struct AdminFacilityListCard: View {
    let facility: Facility
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "2E7D32").opacity(0.1))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "sportscourt.fill")
                        .font(.title)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
                
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
    @State private var showEditFacility = false
    @State private var showAddPitch = false
    
    init(facility: Facility) {
        self.facility = facility
        _viewModel = StateObject(wrappedValue: AdminFacilityDetailViewModel(facility: facility))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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
        .sheet(isPresented: $showEditFacility) {
            EditFacilityView(facility: facility)
        }
        .sheet(isPresented: $showAddPitch) {
            AddPitchView(facilityId: facility.id ?? "")
        }
        .task {
            await viewModel.loadPitches()
        }
    }
    
    // MARK: - Facility Info Card
    private var facilityInfoCard: some View {
        VStack(spacing: 16) {
            // Image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "2E7D32"), Color(hex: "1B5E20")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 150)
                
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.3))
                
                // Status Badge
                VStack {
                    HStack {
                        Spacer()
                        Text(facility.status.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(facility.status.color)
                            .cornerRadius(20)
                            .padding()
                    }
                    Spacer()
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(Color(hex: "2E7D32"))
                    Text(facility.address)
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(Color(hex: "2E7D32"))
                    Text(facility.phone)
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                    Text("\(facility.formattedRating) (\(facility.totalReviews) değerlendirme)")
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
                    // Edit pitch
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
                    // Edit hours
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "2E7D32"))
            }
            
            VStack(spacing: 8) {
                OperatingHourRow(day: "Pazartesi - Cuma", hours: "09:00 - 23:00")
                OperatingHourRow(day: "Cumartesi", hours: "08:00 - 00:00")
                OperatingHourRow(day: "Pazar", hours: "08:00 - 22:00")
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Admin Facility Detail ViewModel
@MainActor
final class AdminFacilityDetailViewModel: ObservableObject {
    
    @Published var pitches: [Pitch] = []
    @Published var isLoading = false
    
    private let facility: Facility
    private let adminService = AdminService.shared
    
    init(facility: Facility) {
        self.facility = facility
    }
    
    func loadPitches() async {
        // Mock pitches
        pitches = [
            Pitch(
                id: "pitch1",
                facilityId: facility.id ?? "",
                name: "Saha 1",
                description: "Ana saha",
                pitchType: .outdoor,
                surfaceType: .syntheticGrass,
                size: .fiveASide,
                capacity: 10,
                pricing: PitchPricing(daytimePrice: 500, eveningPrice: 650)
            ),
            Pitch(
                id: "pitch2",
                facilityId: facility.id ?? "",
                name: "Saha 2",
                description: "Kapalı saha",
                pitchType: .indoor,
                surfaceType: .syntheticGrass,
                size: .fiveASide,
                capacity: 10,
                pricing: PitchPricing(daytimePrice: 600, eveningPrice: 750)
            )
        ]
    }
    
    func deletePitch(_ pitch: Pitch) async {
        guard let pitchId = pitch.id, let facilityId = facility.id else { return }
        try? await adminService.deletePitch(pitchId: pitchId, facilityId: facilityId)
        await loadPitches()
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
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(pitch.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
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

// MARK: - Placeholder Views
struct AddFacilityView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Yeni Tesis Formu")
                .navigationTitle("Yeni Tesis")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("İptal") { dismiss() }
                    }
                }
        }
    }
}

struct EditFacilityView: View {
    let facility: Facility
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Tesis Düzenleme Formu")
                .navigationTitle("Tesisi Düzenle")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("İptal") { dismiss() }
                    }
                }
        }
    }
}

struct AddPitchView: View {
    let facilityId: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Yeni Saha Formu")
                .navigationTitle("Yeni Saha")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("İptal") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AdminFacilitiesView()
    }
}

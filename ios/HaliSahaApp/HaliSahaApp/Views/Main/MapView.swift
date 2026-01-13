//
//  MapView.swift
//  HaliSahaApp
//
//  Harita Görünümü - MapKit entegrasyonu
//
//  Created by Mehmet Mert Mazıcı on 1.01.2026.
//

import SwiftUI
import MapKit

// MARK: - Map View
struct MapView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var locationManager = LocationManager.shared
    
    @State private var selectedAnnotation: FacilityAnnotation?
    @Namespace private var mapScope
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Map
            mapContent
            
            // Overlay Controls
            VStack {
                // Top Bar
                topBar
                
                Spacer()
                
                // Bottom Controls
                bottomControls
            }
            .padding(.bottom, 8) 
            
            // Facility Detail Sheet
            if viewModel.showFacilityDetail, let facility = viewModel.selectedFacility {
                facilityDetailSheet(facility: facility)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $viewModel.showListView) {
            FacilityListSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showFilters) {
            FilterSheet(filters: $viewModel.filters)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .task {
            await viewModel.loadFacilities()
        }
        .onAppear {
            locationManager.requestPermission()
        }
    }
    
    // MARK: - Map Content
    private var mapContent: some View {
        Map(position: $viewModel.mapCameraPosition, scope: mapScope) {
            // User Location
            UserAnnotation()
            
            // Facility Annotations
            ForEach(viewModel.annotations) { annotation in
                Annotation(
                    annotation.facility.name,
                    coordinate: annotation.coordinate,
                    anchor: .bottom
                ) {
                    FacilityMapPin(
                        facility: annotation.facility,
                        isSelected: viewModel.selectedFacility?.id == annotation.facility.id
                    )
                    .onTapGesture {
                        viewModel.selectFacility(annotation.facility)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass(scope: mapScope)
            MapScaleView(scope: mapScope)
        }
        .mapScope(mapScope)
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack(spacing: 12) {
                // Search Field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Saha ara...", text: $viewModel.searchText)
                        .textInputAutocapitalization(.never)
                    
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(.regularMaterial)
                .cornerRadius(12)
                
                // Filter Button
                Button {
                    viewModel.showFilters = true
                } label: {
                    Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(viewModel.hasActiveFilters ? Color(hex: "2E7D32") : .primary)
                        .padding(12)
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.top, 60)
            
            // Sonuç sayısıı
            if viewModel.hasActiveFilters {
                HStack {
                    Text("\(viewModel.filteredFacilities.count) saha bulundu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Temizle") {
                        viewModel.clearFilters()
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "2E7D32"))
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        HStack(spacing: 12) {
            // List View Toggle
            Button {
                viewModel.toggleViewMode()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                    Text("Liste")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial)
                .cornerRadius(25)
            }
            
            Spacer()
            
            // Location Button
            Button {
                viewModel.centerOnUserLocation()
            } label: {
                Image(systemName: locationManager.isAuthorized ? "location.fill" : "location")
                    .font(.title3)
                    .foregroundColor(locationManager.isAuthorized ? Color(hex: "2E7D32") : .primary)
                    .padding(14)
                    .background(.regularMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 16) // Tab bar için boşluk
    }
    
    // MARK: - Facility Detail Sheet
    private func facilityDetailSheet(facility: Facility) -> some View {
        VStack {
            Spacer()
            
            FacilityMapCard(
                facility: facility,
                distance: viewModel.distanceString(for: facility),
                onClose: {
                    viewModel.selectFacility(nil)
                },
                onNavigate: {
                    openInMaps(facility: facility)
                }
            )
            .padding(.horizontal)
            .padding(.bottom, 100)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showFacilityDetail)
    }
    
    // MARK: - Open in Maps
    private func openInMaps(facility: Facility) {
        let coordinate = CLLocationCoordinate2D(
            latitude: facility.latitude,
            longitude: facility.longitude
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = facility.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Facility Map Pin
struct FacilityMapPin: View {
    
    let facility: Facility
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Pin Head
            ZStack {
                Circle()
                    .fill(isSelected ? Color(hex: "2E7D32") : .white)
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: isSelected ? 20 : 16))
                    .foregroundColor(isSelected ? .white : Color(hex: "2E7D32"))
            }
            
            // Pin Tail
            Triangle()
                .fill(isSelected ? Color(hex: "2E7D32") : .white)
                .frame(width: 12, height: 8)
                .offset(y: -2)
        }
        .animation(.spring(response: 0.2), value: isSelected)
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Facility Map Card
struct FacilityMapCard: View {
    
    let facility: Facility
    let distance: String
    var onClose: () -> Void
    var onNavigate: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            HStack(spacing: 12) {
                // Image Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "2E7D32").opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(hex: "2E7D32").opacity(0.5))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(facility.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(facility.formattedRating)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("(\(facility.totalReviews))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(distance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Amenities
                    HStack(spacing: 6) {
                        ForEach(facility.amenities.activeAmenities.prefix(4), id: \.name) { amenity in
                            Text(amenity.icon)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    
                    
                    Button(action: onNavigate) {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.title)
                            .foregroundColor(Color(hex: "2E7D32"))
                    }
                }
            }
            .padding(16)
            
            // Detail Button
            NavigationLink {
                FacilityDetailPlaceholder(facility: facility)
            } label: {
                Text("Detayları Gör")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "2E7D32"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: -5)
    }
}

// MARK: - Facility List Sheet
struct FacilityListSheet: View {
    
    @ObservedObject var viewModel: MapViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredFacilities) { facility in
                        NavigationLink {
                            FacilityDetailPlaceholder(facility: facility)
                        } label: {
                            FacilityCard(
                                facility: facility,
                                showDistance: true,
                                distance: viewModel.facilitiesWithDistance.first { $0.facility.id == facility.id }?.distance
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Sahalar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Harita") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            // Mesafeye göre sırala
                        } label: {
                            Label("Mesafeye Göre", systemImage: "location")
                        }
                        
                        Button {
                            // Puana göre sırala
                        } label: {
                            Label("Puana Göre", systemImage: "star")
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {
    
    @Binding var filters: FacilityFilters
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                // Saha Türü
                Section("Saha Türü") {
                    Picker("Tür", selection: Binding(
                        get: { filters.isIndoor },
                        set: { filters.isIndoor = $0 }
                    )) {
                        Text("Tümü").tag(nil as Bool?)
                        Text("Kapalı").tag(true as Bool?)
                        Text("Açık").tag(false as Bool?)
                    }
                    .pickerStyle(.segmented)
                }
                
                // Minimum Puan
                Section("Minimum Puan") {
                    Picker("Puan", selection: Binding(
                        get: { filters.minRating ?? 0 },
                        set: { filters.minRating = $0 == 0 ? nil : $0 }
                    )) {
                        Text("Tümü").tag(0.0)
                        Text("4.0+").tag(4.0)
                        Text("4.5+").tag(4.5)
                    }
                    .pickerStyle(.segmented)
                }
                
                // Özellikler
                Section("Özellikler") {
                    Toggle(isOn: $filters.hasParking) {
                        Label("Otopark", systemImage: "car.fill")
                    }
                    
                    Toggle(isOn: $filters.hasShower) {
                        Label("Duş", systemImage: "drop.fill")
                    }
                    
                    Toggle(isOn: $filters.hasCafe) {
                        Label("Kafe", systemImage: "cup.and.saucer.fill")
                    }
                    
                    Toggle(isOn: $filters.hasEquipmentRental) {
                        Label("Ekipman Kiralama", systemImage: "sportscourt")
                    }
                }
                .tint(Color(hex: "2E7D32"))
            }
            .navigationTitle("Filtrele")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Temizle") {
                        filters.reset()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Uygula") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MapView()
    }
}

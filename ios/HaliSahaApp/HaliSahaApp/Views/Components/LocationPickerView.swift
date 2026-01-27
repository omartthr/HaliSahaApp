//
//  LocationPickerView.swift
//  HaliSahaApp
//
//  Harita üzerinden konum seçme view'ı
//
//  Created by Mehmet Mert Mazıcı on 26.01.2026.
//

import SwiftUI
import MapKit

// MARK: - Location Picker View
struct LocationPickerView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Binding var coordinate: CLLocationCoordinate2D
    @Binding var address: String
    
    @State private var cameraPosition: MapCameraPosition
    @State private var centerCoordinate: CLLocationCoordinate2D
    @State private var isDragging = false
    @State private var isLoadingAddress = false
    
    init(coordinate: Binding<CLLocationCoordinate2D>, address: Binding<String>) {
        self._coordinate = coordinate
        self._address = address
        
        let initialCoordinate = coordinate.wrappedValue
        self._centerCoordinate = State(initialValue: initialCoordinate)
        self._cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }
    
    var body: some View {
        ZStack {
            // Map
            MapReader { proxy in
                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                    UserAnnotation()
                }
                .mapStyle(.standard(elevation: .realistic))
                .onTapGesture { position in
                    if let tappedCoordinate = proxy.convert(position, from: .local) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            centerCoordinate = tappedCoordinate
                            cameraPosition = .region(MKCoordinateRegion(
                                center: tappedCoordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            ))
                        }
                    }
                }
            }
            
            // Center Pin (sabit, haritanın ortasında)
            VStack {
                Spacer()
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Color(hex: "2E7D32"))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(y: -22) // Pin'in ucu tam ortada olsun
                Spacer()
            }
            
            // Top Bar
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Konum Seç")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        selectLocation()
                    } label: {
                        if isLoadingAddress {
                            ProgressView()
                                .tint(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(hex: "2E7D32"))
                                .cornerRadius(20)
                        } else {
                            Text("Seç")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(hex: "2E7D32"))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                    .disabled(isLoadingAddress)
                }
                .padding()
                .background(.ultraThinMaterial)
                
                Spacer()
            }
            
            // Bottom Info
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Koordinat bilgisi
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(Color(hex: "2E7D32"))
                        
                        Text(String(format: "%.5f, %.5f", centerCoordinate.latitude, centerCoordinate.longitude))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("Haritayı kaydırın veya dokunarak konum seçin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Mevcut konuma git butonu
                    Button {
                        if let userLocation = LocationManager.shared.userLocation {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                centerCoordinate = userLocation
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: userLocation,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                ))
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Mevcut Konumum")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "2E7D32"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(hex: "2E7D32").opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onMapCameraChange(frequency: .onEnd) { context in
            centerCoordinate = context.region.center
        }
    }
    
    // MARK: - Select Location
    private func selectLocation() {
        isLoadingAddress = true
        coordinate = centerCoordinate
        
        // Reverse geocoding ile adres al
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isLoadingAddress = false
                
                if let placemark = placemarks?.first {
                    // Türkiye formatında adres oluştur
                    var addressComponents: [String] = []
                    
                    if let thoroughfare = placemark.thoroughfare {
                        addressComponents.append(thoroughfare)
                    }
                    if let subThoroughfare = placemark.subThoroughfare {
                        if !addressComponents.isEmpty {
                            addressComponents[0] = "\(addressComponents[0]) No: \(subThoroughfare)"
                        }
                    }
                    if let subLocality = placemark.subLocality {
                        addressComponents.append(subLocality)
                    }
                    if let locality = placemark.locality {
                        addressComponents.append(locality)
                    }
                    if let administrativeArea = placemark.administrativeArea {
                        if administrativeArea != placemark.locality {
                            addressComponents.append(administrativeArea)
                        }
                    }
                    
                    if !addressComponents.isEmpty {
                        address = addressComponents.joined(separator: ", ")
                    }
                }
                
                dismiss()
            }
        }
    }
}

//
//  FacilityDetailView.swift
//  HaliSahaApp
//
//  Saha Detay Ekranı
//
//  Created by Mehmet Mert Mazıcı on 13.01.2026.
//

import MapKit
import SwiftUI

// MARK: - Facility Detail View
struct FacilityDetailView: View {

    // MARK: - Properties
    @StateObject private var viewModel: FacilityDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showFullDescription = false
    @State private var showAllAmenities = false
    @State private var showGuestAlert = false

    // MARK: - Init
    init(facility: Facility) {
        _viewModel = StateObject(wrappedValue: FacilityDetailViewModel(facility: facility))
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image - Güncellendi
                heroSection

                VStack(spacing: 24) {
                    // Header Info
                    headerSection

                    Divider()

                    // Pitches Section
                    pitchesSection

                    Divider()

                    // Date Selection & Time Slots - Only show if pitches exist
                    if viewModel.hasPitches {
                        // Date Selection
                        dateSelectionSection

                        // Time Slots
                        timeSlotsSection

                        Divider()
                    }

                    // Amenities
                    amenitiesSection

                    Divider()

                    // Location
                    locationSection

                    Divider()

                    // Reviews Summary
                    reviewsSummarySection
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Share
                    Button {
                        shareVenue()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }

                    // Favorite
                    Button {
                        Task {
                            await viewModel.toggleFavorite()
                        }
                    } label: {
                        Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.isFavorite ? .red : .primary)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }

        .alert("Üye Girişi Gerekli", isPresented: $showGuestAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Rezervasyon yapmak için üye girişi yapmanız gerekiyor.")
        }
        .navigationDestination(isPresented: $viewModel.showBookingFlow) {
            BookingFlowView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Hero Section - Güncellendi
    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            // Fotoğraf Galerisi
            ImageGalleryView(
                images: viewModel.facility.images,
                height: 280,
                cornerRadius: 0,
                placeholder: "sportscourt.fill"
            )

            // Gradient overlay for back button
            LinearGradient(
                colors: [.black.opacity(0.5), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: 120)

            // Top Bar - Back Button Only
            HStack {
                // Back Button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }

                Spacer()
            }
            .padding()
            .padding(.top, 44)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Name
            Text(viewModel.facility.name)
                .font(.title2)
                .fontWeight(.bold)

            // Address
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color(hex: "2E7D32"))
                Text(viewModel.facility.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Phone
            HStack(spacing: 6) {
                Image(systemName: "phone.fill")
                    .foregroundColor(Color(hex: "2E7D32"))
                Text(viewModel.facility.phone)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Description
            if !viewModel.facility.description.isEmpty {
                Text(viewModel.facility.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(showFullDescription ? nil : 2)

                if viewModel.facility.description.count > 100 {
                    Button(showFullDescription ? "Daha az" : "Devamını oku") {
                        withAnimation {
                            showFullDescription.toggle()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "2E7D32"))
                }
            }

            // Tags
            HStack(spacing: 8) {
                if viewModel.facility.amenities.isIndoor {
                    TagView(text: "Kapalı Alan", icon: "house.fill")
                } else {
                    TagView(text: "Açık Alan", icon: "sun.max.fill")
                }

                if viewModel.facility.amenities.hasParking {
                    TagView(text: "Otopark", icon: "car.fill", style: .outlined)
                }
            }
        }
    }

    // MARK: - Pitches Section
    private var pitchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sahalar")
                .font(.headline)

            if viewModel.hasPitches {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.pitches) { pitch in
                            PitchSelectionCard(
                                pitch: pitch,
                                isSelected: viewModel.selectedPitch?.id == pitch.id
                            ) {
                                viewModel.selectPitch(pitch)
                            }
                        }
                    }
                }
            } else {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "sportscourt")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("Henüz saha bilgisi eklenmemiş")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Bu tesis henüz saha detaylarını sisteme tanımlamamış.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    // Call Button
                    Button {
                        if let url = URL(string: "tel:\(viewModel.facility.phone)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Bilgi için ara")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(hex: "2E7D32"))
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Date Selection Section
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tarih Seçin")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<14, id: \.self) { dayOffset in
                        let date = Calendar.current.date(
                            byAdding: .day, value: dayOffset, to: Date())!
                        DateSelectionButton(
                            date: date,
                            isSelected: Calendar.current.isDate(
                                date, inSameDayAs: viewModel.selectedDate)
                        ) {
                            viewModel.selectDate(date)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Time Slots Section
    private var timeSlotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saat Seçin")
                    .font(.headline)

                Spacer()

                if let start = viewModel.selectedStartHour, let end = viewModel.selectedEndHour {
                    Text("\(start.asHourString) - \(end.asHourString)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8
            ) {
                ForEach(viewModel.availableTimeSlots) { slot in
                    TimeSlotButton(
                        slot: slot,
                        isSelected: viewModel.isSlotSelected(slot)
                    ) {
                        viewModel.selectTimeSlot(slot)
                    }
                }
            }

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: Color(hex: "2E7D32"), text: "Seçili")
                LegendItem(color: Color(.systemGray5), text: "Müsait")
                LegendItem(color: Color(.systemGray3), text: "Dolu")
            }
            .font(.caption)
        }
    }

    // MARK: - Amenities Section
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Özellikler")
                .font(.headline)

            let amenities = viewModel.facility.amenities.activeAmenities
            let displayCount = showAllAmenities ? amenities.count : min(6, amenities.count)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(amenities.prefix(displayCount), id: \.name) { amenity in
                    AmenityItem(icon: amenity.icon, name: amenity.name)
                }
            }

            if amenities.count > 6 {
                Button(showAllAmenities ? "Daha az göster" : "Tümünü göster (\(amenities.count))") {
                    withAnimation {
                        showAllAmenities.toggle()
                    }
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "2E7D32"))
            }
        }
    }

    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Konum")
                .font(.headline)

            // Mini Map
            Map(
                position: .constant(
                    .region(
                        MKCoordinateRegion(
                            center: viewModel.facility.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )))
            ) {
                Marker(viewModel.facility.name, coordinate: viewModel.facility.coordinate)
                    .tint(Color(hex: "2E7D32"))
            }
            .frame(height: 150)
            .cornerRadius(12)
            .disabled(true)

            // Directions Button
            Button {
                openInMaps()
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    Text("Yol Tarifi Al")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "2E7D32"))
            }
        }
    }

    // MARK: - Reviews Summary Section
    private var reviewsSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Değerlendirmeler")
                    .font(.headline)

                Spacer()

                NavigationLink {
                    // ReviewsListView
                    Text("Değerlendirmeler - ADIM 8'de")
                } label: {
                    Text("Tümü")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }

            HStack(spacing: 16) {
                // Rating
                VStack {
                    Text(viewModel.facility.formattedRating)
                        .font(.system(size: 40, weight: .bold))

                    RatingStarsView(rating: viewModel.facility.averageRating)

                    Text("\(viewModel.facility.totalReviews) değerlendirme")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Rating Bars
                VStack(spacing: 4) {
                    ForEach((1...5).reversed(), id: \.self) { star in
                        RatingBar(star: star, percentage: Double.random(in: 0.1...1.0))
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                if viewModel.hasPitches {
                    // Price Info
                    VStack(alignment: .leading, spacing: 2) {
                        if viewModel.canProceedToBooking {
                            Text(viewModel.totalPrice.asCurrency)
                                .font(.title3)
                                .fontWeight(.bold)

                            Text("\(viewModel.selectedDuration) saat")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Saat seçin")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Book Button
                    PrimaryButton(
                        title: "Rezervasyon Yap",
                        size: .medium,
                        isDisabled: !viewModel.canProceedToBooking,
                        fullWidth: false
                    ) {
                        if viewModel.isGuestUser {
                            showGuestAlert = true
                        } else {
                            viewModel.proceedToBooking()
                        }
                    }
                } else {
                    // No pitches - show contact info
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Saha bilgisi bekleniyor")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Call Button
                    Button {
                        if let url = URL(string: "tel:\(viewModel.facility.phone)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Tesisi Ara")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "2E7D32"))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Actions
    private func shareVenue() {
        let text = "\(viewModel.facility.name) - \(viewModel.facility.address)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController
        {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func openInMaps() {
        let coordinate = viewModel.facility.coordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = viewModel.facility.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Supporting Views

struct PitchSelectionCard: View {
    let pitch: Pitch
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(pitch.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "2E7D32"))
                    }
                }

                Text(pitch.size.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(pitch.pricing.daytimePrice.asShortCurrency)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "2E7D32"))
            }
            .padding(12)
            .frame(width: 140)
            .background(isSelected ? Color(hex: "2E7D32").opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "2E7D32") : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct DateSelectionButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEE"
        return formatter
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayFormatter.string(from: date))
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .secondary)

                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 50, height: 60)
            .background(isSelected ? Color(hex: "2E7D32") : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct TimeSlotButton: View {
    let slot: TimeSlot
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(slot.hour.asHourString)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if slot.price > 0 {
                    Text(slot.price.asShortCurrency)
                        .font(.caption2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(!slot.isAvailable)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(hex: "2E7D32")
        } else if slot.isAvailable {
            return Color(.systemGray6)
        } else {
            return Color(.systemGray4)
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if slot.isAvailable {
            return .primary
        } else {
            return .secondary
        }
    }
}

struct LegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}

struct AmenityItem: View {
    let icon: String
    let name: String

    var body: some View {
        VStack(spacing: 6) {
            Text(icon)
                .font(.title2)
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct RatingBar: View {
    let star: Int
    let percentage: Double

    var body: some View {
        HStack(spacing: 4) {
            Text("\(star)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 12)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))

                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        FacilityDetailView(facility: Facility.mockFacility)
    }
}

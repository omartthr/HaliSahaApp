//
//  FacilityCard.swift
//  HaliSahaApp
//
//  Saha kartı bileşenleri - Liste ve öne çıkan görünümler
//
//  Created by Mehmet Mert Mazıcı on 26.12.2025.
//

import SwiftUI

// MARK: - Facility Card (Liste görünümü)
struct FacilityCard: View {
    
    // MARK: - Properties
    let facility: Facility
    var showDistance: Bool = false
    var distance: Double? = nil
    var onFavoriteToggle: (() -> Void)? = nil
    
    @State private var isFavorite = false
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            // Image
            facilityImage
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                // Name & Rating
                HStack {
                    Text(facility.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Rating
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(facility.formattedRating)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                
                // Address
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(facility.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Amenities Pills
                amenityPills
                
                // Bottom Row: Price & Distance
                HStack {
                    // Price indicator (gerçek fiyat Pitch'ten gelecek)
                    Text("₺₺")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "2E7D32"))
                    
                    if showDistance, let dist = distance {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(String(format: "%.1f km", dist))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Reviews count
                    Text("\(facility.totalReviews) değerlendirme")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Facility Image
    private var facilityImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "2E7D32").opacity(0.1))
                .frame(width: 100, height: 100)
            
            Image(systemName: "sportscourt.fill")
                .font(.system(size: 30))
                .foregroundColor(Color(hex: "2E7D32").opacity(0.5))
            
            // Status badge
            if facility.amenities.isIndoor {
                VStack {
                    HStack {
                        Spacer()
                        Text("Kapalı")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex: "2E7D32"))
                            .cornerRadius(4)
                    }
                    Spacer()
                }
                .padding(6)
            }
        }
        .frame(width: 100, height: 100)
    }
    
    // MARK: - Amenity Pills
    private var amenityPills: some View {
        HStack(spacing: 6) {
            ForEach(facility.amenities.activeAmenities.prefix(3), id: \.name) { amenity in
                HStack(spacing: 2) {
                    Text(amenity.icon)
                        .font(.system(size: 10))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(.systemGray6))
                .cornerRadius(4)
            }
            
            if facility.amenities.activeAmenities.count > 3 {
                Text("+\(facility.amenities.activeAmenities.count - 3)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - Featured Facility Card (Büyük kart - Öne çıkanlar için)
struct FeaturedFacilityCard: View {
    
    let facility: Facility
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                // Placeholder image
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "2E7D32"), Color(hex: "1B5E20")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(height: 140)
                
                // Favorite button
                Button {
                    // Favorite toggle
                } label: {
                    Image(systemName: "heart")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(12)
                
                // Rating badge
                VStack {
                    Spacer()
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text(facility.formattedRating)
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        
                        Spacer()
                    }
                    .padding(12)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(facility.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                    Text(facility.address)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                // Amenities
                HStack(spacing: 8) {
                    ForEach(facility.amenities.activeAmenities.prefix(4), id: \.name) { amenity in
                        Text(amenity.icon)
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 10)
        }
        .frame(width: 260)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Compact Facility Card (Küçük kart - Grid için)
struct CompactFacilityCard: View {
    
    let facility: Facility
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "2E7D32").opacity(0.15))
                
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "2E7D32").opacity(0.5))
            }
            .frame(height: 80)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(facility.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text(facility.formattedRating)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Match Post Card (Oyuncu aranan maç kartı)
struct MatchPostCard: View {
    
    let matchPost: MatchPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Creator avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: "2E7D32").opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Text(String(matchPost.creatorName.prefix(1)))
                        .font(.headline)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(matchPost.creatorName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(matchPost.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Players needed badge
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .font(.caption)
                    Text("\(matchPost.availableSlots) kişi")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "2E7D32"))
                .cornerRadius(20)
            }
            
            // Title
            Text(matchPost.title)
                .font(.headline)
                .lineLimit(2)
            
            // Match Info
            HStack(spacing: 16) {
                // Location
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(matchPost.facilityName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Time
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(matchPost.timeSlot)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Bottom Row
            HStack {
                // Skill Level
                HStack(spacing: 4) {
                    Text(matchPost.skillLevel.icon)
                        .font(.caption)
                    Text(matchPost.skillLevel.displayName)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // Cost
                if let cost = matchPost.formattedCostPerPlayer {
                    Text(cost)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }
            
            // Progress Bar (Players)
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "2E7D32"))
                            .frame(width: geometry.size.width * CGFloat(matchPost.currentPlayers) / CGFloat(matchPost.maxPlayers), height: 6)
                    }
                }
                .frame(height: 6)
                
                Text("\(matchPost.currentPlayers)/\(matchPost.maxPlayers) oyuncu")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview("Facility Card") {
    VStack(spacing: 16) {
        FacilityCard(
            facility: Facility.mockFacility,
            showDistance: true,
            distance: 2.5
        )
        
        FacilityCard(facility: Facility.mockFacility)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Featured Card") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            FeaturedFacilityCard(facility: Facility.mockFacility)
            FeaturedFacilityCard(facility: Facility.mockFacility)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Match Post Card") {
    MatchPostCard(matchPost: MatchPost.mockPost)
        .padding()
        .background(Color(.systemGroupedBackground))
}

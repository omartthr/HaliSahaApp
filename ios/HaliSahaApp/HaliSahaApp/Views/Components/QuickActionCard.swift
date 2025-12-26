//
//  QuickActionCard.swift
//  HaliSahaApp
//
//  Created by Mehmet Mert Mazıcı on 26.12.2025.
//

//
//  QuickActionCard.swift
//  HaliSaha
//
//  Hızlı erişim kartları ve diğer yardımcı UI bileşenleri
//

import SwiftUI

// MARK: - Quick Action Card
struct QuickActionCard: View {
    
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    
    let title: String
    let value: String
    let icon: String
    let color: Color
    var trend: String? = nil
    var trendUp: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trendUp ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(trend)
                            .font(.caption)
                    }
                    .foregroundColor(trendUp ? .green : .red)
                }
            }
            
            // Value
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Info Banner
struct InfoBanner: View {
    
    enum BannerType {
        case info
        case success
        case warning
        case error
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }
    
    let type: BannerType
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(type.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(type.color)
                    }
                }
            }
            
            Spacer()
            
            if let dismiss = onDismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }
        }
        .padding(16)
        .background(type.color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Tag View
struct TagView: View {
    
    let text: String
    var icon: String? = nil
    var color: Color = Color(hex: "2E7D32")
    var style: TagStyle = .filled
    
    enum TagStyle {
        case filled
        case outlined
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundColor(style == .filled ? .white : color)
        .background(
            Capsule()
                .fill(style == .filled ? color : color.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(style == .outlined ? color : .clear, lineWidth: 1)
        )
    }
}

// MARK: - Rating Stars View
struct RatingStarsView: View {
    
    let rating: Double
    let maxRating: Int = 5
    var size: CGFloat = 14
    var color: Color = .orange
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: starType(for: index))
                    .font(.system(size: size))
                    .foregroundColor(color)
            }
        }
    }
    
    private func starType(for index: Int) -> String {
        let rating = self.rating
        if Double(index) <= rating {
            return "star.fill"
        } else if Double(index) - 0.5 <= rating {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

// MARK: - Avatar View
struct AvatarView: View {
    
    var imageURL: String? = nil
    var name: String
    var size: CGFloat = 44
    var backgroundColor: Color = Color(hex: "2E7D32").opacity(0.1)
    var textColor: Color = Color(hex: "2E7D32")
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
            
            if let imageURL = imageURL, !imageURL.isEmpty {
                // AsyncImage için placeholder
                // Gerçek implementasyonda AsyncImage kullanılacak
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(textColor)
            } else {
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(textColor)
            }
        }
    }
}

// MARK: - Divider with Text
struct DividerWithText: View {
    
    let text: String
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }
}

// MARK: - Badge View
struct BadgeView: View {
    
    let count: Int
    var maxCount: Int = 99
    var backgroundColor: Color = .red
    var textColor: Color = .white
    var size: CGFloat = 18
    
    var body: some View {
        if count > 0 {
            Text(count > maxCount ? "\(maxCount)+" : "\(count)")
                .font(.system(size: size * 0.6, weight: .bold))
                .foregroundColor(textColor)
                .frame(minWidth: size, minHeight: size)
                .padding(.horizontal, count > 9 ? 4 : 0)
                .background(backgroundColor)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview
#Preview("Quick Actions") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            QuickActionCard(
                title: "Saha Bul",
                subtitle: "Yakındaki sahaları keşfet",
                icon: "magnifyingglass",
                color: Color(hex: "2E7D32")
            )
            
            QuickActionCard(
                title: "Maç Kur",
                subtitle: "Arkadaşlarınla maç organize et",
                icon: "person.3.fill",
                color: .blue
            )
        }
        
        HStack(spacing: 12) {
            StatsCard(
                title: "Toplam Maç",
                value: "24",
                icon: "sportscourt.fill",
                color: Color(hex: "2E7D32"),
                trend: "+3",
                trendUp: true
            )
            
            StatsCard(
                title: "Bu Ay",
                value: "5",
                icon: "calendar",
                color: .blue
            )
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Other Components") {
    VStack(spacing: 20) {
        InfoBanner(
            type: .info,
            message: "Yeni özellikler eklendi! Şimdi takım kurabilirsiniz.",
            actionTitle: "Keşfet",
            action: {},
            onDismiss: {}
        )
        
        InfoBanner(
            type: .warning,
            message: "Maçınıza 2 saat kaldı!",
            onDismiss: {}
        )
        
        HStack(spacing: 8) {
            TagView(text: "Kapalı Alan", icon: "house.fill")
            TagView(text: "4.8", icon: "star.fill", style: .outlined)
            TagView(text: "Otopark", color: .blue, style: .outlined)
        }
        
        HStack {
            RatingStarsView(rating: 4.5)
            Text("4.5")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        
        HStack(spacing: 12) {
            AvatarView(name: "Ahmet Yılmaz")
            AvatarView(name: "Mehmet", size: 56)
            AvatarView(name: "Ali", size: 32, backgroundColor: .blue.opacity(0.1), textColor: .blue)
        }
        
        DividerWithText(text: "veya")
        
        HStack(spacing: 16) {
            BadgeView(count: 3)
            BadgeView(count: 12)
            BadgeView(count: 150)
        }
    }
    .padding()
}

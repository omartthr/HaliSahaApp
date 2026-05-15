//
//  ReviewCard.swift
//  HaliSahaApp
//
//  Tek bir yorumu gösteren yeniden kullanılabilir kart bileşeni.
//

import SwiftUI

// MARK: - Review Card
struct ReviewCard: View {
    let review: Review

    /// Detaylı modda 5 satıra kadar yorum gösterir (daha uzunsa "Devamını oku")
    var showsExpandToggle: Bool = true

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Üst: avatar + isim + tarih + yıldızlar
            headerRow

            // Yorum metni
            if let comment = review.comment, !comment.isEmpty {
                commentBlock(comment)
            }
        }
        .padding(14)
        .background(Color.appCardBackground)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
    }

    // MARK: - Header
    private var headerRow: some View {
        HStack(alignment: .top, spacing: 12) {
            avatar
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(review.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    if review.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "2E7D32"))
                            .help("Gerçek rezervasyon sonrası yorum")
                    }
                }

                HStack(spacing: 6) {
                    starsRow
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(review.relativeDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let url = review.userProfileImage, !url.isEmpty {
            CachedAsyncImage(
                url: url,
                targetSize: CGSize(width: 88, height: 88)
            ) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                avatarPlaceholder
            }
            .clipShape(Circle())
        } else {
            avatarPlaceholder
                .clipShape(Circle())
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "4CAF50"), Color(hex: "2E7D32")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(initials)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var initials: String {
        let parts = review.userName
            .split(separator: " ")
            .prefix(2)
        let chars = parts.compactMap { $0.first }.map(String.init)
        let result = chars.joined().uppercased()
        return result.isEmpty ? "?" : result
    }

    // MARK: - Stars
    private var starsRow: some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starIcon(for: star))
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            }

            Text(String(format: "%.1f", review.overallRating))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.leading, 4)
        }
    }

    private func starIcon(for star: Int) -> String {
        let r = review.overallRating
        let s = Double(star)
        if r >= s { return "star.fill" }
        if r >= s - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }

    // MARK: - Comment
    @ViewBuilder
    private func commentBlock(_ comment: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(comment)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(showsExpandToggle && !isExpanded ? 5 : nil)
                .fixedSize(horizontal: false, vertical: true)

            if showsExpandToggle && comment.count > 250 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Daha az" : "Devamını oku")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview
#Preview("Verified") {
    ReviewCard(review: Review.mockReview)
        .padding()
        .background(Color.appBackground)
}

#Preview("Multiple") {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(Review.mockReviews) { review in
                ReviewCard(review: review)
            }
        }
        .padding()
    }
    .background(Color.appBackground)
}

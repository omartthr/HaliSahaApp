//
//  ReviewsListView.swift
//  HaliSahaApp
//
//  Bir tesisin tüm değerlendirmelerini listeleyen ekran.
//

import SwiftUI

// MARK: - Reviews List View
struct ReviewsListView: View {

    // MARK: - Inputs
    let facility: Facility

    // MARK: - State
    @StateObject private var viewModel: ReviewsViewModel
    @StateObject private var authService = AuthService.shared
    @State private var pendingDelete: Review?

    init(facility: Facility) {
        self.facility = facility
        _viewModel = StateObject(wrappedValue: ReviewsViewModel(facility: facility))
    }

    // MARK: - Body
    var body: some View {
        SwiftUI.Group {
            if viewModel.isLoading && viewModel.reviews.isEmpty {
                LoadingView()
            } else if viewModel.reviews.isEmpty {
                EmptyStateView(
                    icon: "text.bubble",
                    title: "Henüz Değerlendirme Yok",
                    message:
                        "Bu sahaya henüz kimse yorum yapmamış. Maçtan sonra ilk değerlendirmeyi sen yapabilirsin."
                )
            } else {
                content
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Değerlendirmeler")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .alert(
            "Yorumu Sil",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )
        ) {
            Button("Vazgeç", role: .cancel) { pendingDelete = nil }
            Button("Sil", role: .destructive) {
                if let review = pendingDelete {
                    Task {
                        await viewModel.deleteReview(review)
                        pendingDelete = nil
                    }
                }
            }
        } message: {
            Text("Bu yorumu kalıcı olarak silmek istediğinden emin misin?")
        }
        .alert("Hata", isPresented: $viewModel.showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Content
    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 14, pinnedViews: []) {
                summaryHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                ForEach(viewModel.reviews) { review in
                    ReviewCard(review: review)
                        .padding(.horizontal, 16)
                        .contextMenu {
                            if review.userId == authService.currentUser?.id {
                                Button(role: .destructive) {
                                    pendingDelete = review
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                        }
                }
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Summary Header
    private var summaryHeader: some View {
        HStack(alignment: .center, spacing: 20) {
            // Sol: ortalama puan
            VStack(spacing: 4) {
                Text(String(format: "%.1f", viewModel.averageRating))
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.primary)

                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: starIcon(for: star, average: viewModel.averageRating))
                            .font(.system(size: 13))
                            .foregroundColor(.orange)
                    }
                }

                Text("\(viewModel.reviews.count) değerlendirme")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 110)

            // Sağ: yıldız dağılımı çubukları
            VStack(spacing: 6) {
                ForEach((1...5).reversed(), id: \.self) { star in
                    RatingDistributionRow(
                        star: star,
                        count: viewModel.distribution.count(for: star),
                        percentage: viewModel.distribution.percentage(for: star)
                    )
                }
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }

    private func starIcon(for star: Int, average: Double) -> String {
        let s = Double(star)
        if average >= s { return "star.fill" }
        if average >= s - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

// MARK: - Distribution Row
private struct RatingDistributionRow: View {
    let star: Int
    let count: Int
    let percentage: Double

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                Text("\(star)")
                    .font(.caption)
                    .frame(width: 12)
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.orange)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    Capsule()
                        .fill(Color.orange)
                        .frame(width: max(0, geo.size.width * CGFloat(percentage)), height: 6)
                        .animation(.easeInOut(duration: 0.25), value: percentage)
                }
            }
            .frame(height: 6)

            Text("\(count)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 24, alignment: .trailing)
                .monospacedDigit()
        }
    }
}

// MARK: - Reviews View Model
@MainActor
final class ReviewsViewModel: ObservableObject {

    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?

    private let facility: Facility
    private let reviewService = ReviewService.shared

    var averageRating: Double {
        guard !reviews.isEmpty else { return facility.averageRating }
        let sum = reviews.reduce(0.0) { $0 + $1.overallRating }
        return sum / Double(reviews.count)
    }

    var distribution: ReviewDistribution {
        ReviewDistribution(reviews: reviews)
    }

    init(facility: Facility) {
        self.facility = facility
    }

    func load() async {
        guard let id = facility.id else {
            reviews = []
            return
        }

        isLoading = true
        do {
            reviews = try await reviewService.fetchReviews(forFacility: id)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            reviews = []
        }
        isLoading = false
    }

    func deleteReview(_ review: Review) async {
        do {
            try await reviewService.deleteReview(review)
            reviews.removeAll { $0.id == review.id }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ReviewsListView(facility: Facility.mockFacility)
    }
}

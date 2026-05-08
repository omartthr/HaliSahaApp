//
//  WriteReviewView.swift
//  HaliSahaApp
//
//  Tamamlanmış bir rezervasyon için saha değerlendirmesi yazma ekranı.
//

import SwiftUI

// MARK: - Write Review View
struct WriteReviewView: View {

    // MARK: - Inputs
    let booking: Booking

    /// Yorum başarıyla kaydedildiğinde çağrılır (parent listeyi yenilesin).
    var onSubmitted: (() -> Void)?

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared

    // MARK: - State
    @State private var rating: Int = 0
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    private let reviewService = ReviewService.shared
    private let maxCommentLength = AppConstants.maxCommentLength

    // MARK: - Computed
    private var isFormValid: Bool {
        rating > 0 && rating <= 5
    }

    private var commentRemaining: Int {
        maxCommentLength - comment.count
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    bookingSummaryCard
                    ratingCard
                    commentCard
                    submitButton
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Değerlendirme Yaz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Teşekkürler!", isPresented: $showSuccess) {
                Button("Tamam") {
                    onSubmitted?()
                    dismiss()
                }
            } message: {
                Text("Yorumun başarıyla yayınlandı. Diğer kullanıcılar için değerli bir geri bildirim oldu.")
            }
            .interactiveDismissDisabled(isSubmitting)
            .overlay {
                if isSubmitting {
                    LoadingView()
                }
            }
        }
    }

    // MARK: - Booking Summary
    private var bookingSummaryCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "2E7D32").opacity(0.12))
                    .frame(width: 56, height: 56)

                Image(systemName: "sportscourt.fill")
                    .font(.title2)
                    .foregroundColor(Color(hex: "2E7D32"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(booking.facilityName)
                    .font(.headline)
                    .lineLimit(1)

                Text(booking.pitchName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Label(booking.shortDate, systemImage: "calendar")
                    Label(booking.timeSlotString, systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.appCardBackground)
        .cornerRadius(14)
    }

    // MARK: - Rating Card
    private var ratingCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Tesisi Nasıl Buldun?")
                    .font(.headline)

                Text(ratingDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 20)
                    .animation(.easeInOut(duration: 0.15), value: rating)
            }

            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            rating = star
                        }
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 36))
                            .foregroundColor(star <= rating ? .orange : .gray.opacity(0.4))
                            .scaleEffect(star == rating ? 1.15 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.appCardBackground)
        .cornerRadius(14)
    }

    private var ratingDescription: String {
        switch rating {
        case 0: return "Yıldıza dokunarak puan ver"
        case 1: return "😞  Hiç beğenmedim"
        case 2: return "😐  Beklediğim gibi değildi"
        case 3: return "🙂  Fena değildi"
        case 4: return "😊  İyiydi"
        case 5: return "🤩  Mükemmeldi!"
        default: return ""
        }
    }

    // MARK: - Comment Card
    private var commentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Yorumun")
                    .font(.headline)

                Text("(opsiyonel)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(commentRemaining)")
                    .font(.caption2)
                    .foregroundColor(commentRemaining < 0 ? .red : .secondary)
                    .monospacedDigit()
            }

            ZStack(alignment: .topLeading) {
                if comment.isEmpty {
                    Text("Tesis hakkındaki düşüncelerini paylaş…")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $comment)
                    .font(.subheadline)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .onChange(of: comment) { _, newValue in
                        if newValue.count > maxCommentLength {
                            comment = String(newValue.prefix(maxCommentLength))
                        }
                    }
            }
            .padding(8)
            .background(Color.appElevatedBackground)
            .cornerRadius(10)
        }
        .padding(20)
        .background(Color.appCardBackground)
        .cornerRadius(14)
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        VStack(spacing: 8) {
            PrimaryButton(
                title: "Değerlendirmeyi Yayınla",
                icon: "checkmark.circle.fill",
                isLoading: isSubmitting,
                isDisabled: !isFormValid
            ) {
                Task { await submit() }
            }

            Text("Yorumun, sahanın diğer kullanıcılar tarafından doğru tanınmasına yardımcı olur.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Submit
    @MainActor
    private func submit() async {
        guard isFormValid else { return }
        guard let user = authService.currentUser else {
            errorMessage = "Oturumun sona ermiş. Lütfen tekrar giriş yap."
            showError = true
            return
        }

        isSubmitting = true
        do {
            _ = try await reviewService.createReview(
                booking: booking,
                rating: Double(rating),
                comment: comment,
                userFullName: user.fullName,
                userProfileImage: user.profileImageURL
            )
            isSubmitting = false
            showSuccess = true
        } catch {
            isSubmitting = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview
#Preview {
    WriteReviewView(booking: Booking.mockBooking)
}

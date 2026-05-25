//
//  MatchPostApplicantsView.swift
//  HaliSahaApp
//
//  Host'un kendi ilanına başvuran oyuncuları görüp Kabul/Red verdiği ekran.
//  Real-time: ilan dokümanı dinlenir; her kabul/red sonrası liste anında güncellenir.
//

import FirebaseFirestore
import SwiftUI

// MARK: - View
struct MatchPostApplicantsView: View {

    @StateObject private var viewModel: MatchPostApplicantsViewModel

    init(matchPost: MatchPost) {
        _viewModel = StateObject(wrappedValue: MatchPostApplicantsViewModel(matchPost: matchPost))
    }

    var body: some View {
        SwiftUI.Group {
            if viewModel.isInitialLoading {
                LoadingView()
            } else if viewModel.applicants.isEmpty {
                EmptyStateView(
                    icon: "person.crop.circle.badge.questionmark",
                    title: "Bekleyen Başvuru Yok",
                    message: "Yeni başvuranlar burada görünecek. Onay verdiğinde sohbete otomatik eklenirler."
                )
            } else {
                listContent
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Başvuranlar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text("Başvuranlar")
                        .font(.subheadline.weight(.semibold))
                    Text("\(viewModel.applicants.count) bekliyor")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .alert(
            "Hata",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            presenting: viewModel.errorMessage
        ) { _ in
            Button("Tamam") { viewModel.errorMessage = nil }
        } message: { msg in
            Text(msg)
        }
        .confirmationDialog(
            "Bu başvuranı reddetmek istediğine emin misin?",
            isPresented: Binding(
                get: { viewModel.pendingRejectId != nil },
                set: { if !$0 { viewModel.pendingRejectId = nil } }
            ),
            titleVisibility: .visible,
            presenting: viewModel.pendingRejectId
        ) { _ in
            Button("Reddet", role: .destructive) {
                Task { await viewModel.confirmReject() }
            }
            Button("Vazgeç", role: .cancel) {
                viewModel.pendingRejectId = nil
            }
        } message: { _ in
            Text("Başvuran reddedildiğinde bildirim alır ve sohbete eklenmez.")
        }
    }

    // MARK: - List
    private var listContent: some View {
        List {
            ForEach(viewModel.applicants) { applicant in
                ApplicantRow(
                    applicant: applicant,
                    isBusy: viewModel.busyApplicantId == applicant.id,
                    onAccept: {
                        Task { await viewModel.accept(applicant) }
                    },
                    onReject: {
                        viewModel.pendingRejectId = applicant.id
                    }
                )
                .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }
}

// MARK: - Applicant Row
private struct ApplicantRow: View {
    let applicant: User
    let isBusy: Bool
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                avatar
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(applicant.fullName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text(String(format: "%.1f", applicant.reliabilityScore))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)

                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(applicant.preferredPosition.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)
            }

            HStack(spacing: 8) {
                Button(action: onReject) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                        Text("Reddet")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.12))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(isBusy)

                Button(action: onAccept) {
                    HStack(spacing: 6) {
                        if isBusy {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                        }
                        Text("Kabul Et")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "2E7D32"), Color(hex: "1B5E20")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(isBusy)
            }
        }
        .padding(14)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
        .opacity(isBusy ? 0.7 : 1)
    }

    private var avatar: some View {
        SwiftUI.Group {
            if let url = applicant.profileImageURL, !url.isEmpty {
                CachedAsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initialsAvatar
                }
            } else {
                initialsAvatar
            }
        }
        .clipShape(Circle())
    }

    private var initialsAvatar: some View {
        ZStack {
            Circle().fill(Color(hex: "2E7D32").opacity(0.18))
            Text(initials)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: "2E7D32"))
        }
    }

    private var initials: String {
        let parts = applicant.fullName.split(separator: " ")
        let f = parts.first?.first.map(String.init) ?? "?"
        let l = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }
}

// MARK: - ViewModel
@MainActor
final class MatchPostApplicantsViewModel: ObservableObject {

    @Published private(set) var matchPost: MatchPost
    @Published private(set) var applicants: [User] = []
    @Published private(set) var isInitialLoading: Bool = true
    @Published private(set) var busyApplicantId: String?
    @Published var pendingRejectId: String?
    @Published var errorMessage: String?

    private let firebaseService = FirebaseService.shared
    private let matchPostService = MatchPostService.shared
    private var postListener: ListenerRegistration?
    private var userCache: [String: User] = [:]

    init(matchPost: MatchPost) {
        self.matchPost = matchPost
    }

    func start() {
        guard let postId = matchPost.id, postListener == nil else { return }
        postListener = matchPostService.observePost(id: postId) { [weak self] updated in
            Task { @MainActor in
                guard let self else { return }
                if let updated = updated {
                    self.matchPost = updated
                    await self.refreshApplicants()
                }
                self.isInitialLoading = false
            }
        }
    }

    func stop() {
        postListener?.remove()
        postListener = nil
    }

    deinit {
        postListener?.remove()
    }

    // MARK: - Refresh
    private func refreshApplicants() async {
        let ids = matchPost.applicantIds
        guard !ids.isEmpty else {
            applicants = []
            return
        }

        var loaded: [User] = []
        for id in ids {
            if let cached = userCache[id] {
                loaded.append(cached)
                continue
            }
            do {
                let user: User = try await firebaseService.fetchDocument(
                    from: firebaseService.usersCollection,
                    documentId: id
                )
                userCache[id] = user
                loaded.append(user)
            } catch {
                print("⚠️ applicant fetch failed for \(id): \(error.localizedDescription)")
            }
        }
        applicants = loaded
    }

    // MARK: - Actions
    func accept(_ applicant: User) async {
        guard let id = applicant.id else { return }
        busyApplicantId = id
        defer { busyApplicantId = nil }
        do {
            try await matchPostService.acceptApplication(post: matchPost, applicant: applicant)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmReject() async {
        guard let id = pendingRejectId else { return }
        defer { pendingRejectId = nil }
        guard let applicant = applicants.first(where: { $0.id == id }) else { return }

        busyApplicantId = id
        defer { busyApplicantId = nil }
        do {
            try await matchPostService.rejectApplication(post: matchPost, applicant: applicant)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MatchPostApplicantsView(matchPost: .mockPost)
    }
}

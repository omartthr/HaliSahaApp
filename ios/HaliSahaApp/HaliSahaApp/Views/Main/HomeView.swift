//
//  HomeView.swift
//  HaliSaha
//
//  Keşfet Ana Sayfası
//

import SwiftUI

// MARK: - Home View
struct HomeView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var authService = AuthService.shared
    @StateObject private var notificationService = AppNotificationService.shared
    @State private var showNotifications = false
    @State private var showFilters = false
    @State private var showAllFacilities = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Search Bar
                searchSection
                
                // Filter Pills
                filterSection
                
                // Content
                if viewModel.isLoading {
                    loadingSection
                } else {
                    contentSection
                }
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                logoView
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                notificationButton
            }
        }
        .refreshable {
            await viewModel.refreshData()
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsListView()
        }
        .navigationDestination(isPresented: $showAllFacilities) {
            FacilityListView()
        }
    }
    
    // MARK: - Logo View
    private var logoView: some View {
        HStack(spacing: 6) {
            Image(systemName: "sportscourt.fill")
                .font(.title3)
                .foregroundColor(Color(hex: "2E7D32"))
            
            Text(AppConstants.appName)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Notification Button
    private var notificationButton: some View {
        Button {
            showNotifications = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: notificationService.unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
                    .font(.body)
                    .foregroundColor(.primary)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        notificationService.unreadCount > 0 ? Color.red : .primary,
                        Color.primary
                    )

                if notificationService.unreadCount > 0 {
                    Text(badgeText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 16, minHeight: 16)
                        .padding(.horizontal, 4)
                        .background(Capsule().fill(Color.red))
                        .overlay(Capsule().stroke(Color.appCardBackground, lineWidth: 1.5))
                        .offset(x: 8, y: -6)
                }
            }
        }
    }

    private var badgeText: String {
        let count = notificationService.unreadCount
        return count > 99 ? "99+" : "\(count)"
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let user = authService.currentUser {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Merhaba, \(user.firstName) 👋")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Bugün maç yapmaya ne dersin?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // User avatar
                    ZStack {
                        Circle()
                            .fill(Color(hex: "2E7D32").opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Text(String(user.firstName.prefix(1)))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "2E7D32"))
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: 12) {
            // Search Field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.body)
                    .foregroundColor(.gray)
                
                TextField("Saha ara...", text: $viewModel.searchText)
                    .textInputAutocapitalization(.never)
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.appCardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            
            // Filter Button
            Button {
                showFilters.toggle()
            } label: {
                Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(viewModel.hasActiveFilters ? Color(hex: "2E7D32") : .gray)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HomeFilter.allCases) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectFilter(filter)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                CardSkeletonView()
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(spacing: 24) {
            // Featured Section
            if !viewModel.featuredFacilities.isEmpty && viewModel.searchText.isEmpty {
                featuredSection
            }
            
            // Upcoming Matches Section
            if !viewModel.upcomingMatches.isEmpty && viewModel.searchText.isEmpty {
                upcomingMatchesSection
            }
            
            // Nearby/Filtered Facilities Section
            nearbySection
        }
        .padding(.bottom, 100) // Tab bar için boşluk
    }
    
    // MARK: - Featured Section
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Öne Çıkanlar", icon: "star.fill")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.featuredFacilities) { facility in
                        NavigationLink {
                            FacilityDetailView(facility: facility)
                        } label: {
                            FeaturedFacilityCard(facility: facility)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Upcoming Matches Section
    private var upcomingMatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Oyuncu Aranan Maçlar",
                icon: "person.badge.plus",
                actionTitle: "Tümü"
            ) {
                // Tümünü gör
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.upcomingMatches) { matchPost in
                    NavigationLink {
                        MatchPostDetailView(matchPost: matchPost)
                    } label: {
                        MatchPostCard(matchPost: matchPost)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Nearby Section
    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: viewModel.hasActiveFilters ? "Sonuçlar" : "Yakındaki Sahalar",
                icon: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle" : "location.fill",
                actionTitle: viewModel.hasActiveFilters ? "Temizle" : "Tümünü Gör"
            ) {
                if viewModel.hasActiveFilters {
                    viewModel.clearFilters()
                } else {
                    showAllFacilities = true
                }
            }
            
            if viewModel.filteredFacilities.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Saha Bulunamadı",
                    message: "Arama kriterlerinize uygun saha bulunamadı. Filtreleri değiştirmeyi deneyin.",
                    buttonTitle: "Filtreleri Temizle"
                ) {
                    viewModel.clearFilters()
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    // Sadece ilk 5 sahayı göster
                    ForEach(viewModel.filteredFacilities.prefix(5)) { facility in
                        NavigationLink {
                            FacilityDetailView(facility: facility)
                        } label: {
                            FacilityCard(
                                facility: facility,
                                showDistance: true,
                                distance: Double.random(in: 0.5...10.0)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Daha fazla varsa "Tümünü Gör" butonu
                    if viewModel.filteredFacilities.count > 5 {
                        Button {
                            showAllFacilities = true
                        } label: {
                            HStack {
                                Text("Tüm Sahaları Gör (\(viewModel.filteredFacilities.count))")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(Color(hex: "2E7D32"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "2E7D32").opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    
    let title: String
    var icon: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundColor(isSelected ? .white : .primary)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "2E7D32") : Color.appCardBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Match Post Detail View
struct MatchPostDetailView: View {
    let matchPost: MatchPost

    @StateObject private var authService = AuthService.shared
    @State private var hasAppliedLocally = false
    @State private var showApplicationAlert = false

    private let accentColor = Color(hex: "2E7D32")

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroSection
                rosterSection
                facilitySection
                expectationsSection
                organizerSection
                noteSection
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .background(Color.appBackground)
        .navigationTitle("Maç Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(accentColor)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
        .alert("Başvuru Alındı", isPresented: $showApplicationAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Başvurun ilan sahibine iletilmek üzere hazırlandı.")
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.16))
                        .frame(width: 58, height: 58)

                    Image(systemName: "person.3.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 8) {
                    MatchDetailStatusBadge(
                        title: statusTitle,
                        color: statusColor,
                        foregroundColor: .white
                    )

                    Text(matchPost.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    MatchDetailHeroChip(icon: "calendar", title: dateLabel)
                    MatchDetailHeroChip(icon: "clock.fill", title: matchPost.timeSlot)
                }

                HStack(spacing: 10) {
                    MatchDetailHeroChip(icon: "person.badge.plus", title: "\(remainingSlots) kişi aranıyor")
                    MatchDetailHeroChip(icon: "sportscourt.fill", title: matchPost.pitchName)
                }
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color(hex: "1B5E20"), Color(hex: "2E7D32"), Color(hex: "1E6F5C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }

    private var rosterSection: some View {
        MatchDetailSection(title: "Kadro Durumu", icon: "person.3.sequence.fill") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray5))

                            RoundedRectangle(cornerRadius: 6)
                                .fill(accentColor)
                                .frame(width: geometry.size.width * rosterProgress)
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        Text("\(confirmedPlayers)/\(matchPost.maxPlayers) oyuncu")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text(remainingSlots > 0 ? "\(remainingSlots) boş yer" : "Kadro tamam")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(remainingSlots > 0 ? accentColor : .secondary)
                    }
                }

                LazyVGrid(columns: statColumns, spacing: 10) {
                    MatchDetailStatTile(title: "Mevcut", value: "\(matchPost.currentPlayers)", icon: "person.fill")
                    MatchDetailStatTile(title: "Kabul", value: "\(matchPost.acceptedIds.count)", icon: "checkmark.circle.fill")
                    MatchDetailStatTile(title: "Bekleyen", value: "\(matchPost.pendingApplicationsCount)", icon: "hourglass")
                }
            }
        }
    }

    private var facilitySection: some View {
        MatchDetailSection(title: "Tesis Bilgisi", icon: "mappin.and.ellipse") {
            VStack(alignment: .leading, spacing: 14) {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(matchPost.facilityName)
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(matchPost.facilityAddress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } icon: {
                    MatchDetailIconBox(icon: "sportscourt.fill", color: accentColor)
                }

                Divider()

                HStack(spacing: 12) {
                    MatchDetailInfoRow(icon: "calendar", title: "Tarih", value: matchPost.formattedDate)
                    MatchDetailInfoRow(icon: "clock.fill", title: "Saat", value: matchPost.timeSlot)
                }
            }
        }
    }

    private var expectationsSection: some View {
        MatchDetailSection(title: "Oyuncu Beklentisi", icon: "slider.horizontal.3") {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    MatchDetailInfoPill(
                        icon: "chart.bar.fill",
                        title: "Seviye",
                        value: matchPost.skillLevel.displayName,
                        color: .blue
                    )

                    MatchDetailInfoPill(
                        icon: "creditcard.fill",
                        title: "Ücret",
                        value: matchPost.formattedCostPerPlayer ?? "Belirtilmedi",
                        color: .orange
                    )
                }

                if let ageRange = matchPost.ageRange {
                    MatchDetailInfoPill(
                        icon: "person.text.rectangle.fill",
                        title: "Yaş aralığı",
                        value: ageRange.displayName,
                        color: .purple
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Tercih edilen mevkiler")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if preferredPositions.isEmpty {
                        MatchDetailEmptyPill(title: "Mevki fark etmez")
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 8)], spacing: 8) {
                            ForEach(preferredPositions, id: \.self) { position in
                                MatchDetailPositionChip(position: position)
                            }
                        }
                    }
                }
            }
        }
    }

    private var organizerSection: some View {
        MatchDetailSection(title: "İlan Sahibi", icon: "person.crop.circle.badge.checkmark") {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Text(String(matchPost.creatorName.prefix(1)))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(matchPost.creatorName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("İlan \(matchPost.createdAt.shortRelativeTime) oluşturuldu")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var noteSection: some View {
        if let description = matchPost.description, !description.trimmed.isEmpty {
            MatchDetailSection(title: "İlan Notu", icon: "text.alignleft") {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: 8) {
            PrimaryButton(
                title: actionTitle,
                icon: actionIcon,
                isDisabled: isActionDisabled
            ) {
                hasAppliedLocally = true
                showApplicationAlert = true
            }

            Text(actionHint)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private var statColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    }

    private var shareText: String {
        "\(matchPost.title)\n\(matchPost.facilityName) - \(matchPost.formattedDate), \(matchPost.timeSlot)"
    }

    private var currentUserId: String? {
        authService.currentUser?.id
    }

    private var isOwnPost: Bool {
        currentUserId == matchPost.creatorId
    }

    private var hasApplied: Bool {
        guard let currentUserId else { return hasAppliedLocally }
        return hasAppliedLocally || matchPost.hasApplied(currentUserId)
    }

    private var isAccepted: Bool {
        guard let currentUserId else { return false }
        return matchPost.isAccepted(currentUserId)
    }

    private var confirmedPlayers: Int {
        min(matchPost.maxPlayers, matchPost.currentPlayers + matchPost.acceptedIds.count)
    }

    private var remainingSlots: Int {
        max(matchPost.availableSlots, 0)
    }

    private var rosterProgress: CGFloat {
        guard matchPost.maxPlayers > 0 else { return 0 }
        return min(CGFloat(confirmedPlayers) / CGFloat(matchPost.maxPlayers), 1)
    }

    private var preferredPositions: [PlayerPosition] {
        matchPost.preferredPositions.filter { $0 != .unspecified }
    }

    private var dateLabel: String {
        if matchPost.matchDate.isToday {
            return "Bugün"
        } else if matchPost.matchDate.isTomorrow {
            return "Yarın"
        } else {
            return matchPost.matchDate.shortFormatted
        }
    }

    private var statusTitle: String {
        if matchPost.isExpired {
            return "Süresi Doldu"
        }
        return matchPost.status.displayName
    }

    private var statusColor: Color {
        if matchPost.isExpired {
            return .gray
        }

        switch matchPost.status {
        case .active: return accentColor
        case .full: return .blue
        case .completed: return .gray
        case .cancelled: return .red
        case .expired: return .gray
        }
    }

    private var actionTitle: String {
        if isOwnPost { return "Bu İlan Sana Ait" }
        if isAccepted { return "Kadroya Kabul Edildin" }
        if hasApplied { return "Başvuru Alındı" }
        if matchPost.isExpired { return "Maç Saati Geçti" }
        if matchPost.isFull || matchPost.status == .full { return "Kadro Tamamlandı" }
        if matchPost.status != .active { return "Başvuru Kapalı" }
        if currentUserId == nil { return "Giriş Yaparak Başvur" }
        return "Maça Başvur"
    }

    private var actionIcon: String {
        if isAccepted || hasApplied { return "checkmark.circle.fill" }
        if isActionDisabled { return "lock.fill" }
        return "paperplane.fill"
    }

    private var isActionDisabled: Bool {
        isOwnPost ||
        isAccepted ||
        hasApplied ||
        currentUserId == nil ||
        matchPost.status != .active ||
        matchPost.isExpired ||
        matchPost.isFull
    }

    private var actionHint: String {
        if isOwnPost {
            return "Kendi ilanındaki başvuruları randevular ekranından takip edebilirsin."
        }
        if hasApplied || isAccepted {
            return "İlan sahibi başvurunu değerlendirdiğinde bildirim alacaksın."
        }
        if currentUserId == nil {
            return "Başvurmak için oyuncu hesabıyla giriş yapmalısın."
        }
        return "Başvurun ilan sahibine iletilir; kabul edilirse kadroya eklenirsin."
    }
}

private struct MatchDetailSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "2E7D32"))

                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

private struct MatchDetailHeroChip: View {
    let icon: String
    let title: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(.white.opacity(0.14))
            .cornerRadius(12)
    }
}

private struct MatchDetailStatusBadge: View {
    let title: String
    let color: Color
    var foregroundColor: Color = .primary

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.22))
            .cornerRadius(20)
    }
}

private struct MatchDetailStatTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color(hex: "2E7D32"))

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct MatchDetailIconBox: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.12))
                .frame(width: 44, height: 44)

            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
        }
    }
}

private struct MatchDetailInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color(hex: "2E7D32"))
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MatchDetailInfoPill: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct MatchDetailPositionChip: View {
    let position: PlayerPosition

    var body: some View {
        HStack(spacing: 6) {
            Text(position.icon)
            Text(position.displayName)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color(hex: "2E7D32").opacity(0.1))
        .foregroundColor(Color(hex: "2E7D32"))
        .cornerRadius(12)
    }
}

private struct MatchDetailEmptyPill: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MatchPostDetailView(matchPost: .mockPost)
    }
}

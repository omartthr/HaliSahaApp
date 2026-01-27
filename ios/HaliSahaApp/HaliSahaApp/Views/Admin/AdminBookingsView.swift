//
//  AdminBookingsView.swift
//  HaliSahaApp
//
//  Admin Rezervasyon Yönetimi
//
//  Created by Mehmet Mert Mazıcı on 24.01.2026.
//

import SwiftUI
import UIKit

// MARK: - Admin Bookings View
struct AdminBookingsView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = AdminBookingsViewModel()
    @State private var selectedFilter: AdminBookingFilter = .all
    @State private var selectedBooking: Booking?
    @State private var showActionSheet = false
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Filter Tabs
            filterTabs
            
            // Date Picker
            datePicker
            
            // Content
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if viewModel.filteredBookings.isEmpty {
                emptyState
            } else {
                bookingsList
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Rezervasyonlar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        exportAndShare()
                    } label: {
                        Label("Dışa Aktar", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        printBookings()
                    } label: {
                        Label("Yazdır", systemImage: "printer")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Rezervasyon İşlemleri",
            isPresented: $showActionSheet,
            presenting: selectedBooking
        ) { booking in
            if booking.status == .confirmed {
                Button("Tamamlandı Olarak İşaretle") {
                    Task {
                        await viewModel.completeBooking(booking)
                        selectedBooking = nil
                    }
                }
                
                Button("Gelmedi Olarak İşaretle", role: .destructive) {
                    Task {
                        await viewModel.markAsNoShow(booking)
                        selectedBooking = nil
                    }
                }
            }
            
            if booking.status == .pending {
                Button("Onayla") {
                    Task {
                        await viewModel.confirmBooking(booking)
                        selectedBooking = nil
                    }
                }
                
                Button("Reddet", role: .destructive) {
                    Task {
                        await viewModel.rejectBooking(booking)
                        selectedBooking = nil
                    }
                }
            }
            
            Button("İptal", role: .cancel) {
                selectedBooking = nil
            }
        } message: { booking in
            Text("Rezervasyon: \(booking.ticketNumber)")
        }
        .task {
            await viewModel.loadBookings()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    // MARK: - Export and Share
    private func exportAndShare() {
        if let url = viewModel.exportBookingsToCSV() {
            exportedFileURL = url
            showShareSheet = true
        }
    }
    
    // MARK: - Print Bookings
    private func printBookings() {
        viewModel.printBookings()
    }
    
    // MARK: - Filter Tabs
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AdminBookingFilter.allCases) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        count: viewModel.countForFilter(filter),
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        viewModel.applyFilter(filter)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Date Picker
    private var datePicker: some View {
        HStack {
            Button {
                viewModel.previousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color(hex: "2E7D32"))
            }
            
            Spacer()
            
            DatePicker(
                "",
                selection: $viewModel.selectedDate,
                displayedComponents: .date
            )
            .labelsHidden()
            .onChange(of: viewModel.selectedDate) { _, _ in
                Task {
                    await viewModel.loadBookings()
                }
            }
            
            Spacer()
            
            Button {
                viewModel.nextDay()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color(hex: "2E7D32"))
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Rezervasyon Bulunamadı")
                .font(.headline)
            
            Text("Seçili tarih ve filtre için rezervasyon bulunmuyor.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Bookings List
    private var bookingsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Summary Card
                bookingSummary
                
                // Bookings
                ForEach(viewModel.filteredBookings) { booking in
                    AdminBookingDetailCard(booking: booking) {
                        selectedBooking = booking
                        showActionSheet = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Booking Summary
    private var bookingSummary: some View {
        HStack(spacing: 16) {
            SummaryItem(
                value: "\(viewModel.filteredBookings.count)",
                label: "Toplam",
                color: .blue
            )
            
            SummaryItem(
                value: "\(viewModel.confirmedCount)",
                label: "Onaylı",
                color: .green
            )
            
            SummaryItem(
                value: "\(viewModel.pendingCount)",
                label: "Bekleyen",
                color: .orange
            )
            
            SummaryItem(
                value: viewModel.totalRevenue.asShortCurrency,
                label: "Gelir",
                color: Color(hex: "2E7D32")
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Share Sheet (UIActivityViewController wrapper)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Admin Bookings ViewModel
@MainActor
final class AdminBookingsViewModel: ObservableObject {
    
    @Published var allBookings: [Booking] = []
    @Published var filteredBookings: [Booking] = []
    @Published var selectedDate = Date()
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let adminService = AdminService.shared
    private var currentFilter: AdminBookingFilter = .all
    
    var confirmedCount: Int {
        filteredBookings.filter { $0.status == .confirmed }.count
    }
    
    var pendingCount: Int {
        filteredBookings.filter { $0.status == .pending }.count
    }
    
    var totalRevenue: Double {
        filteredBookings.reduce(0) { $0 + $1.depositAmount }
    }
    
    // MARK: - Date Navigation
    func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        Task {
            await loadBookings()
        }
    }
    
    func nextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        Task {
            await loadBookings()
        }
    }
    
    // MARK: - Filter Count
    func countForFilter(_ filter: AdminBookingFilter) -> Int {
        switch filter {
        case .all:
            return allBookings.count
        case .today:
            return allBookings.filter { Calendar.current.isDateInToday($0.date) }.count
        case .confirmed:
            return allBookings.filter { $0.status == .confirmed }.count
        case .pending:
            return allBookings.filter { $0.status == .pending }.count
        case .completed:
            return allBookings.filter { $0.status == .completed }.count
        case .cancelled:
            return allBookings.filter { $0.status == .cancelled }.count
        }
    }
    
    func loadBookings() async {
        isLoading = true
        errorMessage = ""
        
        do {
            // Gerçek Firebase verileri
            let facilities = try await adminService.fetchMyFacilities()
            let facilityIds = facilities.compactMap { $0.id }
            
            // Tüm rezervasyonları çek ve tesislerime göre filtrele
            let query = FirebaseService.shared.bookingsCollection
                .order(by: FirestoreField.date, descending: true)
            
            let allFetchedBookings: [Booking] = try await FirebaseService.shared.fetchDocuments(query: query)
            allBookings = allFetchedBookings.filter { facilityIds.contains($0.facilityId) }
            
            applyFilter(currentFilter)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            allBookings = []
            filteredBookings = []
        }
        
        isLoading = false
    }
    
    func applyFilter(_ filter: AdminBookingFilter) {
        currentFilter = filter
        
        switch filter {
        case .all:
            filteredBookings = allBookings
        case .today:
            filteredBookings = allBookings.filter { Calendar.current.isDateInToday($0.date) }
        case .confirmed:
            filteredBookings = allBookings.filter { $0.status == .confirmed }
        case .pending:
            filteredBookings = allBookings.filter { $0.status == .pending }
        case .completed:
            filteredBookings = allBookings.filter { $0.status == .completed }
        case .cancelled:
            filteredBookings = allBookings.filter { $0.status == .cancelled }
        }
    }
    
    func confirmBooking(_ booking: Booking) async {
        guard let id = booking.id else { return }
        do {
            try await adminService.confirmBooking(bookingId: id)
            await loadBookings()
        } catch {
            errorMessage = "Onaylama başarısız: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func rejectBooking(_ booking: Booking) async {
        guard let id = booking.id else { return }
        do {
            try await adminService.rejectBooking(bookingId: id, reason: "Admin tarafından reddedildi")
            await loadBookings()
        } catch {
            errorMessage = "Reddetme başarısız: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func completeBooking(_ booking: Booking) async {
        guard let id = booking.id else { return }
        do {
            try await adminService.completeBooking(bookingId: id)
            await loadBookings()
        } catch {
            errorMessage = "Tamamlama başarısız: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func markAsNoShow(_ booking: Booking) async {
        guard let id = booking.id else { return }
        do {
            try await adminService.markAsNoShow(bookingId: id)
            await loadBookings()
        } catch {
            errorMessage = "İşlem başarısız: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - Export Bookings to CSV
    func exportBookingsToCSV() -> URL? {
        // CSV Header
        var csvString = "Rezervasyon No,Müşteri Adı,Telefon,Saha,Tarih,Saat,Durum,Ödenen Tutar\n"
        
        // Date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        // Add each booking
        for booking in filteredBookings {
            let row = [
                booking.ticketNumber,
                booking.userFullName,
                booking.userPhone,
                booking.pitchName,
                dateFormatter.string(from: booking.date),
                booking.timeSlotString,
                booking.status.displayName,
                String(format: "%.2f TL", booking.depositAmount)
            ]
            
            // Escape special characters and join with comma
            let escapedRow = row.map { field in
                // Virgül veya tırnak içeriyorsa tırnak içine al
                if field.contains(",") || field.contains("\"") {
                    return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
                }
                return field
            }
            
            csvString += escapedRow.joined(separator: ",") + "\n"
        }
        
        // Create file in temp directory
        let fileName = "Rezervasyonlar_\(dateFormatter.string(from: Date())).csv"
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            // UTF-8 BOM ekle (Excel uyumluluğu için)
            let bom = "\u{FEFF}"
            let dataString = bom + csvString
            try dataString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("CSV export error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Print Bookings
    func printBookings() {
        // HTML formatında yazdırılacak içerik oluştur
        let htmlContent = generatePrintableHTML()
        
        // Print formatter oluştur
        let printFormatter = UIMarkupTextPrintFormatter(markupText: htmlContent)
        
        // Print controller
        let printController = UIPrintInteractionController.shared
        printController.printFormatter = printFormatter
        
        // Print info
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "Rezervasyonlar"
        printInfo.outputType = .general
        printController.printInfo = printInfo
        
        // Present print dialog
        printController.present(animated: true) { _, completed, error in
            if let error = error {
                print("Print error: \(error.localizedDescription)")
            } else if completed {
                print("Print completed successfully")
            }
        }
    }
    
    // MARK: - Generate Printable HTML
    private func generatePrintableHTML() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        let currentDate = dateFormatter.string(from: Date())
        
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {
                    font-family: -apple-system, Helvetica, Arial, sans-serif;
                    padding: 20px;
                    font-size: 12px;
                }
                h1 {
                    color: #2E7D32;
                    font-size: 18px;
                    margin-bottom: 5px;
                }
                .subtitle {
                    color: #666;
                    font-size: 11px;
                    margin-bottom: 20px;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 10px;
                }
                th {
                    background-color: #2E7D32;
                    color: white;
                    padding: 8px;
                    text-align: left;
                    font-size: 11px;
                }
                td {
                    border-bottom: 1px solid #ddd;
                    padding: 8px;
                    font-size: 11px;
                }
                tr:nth-child(even) {
                    background-color: #f9f9f9;
                }
                .status-confirmed { color: #4CAF50; font-weight: bold; }
                .status-pending { color: #FF9800; font-weight: bold; }
                .status-cancelled { color: #f44336; font-weight: bold; }
                .status-completed { color: #2196F3; font-weight: bold; }
                .summary {
                    margin-top: 20px;
                    padding: 10px;
                    background-color: #f5f5f5;
                    border-radius: 5px;
                }
                .summary-item {
                    display: inline-block;
                    margin-right: 30px;
                }
                .summary-value {
                    font-size: 16px;
                    font-weight: bold;
                    color: #2E7D32;
                }
            </style>
        </head>
        <body>
            <h1>Rezervasyon Listesi</h1>
            <div class="subtitle">Oluşturulma Tarihi: \(currentDate) | Toplam: \(filteredBookings.count) rezervasyon</div>
            
            <table>
                <tr>
                    <th>Rez. No</th>
                    <th>Müşteri</th>
                    <th>Telefon</th>
                    <th>Saha</th>
                    <th>Tarih</th>
                    <th>Saat</th>
                    <th>Durum</th>
                    <th>Tutar</th>
                </tr>
        """
        
        // Add rows
        for booking in filteredBookings {
            let statusClass: String
            switch booking.status {
            case .confirmed: statusClass = "status-confirmed"
            case .pending: statusClass = "status-pending"
            case .cancelled: statusClass = "status-cancelled"
            case .completed: statusClass = "status-completed"
            default: statusClass = ""
            }
            
            html += """
                <tr>
                    <td>\(booking.ticketNumber)</td>
                    <td>\(booking.userFullName)</td>
                    <td>\(booking.userPhone)</td>
                    <td>\(booking.pitchName)</td>
                    <td>\(dateFormatter.string(from: booking.date))</td>
                    <td>\(booking.timeSlotString)</td>
                    <td class="\(statusClass)">\(booking.status.displayName)</td>
                    <td>\(String(format: "%.2f ₺", booking.depositAmount))</td>
                </tr>
            """
        }
        
        // Summary
        html += """
            </table>
            
            <div class="summary">
                <div class="summary-item">
                    <div>Toplam Rezervasyon</div>
                    <div class="summary-value">\(filteredBookings.count)</div>
                </div>
                <div class="summary-item">
                    <div>Onaylı</div>
                    <div class="summary-value">\(confirmedCount)</div>
                </div>
                <div class="summary-item">
                    <div>Bekleyen</div>
                    <div class="summary-value">\(pendingCount)</div>
                </div>
                <div class="summary-item">
                    <div>Toplam Gelir</div>
                    <div class="summary-value">\(String(format: "%.2f ₺", totalRevenue))</div>
                </div>
            </div>
        </body>
        </html>
        """
        
        return html
    }
}

// MARK: - Admin Booking Filter
enum AdminBookingFilter: String, CaseIterable, Identifiable {
    case all = "Tümü"
    case today = "Bugün"
    case pending = "Bekleyen"
    case confirmed = "Onaylı"
    case completed = "Tamamlanan"
    case cancelled = "İptal"
    
    var id: String { rawValue }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? Color(hex: "2E7D32") : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white : Color(.systemGray5))
                        .cornerRadius(10)
                }
            }
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "2E7D32") : Color(.systemGray6))
            .cornerRadius(20)
        }
    }
}

struct SummaryItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AdminBookingDetailCard: View {
    let booking: Booking
    let onAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.userFullName)
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.caption2)
                        Text(booking.userPhone)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: booking.status)
            }
            
            Divider()
            
            // Details
            HStack {
                DetailColumn(icon: "sportscourt", title: booking.pitchName)
                
                Spacer()
                
                DetailColumn(icon: "calendar", title: booking.formattedDate)
                
                Spacer()
                
                DetailColumn(icon: "clock", title: booking.timeSlotString)
            }
            
            Divider()
            
            // Footer
            HStack {
                // Price
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ödenen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(booking.depositAmount.asCurrency)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                
                if !booking.ticketNumber.isEmpty {
                    Text(booking.ticketNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action Button
                Button(action: onAction) {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8)
    }
}

struct DetailColumn: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AdminBookingsView()
    }
}

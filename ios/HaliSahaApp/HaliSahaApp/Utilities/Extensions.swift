//
//  Extensions.swift
//  HaliSahaApp
//
//  Yardımcı Swift extension'ları
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//


import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    
    /// Türkçe formatlanmış tarih
    var formattedTurkish: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: self)
    }
    
    /// Kısa format (gün ay)
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }
    
    /// Gün adı ile birlikte
    var withDayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        return formatter.string(from: self)
    }
    
    /// Saat formatı
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    /// Göreceli zaman (örn: "2 saat önce")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Kısa göreceli zaman
    var shortRelativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Bugün mü?
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Dün mü?
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// Yarın mı?
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// Bu hafta mı?
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Hafta sonu mu?
    var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: self)
        return weekday == 1 || weekday == 7
    }
    
    /// Günün başlangıcı
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Günün sonu
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    /// Belirli gün ekle/çıkar
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// Belirli saat ekle/çıkar
    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }
}

// MARK: - String Extensions
extension String {
    
    /// Geçerli e-posta mı?
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }
    
    /// Geçerli telefon numarası mı? (Türkiye)
    var isValidPhoneNumber: Bool {
        let phoneRegex = "^5[0-9]{9}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        let cleanNumber = self.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "+90", with: "")
            .replacingOccurrences(of: "0", with: "", options: .anchored)
        return predicate.evaluate(with: cleanNumber)
    }
    
    /// Formatlanmış telefon numarası (5XX XXX XX XX)
    var formattedPhoneNumber: String {
        let cleanNumber = self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard cleanNumber.count >= 10 else { return self }
        
        let lastTen = String(cleanNumber.suffix(10))
        let index1 = lastTen.index(lastTen.startIndex, offsetBy: 3)
        let index2 = lastTen.index(lastTen.startIndex, offsetBy: 6)
        let index3 = lastTen.index(lastTen.startIndex, offsetBy: 8)
        
        return "\(lastTen[..<index1]) \(lastTen[index1..<index2]) \(lastTen[index2..<index3]) \(lastTen[index3...])"
    }
    
    /// İlk harfi büyük
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
    
    /// Boşlukları temizle
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Boş veya sadece boşluk mu?
    var isBlank: Bool {
        trimmed.isEmpty
    }
    
    /// URL olarak geçerli mi?
    var isValidURL: Bool {
        URL(string: self) != nil
    }
}

// MARK: - Double Extensions
extension Double {
    
    /// Para formatı (örn: 1.500,00 ₺)
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.currencySymbol = "₺"
        return formatter.string(from: NSNumber(value: self)) ?? "\(self) ₺"
    }
    
    /// Kısa para formatı (örn: 1.500 ₺)
    var asShortCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))") + " ₺"
    }
    
    /// Yıldız puanı formatı (örn: 4.5)
    var asRating: String {
        String(format: "%.1f", self)
    }
    
    /// Yüzde formatı (örn: %85)
    var asPercentage: String {
        String(format: "%%%.0f", self)
    }
}

// MARK: - Int Extensions
extension Int {
    
    /// Saat formatı (örn: 09:00)
    var asHourString: String {
        String(format: "%02d:00", self)
    }
    
    /// Zaman aralığı formatı (örn: 09:00 - 10:00)
    func asTimeRange(to endHour: Int) -> String {
        "\(String(format: "%02d:00", self)) - \(String(format: "%02d:00", endHour))"
    }
}

// MARK: - View Extensions
extension View {
    
    /// Köşe yuvarlatma (belirli köşeler için)
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// Kart stili gölge
    func cardShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(UIConstants.cardShadowOpacity),
            radius: UIConstants.cardShadowRadius,
            x: 0,
            y: 4
        )
    }
    
    /// Koşullu modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Placeholder gizleme (TextField için)
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    /// Klavyeyi gizle
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Rounded Corner Shape
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Array Extensions
extension Array {
    
    /// Güvenli index erişimi
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Array where Element: Identifiable {
    
    /// ID ile element bul
    func first(withId id: Element.ID) -> Element? {
        first { $0.id == id }
    }
    
    /// ID ile index bul
    func firstIndex(withId id: Element.ID) -> Int? {
        firstIndex { $0.id == id }
    }
}

// MARK: - Optional String Extension
extension Optional where Wrapped == String {
    
    /// nil veya boş mu?
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
    
    /// nil veya boş değilse değeri döndür
    var orEmpty: String {
        self ?? ""
    }
}

// MARK: - Collection Extensions
extension Collection {
    
    /// Boş değilse true
    var isNotEmpty: Bool {
        !isEmpty
    }
}

// MARK: - Bundle Extension
extension Bundle {
    
    /// App Version
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    /// Build Number
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// Full Version (örn: 1.0.0 (123))
    var fullVersion: String {
        "\(appVersion) (\(buildNumber))"
    }
}

// MARK: - UIApplication Extension
extension UIApplication {
    
    /// Aktif window'u al
    var currentWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    /// Safe area insets
    var safeAreaInsets: UIEdgeInsets {
        currentWindow?.safeAreaInsets ?? .zero
    }
}

// MARK: - Encodable Extension
extension Encodable {
    
    /// Dictionary'ye dönüştür
    var asDictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

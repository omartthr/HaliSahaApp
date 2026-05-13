//
//  NotificationService.swift
//  HaliSahaApp
//
//  Local notification (UNUserNotificationCenter) yönetimi:
//  - İzin akışı
//  - Maç hatırlatmalarının planlanması ve idempotent senkronizasyonu
//

import Foundation
import UserNotifications

// MARK: - Notification Service
@MainActor
final class NotificationService {

    // MARK: - Singleton
    static let shared = NotificationService()

    // MARK: - Constants
    /// UserDefaults anahtarları
    private enum Keys {
        static let permissionAsked = "notifications.permissionAsked"
        static let matchRemindersEnabled = "settings.matchReminders"
    }

    /// Reminder identifier prefix'i — sync sırasında orphan'ları tanımlamak için
    private static let identifierPrefix = "booking_"

    // MARK: - Dependencies
    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    // MARK: - Init
    private init() {}

    // MARK: - Permission

    /// Daha önce sistem izin diyaloğunu gösterdik mi?
    var hasAskedPermission: Bool {
        defaults.bool(forKey: Keys.permissionAsked)
    }

    /// Sistem yetkilendirme durumu (authorized / denied / notDetermined / provisional)
    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// İzin diyaloğunu göster. Daha önce reddedilmişse sistem direkt false döner.
    @discardableResult
    func requestPermission() async -> Bool {
        defaults.set(true, forKey: Keys.permissionAsked)
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - User Preference

    /// Kullanıcı maç hatırlatmalarını açık/kapalı seçer (ProfileSettings).
    var matchRemindersEnabled: Bool {
        // Default: true. AppStorage(true) ile aynı default.
        defaults.object(forKey: Keys.matchRemindersEnabled) as? Bool ?? true
    }

    // MARK: - Schedule (single booking)

    /// Tek bir rezervasyon için 24 saat ve 2 saat öncesinde hatırlatma planlar.
    /// İzin yoksa, kullanıcı tercihi kapalıysa veya tarih geçmişse no-op.
    func scheduleReminders(for booking: Booking) async {
        guard matchRemindersEnabled else { return }
        guard let bookingId = booking.id else { return }
        guard booking.status == .confirmed else { return }

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        for hours in AppConstants.matchReminderHours {
            await scheduleSingle(for: booking, bookingId: bookingId, hoursBefore: hours)
        }
    }

    /// Bu rezervasyona ait tüm bekleyen hatırlatmaları iptal eder.
    func cancelReminders(forBookingId bookingId: String) {
        let identifiers = AppConstants.matchReminderHours.map {
            identifier(bookingId: bookingId, hoursBefore: $0)
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Sync (idempotent)

    /// Verilen rezervasyon listesine göre eksik hatırlatmaları kurar, gereksizleri kaldırır.
    /// - Idempotent: tekrar tekrar çağırılabilir.
    /// - Auth yoksa veya tercih kapalıysa tüm bizim hatırlatmalarımız temizlenir.
    func syncReminders(for bookings: [Booking]) async {
        // Tercihler kapalıysa veya yetki yoksa: tüm bizim reminder'larımızı temizle
        let preferenceOn = matchRemindersEnabled
        let status = await authorizationStatus()
        let authorized = status == .authorized || status == .provisional

        guard preferenceOn && authorized else {
            await cancelAllOurReminders()
            return
        }

        // Geçerli (gelecekte ve confirmed) rezervasyonları filtrele
        let validBookings = bookings.filter { booking in
            booking.id != nil && booking.status == .confirmed && !booking.isPast
        }

        // Beklenen tüm reminder identifier'larını hesapla
        var expectedIds = Set<String>()
        for booking in validBookings {
            guard let id = booking.id else { continue }
            for hours in AppConstants.matchReminderHours {
                expectedIds.insert(identifier(bookingId: id, hoursBefore: hours))
            }
        }

        // Mevcut bizim olan pending request ID'lerini al
        let pending = await center.pendingNotificationRequests()
        let ourCurrentIds = Set(
            pending.map(\.identifier).filter { $0.hasPrefix(Self.identifierPrefix) }
        )

        // Silinecekler: bizim ama beklenmiyor
        let toRemove = ourCurrentIds.subtracting(expectedIds)
        if !toRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: Array(toRemove))
        }

        // Eklenecekler: beklenen ama yok
        let toAdd = expectedIds.subtracting(ourCurrentIds)
        guard !toAdd.isEmpty else { return }

        for booking in validBookings {
            guard let id = booking.id else { continue }
            for hours in AppConstants.matchReminderHours {
                let identifier = identifier(bookingId: id, hoursBefore: hours)
                guard toAdd.contains(identifier) else { continue }
                await scheduleSingle(for: booking, bookingId: id, hoursBefore: hours)
            }
        }
    }

    /// Tüm `booking_*` prefix'li bekleyen reminder'ları temizler.
    func cancelAllOurReminders() async {
        let pending = await center.pendingNotificationRequests()
        let ourIds = pending.map(\.identifier).filter { $0.hasPrefix(Self.identifierPrefix) }
        if !ourIds.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ourIds)
        }
    }

    /// Çıkış yapan kullanıcı için tüm planlanmış bildirimleri temizler.
    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Private Helpers

    private func identifier(bookingId: String, hoursBefore: Int) -> String {
        "\(Self.identifierPrefix)\(bookingId)_\(hoursBefore)h"
    }

    private func scheduleSingle(
        for booking: Booking,
        bookingId: String,
        hoursBefore: Int
    ) async {
        let calendar = Calendar.current
        guard
            let bookingStart = calendar.date(
                bySettingHour: booking.startHour, minute: 0, second: 0, of: booking.date)
        else { return }

        let triggerDate = bookingStart.addingTimeInterval(-Double(hoursBefore) * 3600)
        guard triggerDate > Date() else { return }  // geçmiş tarih için planlama yapma

        let content = UNMutableNotificationContent()
        content.title = "Maç Hatırlatması ⚽"
        content.body = "\(booking.facilityName) – \(booking.timeSlotString)\nMaça \(hoursBefore) saat kaldı"
        content.sound = .default
        content.userInfo = [
            "bookingId": bookingId,
            "type": NotificationType.bookingReminder.rawValue,
            "hoursBefore": hoursBefore,
        ]

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier(bookingId: bookingId, hoursBefore: hoursBefore),
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("⚠️ Reminder schedule failed: \(error.localizedDescription)")
        }
    }
}

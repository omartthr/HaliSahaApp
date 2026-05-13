//
//  HaliSahaAppApp.swift
//  HaliSahaApp
//
//  Ana uygulama giriş noktası
//
//  Created by Mehmet Mert Mazıcı on 22.12.2025.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import UserNotifications

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase'i yapılandır
        FirebaseApp.configure()

        // Local notification delegate'i bağla (foreground gösterim + tap)
        UNUserNotificationCenter.current().delegate = self

        // UI Appearance ayarları
        configureAppearance()

        return true
    }

    // MARK: - Google Sign In URL Handling
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Notification Delegate
    /// Uygulama açıkken gelen bildirimi banner + ses + badge ile göster
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .list, .sound, .badge]
    }

    /// Kullanıcı bildirime dokunduğunda ilgili sekmeye yönlendir
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        // Maç hatırlatması veya rezervasyon bildirimleri → Randevularım sekmesi
        if userInfo["bookingId"] is String {
            await MainActor.run {
                NotificationCenter.default.post(name: .switchToBookingsTab, object: nil)
            }
        }
    }
    
    private func configureAppearance() {
        // Navigation Bar
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor.systemBackground
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color(hex: "2E7D32"))
        
        // Tab Bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(Color(hex: "2E7D32"))
        
        // TextField
        UITextField.appearance().tintColor = UIColor(Color(hex: "2E7D32"))
    }
}

// MARK: - Main App
@main
struct HaliSahaApp: App {
    
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // MARK: - Environment
    @Environment(\.scenePhase) var scenePhase
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(nil) // Sistem ayarlarına uy
                .onOpenURL { url in
                    // Google Sign In URL handling
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Scene Phase Handler
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            print("📱 App is active")
            // Uygulama aktif olduğunda yapılacaklar
            // Örn: Bildirimleri güncelle, veri senkronize et
            
        case .inactive:
            print("📱 App is inactive")
            // Uygulama pasif olduğunda yapılacaklar
            
        case .background:
            print("📱 App is in background")
            // Uygulama arka plana geçtiğinde yapılacaklar
            // Örn: Verileri kaydet
            
        @unknown default:
            break
        }
    }
}

// MARK: - App Constants Check
extension HaliSahaApp {
    
    /// Uygulama başlatılırken gerekli kontrolleri yapar
    static func performStartupChecks() {
        #if DEBUG
        print("🚀 \(AppConstants.appName) Debug Mode")
        print("📦 Version: \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
        #endif
    }
}

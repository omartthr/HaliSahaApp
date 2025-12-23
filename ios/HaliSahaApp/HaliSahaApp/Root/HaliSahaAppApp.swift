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

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase'i yapılandır
        FirebaseApp.configure()
        
        // UI Appearance ayarları
        configureAppearance()
        
        return true
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
        print("🚀 HaliSaha Debug Mode")
        print("📦 Version: \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
        #endif
    }
}

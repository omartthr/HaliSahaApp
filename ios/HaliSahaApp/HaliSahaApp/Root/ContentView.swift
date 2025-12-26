//
//  ContentView.swift
//  HaliSahaApp
//
//  Root View - Kimlik doğrulama durumuna göre yönlendirme yapar
//
//  Created by Mehmet Mert Mazıcı on 22.12.2025.
//

import SwiftUI

// MARK: - Content View
struct ContentView: View {
    
    // MARK: - Properties
    @StateObject private var authService = AuthService.shared
    @State private var showSplash = true
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                if authService.isAuthenticated {
                    // Ana sayfa - ADIM 3'te MainTabView olacak
                    MainTabViewPlaceholder()
                        .transition(.opacity)
                } else {
                    LoginView()
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        .onAppear {
            // Splash screen'i 2 saniye göster
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "2E7D32")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                    
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                
                // App Name
                VStack(spacing: 8) {
                    Text("HalıSaha")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Maça Başla!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Loading Indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .padding(.top, 32)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Main Tab View Placeholder (ADIM 3'te değiştirilecek)
struct MainTabViewPlaceholder: View {
    
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Welcome
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Hoş Geldiniz!")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // Info
                VStack(spacing: 8) {
                    Text("Ana sayfa eklencek beklemede kallll")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // Logout Button
                PrimaryButton(
                    title: "Çıkış Yap",
                    icon: "rectangle.portrait.and.arrow.right",
                    style: .outline
                ) {
                    try? authService.signOut()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Ana Sayfa")
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}

#Preview("Splash") {
    SplashView()
}

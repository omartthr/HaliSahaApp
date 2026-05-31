//
//  ContentView.swift
//  HaliSaha
//
//  Root View - Kimlik doğrulama durumuna göre yönlendirme yapar
//

import SwiftUI
import Lottie

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
                if authService.isAuthenticated || authService.currentUser?.userType == .guest {
                    // Kullanıcı tipine göre farklı Tab Bar
                    switch authService.currentUser?.userType {
                    case .superAdmin:
                        SuperAdminTabView()
                            .transition(.opacity)
                    case .admin:
                        AdminTabView()
                            .transition(.opacity)
                    default:
                        // Oyuncu: onboarding tamamlanmadıysa önce onu göster
                        if let user = authService.currentUser,
                           user.userType == .player,
                           !user.hasCompletedOnboarding {
                            OnboardingCoordinator()
                                .transition(.opacity)
                        } else {
                            MainTabView()
                                .transition(.opacity)
                        }
                    }
                } else {
                    LoginView()
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: authService.currentUser?.hasCompletedOnboarding)
        .onChange(of: authService.isAuthenticated) { _, _ in
            UIApplication.dismissKeyboard()
        }
        .onAppear {
            // Splash screen'i animasyonun daha net izlenmesi için biraz daha uzun göster
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash View
struct SplashLottieView: UIViewRepresentable {
    
    let animationName: String
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: animationName)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.play()
        return animationView
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if !uiView.isAnimationPlaying {
            uiView.play()
        }
    }
}

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            Color("LaunchScreenBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                SplashLottieView(animationName: "splash_soccer_field")
                    .frame(width: 220, height: 220)
                
                // App Name
                VStack(spacing: 8) {
                    Text("ALO Halısaha")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(titleColor)
                    
                    Text("Maça Başla!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Loading Indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "2E7D32")))
                    .scaleEffect(1.2)
                    .padding(.top, 32)
            }
        }
    }

    private var titleColor: Color {
        colorScheme == .dark ? Color(hex: "A5D6A7") : Color(hex: "1B5E20")
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}

#Preview("Splash") {
    SplashView()
}

//
//  LoadingView.swift
//  HaliSahaApp
//
//  Yükleme göstergeleri ve boş durum bileşenleri
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//


import SwiftUI

// MARK: - Full Screen Loading View
struct LoadingView: View {
    
    var message: String = "Yükleniyor..."
    var showBackground: Bool = true
    
    var body: some View {
        ZStack {
            if showBackground {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "2E7D32")))
                    .scaleEffect(1.5)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10)
            )
        }
    }
}

// MARK: - Inline Loading View
struct InlineLoadingView: View {
    
    var message: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Skeleton Loading View
struct SkeletonView: View {
    
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 8
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.2)
                    ]),
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(height: height)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Card Skeleton
struct CardSkeletonView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            SkeletonView(height: 150, cornerRadius: 12)
            
            // Title
            SkeletonView(height: 20)
                .frame(width: 200)
            
            // Subtitle
            SkeletonView(height: 16)
                .frame(width: 150)
            
            // Info row
            HStack {
                SkeletonView(height: 14)
                    .frame(width: 80)
                Spacer()
                SkeletonView(height: 14)
                    .frame(width: 60)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    
    let icon: String
    let title: String
    var message: String? = nil
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            if let buttonTitle = buttonTitle, let action = buttonAction {
                PrimaryButton(title: buttonTitle, size: .medium, fullWidth: false, action: action)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    
    let message: String
    var retryAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Bir Hata Oluştu")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let retry = retryAction {
                PrimaryButton(
                    title: "Tekrar Dene",
                    icon: "arrow.clockwise",
                    style: .outline,
                    size: .medium,
                    fullWidth: false,
                    action: retry
                )
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Guest Restriction Alert
struct GuestRestrictionView: View {
    
    var message: String = "Bu özelliği kullanmak için üye girişi yapmanız gerekiyor."
    var onLogin: () -> Void
    var onRegister: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "2E7D32"))
            
            // Text
            VStack(spacing: 8) {
                Text("Üye Girişi Gerekli")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Buttons
            VStack(spacing: 12) {
                PrimaryButton(title: "Giriş Yap", action: onLogin)
                PrimaryButton(title: "Kayıt Ol", style: .outline, action: onRegister)
                
                Button("Vazgeç", action: onDismiss)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding(32)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 20)
        .padding(24)
    }
}

// MARK: - Pull to Refresh Indicator
struct RefreshableScrollView<Content: View>: View {
    
    var onRefresh: () async -> Void
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        ScrollView {
            content()
        }
        .refreshable {
            await onRefresh()
        }
    }
}

// MARK: - Preview
#Preview("Loading Views") {
    VStack(spacing: 20) {
        InlineLoadingView(message: "Veriler yükleniyor...")
        
        CardSkeletonView()
            .padding()
    }
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "calendar.badge.exclamationmark",
        title: "Rezervasyon Bulunamadı",
        message: "Henüz bir rezervasyonunuz bulunmuyor. Hemen yeni bir saha keşfedin!",
        buttonTitle: "Sahaları Keşfet"
    ) {
        print("Explore tapped")
    }
}

#Preview("Error State") {
    ErrorStateView(
        message: "İnternet bağlantınızı kontrol edin ve tekrar deneyin."
    ) {
        print("Retry tapped")
    }
}

#Preview("Guest Restriction") {
    ZStack {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
        
        GuestRestrictionView(
            onLogin: {},
            onRegister: {},
            onDismiss: {}
        )
    }
}

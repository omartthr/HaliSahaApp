//
//  PrimaryButton.swift
//  HaliSahaApp
//
//  Özelleştirilmiş buton bileşenleri
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//


import SwiftUI

// MARK: - Primary Button
struct PrimaryButton: View {
    
    // MARK: - Properties
    let title: String
    var icon: String? = nil
    var style: ButtonStyle = .primary
    var size: ButtonSize = .large
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var fullWidth: Bool = true
    let action: () -> Void
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                action()
            }
        }) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize, weight: .semibold))
                    }
                    
                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .foregroundColor(style.foregroundColor)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(isDisabled ? style.disabledBackgroundColor : style.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - Button Style Enum
extension PrimaryButton {
    enum ButtonStyle {
        case primary      // Ana yeşil buton
        case secondary    // İkincil beyaz buton
        case outline      // Kenarlıklı buton
        case destructive  // Kırmızı tehlikeli işlem butonu
        case ghost        // Arka plansız buton
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Color(hex: "2E7D32")
            case .secondary: return Color(.systemBackground)
            case .outline: return .clear
            case .destructive: return .red
            case .ghost: return .clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return Color(hex: "2E7D32")
            case .outline: return Color(hex: "2E7D32")
            case .destructive: return .white
            case .ghost: return Color(hex: "2E7D32")
            }
        }
        
        var disabledBackgroundColor: Color {
            switch self {
            case .primary, .destructive: return .gray.opacity(0.3)
            case .secondary, .outline, .ghost: return .clear
            }
        }
        
        var borderColor: Color {
            switch self {
            case .outline: return Color(hex: "2E7D32")
            case .secondary: return Color.gray.opacity(0.3)
            default: return .clear
            }
        }
        
        var borderWidth: CGFloat {
            switch self {
            case .outline: return 2
            case .secondary: return 1
            default: return 0
            }
        }
    }
}

// MARK: - Button Size Enum
extension PrimaryButton {
    enum ButtonSize {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 52
            }
        }
        
        var font: Font {
            switch self {
            case .small: return .subheadline
            case .medium: return .body
            case .large: return .body
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }
        }
    }
}

// MARK: - Social Sign In Button
struct SocialSignInButton: View {
    
    enum Provider {
        case apple
        case google
        
        var title: String {
            switch self {
            case .apple: return "Apple ile Devam Et"
            case .google: return "Google ile Devam Et"
            }
        }
        
        var icon: String {
            switch self {
            case .apple: return "apple.logo"
            case .google: return "g.circle.fill"
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .apple: return .black
            case .google: return .white
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .apple: return .white
            case .google: return .black
            }
        }
    }
    
    let provider: Provider
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: provider.foregroundColor))
                } else {
                    Image(systemName: provider.icon)
                        .font(.system(size: 20))
                    
                    Text(provider.title)
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundColor(provider.foregroundColor)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(provider.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: provider == .google ? 1 : 0)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - Icon Button
struct IconButton: View {
    
    let icon: String
    var size: CGFloat = 44
    var backgroundColor: Color = Color(.systemGray6)
    var foregroundColor: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
        }
    }
}

// MARK: - Text Link Button
struct TextLinkButton: View {
    
    let title: String
    var color: Color = Color(hex: "2E7D32")
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Group {
                Text("Primary Buttons")
                    .font(.headline)
                
                PrimaryButton(title: "Giriş Yap", icon: "arrow.right") {}
                PrimaryButton(title: "Yükleniyor", isLoading: true) {}
                PrimaryButton(title: "Devre Dışı", isDisabled: true) {}
            }
            
            Divider()
            
            Group {
                Text("Secondary & Outline")
                    .font(.headline)
                
                PrimaryButton(title: "İptal", style: .secondary) {}
                PrimaryButton(title: "Kayıt Ol", icon: "person.badge.plus", style: .outline) {}
                PrimaryButton(title: "Hesabı Sil", icon: "trash", style: .destructive) {}
            }
            
            Divider()
            
            Group {
                Text("Sizes")
                    .font(.headline)
                
                PrimaryButton(title: "Small", size: .small, fullWidth: false) {}
                PrimaryButton(title: "Medium", size: .medium, fullWidth: false) {}
                PrimaryButton(title: "Large", size: .large, fullWidth: false) {}
            }
            
            Divider()
            
            Group {
                Text("Social Buttons")
                    .font(.headline)
                
                SocialSignInButton(provider: .apple) {}
                SocialSignInButton(provider: .google) {}
            }
            
            Divider()
            
            Group {
                Text("Other")
                    .font(.headline)
                
                HStack {
                    IconButton(icon: "heart.fill", foregroundColor: .red) {}
                    IconButton(icon: "square.and.arrow.up") {}
                    IconButton(icon: "ellipsis") {}
                }
                
                TextLinkButton(title: "Şifremi Unuttum") {}
            }
        }
        .padding()
    }
}

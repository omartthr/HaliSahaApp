//
//  CustomTextField.swift
//  HaliSahaApp
//
//  Özelleştirilmiş TextField bileşeni
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//


import SwiftUI

// MARK: - Custom TextField
struct CustomTextField: View {
    
    // MARK: - Properties
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false
    var isDisabled: Bool = false
    var errorMessage: String? = nil
    var trailingContent: AnyView? = nil
    
    // MARK: - Private State
    @State private var isSecureTextVisible = false
    @FocusState private var isFocused: Bool
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            // Input Field
            HStack(spacing: 12) {
                // Leading Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isFocused ? Color(hex: "2E7D32") : .gray)
                        .frame(width: 24)
                }
                
                // Text Field
                Group {
                    if isSecure && !isSecureTextVisible {
                        SecureField(placeholder, text: $text)
                            .textContentType(textContentType)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .textContentType(textContentType)
                            .textInputAutocapitalization(autocapitalization)
                    }
                }
                .focused($isFocused)
                .disabled(isDisabled)
                
                // Trailing Content (Password toggle veya özel içerik)
                if isSecure {
                    Button {
                        isSecureTextVisible.toggle()
                    } label: {
                        Image(systemName: isSecureTextVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                } else if let trailing = trailingContent {
                    trailing
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadiusMedium)
                    .fill(isDisabled ? Color.gray.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadiusMedium)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            
            // Error Message
            if let error = errorMessage, !error.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var borderColor: Color {
        if let _ = errorMessage {
            return .red
        } else if isFocused {
            return Color(hex: "2E7D32")
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Custom TextField Styles
extension CustomTextField {
    
    /// E-posta alanı için hazır yapılandırma
    static func email(title: String = "E-posta", text: Binding<String>, errorMessage: String? = nil) -> CustomTextField {
        CustomTextField(
            title: title,
            placeholder: "ornek@email.com",
            text: text,
            icon: "envelope.fill",
            keyboardType: .emailAddress,
            textContentType: .emailAddress,
            autocapitalization: .never,
            errorMessage: errorMessage
        )
    }
    
    /// Şifre alanı için hazır yapılandırma
    static func password(title: String = "Şifre", text: Binding<String>, errorMessage: String? = nil) -> CustomTextField {
        CustomTextField(
            title: title,
            placeholder: "••••••••",
            text: text,
            icon: "lock.fill",
            textContentType: .password,
            autocapitalization: .never,
            isSecure: true,
            errorMessage: errorMessage
        )
    }
    
    /// Telefon alanı için hazır yapılandırma
    static func phone(title: String = "Telefon", text: Binding<String>, errorMessage: String? = nil) -> CustomTextField {
        CustomTextField(
            title: title,
            placeholder: "5XX XXX XX XX",
            text: text,
            icon: "phone.fill",
            keyboardType: .phonePad,
            textContentType: .telephoneNumber,
            errorMessage: errorMessage
        )
    }
}

// MARK: - Search TextField
struct SearchTextField: View {
    
    @Binding var text: String
    var placeholder: String = "Ara..."
    var onSubmit: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .onSubmit {
                    onSubmit?()
                }
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(UIConstants.cornerRadiusMedium)
    }
}

// MARK: - Text Area (Çok satırlı)
struct CustomTextArea: View {
    
    let title: String
    let placeholder: String
    @Binding var text: String
    var maxLength: Int = 500
    var minHeight: CGFloat = 100
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                
                TextEditor(text: $text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minHeight: minHeight)
                    .scrollContentBackground(.hidden)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
                        }
                    }
            }
            .background(Color(.systemGray6))
            .cornerRadius(UIConstants.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadiusMedium)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            // Karakter sayacı
            HStack {
                Spacer()
                Text("\(text.count)/\(maxLength)")
                    .font(.caption)
                    .foregroundColor(text.count >= maxLength ? .red : .gray)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 24) {
            CustomTextField.email(text: .constant(""))
            CustomTextField.password(text: .constant(""))
            CustomTextField.phone(text: .constant(""))
            
            CustomTextField(
                title: "Kullanıcı Adı",
                placeholder: "kullanici_adi",
                text: .constant(""),
                icon: "person.fill",
                autocapitalization: .never
            )
            
            CustomTextField(
                title: "Hatalı Alan",
                placeholder: "Değer girin",
                text: .constant(""),
                errorMessage: "Bu alan zorunludur"
            )
            
            SearchTextField(text: .constant(""))
            
            CustomTextArea(
                title: "Açıklama",
                placeholder: "Açıklama yazın...",
                text: .constant("")
            )
        }
        .padding()
    }
}

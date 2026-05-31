//
//  EditBillingAddressView.swift
//  HaliSahaApp
//
//  iyzico ödemesi için zorunlu fatura/iletişim adresi düzenleme ekranı.
//  Ödemeye başlamadan önce kullanıcıdan bir kez bu bilgileri istiyoruz.
//

import SwiftUI

struct EditBillingAddressView: View {

    // MARK: - Dependencies
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    private let profileService = ProfileService.shared

    // MARK: - Form State
    @State private var identityNumber: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var district: String = ""
    @State private var zipCode: String = ""

    // MARK: - UI State
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    /// Form geçerli mi? `BillingAddress.validate()` üzerinden kontrol ediyoruz.
    private var validationError: String? {
        let candidate = makeAddress()
        do {
            try candidate.validate()
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private var isFormValid: Bool { validationError == nil }

    private var hasChanges: Bool {
        let current = authService.currentUser?.billingAddress ?? BillingAddress()
        let candidate = makeAddress()
        return current != candidate
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                infoCard
                addressCard

                PrimaryButton(
                    title: "Adresi Kaydet",
                    icon: "checkmark.circle.fill",
                    isLoading: isSaving,
                    isDisabled: !isFormValid || !hasChanges
                ) {
                    Task { await saveAddress() }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle("Fatura Adresi")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadCurrentAddress() }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Başarılı", isPresented: $showSuccess) {
            Button("Tamam", role: .cancel) { dismiss() }
        } message: {
            Text("Fatura adresiniz güncellendi.")
        }
    }

    // MARK: - Info Card
    private var infoCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundColor(Color(hex: "2E7D32"))

            Text(
                "Kapora ödemesi için bankaların gerektirdiği bilgilerdir. "
                + "Bilgileriniz iyzico üzerinden güvenli şekilde işlenir."
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }

    // MARK: - Address Card
    private var addressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Fatura Bilgileri")
                    .font(.headline)
            } icon: {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(Color(hex: "2E7D32"))
            }

            VStack(spacing: 14) {
                CustomTextField(
                    title: "TC Kimlik No",
                    placeholder: "11 haneli kimlik numarası",
                    text: $identityNumber,
                    icon: "person.text.rectangle.fill",
                    keyboardType: .numberPad,
                    textContentType: nil,
                    errorMessage: identityFieldError
                )

                CustomTextField(
                    title: "Açık Adres",
                    placeholder: "Mahalle, sokak, daire no",
                    text: $address,
                    icon: "house.fill",
                    textContentType: .fullStreetAddress,
                    errorMessage: nil
                )

                HStack(spacing: 12) {
                    CustomTextField(
                        title: "Şehir",
                        placeholder: "İstanbul",
                        text: $city,
                        icon: "building.2.fill",
                        textContentType: .addressCity,
                        errorMessage: nil
                    )

                    CustomTextField(
                        title: "İlçe",
                        placeholder: "Kadıköy",
                        text: $district,
                        textContentType: .sublocality,
                        errorMessage: nil
                    )
                }

                CustomTextField(
                    title: "Posta Kodu (opsiyonel)",
                    placeholder: "34000",
                    text: $zipCode,
                    icon: "number",
                    keyboardType: .numberPad,
                    textContentType: .postalCode,
                    errorMessage: nil
                )
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }

    // MARK: - Field-level error (only after user types something)
    private var identityFieldError: String? {
        guard !identityNumber.isEmpty else { return nil }
        let trimmed = identityNumber.trimmingCharacters(in: .whitespaces)
        if trimmed.count != 11 || !trimmed.allSatisfy(\.isNumber) {
            return "11 haneli geçerli bir TC Kimlik No girin."
        }
        return nil
    }

    // MARK: - Helpers
    private func makeAddress() -> BillingAddress {
        BillingAddress(
            identityNumber: identityNumber.trimmingCharacters(in: .whitespaces),
            address: address.trimmingCharacters(in: .whitespaces),
            city: city.trimmingCharacters(in: .whitespaces),
            district: district.trimmingCharacters(in: .whitespaces),
            zipCode: zipCode.trimmingCharacters(in: .whitespaces),
            country: "Turkey"
        )
    }

    private func loadCurrentAddress() {
        guard let current = authService.currentUser?.billingAddress else { return }
        identityNumber = current.identityNumber
        address = current.address
        city = current.city
        district = current.district
        zipCode = current.zipCode
    }

    @MainActor
    private func saveAddress() async {
        let candidate = makeAddress()
        do {
            try candidate.validate()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return
        }

        isSaving = true
        do {
            let updated = try await profileService.updateBillingAddress(candidate)
            authService.currentUser = updated
            isSaving = false
            showSuccess = true
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    NavigationStack {
        EditBillingAddressView()
    }
}

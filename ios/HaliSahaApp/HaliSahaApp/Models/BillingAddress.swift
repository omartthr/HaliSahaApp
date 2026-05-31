//
//  BillingAddress.swift
//  HaliSahaApp
//
//  iyzico ödeme entegrasyonu için kullanıcı fatura/iletişim adresi.
//  3DS akışında iyzico tarafından zorunlu kılınan alanları taşır.
//

import Foundation

struct BillingAddress: Codable, Hashable {
    var identityNumber: String   // TC Kimlik No (11 hane)
    var address: String          // Açık adres
    var city: String             // İl
    var district: String         // İlçe
    var zipCode: String          // Posta kodu
    var country: String          // Ülke (varsayılan: Turkey)

    init(
        identityNumber: String = "",
        address: String = "",
        city: String = "",
        district: String = "",
        zipCode: String = "",
        country: String = "Turkey"
    ) {
        self.identityNumber = identityNumber
        self.address = address
        self.city = city
        self.district = district
        self.zipCode = zipCode
        self.country = country
    }

    /// Iyzico'ya yollanmadan önce minimum doğrulama yapar. Eksik alan varsa hata fırlatır.
    func validate() throws {
        let trimmedTCKN = identityNumber.trimmingCharacters(in: .whitespaces)
        guard trimmedTCKN.count == 11, trimmedTCKN.allSatisfy(\.isNumber) else {
            throw BillingAddressError.invalidIdentityNumber
        }
        guard !address.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw BillingAddressError.missingField("Adres")
        }
        guard !city.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw BillingAddressError.missingField("Şehir")
        }
        guard !district.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw BillingAddressError.missingField("İlçe")
        }
    }

    var isComplete: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }
}

enum BillingAddressError: LocalizedError {
    case invalidIdentityNumber
    case missingField(String)

    var errorDescription: String? {
        switch self {
        case .invalidIdentityNumber:
            return "Geçerli bir 11 haneli TC Kimlik No giriniz."
        case .missingField(let field):
            return "\(field) alanı boş bırakılamaz."
        }
    }
}

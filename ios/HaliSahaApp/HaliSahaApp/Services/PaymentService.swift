//
//  PaymentService.swift
//  HaliSahaApp
//
//  iyzico ödeme entegrasyonu için Cloud Functions istemcisi.
//  Tüm hassas işlemler (3DS init, refund) server-side fonksiyonlar üzerinden
//  yürütülür. Client kart bilgisi GÖRMEZ — sadece iyzico'nun hosted
//  CheckoutForm sayfasını WebView'de açar.
//

import FirebaseFunctions
import Foundation

@MainActor
final class PaymentService {

    // MARK: - Singleton
    static let shared = PaymentService()

    // MARK: - Dependencies
    /// Cloud Functions europe-west1 bölgesinde deploy edildi.
    private lazy var functions: Functions = Functions.functions(region: "europe-west1")

    private init() {}

    // MARK: - Payment Initiation

    /// Iyzico CheckoutForm'u initialize eder, iOS WebView'de açılacak ödeme
    /// sayfasının URL'ini döner. WebView ekranı `paymentDocId` üzerinden
    /// Firestore listener kurarak ödeme sonucunu izlemelidir.
    func initiateDepositPayment(bookingId: String) async throws -> InitiateDepositResult {
        let callable = functions.httpsCallable("initiateDepositPayment")

        let payload: [String: Any] = [
            "bookingId": bookingId
        ]

        let result: HTTPSCallableResult
        do {
            result = try await callable.call(payload)
        } catch {
            throw mapFunctionsError(error)
        }

        guard let dict = result.data as? [String: Any],
            let token = dict["token"] as? String,
            let pageUrl = dict["paymentPageUrl"] as? String,
            let paymentDocId = dict["paymentDocId"] as? String,
            let url = URL(string: pageUrl)
        else {
            throw PaymentError.invalidServerResponse
        }

        return InitiateDepositResult(
            token: token,
            paymentPageUrl: url,
            paymentDocId: paymentDocId
        )
    }

    // MARK: - Refund

    /// İptal sırasında kapora iadesi tetikler. İade yüzdesini sunucu hesaplar
    /// (24h+ = %100, 12-24h = %50, <12h = %0). Sunucu iadeyi tamamlar ve
    /// booking'i `cancelled` + uygun `paymentStatus`'a günceller.
    func refundDeposit(bookingId: String, reason: String?) async throws -> RefundResultData {
        let callable = functions.httpsCallable("refundDeposit")

        var payload: [String: Any] = ["bookingId": bookingId]
        if let reason, !reason.isEmpty {
            payload["reason"] = reason
        }

        let result: HTTPSCallableResult
        do {
            result = try await callable.call(payload)
        } catch {
            throw mapFunctionsError(error)
        }

        guard let dict = result.data as? [String: Any],
            let refundedAmount = (dict["refundedAmount"] as? NSNumber)?.doubleValue,
            let refundPercentage = (dict["refundPercentage"] as? NSNumber)?.doubleValue,
            let statusRaw = dict["paymentStatus"] as? String,
            let paymentStatus = PaymentStatus(rawValue: statusRaw)
        else {
            throw PaymentError.invalidServerResponse
        }

        return RefundResultData(
            refundedAmount: refundedAmount,
            refundPercentage: refundPercentage,
            paymentStatus: paymentStatus
        )
    }

    // MARK: - Error mapping

    /// `NSError`'dan gelen `FunctionsErrorCode` ve `FunctionsErrorDetailsKey`
    /// alanlarını okuyup kullanıcı dostu hata mesajı üretir. Sunucu tarafındaki
    /// HttpsError'larda `message` alanı buraya direkt geçer.
    private func mapFunctionsError(_ error: Error) -> PaymentError {
        let nsError = error as NSError
        guard nsError.domain == FunctionsErrorDomain else {
            return .underlying(error)
        }

        let code = FunctionsErrorCode(rawValue: nsError.code) ?? .unknown
        let serverMessage =
            (nsError.userInfo[FunctionsErrorDetailsKey] as? String)
            ?? nsError.localizedDescription

        switch code {
        case .unauthenticated:
            return .unauthenticated
        case .permissionDenied:
            return .permissionDenied
        case .failedPrecondition:
            return .precondition(serverMessage)
        case .notFound:
            return .notFound(serverMessage)
        case .invalidArgument:
            return .invalidArgument(serverMessage)
        default:
            return .server(serverMessage)
        }
    }
}

// MARK: - Result types

struct InitiateDepositResult {
    let token: String
    let paymentPageUrl: URL
    let paymentDocId: String
}

struct RefundResultData {
    let refundedAmount: Double
    let refundPercentage: Double
    let paymentStatus: PaymentStatus
}

// MARK: - Errors

enum PaymentError: LocalizedError {
    case unauthenticated
    case permissionDenied
    case notFound(String)
    case invalidArgument(String)
    case precondition(String)
    case server(String)
    case invalidServerResponse
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "Bu işlem için giriş yapmalısınız."
        case .permissionDenied:
            return "Bu işlem için yetkiniz yok."
        case .notFound(let msg):
            return msg
        case .invalidArgument(let msg):
            return msg
        case .precondition(let msg):
            return msg
        case .server(let msg):
            return msg
        case .invalidServerResponse:
            return "Sunucudan geçersiz yanıt alındı. Lütfen tekrar deneyin."
        case .underlying(let err):
            return err.localizedDescription
        }
    }
}

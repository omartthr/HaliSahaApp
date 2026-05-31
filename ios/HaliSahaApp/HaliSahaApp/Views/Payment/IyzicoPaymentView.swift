//
//  IyzicoPaymentView.swift
//  HaliSahaApp
//
//  Kullanıcıya iyzico'nun barındırdığı 3DS ödeme sayfasını sunan WebView.
//  Kart bilgileri tamamen iyzico tarafında girilir; uygulama bu verileri
//  hiçbir zaman görmez. Sonuç, server-side `iyzicoCallback` fonksiyonu
//  tarafından Firestore'a yazılır ve burada listener üzerinden yakalanır.
//

import FirebaseFirestore
import SwiftUI
import WebKit

// MARK: - Outcome

enum IyzicoPaymentOutcome: Equatable {
    case success
    case failed(String)
    case cancelled
    case expired
}

// MARK: - Main view

struct IyzicoPaymentView: View {

    let paymentPageUrl: URL
    let paymentDocId: String
    let onFinish: (IyzicoPaymentOutcome) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var listener: ListenerRegistration?
    @State private var hasFinished = false
    @State private var showCancelConfirm = false
    @State private var loadProgress: Double = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                IyzicoWebView(
                    url: paymentPageUrl,
                    progress: $loadProgress
                )
                .ignoresSafeArea(edges: .bottom)

                if loadProgress < 1 {
                    ProgressView(value: loadProgress)
                        .progressViewStyle(.linear)
                        .tint(Color(hex: "2E7D32"))
                }
            }
            .navigationTitle("Kapora Ödemesi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { showCancelConfirm = true }
                        .tint(.red)
                }
            }
            .alert("Ödemeyi iptal et", isPresented: $showCancelConfirm) {
                Button("Devam Et", role: .cancel) {}
                Button("Vazgeç", role: .destructive) {
                    finish(with: .cancelled)
                }
            } message: {
                Text("Ödeme sürecini iptal etmek istediğinize emin misiniz?")
            }
        }
        .interactiveDismissDisabled(true)
        .onAppear { startListener() }
        .onDisappear { stopListener() }
    }

    // MARK: - Firestore listener

    /// `payments/{paymentDocId}` dokümanını dinler. Sunucu `iyzicoCallback`
    /// fonksiyonu içinde `status: succeeded | failed` yazıyor — biz buradan
    /// görüp WebView'i kapatıyoruz.
    private func startListener() {
        let ref = Firestore.firestore().collection("payments").document(paymentDocId)
        listener = ref.addSnapshotListener { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            guard let status = data["status"] as? String else { return }

            switch status {
            case "succeeded":
                finish(with: .success)
            case "failed":
                let msg = (data["errorMessage"] as? String) ?? "Ödeme tamamlanamadı."
                finish(with: .failed(msg))
            default:
                break
            }
        }
    }

    private func stopListener() {
        listener?.remove()
        listener = nil
    }

    private func finish(with outcome: IyzicoPaymentOutcome) {
        guard !hasFinished else { return }
        hasFinished = true
        stopListener()
        onFinish(outcome)
    }
}

// MARK: - UIViewRepresentable WKWebView

private struct IyzicoWebView: UIViewRepresentable {

    let url: URL
    @Binding var progress: Double

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // iyzico bazı JavaScript özelliklerine ihtiyaç duyar
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        if #available(iOS 14.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = context.coordinator

        // KVO ile yükleme ilerlemesini izle
        webView.addObserver(
            context.coordinator,
            forKeyPath: #keyPath(WKWebView.estimatedProgress),
            options: .new,
            context: nil
        )
        context.coordinator.observedWebView = webView

        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // URL sabit; tekrar yükleme gerekmiyor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(progress: $progress)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.detach()
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var progress: Double
        weak var observedWebView: WKWebView?

        init(progress: Binding<Double>) {
            self._progress = progress
        }

        func detach() {
            if let wv = observedWebView {
                wv.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
                observedWebView = nil
            }
        }

        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            guard keyPath == #keyPath(WKWebView.estimatedProgress),
                let value = change?[.newKey] as? Double
            else { return }
            DispatchQueue.main.async {
                self.progress = value >= 0.999 ? 1.0 : value
            }
        }
    }
}

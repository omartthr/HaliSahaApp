# ALO Halısaha

Türkiye'nin halı saha rezervasyon ve maç organizasyon platformu. Web, iOS ve Android istemcileri Firebase backend üzerinde çalışır.

## Özellikler

- Harita üzerinde saha arama ve rezervasyon
- %20 kapora ile güvenli ödeme (Iyzico 3DS)
- "Maç Kur" — eksik oyuncu arama ve maç ilanı
- Grup sohbeti ve oyuncu mesajlaşması
- Admin paneli — tesis ve rezervasyon yönetimi
- SuperAdmin — tesis sahibi başvuru onaylama
- AI asistan "ALO Bot" (Google Gemini)

## Teknoloji Stack'i

| Katman | Teknoloji |
|--------|-----------|
| Web | Next.js 16 (App Router) · React 19 · TypeScript |
| iOS | Swift · SwiftUI |
| Android | Kotlin · Jetpack Compose · MVVM |
| Backend | Firebase Cloud Functions v2 (Node 24) |
| Veritabanı | Cloud Firestore |
| Auth | Firebase Authentication |
| Storage | Firebase Storage |
| Ödeme | Iyzico CheckoutForm (3DS) |
| AI | Google Gemini (`gemini-2.5-flash-preview-04-17`) |
| Harita | Leaflet · Google Maps |

## Proje Yapısı

```
HaliSahaApp/
├── web/          # Next.js web uygulaması
├── functions/    # Firebase Cloud Functions
├── ios/          # Swift/SwiftUI iOS uygulaması
├── android/      # Kotlin/Compose Android uygulaması
└── openapi.yaml  # API dokümantasyonu (OpenAPI 3.0)
```

## Kurulum

### Web

```bash
cd web
npm install
cp .env.example .env.local   # Firebase config değerlerini doldur
npm run dev
```

### Cloud Functions

```bash
cd functions
npm install
npm run build
```

Firebase secrets set et (ilk deploydanönce):

```bash
firebase functions:secrets:set IYZICO_API_KEY
firebase functions:secrets:set IYZICO_SECRET_KEY
firebase functions:secrets:set IYZICO_BASE_URL   # https://sandbox-api.iyzipay.com
firebase functions:params:set WEB_APP_URL="https://your-domain.com"
firebase functions:secrets:set GEMINI_API_KEY
```

Deploy:

```bash
firebase deploy --only functions
```

### Android

Android Studio ile `android/` klasörünü aç, `google-services.json` dosyasını `android/app/` altına koy, build al.

### iOS

Xcode ile `ios/HaliSahaApp/HaliSahaApp.xcodeproj` dosyasını aç, `GoogleService-Info.plist` dosyasını ekle, çalıştır.

## Environment Variables

### Web (`web/.env.local`)

```env
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=
GEMINI_API_KEY=
```

## Cloud Functions API

Tüm endpoint'ler `openapi.yaml` dosyasında OpenAPI 3.0 formatında belgelenmiştir.

| Fonksiyon | Tip | Açıklama |
|-----------|-----|---------|
| `geminiChat` | Callable | AI sohbet asistanı |
| `initiateDepositPayment` | Callable | Iyzico kapora ödemesi başlat |
| `iyzicoCallback` | HTTP | Iyzico ödeme webhook'u |
| `refundDeposit` | Callable | Kapora iadesi |

Tüm callable function'lar `europe-west1` bölgesinde çalışır.

## Ödeme Akışı

```
Kullanıcı → BookingPaymentModal
         → initiateDepositPayment (Cloud Function)
         → Iyzico 3DS Sayfası
         → iyzicoCallback (webhook)
         → /payment-result (Firestore listener)
```

İade politikası: 24+ saat → %100, 12-24 saat → %50, 12 saat altı → %0

## Firebase Projesi

- **Project ID:** `halisahaapp-d611b`
- **Region:** `europe-west1`
- **Firestore Rules:** `ios/HaliSahaApp/firestore.rules`

## Lisans

Bu proje özel kullanım amaçlıdır.

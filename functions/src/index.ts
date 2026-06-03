import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";
import { GoogleGenerativeAI } from "@google/generative-ai";
import * as admin from "firebase-admin";
import Iyzipay = require("iyzipay");

admin.initializeApp();

// ─── Secrets & Params ────────────────────────────────────────────────────────
const geminiKey    = defineSecret("GEMINI_API_KEY");
const iyziApiKey   = defineSecret("IYZICO_API_KEY");
const iyziSecKey   = defineSecret("IYZICO_SECRET_KEY");
const iyziBaseUrl  = defineSecret("IYZICO_BASE_URL"); // https://sandbox-api.iyzipay.com
const webAppUrl    = defineString("WEB_APP_URL", { default: "http://localhost:3000" });

// ─── Helpers ─────────────────────────────────────────────────────────────────
function makeIyzipay(apiKey: string, secretKey: string, uri: string): Iyzipay {
  return new Iyzipay({ apiKey, secretKey, uri: uri || "https://sandbox-api.iyzipay.com" });
}

// ─── Gemini Chat ─────────────────────────────────────────────────────────────
const SYSTEM_PROMPT = `Sen ALO Halısaha platformunun yardımcı asistanısın.
Adın "ALO Bot". Türkçe konuşuyorsun ve kısa, samimi, yardımsever cevaplar veriyorsun.

Platform hakkında bilgiler:
- ALO Halısaha, Türkiye'nin halı saha rezervasyon ve maç organizasyon platformudur.
- Kullanıcılar sahaya kolayca rezervasyon yapabilir, yakınlarındaki sahaları haritada görebilir.
- "Maç Kur" özelliği ile arkadaşlarını veya yabancıları bir araya getirerek maç organize edebilirler.
- "Gruplar" bölümünde açık maç ilanlarına katılabilirler.
- Profil sayfasında geçmiş rezervasyonlarını ve puanlarını görebilirler.
- Rezervasyon için %20 kapora alınır, onay sonrası kesinleşir.

Kapsam dışı sorularda nazikçe "Bu konuda yardımcı olamam, saha rezervasyonu veya maç hakkında bir sorun var mı?" de.
Cevaplarını 2-3 cümleyi geçmeyecek şekilde kısa tut.`;

export const geminiChat = onCall(
  { secrets: [geminiKey], region: "europe-west1", cors: true },
  async (request) => {
    const { message, history } = request.data as {
      message: string;
      history: { role: string; text: string }[];
    };

    if (!message || message.trim() === "") {
      throw new HttpsError("invalid-argument", "Mesaj boş olamaz.");
    }

    const genAI = new GoogleGenerativeAI(geminiKey.value());
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash-preview-04-17",
      systemInstruction: SYSTEM_PROMPT,
    });

    const formattedHistory = (history || []).map((msg) => ({
      role: msg.role === "user" ? "user" : "model",
      parts: [{ text: msg.text }],
    }));

    const chat = model.startChat({ history: formattedHistory });
    const result = await chat.sendMessage(message);
    return { reply: result.response.text() };
  }
);

// ─── initiateDepositPayment ───────────────────────────────────────────────────
export const initiateDepositPayment = onCall(
  {
    secrets: [iyziApiKey, iyziSecKey, iyziBaseUrl],
    region: "europe-west1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Bu işlem için giriş yapmalısınız.");
    }

    const { bookingId } = request.data as { bookingId: string };
    if (!bookingId) {
      throw new HttpsError("invalid-argument", "Rezervasyon ID gerekli.");
    }

    const db = admin.firestore();
    const userId = request.auth.uid;

    // Booking al
    const bookingSnap = await db.collection("bookings").doc(bookingId).get();
    if (!bookingSnap.exists) throw new HttpsError("not-found", "Rezervasyon bulunamadı.");
    const booking = bookingSnap.data()!;
    if (booking.userId !== userId) throw new HttpsError("permission-denied", "Yetkisiz erişim.");

    // Kullanıcı profili & fatura adresi
    const userSnap = await db.collection("users").doc(userId).get();
    if (!userSnap.exists) throw new HttpsError("not-found", "Kullanıcı profili bulunamadı.");
    const userData = userSnap.data()!;
    const billing = userData.billingAddress as Record<string, string> | undefined;

    if (!billing) {
      throw new HttpsError(
        "failed-precondition",
        "Lütfen önce TC Kimlik No ve adres bilgilerinizi ekleyin."
      );
    }

    const tc = (billing.identityNumber || "").replace(/\s/g, "");
    if (tc.length !== 11 || !/^\d{11}$/.test(tc)) {
      throw new HttpsError("failed-precondition", "Geçerli bir TC Kimlik No giriniz.");
    }

    const depositAmount: number = booking.depositAmount || Math.round((booking.totalPrice || 0) * 0.2);
    if (depositAmount <= 0) {
      throw new HttpsError("failed-precondition", "Geçersiz kapora tutarı.");
    }

    const iyzipay = makeIyzipay(iyziApiKey.value(), iyziSecKey.value(), iyziBaseUrl.value());
    const projectId = process.env.GCLOUD_PROJECT ?? "halısahaapp";
    const callbackBase = `https://europe-west1-${projectId}.cloudfunctions.net/iyzicoCallback`;

    // Payment doc önceden oluştur (ID için)
    const paymentRef = db.collection("payments").doc();
    const paymentDocId = paymentRef.id;
    const callbackUrl = `${callbackBase}?docId=${paymentDocId}`;

    const firstName = userData.firstName || "Ad";
    const lastName  = userData.lastName  || "Soyad";
    const email     = userData.email     || request.auth.token.email || "user@example.com";
    const gsmRaw    = (userData.phone || "5000000000").replace(/^\+?90/, "").replace(/^0/, "");
    const gsm       = `+90${gsmRaw}`;
    const priceStr  = depositAmount.toFixed(2);
    const now       = new Date().toISOString().replace("T", " ").slice(0, 19);

    const checkoutReq: Record<string, unknown> = {
      locale: Iyzipay.LOCALE.TR,
      conversationId: paymentDocId,
      price: priceStr,
      paidPrice: priceStr,
      currency: Iyzipay.CURRENCY.TRY,
      basketId: bookingId,
      paymentGroup: Iyzipay.PAYMENT_GROUP.PRODUCT,
      callbackUrl,
      enabledInstallments: [1],
      buyer: {
        id: userId,
        name: firstName,
        surname: lastName,
        gsmNumber: gsm,
        email,
        identityNumber: tc,
        lastLoginDate: now,
        registrationDate: now,
        registrationAddress: billing.address,
        ip: "85.34.78.112",
        city: billing.city,
        country: billing.country || "Turkey",
        zipCode: billing.zipCode || "34000",
      },
      shippingAddress: {
        contactName: `${firstName} ${lastName}`,
        city: billing.city,
        country: billing.country || "Turkey",
        address: billing.address,
        zipCode: billing.zipCode || "34000",
      },
      billingAddress: {
        contactName: `${firstName} ${lastName}`,
        city: billing.city,
        country: billing.country || "Turkey",
        address: billing.address,
        zipCode: billing.zipCode || "34000",
      },
      basketItems: [
        {
          id: bookingId,
          name: `${(booking.fieldName as string || "Halı Saha").substring(0, 40)} Kaporası`,
          category1: "Spor",
          category2: "Halı Saha",
          itemType: Iyzipay.BASKET_ITEM_TYPE.VIRTUAL,
          price: priceStr,
        },
      ],
    };

    const checkoutResult = await new Promise<{ status: string; token: string; paymentPageUrl: string; errorMessage?: string }>(
      (resolve, reject) => {
        iyzipay.checkoutFormInitialize.create(checkoutReq, (err, result) => {
          if (err) reject(new Error(err.message));
          else resolve(result);
        });
      }
    );

    if (checkoutResult.status !== "success") {
      throw new HttpsError("internal", checkoutResult.errorMessage || "Ödeme sistemi başlatılamadı.");
    }

    // Payment dokümanını kaydet
    await paymentRef.set({
      bookingId,
      userId,
      amount: depositAmount,
      currency: "TRY",
      status: "pending",
      iyzicoToken: checkoutResult.token,
      webhookReceived: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Booking'e paymentDocId ekle
    await db.collection("bookings").doc(bookingId).update({
      paymentDocId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      token: checkoutResult.token,
      paymentPageUrl: checkoutResult.paymentPageUrl,
      paymentDocId,
    };
  }
);

// ─── iyzicoCallback (HTTP — Iyzico'dan POST + kullanıcı yönlendirmesi) ────────
export const iyzicoCallback = onRequest(
  { region: "europe-west1", secrets: [iyziApiKey, iyziSecKey, iyziBaseUrl] },
  async (req, res) => {
    const token     = (req.body?.token || req.query.token) as string | undefined;
    const paymentDocId = req.query.docId as string | undefined;
    const appUrl    = webAppUrl.value();

    if (!token || !paymentDocId) {
      res.redirect(`${appUrl}/payment-result?status=error`);
      return;
    }

    const iyzipay = makeIyzipay(iyziApiKey.value(), iyziSecKey.value(), iyziBaseUrl.value());
    const db = admin.firestore();

    try {
      const paymentSnap = await db.collection("payments").doc(paymentDocId).get();
      if (!paymentSnap.exists) {
        res.redirect(`${appUrl}/payment-result?docId=${paymentDocId}&status=error`);
        return;
      }

      const paymentData = paymentSnap.data()!;

      // İdempotency: tekrar işleme
      if (paymentData.webhookReceived) {
        const st = paymentData.status === "succeeded" ? "success" : "failed";
        res.redirect(`${appUrl}/payment-result?docId=${paymentDocId}&status=${st}`);
        return;
      }

      // Iyzico'dan ödeme sonucunu doğrula
      const authResult = await new Promise<{ status: string; paymentStatus?: string; paymentId?: string; conversationId?: string; errorMessage?: string }>(
        (resolve, reject) => {
          iyzipay.checkoutForm.retrieve(
            { locale: Iyzipay.LOCALE.TR, token },
            (err, result) => {
              if (err) reject(err);
              else resolve(result);
            }
          );
        }
      );

      const succeeded =
        authResult.status === "success" && authResult.paymentStatus === "SUCCESS";

      await db.collection("payments").doc(paymentDocId).update({
        status: succeeded ? "succeeded" : "failed",
        errorMessage: succeeded ? null : (authResult.errorMessage || "Ödeme başarısız"),
        webhookReceived: true,
        iyzicoPaymentId: authResult.paymentId || null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (succeeded) {
        await db.collection("bookings").doc(paymentData.bookingId).update({
          status: "confirmed",
          paymentStatus: "depositPaid",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      const finalStatus = succeeded ? "success" : "failed";
      res.redirect(`${appUrl}/payment-result?docId=${paymentDocId}&status=${finalStatus}`);
    } catch {
      res.redirect(`${appUrl}/payment-result?docId=${paymentDocId}&status=error`);
    }
  }
);

// ─── refundDeposit ────────────────────────────────────────────────────────────
export const refundDeposit = onCall(
  {
    secrets: [iyziApiKey, iyziSecKey, iyziBaseUrl],
    region: "europe-west1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Bu işlem için giriş yapmalısınız.");
    }

    const { bookingId, reason } = request.data as { bookingId: string; reason?: string };
    if (!bookingId) throw new HttpsError("invalid-argument", "Rezervasyon ID gerekli.");

    const db = admin.firestore();
    const userId = request.auth.uid;

    const bookingSnap = await db.collection("bookings").doc(bookingId).get();
    if (!bookingSnap.exists) throw new HttpsError("not-found", "Rezervasyon bulunamadı.");
    const booking = bookingSnap.data()!;
    if (booking.userId !== userId) throw new HttpsError("permission-denied", "Yetkisiz erişim.");
    if (booking.paymentStatus !== "depositPaid") {
      throw new HttpsError("failed-precondition", "Bu rezervasyon için iade yapılamaz.");
    }

    const paymentQuery = await db
      .collection("payments")
      .where("bookingId", "==", bookingId)
      .where("status", "==", "succeeded")
      .limit(1)
      .get();

    if (paymentQuery.empty) throw new HttpsError("not-found", "Ödeme kaydı bulunamadı.");
    const paymentDoc  = paymentQuery.docs[0];
    const paymentData = paymentDoc.data();

    // Zaman bazlı iade yüzdesi
    const bookingDate  = booking.date as string;
    const startHour    = (booking.startHour as number | undefined) ?? 8;
    const bookingDT    = new Date(`${bookingDate}T${String(startHour).padStart(2, "0")}:00:00`);
    const hoursLeft    = (bookingDT.getTime() - Date.now()) / 3_600_000;

    let refundPct = 0;
    if (hoursLeft >= 24) refundPct = 1.0;
    else if (hoursLeft >= 12) refundPct = 0.5;

    const depositAmount  = paymentData.amount as number;
    const refundedAmount = Math.round(depositAmount * refundPct);

    if (refundedAmount > 0 && paymentData.iyzicoPaymentId) {
      const iyzipay = makeIyzipay(iyziApiKey.value(), iyziSecKey.value(), iyziBaseUrl.value());

      const refundResult = await new Promise<{ status: string; errorMessage?: string }>(
        (resolve, reject) => {
          iyzipay.refund.create(
            {
              locale: Iyzipay.LOCALE.TR,
              conversationId: `refund-${bookingId}`,
              paymentTransactionId: paymentData.iyzicoPaymentId,
              price: refundedAmount.toFixed(2),
              currency: Iyzipay.CURRENCY.TRY,
              ip: "85.34.78.112",
            },
            (err, result) => {
              if (err) reject(err);
              else resolve(result);
            }
          );
        }
      );

      if (refundResult.status !== "success") {
        throw new HttpsError("internal", refundResult.errorMessage || "İade işlemi başarısız.");
      }
    }

    const newPaymentStatus = refundPct === 1.0 ? "refunded" : refundPct === 0.5 ? "partialRefund" : "noRefund";

    await paymentDoc.ref.update({
      status: "refunded",
      refundedAmount,
      refundPercentage: refundPct,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection("bookings").doc(bookingId).update({
      status: "cancelled",
      paymentStatus: newPaymentStatus,
      cancellationReason: reason || "Kullanıcı tarafından iptal edildi",
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { refundedAmount, refundPercentage: refundPct, paymentStatus: newPaymentStatus };
  }
);

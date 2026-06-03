import { doc, getDoc, setDoc, onSnapshot } from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { db, functions } from "@/database/firebase";

export type BillingAddress = {
  identityNumber: string;
  address: string;
  city: string;
  district: string;
  zipCode?: string;
  country: string;
};

export type PaymentStatus = "pending" | "succeeded" | "failed";

export type InitiatePaymentResult = {
  token: string;
  paymentPageUrl: string;
  paymentDocId: string;
};

export type RefundResult = {
  refundedAmount: number;
  refundPercentage: number;
  paymentStatus: string;
};

/** Kullanıcının kayıtlı fatura adresini Firestore'dan okur */
export async function getBillingAddress(userId: string): Promise<BillingAddress | null> {
  const snap = await getDoc(doc(db, "users", userId));
  if (!snap.exists()) return null;
  return (snap.data().billingAddress as BillingAddress) ?? null;
}

/** Fatura adresini Firestore'a kaydeder (users/{userId}.billingAddress) */
export async function saveBillingAddress(userId: string, billingAddress: BillingAddress): Promise<void> {
  await setDoc(doc(db, "users", userId), { billingAddress }, { merge: true });
}

/** Cloud Function çağrısı: Iyzico CheckoutForm başlatır */
export async function initiatePayment(bookingId: string): Promise<InitiatePaymentResult> {
  const fn = httpsCallable<{ bookingId: string }, InitiatePaymentResult>(
    functions,
    "initiateDepositPayment"
  );
  const result = await fn({ bookingId });
  return result.data;
}

/** payments/{paymentDocId} dokümanını gerçek zamanlı dinler, iOS'taki gibi */
export function listenToPayment(
  paymentDocId: string,
  callback: (status: PaymentStatus, errorMessage?: string) => void
): () => void {
  return onSnapshot(doc(db, "payments", paymentDocId), (snap) => {
    const data = snap.data();
    if (!data) return;
    const status = data.status as PaymentStatus;
    if (status === "succeeded" || status === "failed") {
      callback(status, data.errorMessage as string | undefined);
    }
  });
}

/** Cloud Function çağrısı: kapora iadesi */
export async function refundBooking(bookingId: string, reason?: string): Promise<RefundResult> {
  const fn = httpsCallable<{ bookingId: string; reason?: string }, RefundResult>(
    functions,
    "refundDeposit"
  );
  const result = await fn({ bookingId, reason });
  return result.data;
}

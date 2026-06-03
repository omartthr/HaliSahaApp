"use client";

import React, { useEffect, useState, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import Navbar from "@/frontend/components/common/Navbar";
import { CheckCircle2, XCircle, Loader2 } from "lucide-react";
import { doc, onSnapshot } from "firebase/firestore";
import { db } from "@/database/firebase";

type UIStatus = "loading" | "succeeded" | "failed" | "error";

function PaymentResultContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const [status, setStatus] = useState<UIStatus>("loading");
  const [errorMsg, setErrorMsg] = useState<string>("");

  useEffect(() => {
    const docId     = searchParams.get("docId");
    const urlStatus = searchParams.get("status");

    // URL'deki status parametresi hızlı bir ipucu — Firestore listener kesin cevap verir
    if (urlStatus === "error" && !docId) {
      setStatus("error");
      return;
    }

    if (!docId) {
      setStatus("error");
      return;
    }

    // Iyzico callback'te "failed" geldiyse direkt göster
    if (urlStatus === "failed") {
      setStatus("failed");
    }

    // Firestore gerçek zamanlı dinleyici (iOS'taki startListener() ile aynı mantık)
    const unsubscribe = onSnapshot(doc(db, "payments", docId), (snap) => {
      const data = snap.data();
      if (!data) return;

      if (data.status === "succeeded") {
        setStatus("succeeded");
      } else if (data.status === "failed") {
        setStatus("failed");
        setErrorMsg((data.errorMessage as string | undefined) ?? "Ödeme tamamlanamadı.");
      }
    });

    return unsubscribe;
  }, [searchParams]);

  const cardStyle: React.CSSProperties = {
    background: "#fff",
    borderRadius: 24,
    padding: "48px 40px",
    maxWidth: 420,
    width: "90%",
    textAlign: "center",
    boxShadow: "0 20px 60px rgba(0,0,0,0.10)",
  };

  return (
    <div className="page-wrapper">
      <Navbar />
      <div style={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: "calc(100vh - 80px)", padding: 16 }}>
        <div style={cardStyle}>

          {/* ── Yükleniyor ── */}
          {status === "loading" && (
            <>
              <div style={{ display: "flex", justifyContent: "center", marginBottom: 24 }}>
                <Loader2 size={56} color="#2E7D32" style={{ animation: "pr-spin 1s linear infinite" }} />
              </div>
              <h2 style={{ fontSize: 20, fontWeight: 800, color: "#111827", margin: "0 0 8px" }}>
                Ödeme kontrol ediliyor...
              </h2>
              <p style={{ color: "#6b7280", margin: 0 }}>Lütfen birkaç saniye bekleyin.</p>
              <style>{`@keyframes pr-spin { to { transform: rotate(360deg); } }`}</style>
            </>
          )}

          {/* ── Başarılı ── */}
          {status === "succeeded" && (
            <>
              <div style={{ width: 80, height: 80, borderRadius: "50%", background: "#E8F5E9", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 24px" }}>
                <CheckCircle2 size={44} color="#2E7D32" />
              </div>
              <h2 style={{ fontSize: 24, fontWeight: 900, color: "#111827", margin: "0 0 12px" }}>
                Kapora Ödendi!
              </h2>
              <p style={{ color: "#6b7280", lineHeight: 1.6, margin: "0 0 32px" }}>
                Rezervasyonunuz onay sürecine alındı. Saha sahibi onayladığında bildirim alacaksınız.
              </p>
              <button
                onClick={() => router.push("/profile")}
                style={{ width: "100%", background: "#2E7D32", color: "#fff", padding: "14px", borderRadius: 14, border: "none", fontWeight: 700, fontSize: 15, cursor: "pointer" }}
              >
                Rezervasyonlarıma Git
              </button>
            </>
          )}

          {/* ── Başarısız / Hata ── */}
          {(status === "failed" || status === "error") && (
            <>
              <div style={{ width: 80, height: 80, borderRadius: "50%", background: "#FFEBEE", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 24px" }}>
                <XCircle size={44} color="#C62828" />
              </div>
              <h2 style={{ fontSize: 24, fontWeight: 900, color: "#111827", margin: "0 0 12px" }}>
                Ödeme Başarısız
              </h2>
              <p style={{ color: "#6b7280", margin: "0 0 32px", lineHeight: 1.5 }}>
                {errorMsg || "Ödeme işlemi tamamlanamadı. Lütfen tekrar deneyiniz."}
              </p>
              <div style={{ display: "flex", gap: 10 }}>
                <button
                  onClick={() => router.back()}
                  style={{ flex: 1, padding: "12px", borderRadius: 12, border: "1px solid #E5E7EB", background: "#fff", fontWeight: 600, cursor: "pointer", fontSize: 14 }}
                >
                  Geri Dön
                </button>
                <button
                  onClick={() => router.push("/")}
                  style={{ flex: 1, padding: "12px", borderRadius: 12, border: "none", background: "#2E7D32", color: "#fff", fontWeight: 700, cursor: "pointer", fontSize: 14 }}
                >
                  Ana Sayfa
                </button>
              </div>
            </>
          )}

        </div>
      </div>
    </div>
  );
}

export default function PaymentResultPage() {
  return (
    <Suspense fallback={
      <div className="page-wrapper" style={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: "100vh" }}>
        <Loader2 size={40} color="#2E7D32" style={{ animation: "spin 1s linear infinite" }} />
        <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
      </div>
    }>
      <PaymentResultContent />
    </Suspense>
  );
}

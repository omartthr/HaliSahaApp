"use client";

import React, { useState } from "react";
import { X, AlertCircle, CreditCard } from "lucide-react";
import { initiatePayment } from "@/backend/services/paymentService";
import { toast } from "react-hot-toast";

interface Props {
  isOpen: boolean;
  onClose: () => void;
  fieldName: string;
  date: string;
  timeSlots: string;
  totalPrice: number;
  matchTitle?: string;
  maxPlayers?: number;
  onCreateBooking: () => Promise<string>;
}

export default function BookingPaymentModal({
  isOpen, onClose,
  fieldName, date, timeSlots, totalPrice,
  matchTitle, maxPlayers,
  onCreateBooking,
}: Props) {
  const [loading, setLoading] = useState(false);
  const depositAmount = Math.round(totalPrice * 0.2);

  const handlePay = async () => {
    setLoading(true);
    try {
      const bookingId = await onCreateBooking();
      
      // bookingService.ts içinde zaten status: "pending" olarak zorlanıyor, DB ile senkronize.
      toast.success("Kapora ödendi! (Test Modu) İşleminiz onaya gönderildi.");
      window.location.href = "/profile";
    } catch (err: unknown) {
      setLoading(false);
      const msg = err instanceof Error ? err.message : "Ödeme başlatılamadı.";
      if (msg.toLowerCase().includes("adres") || msg.toLowerCase().includes("kimlik")) {
        toast.error("Profilinizden TC Kimlik No ve adres bilgilerinizi ekleyin.");
      } else {
        toast.error(msg);
      }
    }
  };

  if (!isOpen) return null;

  return (
    <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)", backdropFilter: "blur(4px)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 60, padding: 16 }}>
      <div style={{ background: "#fff", borderRadius: 24, padding: 32, maxWidth: 450, width: "100%", maxHeight: "90vh", overflowY: "auto" }}>

        {/* Başlık */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
          <h2 style={{ fontSize: 22, fontWeight: 900, color: "#111827", margin: 0 }}>
            {loading ? "Yönlendiriliyor..." : matchTitle ? "Maç Kurulum Özeti" : "Rezervasyon Özeti"}
          </h2>
          {!loading && (
            <button onClick={onClose} style={{ background: "none", border: "none", cursor: "pointer", color: "#6b7280" }}>
              <X size={24} />
            </button>
          )}
        </div>

        {loading ? (
          /* ── Yükleniyor ── */
          <div style={{ textAlign: "center", padding: "40px 0" }}>
            <div style={{ width: 52, height: 52, border: "4px solid #E8F5E9", borderTopColor: "#2E7D32", borderRadius: "50%", animation: "bpm-spin 1s linear infinite", margin: "0 auto 20px" }} />
            <p style={{ fontSize: 16, fontWeight: 700, color: "#374151", margin: 0 }}>Ödeme sayfasına yönlendiriliyorsunuz...</p>
            <p style={{ fontSize: 13, color: "#9ca3af", marginTop: 8 }}>Lütfen sayfadan ayrılmayın.</p>
            <style>{`@keyframes bpm-spin { to { transform: rotate(360deg); } }`}</style>
          </div>
        ) : (
          <>
            {/* Bilgi bandı */}
            <div style={{ background: "#E8F5E9", borderRadius: 12, padding: "14px 16px", display: "flex", gap: 10, alignItems: "flex-start", marginBottom: 24 }}>
              <AlertCircle size={18} style={{ color: "#2E7D32", flexShrink: 0, marginTop: 1 }} />
              <p style={{ fontSize: 13, color: "#2E7D32", lineHeight: 1.5, fontWeight: 500, margin: 0 }}>
                {matchTitle
                  ? "Maç ilanınız yayınlandıktan sonra sahayı rezerve etmiş olursunuz. İşlemi tamamlamak için kapora alınacaktır."
                  : "Randevu talebiniz saha sahibi tarafından onaylandıktan sonra kaporanız alınacaktır."}
              </p>
            </div>

            {/* Detaylar */}
            <div style={{ borderTop: "1px solid #f0f0f0", borderBottom: "1px solid #f0f0f0", padding: "16px 0", marginBottom: 24, display: "flex", flexDirection: "column", gap: 12 }}>
              {matchTitle && <Row label="Maç Başlığı" value={matchTitle} />}
              <Row label="Saha"   value={fieldName} />
              <Row label="Tarih"  value={date} />
              <Row label="Saatler" value={timeSlots} highlight />
            </div>

            {/* Fiyat */}
            <div style={{ display: "flex", flexDirection: "column", gap: 10, marginBottom: 32 }}>
              <Row label="Saha Ücreti" value={`₺${totalPrice}`} />
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span style={{ color: "#6b7280", fontWeight: 600, fontSize: 16 }}>Kapora (%20)</span>
                <span style={{ fontWeight: 900, color: "#2E7D32", fontSize: 22 }}>₺{depositAmount}</span>
              </div>
              {maxPlayers && maxPlayers > 0 && (
                <div style={{ display: "flex", justifyContent: "space-between", fontSize: 13 }}>
                  <span style={{ color: "#9ca3af" }}>Tahmini Kişi Başı</span>
                  <span style={{ fontWeight: 700, color: "#6b7280" }}>₺{Math.round(totalPrice / maxPlayers)} / kişi</span>
                </div>
              )}
            </div>

            <button
              onClick={() => void handlePay()}
              style={{ width: "100%", background: "#2E7D32", color: "white", padding: "16px", borderRadius: 16, border: "none", fontWeight: 800, fontSize: 16, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}
            >
              <CreditCard size={20} /> Kapora Öde
            </button>
          </>
        )}
      </div>
    </div>
  );
}

function Row({ label, value, highlight = false }: { label: string; value: string; highlight?: boolean }) {
  return (
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: 15 }}>
      <span style={{ color: "#6b7280" }}>{label}</span>
      <span style={{ fontWeight: 700, color: highlight ? "#2E7D32" : "#111827" }}>{value}</span>
    </div>
  );
}

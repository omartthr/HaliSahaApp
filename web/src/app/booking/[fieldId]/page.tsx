"use client";

import React, { useState, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import { db, auth } from "@/lib/firebase";
import { doc, getDoc, collection, addDoc, query, where, onSnapshot } from "firebase/firestore";
import { toast } from "react-hot-toast";
import Navbar from "@/components/common/Navbar";
import { Calendar, Clock, CreditCard, ChevronLeft, MapPin, Check, AlertCircle } from "lucide-react";
import { format, addDays } from "date-fns";
import { tr } from "date-fns/locale";
import Link from "next/link";

const BookingPage = () => {
  const { fieldId } = useParams();
  const router = useRouter();
  const [field, setField] = useState<any>(null);
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [selectedSlot, setSelectedSlot] = useState<string | null>(null);
  const [occupiedSlots, setOccupiedSlots] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [booking, setBooking] = useState(false);

  const timeSlots = Array.from({ length: 17 }, (_, i) => {
    const hour = i + 8;
    return `${hour.toString().padStart(2, "0")}:00`;
  });

  useEffect(() => {
    const fetchField = async () => {
      const fieldDoc = await getDoc(doc(db, "football_fields", fieldId as string));
      if (fieldDoc.exists()) setField({ id: fieldDoc.id, ...fieldDoc.data() });
      setLoading(false);
    };
    fetchField();
  }, [fieldId]);

  useEffect(() => {
    const q = query(
      collection(db, "reservations"),
      where("fieldId", "==", fieldId),
      where("date", "==", format(selectedDate, "yyyy-MM-dd"))
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setOccupiedSlots(snapshot.docs.map(d => d.data().timeSlot));
    });
    return () => unsubscribe();
  }, [fieldId, selectedDate]);

  const handleBooking = async () => {
    const user = auth.currentUser;
    if (!user) { toast.error("Randevu için giriş yapmalısınız."); return; }
    if (!selectedSlot) return;

    setBooking(true);
    try {
      await addDoc(collection(db, "reservations"), {
        fieldId,
        fieldName: field.name,
        userId: user.uid,
        userName: user.displayName || "Kullanıcı",
        date: format(selectedDate, "yyyy-MM-dd"),
        timeSlot: selectedSlot,
        status: "pending_payment",
        createdAt: new Date().toISOString(),
      });
      toast.success("Randevu talebi oluşturuldu!");
      router.push("/profile");
    } catch {
      toast.error("Randevu oluşturulurken hata oluştu.");
    } finally {
      setBooking(false);
    }
  };

  if (loading) {
    return (
      <div className="page-wrapper">
        <Navbar />
        <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <div style={{ textAlign: "center", color: "#9ca3af" }}>
            <div style={{ width: 40, height: 40, border: "3px solid #E8F5E9", borderTopColor: "#2E7D32", borderRadius: "50%", animation: "spin 1s linear infinite", margin: "0 auto 16px" }} />
            <p style={{ fontWeight: 600 }}>Saha bilgileri yükleniyor...</p>
          </div>
          <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
        </div>
      </div>
    );
  }

  if (!field) {
    return (
      <div className="page-wrapper">
        <Navbar />
        <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column", gap: 16 }}>
          <AlertCircle size={48} style={{ color: "#9ca3af" }} />
          <p style={{ fontWeight: 700, color: "#374151" }}>Saha bulunamadı.</p>
          <Link href="/" className="btn-outline" style={{ textDecoration: "none" }}>Ana Sayfaya Dön</Link>
        </div>
      </div>
    );
  }

  const pricePerHour = 1200;
  const deposit = Math.round(pricePerHour * 0.2);

  return (
    <div className="page-wrapper">
      <Navbar />

      <div className="content-container" style={{ paddingTop: 24, paddingBottom: 40 }}>
        {/* Back */}
        <button onClick={() => router.back()} style={{ display: "flex", alignItems: "center", gap: 6, background: "none", border: "none", cursor: "pointer", color: "#6b7280", fontWeight: 600, marginBottom: 20, fontSize: 15 }}>
          <ChevronLeft size={20} /> Geri
        </button>

        <div style={{ display: "grid", gridTemplateColumns: "1fr", gap: 20 }}>
          {/* Field Summary Card (sticky on desktop) */}
          <div className="card" style={{ padding: 24 }}>
            <h1 style={{ fontSize: 20, fontWeight: 800, color: "#111827", marginBottom: 8 }}>{field.name}</h1>
            <div style={{ display: "flex", alignItems: "center", gap: 6, color: "#9ca3af", fontSize: 13, marginBottom: 20 }}>
              <MapPin size={14} style={{ color: "#2E7D32" }} />
              <span>{field.address}</span>
            </div>

            {/* Info Banner */}
            <div style={{ background: "#E8F5E9", borderRadius: 12, padding: "14px 16px", display: "flex", gap: 10, alignItems: "flex-start", marginBottom: 20 }}>
              <AlertCircle size={18} style={{ color: "#2E7D32", flexShrink: 0, marginTop: 1 }} />
              <p style={{ fontSize: 13, color: "#2E7D32", lineHeight: 1.5 }}>
                Randevu talebiniz saha sahibi tarafından onaylandıktan sonra kaporanız alınacaktır.
              </p>
            </div>

            {/* Pricing breakdown */}
            <div style={{ borderTop: "1px solid #f0f0f0", paddingTop: 16, display: "flex", flexDirection: "column", gap: 10 }}>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 14 }}>
                <span style={{ color: "#9ca3af" }}>Saha Ücreti</span>
                <span style={{ fontWeight: 700, color: "#111827" }}>₺{pricePerHour.toLocaleString()} / Saat</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 14 }}>
                <span style={{ color: "#9ca3af" }}>Kapora (%20)</span>
                <span style={{ fontWeight: 700, color: "#2E7D32" }}>₺{deposit}</span>
              </div>
            </div>

            {selectedSlot && (
              <div style={{ background: "#2E7D32", borderRadius: 12, padding: "14px 16px", marginTop: 16, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                  <p style={{ color: "rgba(255,255,255,0.8)", fontSize: 12, marginBottom: 2 }}>Seçili Saat</p>
                  <p style={{ color: "white", fontWeight: 800, fontSize: 18 }}>
                    {format(selectedDate, "d MMM", { locale: tr })} — {selectedSlot}
                  </p>
                </div>
                <Check size={22} style={{ color: "white" }} />
              </div>
            )}
          </div>

          {/* Date Selection */}
          <div className="card" style={{ padding: 24 }}>
            <h2 style={{ fontSize: 17, fontWeight: 700, marginBottom: 16, display: "flex", alignItems: "center", gap: 8 }}>
              <Calendar size={18} style={{ color: "#2E7D32" }} /> Tarih Seçin
            </h2>
            <div className="scroll-x">
              {Array.from({ length: 14 }, (_, i) => addDays(new Date(), i)).map((date) => {
                const isSelected = format(selectedDate, "yyyy-MM-dd") === format(date, "yyyy-MM-dd");
                return (
                  <button key={date.toISOString()} onClick={() => { setSelectedDate(date); setSelectedSlot(null); }}
                    style={{ flexShrink: 0, width: 56, height: 68, borderRadius: 12, border: "none", cursor: "pointer", background: isSelected ? "#2E7D32" : "#f3f4f6", color: isSelected ? "white" : "#374151", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2, transition: "all 0.15s" }}>
                    <span style={{ fontSize: 11, fontWeight: 600, opacity: isSelected ? 1 : 0.6 }}>
                      {format(date, "EEE", { locale: tr }).toUpperCase()}
                    </span>
                    <span style={{ fontSize: 20, fontWeight: 800 }}>{format(date, "d")}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Time Slot Grid */}
          <div className="card" style={{ padding: 24 }}>
            <h2 style={{ fontSize: 17, fontWeight: 700, marginBottom: 16, display: "flex", alignItems: "center", gap: 8 }}>
              <Clock size={18} style={{ color: "#2E7D32" }} /> Saat Seçin
            </h2>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10 }}>
              {timeSlots.map((slot) => {
                const isOccupied = occupiedSlots.includes(slot);
                const isSelected = selectedSlot === slot;
                return (
                  <button key={slot} disabled={isOccupied} onClick={() => setSelectedSlot(slot)}
                    style={{ padding: "12px 8px", borderRadius: 10, border: `2px solid ${isSelected ? "#2E7D32" : isOccupied ? "#e5e7eb" : "#e5e7eb"}`, cursor: isOccupied ? "not-allowed" : "pointer", background: isSelected ? "#2E7D32" : isOccupied ? "#f5f5f5" : "white", color: isSelected ? "white" : isOccupied ? "#d1d5db" : "#374151", fontWeight: 700, fontSize: 13, textDecoration: isOccupied ? "line-through" : "none", transition: "all 0.15s" }}>
                    {slot}
                  </button>
                );
              })}
            </div>

            {/* Legend */}
            <div style={{ display: "flex", gap: 20, marginTop: 16 }}>
              {[{ color: "#2E7D32", label: "Seçili" }, { color: "#f3f4f6", label: "Müsait" }, { color: "#e5e7eb", label: "Dolu" }].map(l => (
                <div key={l.label} style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "#9ca3af" }}>
                  <div style={{ width: 10, height: 10, borderRadius: "50%", background: l.color, border: l.label === "Müsait" ? "1px solid #d1d5db" : "none" }} />
                  {l.label}
                </div>
              ))}
            </div>
          </div>

          {/* Book Button */}
          <button disabled={!selectedSlot || booking} onClick={handleBooking}
            style={{ width: "100%", background: !selectedSlot ? "#e5e7eb" : "#2E7D32", color: !selectedSlot ? "#9ca3af" : "white", padding: "18px", borderRadius: "16px", border: "none", fontWeight: 800, fontSize: 16, cursor: !selectedSlot ? "not-allowed" : "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 10, boxShadow: selectedSlot ? "0 6px 20px rgba(46,125,50,0.3)" : "none", transition: "all 0.2s" }}>
            {booking ? "İşleniyor..." : (<><CreditCard size={22} /> Randevu Talebi &amp; Kapora Öde</>)}
          </button>
        </div>
      </div>
    </div>
  );
};

export default BookingPage;

"use client";

import React, { useState } from "react";
import Navbar from "@/components/common/Navbar";
import Link from "next/link";
import { MapPin, Star, ChevronLeft, Check, ArrowRight } from "lucide-react";

// Maç Kur kartı için, öne çıkan saha detay tasarımının kopyası
const mockField = {
  id: "1",
  name: "Kadıköy Merkez Halı Saha",
  address: "Zühtüpaşa, Şükrü Saracoğlu Stadı Yanı, Kadıköy / İstanbul",
  phone: "0216 123 45 67",
  description:
    "İstanbul'un kalbinde, modern tesislerle donatılmış halı saha kompleksi. 5v5 ve 7v7 sahaları, soyunma odaları ve kafeterya ile eksiksiz bir spor deneyimi sunuyoruz.",
  rating: 4.8,
  reviewCount: 124,
  isIndoor: false,
  hasParking: true,
  features: [
    { icon: "🚿", name: "Duş" },
    { icon: "🅿️", name: "Otopark" },
    { icon: "🍔", name: "Kantin" },
    { icon: "💡", name: "Aydınlatma" },
    { icon: "🌀", name: "Klima" },
    { icon: "📶", name: "Wi-Fi" },
  ],
  pitches: [
    { id: "p1", name: "5v5 Saha A", size: "5'e 5", price: 350, nightPrice: 450 },
    { id: "p2", name: "5v5 Saha B", size: "5'e 5", price: 350, nightPrice: 450 },
    { id: "p3", name: "7v7 Büyük Saha", size: "7'ye 7", price: 500, nightPrice: 650 },
  ],
};

const today = new Date();
const getDates = () =>
  Array.from({ length: 14 }, (_, i) => {
    const d = new Date(today);
    d.setDate(today.getDate() + i);
    return d;
  });

const timeSlots = Array.from({ length: 14 }, (_, i) => ({
  hour: 8 + i,
  label: `${8 + i}:00`,
  available: ![11, 12, 15].includes(8 + i),
  price: 8 + i >= 18 ? 450 : 350,
}));

const nearbyFacilities = [
  { id: "f1", district: "Kadıköy", name: "Saha 1", address: "Adres bilgisi gelecek" },
  { id: "f2", district: "Üsküdar", name: "Saha 2", address: "Adres bilgisi gelecek" },
  { id: "f3", district: "Beşiktaş", name: "Saha 3", address: "Adres bilgisi gelecek" },
  { id: "f4", district: "Ataşehir", name: "Saha 4", address: "Adres bilgisi gelecek" },
];

export default function MatchCreatePage() {
  const [selectedPitch, setSelectedPitch] = useState(mockField.pitches[0]);
  const [selectedDate, setSelectedDate] = useState(today);
  const [selectedSlots, setSelectedSlots] = useState<number[]>([]);
  const [selectedFacilityId, setSelectedFacilityId] = useState(nearbyFacilities[0].id);

  const dates = getDates();

  const toggleSlot = (hour: number) => {
    const slot = timeSlots.find((s) => s.hour === hour);
    if (!slot?.available) return;
    setSelectedSlots((prev) =>
      prev.includes(hour)
        ? prev.filter((h) => h !== hour)
        : [...prev, hour].sort((a, b) => a - b)
    );
  };

  const totalPrice = selectedSlots.length * selectedPitch.price;
  const canBook = selectedSlots.length > 0;

  const dayNames = ["Paz", "Pzt", "Sal", "Çrş", "Per", "Cum", "Cmt"];
  const monthNames = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"];

  return (
    <div className="page-wrapper">
      <Navbar />

      <div
        style={{
          height: 280,
          background: "linear-gradient(180deg, #114B32 0%, #1A754E 100%)",
          position: "relative",
          zIndex: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <div style={{ position: "absolute", top: 16, left: 16 }}>
          <Link
            href="/"
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              width: 40,
              height: 40,
              borderRadius: "50%",
              background: "rgba(0,0,0,0.3)",
              backdropFilter: "blur(8px)",
              color: "white",
              textDecoration: "none",
            }}
          >
            <ChevronLeft size={20} />
          </Link>
        </div>

        <div style={{ position: "absolute", bottom: -118, left: 0, width: "100%", lineHeight: 0, zIndex: 0, pointerEvents: "none" }}>
          <svg
            data-name="Layer 1"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 1200 120"
            preserveAspectRatio="none"
            style={{ display: "block", width: "calc(100% + 1.3px)", height: 120, overflow: "visible" }}
          >
            <defs>
              <filter id="match-wave-soft-shadow" x="-8%" y="-8%" width="116%" height="180%">
                <feGaussianBlur stdDeviation="7" />
              </filter>
            </defs>
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="rgba(0,0,0,0.22)"
              transform="translate(0, 14)"
              filter="url(#match-wave-soft-shadow)"
            />
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="#1A754E"
            />
          </svg>
        </div>
      </div>

      <div className="content-container" style={{ position: "relative", zIndex: 2, marginTop: -220, paddingTop: 24, paddingBottom: 100 }}>
        <div className="auth-dynamo-glass match-dynamo-card" style={{ padding: 24, marginBottom: 16, borderRadius: 24 }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 14, gap: 12, flexWrap: "wrap" }}>
            <h2 style={{ fontSize: 18, fontWeight: 700, color: "#111827" }}>Saha ve Oyun Tipi Seçimi</h2>
            <span className="pill pill-outline">{mockField.isIndoor ? "🏠 Kapalı Alan" : "☀️ Açık Alan"}</span>
          </div>

          <div style={{ display: "grid", gap: 16, gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))" }}>
            <div>
              <p style={{ fontSize: 13, color: "#6b7280", fontWeight: 600, marginBottom: 10 }}>Saha Listesi</p>
              <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                {nearbyFacilities.map((facility) => {
                  const isSelected = selectedFacilityId === facility.id;
                  return (
                    <button
                      key={facility.id}
                      onClick={() => setSelectedFacilityId(facility.id)}
                      style={{
                        width: "100%",
                        border: `1px solid ${isSelected ? "#2E7D32" : "#e5e7eb"}`,
                        background: isSelected ? "rgba(232,245,233,0.78)" : "rgba(255,255,255,0.56)",
                        borderRadius: 16,
                        padding: "14px 16px",
                        textAlign: "left",
                        cursor: "pointer",
                        transition: "all 0.2s ease",
                      }}
                    >
                      <p style={{ fontSize: 11, letterSpacing: "0.08em", textTransform: "uppercase", color: "#2E7D32", fontWeight: 700, marginBottom: 3 }}>
                        {facility.district}
                      </p>
                      <p style={{ fontSize: 18, fontWeight: 700, color: "#0f172a", marginBottom: 4 }}>{facility.name}</p>
                      <p style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 14, color: "#64748b", margin: 0 }}>
                        <MapPin size={14} /> {facility.address}
                      </p>
                    </button>
                  );
                })}
              </div>
            </div>

            <div>
              <p style={{ fontSize: 13, color: "#6b7280", fontWeight: 600, marginBottom: 10 }}>Sahalar</p>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))", gap: 10 }}>
                {mockField.pitches.map((pitch) => (
                  <button
                    key={pitch.id}
                    onClick={() => setSelectedPitch(pitch)}
                    style={{
                      padding: "12px 14px",
                      borderRadius: 14,
                      border: `2px solid ${selectedPitch.id === pitch.id ? "#2E7D32" : "#e5e7eb"}`,
                      background: selectedPitch.id === pitch.id ? "rgba(232,245,233,0.8)" : "rgba(255,255,255,0.58)",
                      cursor: "pointer",
                      textAlign: "left",
                      transition: "all 0.2s",
                    }}
                  >
                    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4, gap: 8 }}>
                      <span style={{ fontWeight: 700, fontSize: 14, color: "#111827" }}>{pitch.name}</span>
                      {selectedPitch.id === pitch.id && <Check size={16} style={{ color: "#2E7D32" }} />}
                    </div>
                    <p style={{ fontSize: 13, color: "#9ca3af" }}>{pitch.size}</p>
                    <p style={{ fontSize: 22, lineHeight: 1.1, fontWeight: 700, color: "#2E7D32", marginTop: 8 }}>₺{pitch.price}<span style={{ fontSize: 13 }}>/saat</span></p>
                  </button>
                ))}
              </div>

              <div style={{ marginTop: 16 }}>
                <p style={{ fontSize: 13, color: "#6b7280", fontWeight: 600, marginBottom: 10 }}>Tarih Seçin</p>
                <div className="scroll-x">
                  {dates.map((date, i) => {
                    const isSelected = date.toDateString() === selectedDate.toDateString();
                    return (
                      <button
                        key={i}
                        onClick={() => setSelectedDate(date)}
                        style={{
                          flexShrink: 0,
                          width: 52,
                          height: 64,
                          borderRadius: 12,
                          border: "none",
                          cursor: "pointer",
                          background: isSelected ? "#2E7D32" : "rgba(255,255,255,0.56)",
                          color: isSelected ? "white" : "#374151",
                          display: "flex",
                          flexDirection: "column",
                          alignItems: "center",
                          justifyContent: "center",
                          gap: 2,
                          transition: "all 0.15s",
                        }}
                      >
                        <span style={{ fontSize: 12, fontWeight: 600, opacity: isSelected ? 1 : 0.6 }}>{dayNames[date.getDay()]}</span>
                        <span style={{ fontSize: 18, fontWeight: 800 }}>{date.getDate()}</span>
                      </button>
                    );
                  })}
                </div>
                <p style={{ fontSize: 12, color: "#9ca3af", marginTop: 10 }}>
                  {selectedDate.getDate()} {monthNames[selectedDate.getMonth()]} {selectedDate.getFullYear()}
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="auth-dynamo-glass match-dynamo-card" style={{ padding: 24, marginBottom: 16, borderRadius: 24 }}>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))", gap: 18, alignItems: "start" }}>
            <div>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
                <h2 style={{ fontSize: 17, fontWeight: 700, color: "#111827" }}>Saat Seçin</h2>
                {selectedSlots.length > 0 && (
                  <span style={{ fontSize: 14, fontWeight: 700, color: "#2E7D32" }}>
                    {selectedSlots[0]}:00 - {selectedSlots[selectedSlots.length - 1] + 1}:00
                  </span>
                )}
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 8 }}>
                {timeSlots.map((slot) => {
                  const isSelected = selectedSlots.includes(slot.hour);
                  const cls = `time-slot ${!slot.available ? "booked" : isSelected ? "selected" : "available"}`;
                  return (
                    <button key={slot.hour} className={cls} onClick={() => toggleSlot(slot.hour)}>
                      <div style={{ fontWeight: 700 }}>{slot.label}</div>
                      <div style={{ fontSize: 11, opacity: 0.7 }}>₺{slot.price}</div>
                    </button>
                  );
                })}
              </div>
              <div style={{ display: "flex", gap: 20, marginTop: 14 }}>
                {[
                  { color: "#2E7D32", label: "Seçili" },
                  { color: "#f3f4f6", label: "Müsait" },
                  { color: "#d1d5db", label: "Dolu" },
                ].map((l) => (
                  <div key={l.label} style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "#9ca3af" }}>
                    <div style={{ width: 10, height: 10, borderRadius: "50%", background: l.color }} />
                    {l.label}
                  </div>
                ))}
              </div>
            </div>

            <div>
              <h2 style={{ fontSize: 17, fontWeight: 700, color: "#111827", marginBottom: 14 }}>Özellikler</h2>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12 }}>
                {mockField.features.map((f) => (
                  <div key={f.name} style={{ background: "rgba(255,255,255,0.56)", borderRadius: 10, padding: "14px 8px", textAlign: "center" }}>
                    <div style={{ fontSize: 22, marginBottom: 4 }}>{f.icon}</div>
                    <div style={{ fontSize: 12, color: "#6b7280", fontWeight: 500 }}>{f.name}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        <div className="auth-dynamo-glass match-dynamo-card" style={{ padding: 24, marginBottom: 16, borderRadius: 24 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
            <h2 style={{ fontSize: 17, fontWeight: 700, color: "#111827" }}>Değerlendirmeler</h2>
            <span style={{ fontSize: 13, color: "#2E7D32", fontWeight: 600, cursor: "pointer" }}>Tümü →</span>
          </div>
          <div style={{ display: "flex", gap: 24, alignItems: "center", background: "rgba(255,255,255,0.56)", borderRadius: 12, padding: 16 }}>
            <div style={{ textAlign: "center" }}>
              <div style={{ fontSize: 40, fontWeight: 900, color: "#111827" }}>{mockField.rating}</div>
              <div style={{ display: "flex", gap: 2, justifyContent: "center" }}>
                {[1, 2, 3, 4, 5].map((i) => (
                  <Star
                    key={i}
                    size={14}
                    style={{ color: "#F59E0B", fill: i <= Math.round(mockField.rating) ? "#F59E0B" : "transparent" }}
                  />
                ))}
              </div>
              <div style={{ fontSize: 12, color: "#9ca3af", marginTop: 4 }}>{mockField.reviewCount} değerlendirme</div>
            </div>
            <div style={{ flex: 1 }}>
              {[5, 4, 3, 2, 1].map((star) => {
                const pct = star === 5 ? 72 : star === 4 ? 18 : star === 3 ? 7 : star === 2 ? 2 : 1;
                return (
                  <div key={star} style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4 }}>
                    <span style={{ fontSize: 12, color: "#9ca3af", width: 12 }}>{star}</span>
                    <div style={{ flex: 1, background: "#e5e7eb", borderRadius: 3, height: 6 }}>
                      <div style={{ width: `${pct}%`, background: "#F59E0B", height: 6, borderRadius: 3 }} />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      <div
        style={{
          position: "fixed",
          bottom: 0,
          left: 0,
          right: 0,
          background: "white",
          borderTop: "1px solid #f0f0f0",
          padding: "16px 20px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          zIndex: 50,
          boxShadow: "0 -4px 20px rgba(0,0,0,0.08)",
        }}
      >
        <div>
          {canBook ? (
            <>
              <p style={{ fontSize: 20, fontWeight: 900, color: "#111827" }}>₺{totalPrice}</p>
              <p style={{ fontSize: 12, color: "#9ca3af" }}>{selectedSlots.length} saat</p>
            </>
          ) : (
            <p style={{ fontSize: 14, color: "#9ca3af" }}>Saat seçin</p>
          )}
        </div>
        <Link
          href={canBook ? `/booking/${mockField.id}` : "#"}
          style={{
            background: canBook ? "#2E7D32" : "#e5e7eb",
            color: canBook ? "white" : "#9ca3af",
            padding: "14px 28px",
            borderRadius: "14px",
            fontWeight: 800,
            fontSize: 15,
            textDecoration: "none",
            display: "flex",
            alignItems: "center",
            gap: 8,
            boxShadow: canBook ? "0 4px 12px rgba(46,125,50,0.3)" : "none",
            pointerEvents: canBook ? "auto" : "none",
          }}
        >
          Rezervasyon Yap <ArrowRight size={18} />
        </Link>
      </div>
    </div>
  );
}

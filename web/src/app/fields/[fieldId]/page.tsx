"use client";

import React, { useState } from "react";
import Navbar from "@/components/common/Navbar";
import Link from "next/link";
import { MapPin, Phone, Star, Heart, Share2, ChevronLeft, ChevronRight, Check, Car, Droplets, Utensils, Lightbulb, Wifi, Wind, ArrowRight } from "lucide-react";

// Mock data — Firebase bağlandığında gerçek data gelecek
const mockField = {
  id: "1",
  name: "Kadıköy Merkez Halı Saha",
  address: "Zühtüpaşa, Şükrü Saracoğlu Stadı Yanı, Kadıköy / İstanbul",
  phone: "0216 123 45 67",
  description: "İstanbul'un kalbinde, modern tesislerle donatılmış halı saha kompleksi. 5v5 ve 7v7 sahaları, soyunma odaları ve kafeterya ile eksiksiz bir spor deneyimi sunuyoruz.",
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
const getDates = () => Array.from({ length: 14 }, (_, i) => {
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

export default function FieldDetailPage({ params }: { params: { fieldId: string } }) {
  const [selectedPitch, setSelectedPitch] = useState(mockField.pitches[0]);
  const [selectedDate, setSelectedDate] = useState(today);
  const [selectedSlots, setSelectedSlots] = useState<number[]>([]);
  const [isFavorite, setIsFavorite] = useState(false);
  const [showFullDesc, setShowFullDesc] = useState(false);

  const dates = getDates();

  const toggleSlot = (hour: number) => {
    const slot = timeSlots.find(s => s.hour === hour);
    if (!slot?.available) return;
    setSelectedSlots(prev =>
      prev.includes(hour) ? prev.filter(h => h !== hour) : [...prev, hour].sort((a, b) => a - b)
    );
  };

  const totalPrice = selectedSlots.length * selectedPitch.price;
  const canBook = selectedSlots.length > 0;

  const dayNames = ["Paz", "Pzt", "Sal", "Çrş", "Per", "Cum", "Cmt"];
  const monthNames = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"];

  return (
    <div className="page-wrapper">
      <Navbar />

      {/* Hero Image */}
      <div style={{ height: 280, background: "linear-gradient(135deg, #2E7D32 0%, #1B5E20 60%, #004D40 100%)", position: "relative", display: "flex", alignItems: "center", justifyContent: "center" }}>
        <span style={{ fontSize: 80, opacity: 0.2 }}>⚽</span>
        <div style={{ position: "absolute", top: 16, left: 16 }}>
          <Link href="/" style={{ display: "flex", alignItems: "center", justifyContent: "center", width: 40, height: 40, borderRadius: "50%", background: "rgba(0,0,0,0.3)", backdropFilter: "blur(8px)", color: "white", textDecoration: "none" }}>
            <ChevronLeft size={20} />
          </Link>
        </div>
        <div style={{ position: "absolute", top: 16, right: 16, display: "flex", gap: 8 }}>
          <button onClick={() => setIsFavorite(!isFavorite)}
            style={{ display: "flex", alignItems: "center", justifyContent: "center", width: 40, height: 40, borderRadius: "50%", background: "rgba(0,0,0,0.3)", backdropFilter: "blur(8px)", border: "none", cursor: "pointer" }}>
            <Heart size={18} style={{ color: isFavorite ? "#ef4444" : "white", fill: isFavorite ? "#ef4444" : "transparent" }} />
          </button>
          <button style={{ display: "flex", alignItems: "center", justifyContent: "center", width: 40, height: 40, borderRadius: "50%", background: "rgba(0,0,0,0.3)", backdropFilter: "blur(8px)", border: "none", cursor: "pointer" }}>
            <Share2 size={18} style={{ color: "white" }} />
          </button>
        </div>
        {/* Rating badge */}
        <div style={{ position: "absolute", bottom: 16, left: 16, background: "rgba(0,0,0,0.4)", backdropFilter: "blur(8px)", borderRadius: 20, padding: "6px 12px", display: "flex", alignItems: "center", gap: 6 }}>
          <Star size={14} style={{ color: "#FCD34D", fill: "#FCD34D" }} />
          <span style={{ color: "white", fontWeight: 700, fontSize: 14 }}>{mockField.rating}</span>
          <span style={{ color: "rgba(255,255,255,0.7)", fontSize: 12 }}>({mockField.reviewCount} değerlendirme)</span>
        </div>
      </div>

      <div className="content-container" style={{ paddingTop: 24, paddingBottom: 100 }}>
        {/* Header Info */}
        <div className="card" style={{ padding: 24, marginBottom: 16 }}>
          <h1 style={{ fontSize: 22, fontWeight: 800, color: "#111827", marginBottom: 10 }}>{mockField.name}</h1>
          <div style={{ display: "flex", alignItems: "center", gap: 8, color: "#9ca3af", fontSize: 14, marginBottom: 8 }}>
            <MapPin size={16} style={{ color: "#2E7D32" }} />
            <span>{mockField.address}</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 8, color: "#9ca3af", fontSize: 14, marginBottom: 16 }}>
            <Phone size={16} style={{ color: "#2E7D32" }} />
            <a href={`tel:${mockField.phone}`} style={{ color: "#2E7D32", fontWeight: 600, textDecoration: "none" }}>{mockField.phone}</a>
          </div>
          <p style={{ fontSize: 14, color: "#6b7280", lineHeight: 1.7, display: showFullDesc ? "block" : "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
            {mockField.description}
          </p>
          <button onClick={() => setShowFullDesc(!showFullDesc)} style={{ background: "none", border: "none", color: "#2E7D32", fontSize: 13, fontWeight: 600, cursor: "pointer", marginTop: 6, padding: 0 }}>
            {showFullDesc ? "Daha az" : "Devamını oku"}
          </button>

          {/* Tags */}
          <div style={{ display: "flex", gap: 8, marginTop: 14, flexWrap: "wrap" }}>
            <span className="pill pill-primary">{mockField.isIndoor ? "🏠 Kapalı Alan" : "☀️ Açık Alan"}</span>
            {mockField.hasParking && <span className="pill pill-outline">🚗 Otopark</span>}
          </div>
        </div>

        {/* Pitch Selection */}
        <div className="card" style={{ padding: 24, marginBottom: 16 }}>
          <h2 style={{ fontSize: 17, fontWeight: 700, color: "#111827", marginBottom: 14 }}>Sahalar</h2>
          <div className="scroll-x">
            {mockField.pitches.map(pitch => (
              <button key={pitch.id} onClick={() => setSelectedPitch(pitch)}
                style={{ flexShrink: 0, padding: "14px 18px", borderRadius: 12, border: `2px solid ${selectedPitch.id === pitch.id ? "#2E7D32" : "#f0f0f0"}`, background: selectedPitch.id === pitch.id ? "#E8F5E9" : "white", cursor: "pointer", textAlign: "left", minWidth: 140, transition: "all 0.2s" }}>
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                  <span style={{ fontWeight: 700, fontSize: 14, color: "#111827" }}>{pitch.name}</span>
                  {selectedPitch.id === pitch.id && <Check size={16} style={{ color: "#2E7D32" }} />}
                </div>
                <p style={{ fontSize: 13, color: "#9ca3af" }}>{pitch.size}</p>
                <p style={{ fontSize: 14, fontWeight: 700, color: "#2E7D32", marginTop: 6 }}>₺{pitch.price}/saat</p>
              </button>
            ))}
          </div>
        </div>

        {/* Date Selection */}
        <div className="card" style={{ padding: 24, marginBottom: 16 }}>
          <h2 style={{ fontSize: 17, fontWeight: 700, color: "#111827", marginBottom: 14 }}>Tarih Seçin</h2>
          <div className="scroll-x">
            {dates.map((date, i) => {
              const isSelected = date.toDateString() === selectedDate.toDateString();
              return (
                <button key={i} onClick={() => setSelectedDate(date)}
                  style={{ flexShrink: 0, width: 52, height: 64, borderRadius: 12, border: "none", cursor: "pointer", background: isSelected ? "#2E7D32" : "#f3f4f6", color: isSelected ? "white" : "#374151", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2, transition: "all 0.15s" }}>
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

        {/* Time Slots */}
        <div className="card" style={{ padding: 24, marginBottom: 16 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
            <h2 style={{ fontSize: 17, fontWeight: 700, color: "#111827" }}>Saat Seçin</h2>
            {selectedSlots.length > 0 && (
              <span style={{ fontSize: 14, fontWeight: 700, color: "#2E7D32" }}>
                {selectedSlots[0]}:00 - {selectedSlots[selectedSlots.length - 1] + 1}:00
              </span>
            )}
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 8 }}>
            {timeSlots.map(slot => {
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
          {/* Legend */}
          <div style={{ display: "flex", gap: 20, marginTop: 14 }}>
            {[{ color: "#2E7D32", label: "Seçili" }, { color: "#f3f4f6", label: "Müsait" }, { color: "#d1d5db", label: "Dolu" }].map(l => (
              <div key={l.label} style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "#9ca3af" }}>
                <div style={{ width: 10, height: 10, borderRadius: "50%", background: l.color }} />
                {l.label}
              </div>
            ))}
          </div>
        </div>

        {/* Amenities */}
        <div className="card" style={{ padding: 24, marginBottom: 16 }}>
          <h2 style={{ fontSize: 17, fontWeight: 700, color: "#111827", marginBottom: 14 }}>Özellikler</h2>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12 }}>
            {mockField.features.map(f => (
              <div key={f.name} style={{ background: "#f3f4f6", borderRadius: 10, padding: "14px 8px", textAlign: "center" }}>
                <div style={{ fontSize: 22, marginBottom: 4 }}>{f.icon}</div>
                <div style={{ fontSize: 12, color: "#6b7280", fontWeight: 500 }}>{f.name}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Reviews */}
        <div className="card" style={{ padding: 24, marginBottom: 16 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
            <h2 style={{ fontSize: 17, fontWeight: 700, color: "#111827" }}>Değerlendirmeler</h2>
            <span style={{ fontSize: 13, color: "#2E7D32", fontWeight: 600, cursor: "pointer" }}>Tümü →</span>
          </div>
          <div style={{ display: "flex", gap: 24, alignItems: "center", background: "#f9f9f9", borderRadius: 12, padding: 16 }}>
            <div style={{ textAlign: "center" }}>
              <div style={{ fontSize: 40, fontWeight: 900, color: "#111827" }}>{mockField.rating}</div>
              <div style={{ display: "flex", gap: 2, justifyContent: "center" }}>
                {[1, 2, 3, 4, 5].map(i => (
                  <Star key={i} size={14} style={{ color: "#F59E0B", fill: i <= Math.round(mockField.rating) ? "#F59E0B" : "transparent" }} />
                ))}
              </div>
              <div style={{ fontSize: 12, color: "#9ca3af", marginTop: 4 }}>{mockField.reviewCount} değerlendirme</div>
            </div>
            <div style={{ flex: 1 }}>
              {[5, 4, 3, 2, 1].map(star => {
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

      {/* Bottom Bar */}
      <div style={{ position: "fixed", bottom: 0, left: 0, right: 0, background: "white", borderTop: "1px solid #f0f0f0", padding: "16px 20px", display: "flex", alignItems: "center", justifyContent: "space-between", zIndex: 50, boxShadow: "0 -4px 20px rgba(0,0,0,0.08)" }}>
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
        <Link href={canBook ? `/booking/${mockField.id}` : "#"}
          style={{ background: canBook ? "#2E7D32" : "#e5e7eb", color: canBook ? "white" : "#9ca3af", padding: "14px 28px", borderRadius: "14px", fontWeight: 800, fontSize: 15, textDecoration: "none", display: "flex", alignItems: "center", gap: 8, boxShadow: canBook ? "0 4px 12px rgba(46,125,50,0.3)" : "none", pointerEvents: canBook ? "auto" : "none" }}>
          Rezervasyon Yap <ArrowRight size={18} />
        </Link>
      </div>
    </div>
  );
}

"use client";

import React, { useState, useEffect } from "react";
import Navbar from "@/frontend/components/common/Navbar";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { format } from "date-fns";
import { MapPin, Phone, Star, Heart, Share2, ChevronLeft, ChevronRight, Check, Car, Droplets, Utensils, Lightbulb, Wifi, Wind, ArrowRight, X, AlertCircle, CreditCard } from "lucide-react";
import { getFieldAverageRating, getFieldReviews, rateField, hasRatedField } from "@/backend/services/ratingService";
import { getField } from "@/backend/services/fieldService";
import { createBooking } from "@/backend/services/bookingService";
import { useAuth } from "@/frontend/context/AuthContext";
import { toast } from "react-hot-toast";

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
    { icon: "shower", name: "Duş" },
    { icon: "parking", name: "Otopark" },
    { icon: "utensils", name: "Kantin" },
    { icon: "lightbulb", name: "Aydınlatma" },
    { icon: "wind", name: "Klima" },
    { icon: "wifi", name: "Wi-Fi" },
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
}));

export default function FieldDetailPage({ params }: { params: Promise<{ fieldId: string }> }) {
  const resolvedParams = React.use(params);
  const fieldId = resolvedParams.fieldId;
  const { user } = useAuth();
  const router = useRouter();
  const [realField, setRealField] = useState<any>(null);
  const currentField = realField || mockField;
  
  const [selectedPitch, setSelectedPitch] = useState(mockField.pitches[0]);
  const [selectedDate, setSelectedDate] = useState(today);
  const [selectedSlots, setSelectedSlots] = useState<number[]>([]);
  const [isFavorite, setIsFavorite] = useState(false);
  const [showFullDesc, setShowFullDesc] = useState(false);
  const [fieldRating, setFieldRating] = useState<number>(0);
  const [reviews, setReviews] = useState<any[]>([]);
  const [showReviewForm, setShowReviewForm] = useState(false);
  const [reviewForm, setReviewForm] = useState({ rating: 0, comment: "" });
  
  const [showBookingModal, setShowBookingModal] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleBooking = async () => {
    if (!user) {
      toast.error("Randevu için giriş yapmalısınız.");
      return;
    }
    setIsSubmitting(true);
    try {
      for (const slotHour of selectedSlots) {
        const slotLabel = timeSlots.find(s => s.hour === slotHour)?.label;
        await createBooking({
          fieldId,
          fieldName: currentField.name,
          userId: user.uid,
          userName: user.displayName || "Kullanıcı",
          date: format(selectedDate, "yyyy-MM-dd"),
          timeSlot: slotLabel || "",
        });
      }
      toast.success("Randevu talebi başarıyla oluşturuldu!");
      router.push("/profile");
    } catch (error) {
      toast.error("Randevu oluşturulurken bir hata oluştu.");
    } finally {
      setIsSubmitting(false);
      setShowBookingModal(false);
    }
  };

  const dates = getDates();

  useEffect(() => {
    getField(fieldId).then(setRealField);
    getFieldAverageRating(fieldId).then(setFieldRating);
    getFieldReviews(fieldId).then(setReviews);
  }, [fieldId]);

  const toggleSlot = (hour: number) => {
    const slot = timeSlots.find(s => s.hour === hour);
    if (!slot?.available) return;
    setSelectedSlots(prev =>
      prev.includes(hour) ? prev.filter(h => h !== hour) : [...prev, hour].sort((a, b) => a - b)
    );
  };

  const pricePerHour = currentField.price || selectedPitch.price || 350;
  const totalPrice = selectedSlots.length * pricePerHour;
  const canBook = selectedSlots.length > 0;

  const dayNames = ["Paz", "Pzt", "Sal", "Çrş", "Per", "Cum", "Cmt"];
  const monthNames = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"];

  return (
    <div className="page-wrapper">
      <Navbar />

      {/* Hero Section — Maç Kur sayfasındaki gibi dinamik Aurora + Wave */}
      <div
        className="match-hero"
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
        <div style={{ position: "absolute", top: 80, left: 16 }}>
          <button
            onClick={() => router.back()}
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
          </button>
        </div>

        <div style={{ position: "absolute", top: 80, right: 16, display: "flex", gap: 8 }}>
          <button onClick={() => {
            setIsFavorite(!isFavorite);
            toast.success(isFavorite ? "Saha favorilerden çıkarıldı." : "Saha favorilere eklendi.");
          }}
            style={{ display: "flex", alignItems: "center", justifyContent: "center", width: 40, height: 40, borderRadius: "50%", background: "rgba(0,0,0,0.3)", backdropFilter: "blur(8px)", border: "none", cursor: "pointer" }}>
            <Heart size={18} style={{ color: isFavorite ? "#ef4444" : "white", fill: isFavorite ? "#ef4444" : "transparent" }} />
          </button>
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
              <filter id="field-wave-soft-shadow" x="-8%" y="-8%" width="116%" height="180%">
                <feGaussianBlur stdDeviation="7" />
              </filter>
            </defs>
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="rgba(0,0,0,0.22)"
              transform="translate(0, 14)"
              filter="url(#field-wave-soft-shadow)"
            />
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="#1A754E"
            />
          </svg>
        </div>
      </div>

      <div className="content-container match-main-content" style={{ position: "relative", zIndex: 2, marginTop: -220, paddingTop: 24, paddingBottom: 100 }}>
        {/* Header Info — Maç Kur kartı stilinde */}
        <div className="auth-dynamo-glass match-dynamo-card" style={{ padding: 24, marginBottom: 16, borderRadius: 24 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 16 }}>
            <div>
              <p style={{ fontSize: 11, letterSpacing: "0.08em", textTransform: "uppercase", color: "#2E7D32", fontWeight: 700, marginBottom: 4 }}>SAHA DETAYI</p>
              <h1 style={{ fontSize: 24, fontWeight: 800, color: "#111827", marginBottom: 8 }}>{currentField.name}</h1>
            </div>
            <div style={{ background: "#F59E0B", color: "white", borderRadius: 12, padding: "8px 12px", display: "flex", alignItems: "center", gap: 6, boxShadow: "0 4px 12px rgba(245,158,11,0.2)" }}>
              <Star size={16} fill="white" />
              <span style={{ fontWeight: 800, fontSize: 16 }}>{fieldRating > 0 ? fieldRating.toFixed(1) : (currentField.rating || "Yen")}</span>
            </div>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: 12, marginBottom: 20 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, color: "#6b7280", fontSize: 14 }}>
              <MapPin size={16} style={{ color: "#2E7D32" }} />
              <span>{currentField.address}</span>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 8, color: "#6b7280", fontSize: 14 }}>
              <Phone size={16} style={{ color: "#2E7D32" }} />
              <a href={`tel:${currentField.phone}`} style={{ color: "#2E7D32", fontWeight: 700, textDecoration: "none" }}>{currentField.phone}</a>
            </div>
          </div>

          <p style={{ fontSize: 15, color: "#4b5563", lineHeight: 1.6, display: showFullDesc ? "block" : "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
            {currentField.description}
          </p>
          <button onClick={() => setShowFullDesc(!showFullDesc)} style={{ background: "none", border: "none", color: "#2E7D32", fontSize: 14, fontWeight: 700, cursor: "pointer", marginTop: 8, padding: 0 }}>
            {showFullDesc ? "Daha az" : "Devamını oku"}
          </button>

          {/* Tags */}
          <div style={{ display: "flex", gap: 8, marginTop: 20, flexWrap: "wrap" }}>
            <span className="pill pill-primary" style={{ padding: "6px 14px", display: "inline-flex", alignItems: "center", gap: 6 }}>
              {(currentField.amenities?.isIndoor ?? currentField.isIndoor) ? <><Wind size={13} /> Kapalı Alan</> : <><Lightbulb size={13} /> Açık Alan</>}
            </span>
            {(currentField.amenities?.hasParking ?? currentField.hasParking) && <span className="pill pill-outline" style={{ padding: "6px 14px", background: "white", display: "inline-flex", alignItems: "center", gap: 6 }}><Car size={13} /> Otopark</span>}
          </div>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))", gap: 16 }}>
          {/* Left Column */}
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            {/* Pitch Selection */}
            <div className="auth-dynamo-glass match-dynamo-card" style={{ padding: 24, borderRadius: 24 }}>
              <h2 style={{ fontSize: 18, fontWeight: 700, color: "#111827", marginBottom: 16 }}>Sahalar</h2>
              <div style={{ display: "grid", gap: 10 }}>
                {(currentField.pitches || mockField.pitches).map((pitch: any) => {
                  const isSelected = selectedPitch.id === pitch.id;
                  return (
                    <button key={pitch.id} onClick={() => setSelectedPitch(pitch)}
                      style={{ 
                        width: "100%", 
                        padding: "16px", 
                        borderRadius: 16, 
                        border: `2px solid ${isSelected ? "#2E7D32" : "rgba(15,23,42,0.08)"}`, 
                        background: isSelected ? "rgba(232,245,233,0.85)" : "rgba(255,255,255,0.5)", 
                        cursor: "pointer", 
                        textAlign: "left", 
                        transition: "all 0.2s" 
                      }}>
                      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                        <span style={{ fontWeight: 700, fontSize: 15, color: "#111827" }}>{pitch.name}</span>
                        {isSelected && <Check size={18} style={{ color: "#2E7D32" }} />}
                      </div>
                      <p style={{ fontSize: 13, color: "#9ca3af" }}>{pitch.size}</p>
                      <p style={{ fontSize: 20, fontWeight: 800, color: "#2E7D32", marginTop: 8 }}>₺{currentField.price || pitch.price}<span style={{ fontSize: 13, fontWeight: 600 }}>/saat</span></p>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Amenities */}
            <div className="auth-dynamo-glass match-dynamo-card" style={{ padding: 24, borderRadius: 24 }}>
              <h2 style={{ fontSize: 18, fontWeight: 700, color: "#111827", marginBottom: 16 }}>Özellikler</h2>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10 }}>
                {(currentField.features || mockField.features).map((f: any) => {
                  const iconMap: Record<string, React.ReactNode> = {
                    shower: <Droplets size={20} strokeWidth={2} />,
                    parking: <Car size={20} strokeWidth={2} />,
                    utensils: <Utensils size={20} strokeWidth={2} />,
                    lightbulb: <Lightbulb size={20} strokeWidth={2} />,
                    wind: <Wind size={20} strokeWidth={2} />,
                    wifi: <Wifi size={20} strokeWidth={2} />,
                  };
                  return (
                    <div key={f.name} style={{ background: "rgba(255,255,255,0.5)", border: "1px solid rgba(0,0,0,0.06)", borderRadius: 16, padding: "16px 8px", textAlign: "center", display: "flex", flexDirection: "column", alignItems: "center", gap: 8 }}>
                      <div style={{ color: "#2E7D32" }}>{iconMap[f.icon] ?? <Wifi size={20} />}</div>
                      <div style={{ fontSize: 12, color: "#4b5563", fontWeight: 700 }}>{f.name}</div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          {/* Right Column */}
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            {/* Date Selection */}
            <div className="auth-dynamo-glass match-dynamo-card" style={{ padding: 24, borderRadius: 24 }}>
              <h2 style={{ fontSize: 18, fontWeight: 700, color: "#111827", marginBottom: 16 }}>Tarih Seçin</h2>
              <div className="scroll-x">
                {dates.map((date, i) => {
                  const isSelected = date.toDateString() === selectedDate.toDateString();
                  return (
                    <button key={i} onClick={() => setSelectedDate(date)}
                      style={{ flexShrink: 0, width: 54, height: 68, borderRadius: 14, border: "none", cursor: "pointer", background: isSelected ? "#2E7D32" : "rgba(255,255,255,0.6)", color: isSelected ? "white" : "#374151", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2, transition: "all 0.15s", boxShadow: isSelected ? "0 8px 20px rgba(46,125,50,0.2)" : "none" }}>
                      <span style={{ fontSize: 12, fontWeight: 700, opacity: isSelected ? 1 : 0.6 }}>{dayNames[date.getDay()]}</span>
                      <span style={{ fontSize: 20, fontWeight: 800 }}>{date.getDate()}</span>
                    </button>
                  );
                })}
              </div>
              <p style={{ fontSize: 13, color: "#2E7D32", fontWeight: 700, marginTop: 12, background: "rgba(46,125,50,0.06)", padding: "8px 12px", borderRadius: 8, display: "inline-block" }}>
                {selectedDate.getDate()} {monthNames[selectedDate.getMonth()]} {selectedDate.getFullYear()}
              </p>
            </div>

            {/* Time Slots */}
            <div className="auth-dynamo-glass match-dynamo-card" style={{ padding: 24, borderRadius: 24 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
                <h2 style={{ fontSize: 18, fontWeight: 700, color: "#111827" }}>Saat Seçin</h2>
                {selectedSlots.length > 0 && (
                  <span style={{ fontSize: 14, fontWeight: 800, color: "#2E7D32", background: "rgba(46,125,50,0.1)", padding: "4px 10px", borderRadius: 8 }}>
                    {selectedSlots[0]}:00 - {selectedSlots[selectedSlots.length - 1] + 1}:00
                  </span>
                )}
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 8 }}>
                {timeSlots.map(slot => {
                  const isSelected = selectedSlots.includes(slot.hour);
                  const cls = `time-slot ${!slot.available ? "booked" : isSelected ? "selected" : "available"}`;
                  return (
                    <button key={slot.hour} className={cls} onClick={() => toggleSlot(slot.hour)} style={{ height: 54, borderRadius: 12, fontSize: 14 }}>
                      <div style={{ fontWeight: 800 }}>{slot.label}</div>
                      <div style={{ fontSize: 11, opacity: 0.8 }}>₺{pricePerHour}</div>
                    </button>
                  );
                })}
              </div>
              {/* Legend */}
              <div style={{ display: "flex", gap: 16, marginTop: 16, padding: "12px", background: "rgba(0,0,0,0.02)", borderRadius: 12 }}>
                {[{ color: "#2E7D32", label: "Seçili" }, { color: "rgba(255,255,255,0.6)", label: "Müsait" }, { color: "rgba(0,0,0,0.1)", label: "Dolu" }].map(l => (
                  <div key={l.label} style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "#6b7280", fontWeight: 600 }}>
                    <div style={{ width: 10, height: 10, borderRadius: "50%", background: l.color }} />
                    {l.label}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Reviews */}
        <div className="auth-dynamo-glass match-dynamo-card" style={{ padding: 24, marginTop: 16, borderRadius: 24 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
            <h2 style={{ fontSize: 18, fontWeight: 700, color: "#111827" }}>Değerlendirmeler</h2>
            {user && (
              <button
                onClick={() => setShowReviewForm(true)}
                style={{ fontSize: 14, color: "#2E7D32", fontWeight: 700, cursor: "pointer", background: "rgba(46,125,50,0.1)", border: "none", padding: "8px 16px", borderRadius: 10 }}>
                Değerlendir →
              </button>
            )}
          </div>
          <div style={{ display: "flex", gap: 24, alignItems: "center", background: "rgba(255,255,255,0.5)", borderRadius: 16, padding: 20, border: "1px solid rgba(0,0,0,0.03)" }}>
            <div style={{ textAlign: "center" }}>
              <div style={{ fontSize: 44, fontWeight: 900, color: "#111827", lineHeight: 1 }}>{fieldRating.toFixed(1)}</div>
              <div style={{ display: "flex", gap: 2, justifyContent: "center", margin: "8px 0" }}>
                {[1, 2, 3, 4, 5].map(i => (
                  <Star key={i} size={16} style={{ color: "#F59E0B", fill: i <= Math.round(fieldRating) ? "#F59E0B" : "transparent" }} />
                ))}
              </div>
              <div style={{ fontSize: 12, color: "#9ca3af", fontWeight: 600 }}>{reviews.length} değerlendirme</div>
            </div>
            <div style={{ flex: 1 }}>
              {[5, 4, 3, 2, 1].map(star => {
                const count = reviews.filter(r => r.rating === star).length;
                const pct = reviews.length > 0 ? (count / reviews.length) * 100 : 0;
                return (
                  <div key={star} style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 6 }}>
                    <span style={{ fontSize: 12, color: "#6b7280", width: 12, fontWeight: 700 }}>{star}</span>
                    <div style={{ flex: 1, background: "rgba(0,0,0,0.05)", borderRadius: 4, height: 8 }}>
                      <div style={{ width: `${pct}%`, background: "#F59E0B", height: 8, borderRadius: 4 }} />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {reviews.length > 0 && (
            <div style={{ marginTop: 20, display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: 12 }}>
              {reviews.slice(0, 3).map(review => (
                <div key={review.id} style={{ padding: 16, background: "rgba(255,255,255,0.6)", borderRadius: 16, border: "1px solid rgba(0,0,0,0.04)" }}>
                  <div style={{ display: "flex", gap: 4, marginBottom: 8 }}>
                    {[1, 2, 3, 4, 5].map(i => (
                      <Star key={i} size={14} style={{ color: "#F59E0B", fill: i <= review.rating ? "#F59E0B" : "transparent" }} />
                    ))}
                  </div>
                  <p style={{ fontSize: 14, color: "#4b5563", lineHeight: 1.6 }}>{review.comment || "Yorum eklenmedi"}</p>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Bottom Bar — Maç Kur stilinde */}
      <div className="match-booking-bar">
        <div style={{ marginRight: "auto", display: "flex", flexDirection: "column", background: "rgba(255,255,255,0.8)", padding: "10px 20px", borderRadius: 16, backdropFilter: "blur(10px)", border: "1px solid white", boxShadow: "0 4px 12px rgba(0,0,0,0.05)" }}>
          {canBook ? (
            <>
              <p style={{ fontSize: 24, fontWeight: 900, color: "#111827", lineHeight: 1 }}>₺{totalPrice}</p>
              <p style={{ fontSize: 12, color: "#2E7D32", fontWeight: 700 }}>{selectedSlots.length} saat seçildi</p>
            </>
          ) : (
            <p style={{ fontSize: 14, color: "#94a3b8", fontWeight: 600 }}>Henüz saat seçilmedi</p>
          )}
        </div>
        <button
          className={`match-booking-button ${canBook ? "is-active" : "is-disabled"}`}
          onClick={() => {
            if (!user) {
              toast.error("Rezervasyon için giriş yapmalısınız.");
              return;
            }
            setShowBookingModal(true);
          }}
          disabled={!canBook}
          style={{
            border: "none",
            cursor: canBook ? "pointer" : "not-allowed",
          }}
        >
          Rezervasyon Yap <ArrowRight size={18} />
        </button>
      </div>

      {showReviewForm && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 50, padding: 16 }}>
          <div style={{ background: "#fff", borderRadius: 20, padding: 32, maxWidth: 400, width: "100%", maxHeight: "80vh", overflow: "auto" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
              <h2 style={{ fontSize: 22, fontWeight: 900, color: "#111827" }}>Tesisi Değerlendir</h2>
              <button onClick={() => setShowReviewForm(false)} style={{ background: "none", border: "none", cursor: "pointer", fontSize: 24 }}>
                <X size={24} />
              </button>
            </div>

            <div style={{ marginBottom: 20 }}>
              <label style={{ display: "block", fontSize: 14, fontWeight: 600, color: "#374151", marginBottom: 10 }}>Puanın</label>
              <div style={{ display: "flex", gap: 8 }}>
                {[1, 2, 3, 4, 5].map(star => (
                  <button
                    key={star}
                    onClick={() => setReviewForm({ ...reviewForm, rating: star })}
                    style={{ fontSize: 32, background: "none", border: "none", cursor: "pointer", opacity: reviewForm.rating >= star ? 1 : 0.3 }}>
                    ⭐
                  </button>
                ))}
              </div>
            </div>

            <div style={{ marginBottom: 20 }}>
              <label style={{ display: "block", fontSize: 14, fontWeight: 600, color: "#374151", marginBottom: 10 }}>Yorum (İsteğe bağlı)</label>
              <textarea
                value={reviewForm.comment}
                onChange={(e) => setReviewForm({ ...reviewForm, comment: e.target.value })}
                placeholder="Tesisinin özellikleri, hizmet kalitesi vb. hakkında düşüncelerinizi paylaşın..."
                style={{ width: "100%", padding: 12, borderRadius: 10, border: "1px solid #E5E7EB", fontSize: 14, fontFamily: "inherit", resize: "vertical", minHeight: 100 }}
              />
            </div>

            <div style={{ display: "flex", gap: 12 }}>
              <button
                onClick={() => setShowReviewForm(false)}
                style={{ flex: 1, padding: 12, borderRadius: 10, border: "1px solid #E5E7EB", background: "#fff", fontWeight: 700, cursor: "pointer" }}>
                İptal
              </button>
              <button
                onClick={() => {
                  if (reviewForm.rating === 0) {
                    toast.error("Lütfen bir puan seçin");
                    return;
                  }
                  toast.success("Değerlendirmeniz kaydedildi!");
                  setShowReviewForm(false);
                  setReviewForm({ rating: 0, comment: "" });
                }}
                style={{ flex: 1, padding: 12, borderRadius: 10, border: "none", background: "#2E7D32", color: "#fff", fontWeight: 700, cursor: "pointer" }}>
                Gönder
              </button>
            </div>
          </div>
        </div>
      )}

      {showBookingModal && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 60, padding: 16 }}>
          <div style={{ background: "#fff", borderRadius: 24, padding: 32, maxWidth: 450, width: "100%", maxHeight: "90vh", overflow: "auto" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
              <h2 style={{ fontSize: 22, fontWeight: 900, color: "#111827" }}>Rezervasyon Özeti</h2>
              <button onClick={() => setShowBookingModal(false)} style={{ background: "none", border: "none", cursor: "pointer", fontSize: 24 }}>
                <X size={24} />
              </button>
            </div>

            <div style={{ background: "#E8F5E9", borderRadius: 12, padding: "14px 16px", display: "flex", gap: 10, alignItems: "flex-start", marginBottom: 24 }}>
              <AlertCircle size={18} style={{ color: "#2E7D32", flexShrink: 0, marginTop: 1 }} />
              <p style={{ fontSize: 13, color: "#2E7D32", lineHeight: 1.5, fontWeight: 500 }}>
                Randevu talebiniz saha sahibi tarafından onaylandıktan sonra kaporanız alınacaktır.
              </p>
            </div>

            <div style={{ borderTop: "1px solid #f0f0f0", borderBottom: "1px solid #f0f0f0", padding: "16px 0", marginBottom: 24, display: "flex", flexDirection: "column", gap: 12 }}>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 15 }}>
                <span style={{ color: "#6b7280" }}>Saha</span>
                <span style={{ fontWeight: 700, color: "#111827" }}>{currentField.name}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 15 }}>
                <span style={{ color: "#6b7280" }}>Tarih</span>
                <span style={{ fontWeight: 700, color: "#111827" }}>{format(selectedDate, "dd.MM.yyyy")}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 15 }}>
                <span style={{ color: "#6b7280" }}>Saatler</span>
                <span style={{ fontWeight: 700, color: "#2E7D32" }}>
                  {selectedSlots.map(h => `${h}:00`).join(", ")}
                </span>
              </div>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: 10, marginBottom: 32 }}>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 15 }}>
                <span style={{ color: "#6b7280" }}>Saha Ücreti</span>
                <span style={{ fontWeight: 800, color: "#111827" }}>₺{totalPrice}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 16 }}>
                <span style={{ color: "#6b7280", fontWeight: 600 }}>Kapora (%20)</span>
                <span style={{ fontWeight: 900, color: "#2E7D32", fontSize: 18 }}>₺{Math.round(totalPrice * 0.2)}</span>
              </div>
            </div>

            <button
              onClick={handleBooking}
              disabled={isSubmitting}
              style={{ width: "100%", background: "#2E7D32", color: "white", padding: "16px", borderRadius: 16, border: "none", fontWeight: 800, fontSize: 16, cursor: isSubmitting ? "not-allowed" : "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 8, transition: "all 0.2s", opacity: isSubmitting ? 0.7 : 1 }}
            >
              {isSubmitting ? "İşleniyor..." : (<><CreditCard size={20} /> Talebi Gönder & Kapora Öde</>)}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

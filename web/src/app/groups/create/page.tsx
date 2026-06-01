"use client";

import React, { useState, useEffect } from "react";
import Navbar from "@/frontend/components/common/Navbar";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Carousel from "@/frontend/components/Carousel";
import { MapPin, Star, ChevronLeft, Check, ArrowRight, X, AlertCircle, CreditCard } from "lucide-react";
import { getFieldsRealtime, FieldRecord } from "@/backend/services/fieldService";
import { createBooking } from "@/backend/services/bookingService";
import { createMatchPost } from "@/backend/services/matchPostService";
import { getAllPlayers, UserProfile } from "@/backend/services/userService";
import { sendNotification } from "@/backend/services/notificationService";
import { useAuth } from "@/frontend/context/AuthContext";
import { toast } from "react-hot-toast";
import { format } from "date-fns";

const mockPitches = [
  { id: "p1", name: "5v5 Saha A", size: "5'e 5", price: 350, nightPrice: 450 },
  { id: "p2", name: "5v5 Saha B", size: "5'e 5", price: 350, nightPrice: 450 },
  { id: "p3", name: "7v7 Büyük Saha", size: "7'ye 7", price: 500, nightPrice: 650 },
];

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

export default function MatchCreatePage() {
  const router = useRouter();
  const { user, userData } = useAuth();
  const [fields, setFields] = useState<FieldRecord[]>([]);
  const [selectedFacility, setSelectedFacility] = useState<FieldRecord | null>(null);
  const [selectedPitch, setSelectedPitch] = useState(mockPitches[0]);
  const [selectedDate, setSelectedDate] = useState(today);
  const [selectedSlots, setSelectedSlots] = useState<number[]>([]);
  const [allPlayers, setAllPlayers] = useState<UserProfile[]>([]);
  const [selectedPlayerIds, setSelectedPlayerIds] = useState<string[]>([]);
  
  // Maç Detayları State
  const [matchForm, setMatchForm] = useState({
    title: "",
    description: "",
    maxPlayers: 10,
    currentPlayers: 1,
    skillLevel: "intermediate" as any,
    preferredPositions: [] as string[],
  });

  const [showBookingModal, setShowBookingModal] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const dates = getDates();

  useEffect(() => {
    const unsub = getFieldsRealtime((data) => {
      setFields(data);
      if (data.length > 0 && !selectedFacility) {
        setSelectedFacility(data[0]);
      }
    });
    getAllPlayers().then((players) => setAllPlayers(players));
    return () => unsub();
  }, []);

  const toggleSlot = (hour: number) => {
    const slot = timeSlots.find((s) => s.hour === hour);
    if (!slot?.available) return;
    setSelectedSlots((prev) =>
      prev.includes(hour)
        ? prev.filter((h) => h !== hour)
        : [...prev, hour].sort((a, b) => a - b)
    );
  };

  const totalPrice = selectedSlots.length * (selectedPitch.price || 350);
  const canBook = selectedSlots.length > 0 && matchForm.title.trim() !== "" && selectedFacility;

  const handleCreateMatch = async () => {
    if (!user) {
      toast.error("Maç kurmak için giriş yapmalısınız.");
      return;
    }
    setIsSubmitting(true);
    try {
      // 1. Önce kaporayı öde ve rezervasyonu oluştur
      const slotLabel = timeSlots.find(s => s.hour === selectedSlots[0])?.label || "";
      const bookingRef = await createBooking({
        fieldId: selectedFacility!.id!,
        fieldName: (selectedFacility!.name as string) || "Bilinmeyen Saha",
        userId: user.uid,
        userName: user.displayName || userData?.firstName || "Kullanıcı",
        date: format(selectedDate, "yyyy-MM-dd"),
        timeSlot: slotLabel,
        status: "confirmed" // Kapora ödendi simülasyonu
      });

      // 2. Ardından MatchPost oluştur
      const matchPostRef = await createMatchPost({
        creatorId: user.uid,
        creatorName: user.displayName || userData?.firstName || "Kullanıcı",
        creatorProfileImage: user.photoURL || "",
        bookingId: bookingRef.id,
        facilityId: selectedFacility!.id!,
        facilityName: (selectedFacility!.name as string) || "Bilinmeyen Saha",
        facilityAddress: (selectedFacility!.address as string) || "",
        pitchName: selectedPitch.name,
        matchDate: format(selectedDate, "yyyy-MM-dd"),
        startHour: selectedSlots[0],
        endHour: selectedSlots[selectedSlots.length - 1] + 1,
        title: matchForm.title,
        description: matchForm.description,
        neededPlayers: matchForm.maxPlayers - matchForm.currentPlayers,
        currentPlayers: matchForm.currentPlayers,
        maxPlayers: matchForm.maxPlayers,
        preferredPositions: matchForm.preferredPositions,
        skillLevel: matchForm.skillLevel,
        costPerPlayer: Math.round(totalPrice / matchForm.maxPlayers),
      });

      // 3. Seçilen oyunculara anında davet gönder
      if (selectedPlayerIds.length > 0) {
        const promises = selectedPlayerIds.map((playerId) => 
          sendNotification({
            userId: playerId,
            type: "invite",
            title: "Yeni Maç Daveti!",
            body: `${user.displayName || userData?.firstName || "Bir kullanıcı"} seni ${selectedFacility!.name} sahasındaki maça davet ediyor!`,
            relatedId: matchPostRef.id,
          })
        );
        await Promise.all(promises);
        toast.success(`Maç kuruldu ve ${selectedPlayerIds.length} oyuncuya davet gönderildi!`);
      } else {
        toast.success("Maç ilanı başarıyla yayınlandı!");
      }
      
      router.push("/groups");
    } catch (error: any) {
      toast.error(error.message || "Maç kurulurken bir hata oluştu.");
    } finally {
      setIsSubmitting(false);
      setShowBookingModal(false);
    }
  };

  const dayNames = ["Paz", "Pzt", "Sal", "Çrş", "Per", "Cum", "Cmt"];
  const monthNames = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"];

  return (
    <div className="page-wrapper">
      <Navbar />

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
        <div style={{ position: "absolute", top: 16, left: 16 }}>
          <Link
            href="/groups"
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

      <div className="content-container match-main-content" style={{ position: "relative", zIndex: 2, marginTop: -220, paddingTop: 24, paddingBottom: 100 }}>
        
        {/* Maç Detayları Formu (YENİ EKLENDİ) */}
        <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ padding: 24, marginBottom: 16, borderRadius: 24 }}>
          <h2 style={{ fontSize: 18, fontWeight: 700, color: "#111827", marginBottom: 16 }}>Maç Bilgileri</h2>
          
          <div style={{ display: "grid", gridTemplateColumns: "1fr", gap: 16 }}>
            <div>
              <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 4 }}>Maç Başlığı</label>
              <input 
                value={matchForm.title} 
                onChange={(e) => setMatchForm({...matchForm, title: e.target.value})}
                placeholder="Örn: Cuma akşamı kıran kırana maç" 
                className="input-field" 
                style={{ height: 44 }} 
              />
            </div>
            
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
              <div>
                <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 4 }}>Toplam Oyuncu Sayısı</label>
                <select 
                  value={matchForm.maxPlayers} 
                  onChange={(e) => setMatchForm({...matchForm, maxPlayers: Number(e.target.value)})}
                  className="input-field" 
                  style={{ height: 44, paddingLeft: 12 }}>
                  <option value={10}>10 Kişi (5v5)</option>
                  <option value={12}>12 Kişi (6v6)</option>
                  <option value={14}>14 Kişi (7v7)</option>
                </select>
              </div>
              <div>
                <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 4 }}>Seninle Beraber Kaç Kişisiniz?</label>
                <input 
                  type="number" 
                  min={1} 
                  max={matchForm.maxPlayers} 
                  value={matchForm.currentPlayers} 
                  onChange={(e) => setMatchForm({...matchForm, currentPlayers: Number(e.target.value)})}
                  className="input-field" 
                  style={{ height: 44 }} 
                />
              </div>
            </div>

            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
              <div>
                <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 4 }}>Seviye</label>
                <select 
                  value={matchForm.skillLevel} 
                  onChange={(e) => setMatchForm({...matchForm, skillLevel: e.target.value})}
                  className="input-field" 
                  style={{ height: 44, paddingLeft: 12 }}>
                  <option value="any">Fark Etmez</option>
                  <option value="beginner">Başlangıç</option>
                  <option value="intermediate">Orta Seviye</option>
                  <option value="advanced">İleri Seviye</option>
                </select>
              </div>
              <div>
                <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 4 }}>Açıklama</label>
                <input 
                  value={matchForm.description} 
                  onChange={(e) => setMatchForm({...matchForm, description: e.target.value})}
                  placeholder="Opsiyonel detaylar ekleyin..." 
                  className="input-field" 
                  style={{ height: 44 }} 
                />
              </div>
            </div>

            {matchForm.maxPlayers > matchForm.currentPlayers && (
              <div>
                <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 8 }}>Eksik Mevkiler (Çoklu Seçim Yapabilirsiniz)</label>
                <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                  {["Kaleci", "Defans", "Orta Saha", "Forvet"].map((pos) => {
                    const isSelected = matchForm.preferredPositions.includes(pos);
                    return (
                      <button
                        key={pos}
                        onClick={() => {
                          setMatchForm(prev => ({
                            ...prev,
                            preferredPositions: isSelected 
                              ? prev.preferredPositions.filter(p => p !== pos)
                              : [...prev.preferredPositions, pos]
                          }));
                        }}
                        style={{
                          background: isSelected ? "#2E7D32" : "#f3f4f6",
                          color: isSelected ? "white" : "#4b5563",
                          border: isSelected ? "1px solid #2E7D32" : "1px solid #e5e7eb",
                          borderRadius: 20,
                          padding: "6px 16px",
                          fontSize: 13,
                          fontWeight: 600,
                          cursor: "pointer",
                          transition: "all 0.2s"
                        }}
                      >
                        {pos}
                      </button>
                    )
                  })}
                </div>
                <div style={{ marginTop: 12, padding: "10px 14px", background: "#f3f4f6", borderRadius: 8, fontSize: 13, color: "#4b5563", display: "flex", alignItems: "center", gap: 8 }}>
                  <AlertCircle size={16} /> 
                  Aşağıdan oyuncu seçmezseniz ilanınız genel olarak yayınlanır. Maçı kurduktan sonra seçili oyunculara otomatik davet gidecektir.
                </div>
                
                {matchForm.preferredPositions.length > 0 && (
                  <div style={{ marginTop: 16 }}>
                    <p style={{ fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 8 }}>Uygun Oyuncular ({allPlayers.filter(p => p.id !== user?.uid && matchForm.preferredPositions.includes(p.position || "")).length})</p>
                    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: 12, maxHeight: 250, overflowY: "auto", paddingRight: 4 }}>
                      {allPlayers
                        .filter(p => p.id !== user?.uid && matchForm.preferredPositions.includes(p.position || ""))
                        .map(player => {
                          const isSelected = selectedPlayerIds.includes(player.id);
                          return (
                            <div 
                              key={player.id} 
                              onClick={() => {
                                setSelectedPlayerIds(prev => 
                                  isSelected ? prev.filter(id => id !== player.id) : [...prev, player.id]
                                )
                              }}
                              style={{
                                display: "flex", alignItems: "center", gap: 10, padding: 12,
                                borderRadius: 12, cursor: "pointer", transition: "all 0.2s",
                                border: isSelected ? "2px solid #2E7D32" : "1px solid #e5e7eb",
                                background: isSelected ? "#E8F5E9" : "white",
                              }}
                            >
                              <div style={{ width: 40, height: 40, borderRadius: "50%", background: "#f3f4f6", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16 }}>
                                👤
                              </div>
                              <div style={{ flex: 1 }}>
                                <p style={{ fontSize: 14, fontWeight: 600, color: "#111827", margin: 0 }}>{player.firstName} {player.lastName}</p>
                                <p style={{ fontSize: 12, color: "#6b7280", margin: 0 }}>{player.position || "Mevki Yok"} • ⭐ {(player.averageRating || 0).toFixed(1)}</p>
                              </div>
                              <div style={{ width: 20, height: 20, borderRadius: "50%", border: isSelected ? "none" : "1px solid #d1d5db", background: isSelected ? "#2E7D32" : "transparent", display: "flex", alignItems: "center", justifyContent: "center" }}>
                                {isSelected && <Check size={14} color="white" />}
                              </div>
                            </div>
                          );
                        })}
                      {allPlayers.filter(p => p.id !== user?.uid && matchForm.preferredPositions.includes(p.position || "")).length === 0 && (
                        <p style={{ fontSize: 13, color: "#9ca3af" }}>Bu mevkilerde şu an uygun oyuncu bulunmuyor.</p>
                      )}
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>

        {/* Saha ve Zaman Seçimi */}
        <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ padding: 24, marginBottom: 16, borderRadius: 24 }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 14, gap: 12, flexWrap: "wrap" }}>
            <h2 style={{ fontSize: 18, fontWeight: 700, color: "#111827" }}>Saha ve Oyun Tipi Seçimi</h2>
            <span className="pill pill-outline">{(selectedFacility?.isIndoor) ? "🏠 Kapalı Alan" : "☀️ Açık Alan"}</span>
          </div>

          <div style={{ display: "grid", gap: 16, gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))" }}>
            {/* Saha Listesi */}
            <div>
              <p style={{ fontSize: 13, color: "#6b7280", fontWeight: 600, marginBottom: 10 }}>Yakındaki Sahalar</p>
              <div style={{ display: "flex", flexDirection: "column", gap: 10, maxHeight: 400, overflowY: "auto", paddingRight: 4 }}>
                {fields.length === 0 ? (
                  <p style={{ fontSize: 14, color: "#9ca3af" }}>Yükleniyor...</p>
                ) : fields.map((facility) => {
                  const isSelected = selectedFacility?.id === facility.id;
                  const cityName = facility.address ? (facility.address as string).split(',')[0] : "İlçe";
                  return (
                    <button
                      key={facility.id}
                      onClick={() => setSelectedFacility(facility)}
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
                        {cityName}
                      </p>
                      <p style={{ fontSize: 16, fontWeight: 700, color: "#0f172a", marginBottom: 4 }}>{facility.name as string}</p>
                      <p style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 13, color: "#64748b", margin: 0 }}>
                        <MapPin size={13} /> {facility.address as string}
                      </p>
                    </button>
                  );
                })}
              </div>
            </div>

            <div>
              <p style={{ fontSize: 13, color: "#6b7280", fontWeight: 600, marginBottom: 10 }}>Pitches (Oyun Alanı)</p>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))", gap: 10 }}>
                {/* Firebase'de pitch datası varsa onu, yoksa mockPitches kullan */}
                {((selectedFacility?.pitches as any[] | undefined)?.length ? (selectedFacility!.pitches as any[]) : mockPitches).map((pitch: any) => (
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
                    <p style={{ fontSize: 13, color: "#9ca3af" }}>{pitch.size || "Saha Boyutu"}</p>
                    <p style={{ fontSize: 22, lineHeight: 1.1, fontWeight: 700, color: "#2E7D32", marginTop: 8 }}>₺{pitch.price || 350}<span style={{ fontSize: 13 }}>/saat</span></p>
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
              </div>
            </div>
          </div>
        </div>

        <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ padding: 24, marginBottom: 16, borderRadius: 24 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
            <h2 style={{ fontSize: 17, fontWeight: 700, color: "#111827" }}>Saat Seçin</h2>
            {selectedSlots.length > 0 && (
              <span style={{ fontSize: 14, fontWeight: 700, color: "#2E7D32" }}>
                {selectedSlots[0]}:00 - {selectedSlots[selectedSlots.length - 1] + 1}:00
              </span>
            )}
          </div>
          <div className="match-time-grid" style={{ display: "grid", gridTemplateColumns: "repeat(6, 1fr)", gap: 8 }}>
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
        </div>

      </div>

      <div className="match-booking-bar">
        <button
          className={`match-booking-button ${canBook ? "is-active" : "is-disabled"}`}
          onClick={() => {
            if (canBook) {
              if (!user) {
                toast.error("İşlem için giriş yapmalısınız.");
                router.push("/login");
              } else {
                setShowBookingModal(true);
              }
            }
          }}
          disabled={!canBook}
        >
          Maçı Kur & Rezervasyon Yap <ArrowRight size={18} />
        </button>
      </div>

      {/* REZERVASYON VE KAPORA MODALI */}
      {showBookingModal && selectedFacility && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 60, padding: 16 }}>
          <div style={{ background: "#fff", borderRadius: 24, padding: 32, maxWidth: 450, width: "100%", maxHeight: "90vh", overflow: "auto" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
              <h2 style={{ fontSize: 22, fontWeight: 900, color: "#111827" }}>Maç Kurulum Özeti</h2>
              <button onClick={() => setShowBookingModal(false)} style={{ background: "none", border: "none", cursor: "pointer", fontSize: 24 }}>
                <X size={24} />
              </button>
            </div>

            <div style={{ background: "#E8F5E9", borderRadius: 12, padding: "14px 16px", display: "flex", gap: 10, alignItems: "flex-start", marginBottom: 24 }}>
              <AlertCircle size={18} style={{ color: "#2E7D32", flexShrink: 0, marginTop: 1 }} />
              <p style={{ fontSize: 13, color: "#2E7D32", lineHeight: 1.5, fontWeight: 500 }}>
                Maç ilanınız yayınlandıktan sonra sahayı rezerve etmiş olursunuz. İşlemi tamamlamak için kapora alınacaktır.
              </p>
            </div>

            <div style={{ borderTop: "1px solid #f0f0f0", borderBottom: "1px solid #f0f0f0", padding: "16px 0", marginBottom: 24, display: "flex", flexDirection: "column", gap: 12 }}>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 15 }}>
                <span style={{ color: "#6b7280" }}>Maç Başlığı</span>
                <span style={{ fontWeight: 700, color: "#111827" }}>{matchForm.title}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 15 }}>
                <span style={{ color: "#6b7280" }}>Saha</span>
                <span style={{ fontWeight: 700, color: "#111827" }}>{selectedFacility.name as string}</span>
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
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 13, marginTop: 8 }}>
                <span style={{ color: "#9ca3af", fontWeight: 500 }}>Tahmini Kişi Başı</span>
                <span style={{ fontWeight: 700, color: "#6b7280" }}>₺{Math.round(totalPrice / matchForm.maxPlayers)} / kişi</span>
              </div>
            </div>

            <button
              onClick={handleCreateMatch}
              disabled={isSubmitting}
              style={{ width: "100%", background: "#2E7D32", color: "white", padding: "16px", borderRadius: 16, border: "none", fontWeight: 800, fontSize: 16, cursor: isSubmitting ? "not-allowed" : "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 8, transition: "all 0.2s", opacity: isSubmitting ? 0.7 : 1 }}
            >
              {isSubmitting ? "İşleniyor..." : (<><CreditCard size={20} /> Kapora Öde & Maçı Kur</>)}
            </button>
          </div>
        </div>
      )}

    </div>
  );
}


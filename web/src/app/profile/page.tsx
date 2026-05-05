"use client";

import React, { useState, useEffect } from "react";
import { auth } from "@/database/firebase";
import { getUserBookingsRealtime } from "@/backend/services/bookingService";
import { useAuth } from "@/frontend/context/AuthContext";
import Navbar from "@/frontend/components/common/Navbar";
import { toast } from "react-hot-toast";
import { Trash2, Calendar, Clock, User as UserIcon, ChevronRight, Star, Trophy, Bell, Heart, Shield, X } from "lucide-react";
import { deleteUser } from "firebase/auth";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { getUserAverageRating, ratePlayer, hasRatedPlayer } from "@/backend/services/ratingService";

const settingsItems = [
  { icon: UserIcon, label: "Profili Düzenle", color: "#2E7D32" },
  { icon: Bell, label: "Bildirimler", color: "#1565C0" },
  { icon: Heart, label: "Favorilerim", color: "#C62828" },
  { icon: Shield, label: "Gizlilik & Güvenlik", color: "#6A1B9A" },
];

const ProfilePage = () => {
  const { user, userData, isAdmin, loading: authLoading } = useAuth();
  const [reservations, setReservations] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<"bookings" | "settings">("bookings");
  const [userRating, setUserRating] = useState<number>(0);
  const [ratingModal, setRatingModal] = useState<{ show: boolean; resId?: string; opponentIds?: string[] }>({ show: false });
  const [ratingScores, setRatingScores] = useState<{ [key: string]: number }>({});
  const router = useRouter();

  useEffect(() => {
    if (!authLoading && isAdmin) {
      router.replace("/admin/dashboard");
    }
  }, [isAdmin, authLoading, router]);

  useEffect(() => {
    if (!user) return;
    const unsubscribe = getUserBookingsRealtime(user.uid, (bookingList) => {
      setReservations(bookingList);
      setLoading(false);
    });
    return () => unsubscribe();
  }, [user]);

  useEffect(() => {
    if (!user) return;
    getUserAverageRating(user.uid).then(setUserRating);
  }, [user]);


  const handleDeleteAccount = async () => {
    if (confirm("Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.")) {
      try {
        if (auth.currentUser) {
          await deleteUser(auth.currentUser);
          toast.success("Hesabınız silindi.");
          router.push("/");
        }
      } catch {
        toast.error("Hata oluştu. Lütfen tekrar giriş yapıp deneyin.");
      }
    }
  };

  if (authLoading || loading || isAdmin) {
    return (
      <div className="page-wrapper">
        <Navbar />
        <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <div style={{ textAlign: "center", color: "#9ca3af" }}>
            <div style={{ width: 40, height: 40, border: "3px solid #E8F5E9", borderTopColor: "#2E7D32", borderRadius: "50%", animation: "spin 1s linear infinite", margin: "0 auto 16px" }} />
            <p style={{ fontWeight: 600 }}>{isAdmin ? "Yönetici paneline yönlendiriliyor..." : "Yükleniyor..."}</p>
          </div>
        </div>
        <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="page-wrapper">
        <Navbar />
        <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", padding: 40, textAlign: "center" }}>
          <div>
            <div style={{ fontSize: 60, marginBottom: 20 }}>🔒</div>
            <h2 style={{ fontSize: 22, fontWeight: 800, marginBottom: 8 }}>Giriş Gerekli</h2>
            <p style={{ color: "#9ca3af", marginBottom: 24 }}>Bu sayfayı görmek için üye girişi yapmalısınız.</p>
            <Link href="/login" className="btn-primary" style={{ textDecoration: "none" }}>Giriş Yap</Link>
          </div>
        </div>
      </div>
    );
  }

  const initials = (userData?.firstName?.[0] || user.email?.[0] || "U").toUpperCase();
  const fullName = `${userData?.firstName || ""} ${userData?.lastName || ""}`.trim() || "Kullanıcı";

  return (
    <div className="page-wrapper" style={{ height: "100vh", overflow: "hidden" }}>
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
        <div style={{ position: "absolute", bottom: -118, left: 0, width: "100%", lineHeight: 0, zIndex: 0, pointerEvents: "none" }}>
          <svg
            data-name="Layer 1"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 1200 120"
            preserveAspectRatio="none"
            style={{ display: "block", width: "calc(100% + 1.3px)", height: 120, overflow: "visible" }}
          >
            <defs>
              <filter id="profile-wave-soft-shadow" x="-8%" y="-8%" width="116%" height="180%">
                <feGaussianBlur stdDeviation="7" />
              </filter>
            </defs>
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="rgba(0,0,0,0.22)"
              transform="translate(0, 14)"
              filter="url(#profile-wave-soft-shadow)"
            />
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="#1A754E"
            />
          </svg>
        </div>
      </div>

            <div className="content-container" style={{ position: "relative", zIndex: 2, marginTop: -170, paddingTop: 24, paddingBottom: 40, maxWidth: 1400, width: "96%" }}>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 items-start" style={{ gridTemplateColumns: "minmax(0, 1.08fr) minmax(0, 1fr)" }}>
          {/* Sol Kolon */}
          <div style={{ display: "flex", flexDirection: "column", gap: 18, height: "calc(100vh - 160px)", overflowY: "auto", padding: "4px 8px 24px 12px" }}>
            <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ padding: 30, borderRadius: 24, flexShrink: 0 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 20, flexWrap: "wrap" }}>
                <div style={{ width: 92, height: 92, borderRadius: "50%", background: "rgba(17,75,50,0.12)", border: "2px solid rgba(17,75,50,0.22)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 38, fontWeight: 900, flexShrink: 0, color: "#114B32" }}>
                  {initials}
                </div>
                <div style={{ flex: 1 }}>
                  <h1 style={{ fontSize: 38, fontWeight: 900, marginBottom: 6, color: "#0f172a", lineHeight: 1.05 }}>{fullName}</h1>
                  <p style={{ color: "#2E7D32", fontSize: 22, fontWeight: 700, marginBottom: 4 }}>@{userData?.username || "kullanici"}</p>
                  <p style={{ color: "#64748b", fontSize: 18, marginBottom: 6 }}>{user.email}</p>
                  {userData?.position && (
                    <span style={{ display: "inline-block", background: "#E8F5E9", color: "#2E7D32", padding: "6px 14px", borderRadius: 12, fontSize: 14, fontWeight: 700, marginTop: 4 }}>
                      ⚽ Mevki: {userData.position}
                    </span>
                  )}
                </div>
              </div>

              <div style={{ display: "flex", gap: 14, marginTop: 24, flexWrap: "wrap" }}>
                {[{ label: "Randevu", value: reservations.length.toString() }, { label: "Puan", value: Math.round(userRating * 100).toString() }, { label: "Maç", value: reservations.filter(r => r.status === "completed").length.toString() }].map((s) => (
                  <div key={s.label} style={{ background: "rgba(255,255,255,0.72)", backdropFilter: "blur(8px)", borderRadius: 14, padding: "14px 24px", border: "1px solid rgba(17,75,50,0.08)" }}>
                    <p style={{ fontSize: 26, fontWeight: 900, color: "#0f172a", lineHeight: 1 }}>{s.value}</p>
                    <p style={{ fontSize: 13, color: "#64748b", fontWeight: 700, marginTop: 6 }}>{s.label}</p>
                  </div>
                ))}
              </div>
            </div>

            <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 20, padding: "24px 28px", display: "flex", justifyContent: "space-between", alignItems: "center", flexShrink: 0 }}>
              <div style={{ width: "100%" }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 12 }}>
                  <Star size={18} style={{ color: "#FCD34D", fill: "#FCD34D" }} />
                  <span style={{ fontWeight: 700, fontSize: 16, color: "#0f172a" }}>Oyuncu Puanı</span>
                </div>
                <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                  {[1, 2, 3, 4, 5].map((star) => {
                    const isFilled = star <= Math.round(userRating);
                    return (
                      <Star 
                        key={star} 
                        size={38} 
                        style={{ 
                          color: isFilled ? "#F59E0B" : "#CBD5E1", 
                          fill: isFilled ? "#F59E0B" : "transparent",
                          filter: isFilled ? "drop-shadow(0 2px 4px rgba(245,158,11,0.2))" : "none"
                        }} 
                      />
                    );
                  })}
                  <span style={{ marginLeft: 12, fontSize: 28, fontWeight: 900, color: "#0f172a" }}>
                    {userRating.toFixed(1)}
                  </span>
                </div>
              </div>
            </div>

            <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 20, padding: "24px 28px", display: "flex", justifyContent: "space-between", alignItems: "center", flexShrink: 0 }}>
              <div>
                <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
                  <Trophy size={18} style={{ color: "#FCD34D" }} />
                  <span style={{ fontWeight: 700, fontSize: 16, color: "#0f172a" }}>Sadakat Puanı</span>
                </div>
                <p style={{ fontSize: 48, fontWeight: 900, color: "#0f172a", lineHeight: 1 }}>450</p>
                <p style={{ fontSize: 14, color: "#64748b", marginTop: 8 }}>Sonraki seviye için 50 puan kaldı!</p>
              </div>
              <div style={{ textAlign: "right" }}>
                <Trophy size={52} style={{ color: "rgba(17,75,50,0.12)", fill: "rgba(17,75,50,0.12)" }} />
              </div>
            </div>
          </div>

          {/* Sağ Kolon */}
          <div style={{ display: "flex", flexDirection: "column", gap: 18, height: "calc(100vh - 160px)", overflowY: "auto", padding: "4px 8px 24px 12px" }}>
            <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ padding: 20, borderRadius: 20, flexShrink: 0 }}>
              <div style={{ display: "flex", gap: 8, borderRadius: 14, padding: 4 }}>
                {[{ key: "bookings", label: "Randevularım" }, { key: "settings", label: "Ayarlar" }].map((tab) => (
                  <button
                    key={tab.key}
                    onClick={() => setActiveTab(tab.key as "bookings" | "settings")}
                    style={{
                      flex: 1,
                      padding: "14px 0",
                      borderRadius: 12,
                      fontWeight: 700,
                      fontSize: 17,
                      border: "1px solid rgba(255,255,255,0.9)",
                      cursor: "pointer",
                      transition: "all 0.2s",
                      background: activeTab === tab.key ? "rgba(255,255,255,0.88)" : "rgba(255,255,255,0.56)",
                      color: activeTab === tab.key ? "#111827" : "#475569",
                      boxShadow: activeTab === tab.key ? "0 6px 16px rgba(15,23,42,0.08), inset 0 1px 0 rgba(255,255,255,0.7)" : "inset 0 1px 0 rgba(255,255,255,0.45)",
                    }}
                  >
                    {tab.label}
                  </button>
                ))}
              </div>
            </div>

            {activeTab === "bookings" && (
              <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                {reservations.length === 0 ? (
                  <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 20, padding: "56px 20px", textAlign: "center" }}>
                    <div style={{ fontSize: 48, marginBottom: 16 }}>📅</div>
                    <p style={{ fontWeight: 700, color: "#374151", marginBottom: 8 }}>Henüz Randevun Yok</p>
                    <p style={{ color: "#9ca3af", fontSize: 14, marginBottom: 20 }}>İlk randevunu alarak başla!</p>
                    <Link href="#map" className="btn-primary" style={{ textDecoration: "none", display: "inline-flex" }}>
                      Saha Bul
                    </Link>
                  </div>
                ) : (
                  reservations.map((res) => (
                    <div key={res.id} className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 16, padding: "20px" }}>
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 12 }}>
                        <h3 style={{ fontSize: 16, fontWeight: 700, color: "#111827" }}>{res.fieldName}</h3>
                        <span style={{ fontSize: 11, fontWeight: 700, padding: "4px 12px", borderRadius: 20, background: res.status === "completed" ? "#E0F2F1" : res.status === "approved" ? "#E8F5E9" : "#FFF3E0", color: res.status === "completed" ? "#00695C" : res.status === "approved" ? "#2E7D32" : "#E65100" }}>
                          {res.status === "completed" ? "✓ Tamamlandı" : res.status === "approved" ? "✓ Onaylandı" : "⏳ Bekliyor"}
                        </span>
                      </div>
                      <div style={{ display: "flex", gap: 16, color: "#9ca3af", fontSize: 13, marginBottom: 12 }}>
                        <span style={{ display: "flex", alignItems: "center", gap: 4 }}>
                          <Calendar size={13} /> {res.date}
                        </span>
                        <span style={{ display: "flex", alignItems: "center", gap: 4 }}>
                          <Clock size={13} /> {res.timeSlot}
                        </span>
                      </div>
                      {res.status === "completed" && (
                        <button
                          onClick={() => setRatingModal({ show: true, resId: res.id, opponentIds: [] })}
                          style={{ fontSize: 12, fontWeight: 700, padding: "6px 12px", borderRadius: 8, border: "none", background: "#2E7D32", color: "#fff", cursor: "pointer" }}
                        >
                          ⭐ Takım Arkadaşlarını Puanla
                        </button>
                      )}
                    </div>
                  ))
                )}
              </div>
            )}

            {activeTab === "settings" && (
              <div>
                <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 20, overflow: "hidden", marginBottom: 16 }}>
                  {settingsItems.map((item, idx) => {
                    const Icon = item.icon;
                    return (
                      <div
                        key={item.label}
                        style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "16px 20px", borderBottom: idx < settingsItems.length - 1 ? "1px solid rgba(17,75,50,0.08)" : "none", cursor: "pointer" }}
                        className="hover:bg-gray-50 transition-colors"
                      >
                        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                          <div style={{ width: 36, height: 36, borderRadius: 10, background: `${item.color}15`, display: "flex", alignItems: "center", justifyContent: "center" }}>
                            <Icon size={18} style={{ color: item.color }} />
                          </div>
                          <span style={{ fontWeight: 600, fontSize: 15, color: "#374151" }}>{item.label}</span>
                        </div>
                        <ChevronRight size={16} style={{ color: "#d1d5db" }} />
                      </div>
                    );
                  })}
                </div>

                <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 20, overflow: "hidden" }}>
                  <button
                    onClick={handleDeleteAccount}
                    style={{ width: "100%", display: "flex", alignItems: "center", gap: 12, padding: "16px 20px", background: "none", border: "none", cursor: "pointer" }}
                    className="hover:bg-red-50 transition-colors"
                  >
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: "#FFEBEE", display: "flex", alignItems: "center", justifyContent: "center" }}>
                      <Trash2 size={18} style={{ color: "#C62828" }} />
                    </div>
                    <span style={{ fontWeight: 600, fontSize: 15, color: "#C62828" }}>Hesabı Sil</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {ratingModal.show && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 50, padding: 16 }}>
          <div style={{ background: "#fff", borderRadius: 20, padding: 32, maxWidth: 400, width: "100%", maxHeight: "80vh", overflow: "auto" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
              <h2 style={{ fontSize: 22, fontWeight: 900, color: "#111827" }}>Takım Arkadaşlarını Puanla</h2>
              <button onClick={() => setRatingModal({ show: false })} style={{ background: "none", border: "none", cursor: "pointer", fontSize: 24 }}>
                <X size={24} />
              </button>
            </div>
            <p style={{ color: "#9ca3af", fontSize: 14, marginBottom: 20 }}>Aynı takımda oynadığınız arkadaşlarınızı puanlandırın (1-5 yıldız)</p>
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              {["Oyuncu 1", "Oyuncu 2", "Oyuncu 3", "Oyuncu 4"].map((name, idx) => (
                <div key={idx} style={{ padding: 12, background: "#F9FAFB", borderRadius: 12, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <span style={{ fontWeight: 600, color: "#374151" }}>{name}</span>
                  <div style={{ display: "flex", gap: 6 }}>
                    {[1, 2, 3, 4, 5].map((star) => (
                      <button
                        key={star}
                        onClick={() => setRatingScores({ ...ratingScores, [idx]: star })}
                        style={{ background: "none", border: "none", cursor: "pointer", fontSize: 18, opacity: (ratingScores[idx] || 0) >= star ? 1 : 0.3 }}
                      >
                        ⭐
                      </button>
                    ))}
                  </div>
                </div>
              ))}
            </div>
            <div style={{ display: "flex", gap: 12, marginTop: 24 }}>
              <button
                onClick={() => setRatingModal({ show: false })}
                style={{ flex: 1, padding: 12, borderRadius: 10, border: "1px solid #E5E7EB", background: "#fff", fontWeight: 700, cursor: "pointer" }}
              >
                İptal
              </button>
              <button
                onClick={() => {
                  toast.success("Puanlamalar kaydedildi!");
                  setRatingModal({ show: false });
                }}
                style={{ flex: 1, padding: 12, borderRadius: 10, border: "none", background: "#2E7D32", color: "#fff", fontWeight: 700, cursor: "pointer" }}
              >
                Puanla
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ProfilePage;

"use client";

import React, { useState, useEffect } from "react";
import { db, auth } from "@/lib/firebase";
import { collection, query, where, onSnapshot } from "firebase/firestore";
import { useAuth } from "@/context/AuthContext";
import Navbar from "@/components/common/Navbar";
import { toast } from "react-hot-toast";
import { LogOut, Trash2, Calendar, Clock, MapPin, User as UserIcon, Settings, ChevronRight, Star, Trophy, Bell, Heart, Shield } from "lucide-react";
import { signOut, deleteUser } from "firebase/auth";
import { useRouter } from "next/navigation";
import Link from "next/link";

const settingsItems = [
  { icon: UserIcon, label: "Profili Düzenle", color: "#2E7D32" },
  { icon: Bell, label: "Bildirimler", color: "#1565C0" },
  { icon: Heart, label: "Favorilerim", color: "#C62828" },
  { icon: Shield, label: "Gizlilik & Güvenlik", color: "#6A1B9A" },
];

const ProfilePage = () => {
  const { user, userData, loading: authLoading } = useAuth();
  const [reservations, setReservations] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<"bookings" | "settings">("bookings");
  const router = useRouter();

  useEffect(() => {
    if (!user) return;
    const q = query(collection(db, "reservations"), where("userId", "==", user.uid));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setReservations(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    });
    return () => unsubscribe();
  }, [user]);

  const handleLogout = async () => {
    await signOut(auth);
    toast.success("Çıkış yapıldı.");
    router.push("/login");
  };

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

  if (authLoading || loading) {
    return (
      <div className="page-wrapper">
        <Navbar />
        <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <div style={{ textAlign: "center", color: "#9ca3af" }}>
            <div style={{ width: 40, height: 40, border: "3px solid #E8F5E9", borderTopColor: "#2E7D32", borderRadius: "50%", animation: "spin 1s linear infinite", margin: "0 auto 16px" }} />
            <p style={{ fontWeight: 600 }}>Yükleniyor...</p>
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
    <div className="page-wrapper">
      <Navbar />

      {/* Profile Header */}
      <div style={{ background: "linear-gradient(135deg, #2E7D32, #1B5E20)", color: "white", padding: "40px 16px 60px", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: -60, right: -60, width: 200, height: 200, background: "rgba(255,255,255,0.05)", borderRadius: "50%" }} />
        <div className="content-container">
          <div style={{ display: "flex", alignItems: "center", gap: 20, flexWrap: "wrap" }}>
            {/* Avatar */}
            <div style={{ width: 80, height: 80, borderRadius: "50%", background: "rgba(255,255,255,0.2)", border: "3px solid rgba(255,255,255,0.4)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 32, fontWeight: 900, flexShrink: 0 }}>
              {initials}
            </div>
            <div style={{ flex: 1 }}>
              <h1 style={{ fontSize: 26, fontWeight: 900, marginBottom: 4 }}>{fullName}</h1>
              <p style={{ color: "rgba(255,255,255,0.75)", fontSize: 14 }}>@{userData?.username || "kullanici"}</p>
              <p style={{ color: "rgba(255,255,255,0.6)", fontSize: 13, marginTop: 2 }}>{user.email}</p>
            </div>
            <button onClick={handleLogout} style={{ background: "rgba(255,255,255,0.15)", border: "1px solid rgba(255,255,255,0.25)", color: "white", padding: "10px 20px", borderRadius: 12, fontWeight: 700, fontSize: 14, cursor: "pointer", display: "flex", alignItems: "center", gap: 6, backdropFilter: "blur(8px)" }}>
              <LogOut size={16} /> Çıkış
            </button>
          </div>

          {/* Stats row */}
          <div style={{ display: "flex", gap: 12, marginTop: 24, flexWrap: "wrap" }}>
            {[{ label: "Randevu", value: reservations.length.toString() }, { label: "Puan", value: "450" }, { label: "Maç", value: "24" }].map(s => (
              <div key={s.label} style={{ background: "rgba(255,255,255,0.12)", backdropFilter: "blur(8px)", borderRadius: 12, padding: "12px 20px", border: "1px solid rgba(255,255,255,0.15)" }}>
                <p style={{ fontSize: 20, fontWeight: 900 }}>{s.value}</p>
                <p style={{ fontSize: 11, color: "rgba(255,255,255,0.7)", fontWeight: 600, marginTop: 2 }}>{s.label}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Loyalty Card */}
      <div className="content-container" style={{ marginTop: -24, marginBottom: 0, zIndex: 10, position: "relative" }}>
        <div style={{ background: "linear-gradient(135deg, #1565C0, #0D47A1)", borderRadius: 20, padding: "20px 24px", color: "white", display: "flex", justifyContent: "space-between", alignItems: "center", boxShadow: "0 8px 24px rgba(21,101,192,0.3)" }}>
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
              <Trophy size={18} style={{ color: "#FCD34D" }} />
              <span style={{ fontWeight: 700, fontSize: 14 }}>Sadakat Puanın</span>
            </div>
            <p style={{ fontSize: 36, fontWeight: 900 }}>450</p>
            <p style={{ fontSize: 12, color: "rgba(255,255,255,0.7)", marginTop: 4 }}>Sonraki seviye için 50 puan kaldı!</p>
          </div>
          <div style={{ textAlign: "right" }}>
            <Star size={40} style={{ color: "rgba(255,255,255,0.15)", fill: "rgba(255,255,255,0.15)" }} />
          </div>
        </div>
      </div>

      {/* Tab Switcher */}
      <div className="content-container" style={{ paddingTop: 24 }}>
        <div style={{ display: "flex", gap: 0, background: "#f3f4f6", borderRadius: 12, padding: 4, marginBottom: 24 }}>
          {[{ key: "bookings", label: "Randevularım" }, { key: "settings", label: "Ayarlar" }].map(tab => (
            <button key={tab.key} onClick={() => setActiveTab(tab.key as any)}
              style={{ flex: 1, padding: "10px 0", borderRadius: 10, fontWeight: 700, fontSize: 14, border: "none", cursor: "pointer", transition: "all 0.2s", background: activeTab === tab.key ? "white" : "transparent", color: activeTab === tab.key ? "#111827" : "#9ca3af", boxShadow: activeTab === tab.key ? "0 2px 8px rgba(0,0,0,0.08)" : "none" }}>
              {tab.label}
            </button>
          ))}
        </div>

        {activeTab === "bookings" && (
          <div style={{ display: "flex", flexDirection: "column", gap: 12, paddingBottom: 40 }}>
            {reservations.length === 0 ? (
              <div style={{ background: "white", borderRadius: 20, padding: "60px 20px", textAlign: "center", border: "2px dashed #e5e7eb" }}>
                <div style={{ fontSize: 48, marginBottom: 16 }}>📅</div>
                <p style={{ fontWeight: 700, color: "#374151", marginBottom: 8 }}>Henüz Randevun Yok</p>
                <p style={{ color: "#9ca3af", fontSize: 14, marginBottom: 20 }}>İlk randevunu alarak başla!</p>
                <Link href="#map" className="btn-primary" style={{ textDecoration: "none", display: "inline-flex" }}>Saha Bul</Link>
              </div>
            ) : reservations.map((res) => (
              <div key={res.id} style={{ background: "white", borderRadius: 16, padding: "20px", boxShadow: "0 2px 8px rgba(0,0,0,0.06)", border: "1px solid #f0f0f0" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 12 }}>
                  <h3 style={{ fontSize: 16, fontWeight: 700, color: "#111827" }}>{res.fieldName}</h3>
                  <span style={{ fontSize: 11, fontWeight: 700, padding: "4px 12px", borderRadius: 20, background: res.status === "approved" ? "#E8F5E9" : "#FFF3E0", color: res.status === "approved" ? "#2E7D32" : "#E65100" }}>
                    {res.status === "approved" ? "✓ Onaylandı" : "⏳ Bekliyor"}
                  </span>
                </div>
                <div style={{ display: "flex", gap: 16, color: "#9ca3af", fontSize: 13 }}>
                  <span style={{ display: "flex", alignItems: "center", gap: 4 }}><Calendar size={13} /> {res.date}</span>
                  <span style={{ display: "flex", alignItems: "center", gap: 4 }}><Clock size={13} /> {res.timeSlot}</span>
                </div>
              </div>
            ))}
          </div>
        )}

        {activeTab === "settings" && (
          <div style={{ paddingBottom: 40 }}>
            <div style={{ background: "white", borderRadius: 20, overflow: "hidden", boxShadow: "0 2px 8px rgba(0,0,0,0.06)", border: "1px solid #f0f0f0", marginBottom: 16 }}>
              {settingsItems.map((item, idx) => {
                const Icon = item.icon;
                return (
                  <div key={item.label} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "16px 20px", borderBottom: idx < settingsItems.length - 1 ? "1px solid #f5f5f5" : "none", cursor: "pointer" }}
                    className="hover:bg-gray-50 transition-colors">
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

            <div style={{ background: "white", borderRadius: 20, overflow: "hidden", boxShadow: "0 2px 8px rgba(0,0,0,0.06)", border: "1px solid #f0f0f0" }}>
              <button onClick={handleLogout} style={{ width: "100%", display: "flex", alignItems: "center", gap: 12, padding: "16px 20px", background: "none", border: "none", cursor: "pointer", borderBottom: "1px solid #f5f5f5" }}
                className="hover:bg-orange-50 transition-colors">
                <div style={{ width: 36, height: 36, borderRadius: 10, background: "#FFF3E0", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  <LogOut size={18} style={{ color: "#E65100" }} />
                </div>
                <span style={{ fontWeight: 600, fontSize: 15, color: "#E65100" }}>Çıkış Yap</span>
              </button>
              <button onClick={handleDeleteAccount} style={{ width: "100%", display: "flex", alignItems: "center", gap: 12, padding: "16px 20px", background: "none", border: "none", cursor: "pointer" }}
                className="hover:bg-red-50 transition-colors">
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
  );
};

export default ProfilePage;

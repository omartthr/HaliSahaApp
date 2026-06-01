"use client";

import { useEffect, useState, useMemo } from "react";
import Navbar from "@/frontend/components/common/Navbar";
import { getAllPlayers, UserProfile } from "@/backend/services/userService";
import { sendInviteNotification } from "@/backend/services/notificationService";
import { useAuth } from "@/frontend/context/AuthContext";
import { Search, Filter, Star, Trophy, MapPin, Send, ChevronLeft, UserPlus, Check } from "lucide-react";
import { toast } from "react-hot-toast";
import Link from "next/link";
import CustomSelect from "@/frontend/components/common/CustomSelect";

export default function PlayersPage() {
  const { user } = useAuth();
  const [players, setPlayers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [positionFilter, setPositionFilter] = useState("all");
  const [invitingIds, setInvitingIds] = useState<string[]>([]);

  useEffect(() => {
    const fetchPlayers = async () => {
      try {
        const data = await getAllPlayers();
        setPlayers(data.filter(p => p.id !== user?.uid)); // Exclude self
      } catch (error) {
        toast.error("Oyuncular yüklenemedi.");
      } finally {
        setLoading(false);
      }
    };
    fetchPlayers();
  }, [user]);

  const filteredPlayers = useMemo(() => {
    let filtered = players;
    if (search) {
      const q = search.toLowerCase();
      filtered = filtered.filter(p => 
        (p.firstName + " " + p.lastName).toLowerCase().includes(q) ||
        p.username?.toLowerCase().includes(q)
      );
    }
    if (positionFilter !== "all") {
      filtered = filtered.filter(p => p.position === positionFilter);
    }
    // Sort by rating descending
    return filtered.sort((a, b) => (b.averageRating || 0) - (a.averageRating || 0));
  }, [players, search, positionFilter]);

  const handleInvite = async (targetId: string) => {
    if (!user) {
      return toast.error("Davet göndermek için giriş yapmalısınız.");
    }
    setInvitingIds(prev => [...prev, targetId]);
    try {
      await sendInviteNotification(targetId, user.uid, user.displayName || "Kullanıcı");
      toast.success("Davet başarıyla gönderildi!");
    } catch (error) {
      toast.error("Davet gönderilirken hata oluştu.");
    } finally {
      setTimeout(() => setInvitingIds(prev => prev.filter(id => id !== targetId)), 2000);
    }
  };

  return (
    <div className="page-wrapper" style={{ minHeight: "100vh", background: "#f9fafb", paddingBottom: 100 }}>
      <Navbar />

      <div
        className="groups-hero"
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
              <filter id="players-wave-soft-shadow" x="-8%" y="-8%" width="116%" height="180%">
                <feGaussianBlur stdDeviation="7" />
              </filter>
            </defs>
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="rgba(0,0,0,0.22)"
              transform="translate(0, 14)"
              filter="url(#players-wave-soft-shadow)"
            />
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="#1A754E"
            />
          </svg>
        </div>
      </div>

      <div className="content-container groups-main-content" style={{ position: "relative", zIndex: 2, marginTop: -220, paddingTop: 24, paddingBottom: 100, maxWidth: 900 }}>
        <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ padding: 24, borderRadius: 24, display: "flex", flexDirection: "column" }}>
          
          {/* Header Section */}
          <div style={{ display: "flex", flexWrap: "wrap", justifyContent: "space-between", alignItems: "center", gap: 16, marginBottom: 24, paddingBottom: 24, borderBottom: "1px solid rgba(0,0,0,0.06)" }}>
            <div>
              <h1 style={{ fontSize: 24, fontWeight: 800, color: "#111827", margin: 0, display: "flex", alignItems: "center", gap: 10 }}>
                <UserPlus size={24} style={{ color: "#2E7D32" }} /> Oyuncu Ara
              </h1>
              <p style={{ color: "#6b7280", margin: "4px 0 0 0", fontSize: 14 }}>Takımına uygun oyuncuları bul ve maça davet et.</p>
            </div>

            <div style={{ display: "flex", gap: 12, flexWrap: "wrap", flex: "1 1 auto", justifyItems: "flex-end", justifyContent: "flex-end" }}>
              <div style={{ position: "relative", minWidth: 240, maxWidth: 300, flex: "1 1 auto" }}>
                <Search style={{ position: "absolute", left: 14, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} size={18} />
                <input 
                  type="text" 
                  placeholder="İsim veya kullanıcı adı..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="input-field"
                  style={{ width: "100%", padding: "12px 16px 12px 40px", borderRadius: 16, border: "1px solid rgba(0,0,0,0.1)", outline: "none", fontSize: 14, background: "rgba(255,255,255,0.9)" }}
                />
              </div>
              
              <div style={{ position: "relative", minWidth: 160 }}>
                <CustomSelect 
                  value={positionFilter}
                  onChange={(val) => setPositionFilter(val)}
                  icon={<Filter size={18} />}
                  options={[
                    { value: "all", label: "Tüm Mevkiler" },
                    { value: "Kaleci", label: "Kaleci" },
                    { value: "Defans", label: "Defans" },
                    { value: "Orta Saha", label: "Orta Saha" },
                    { value: "Forvet", label: "Forvet" },
                  ]}
                  className="input-field-override" // To override border if needed, but it comes with its own border
                />
              </div>
            </div>
          </div>

          {/* Player List */}
          {loading ? (
            <div style={{ display: "flex", justifyContent: "center", padding: "40px 0" }}>
              <p style={{ color: "#2E7D32", fontWeight: 600 }}>Oyuncular yükleniyor...</p>
            </div>
          ) : filteredPlayers.length === 0 ? (
            <div style={{ textAlign: "center", padding: "40px 20px", background: "rgba(255,255,255,0.5)", borderRadius: 16, border: "1px dashed rgba(0,0,0,0.1)" }}>
              <div style={{ width: 64, height: 64, background: "rgba(255,255,255,0.8)", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 16px", color: "#9ca3af" }}>
                <Search size={28} />
              </div>
              <h3 style={{ fontSize: 16, fontWeight: 700, color: "#111827", marginBottom: 4 }}>Oyuncu Bulunamadı</h3>
              <p style={{ color: "#6b7280", fontSize: 14 }}>Arama kriterlerinize uygun oyuncu bulunamadı.</p>
            </div>
          ) : (
            <div style={{ display: "grid", gridTemplateColumns: "1fr", gap: 12 }}>
              <p style={{ fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 4 }}>Toplam {filteredPlayers.length} oyuncu bulundu</p>
              {filteredPlayers.map((player) => {
                const isInviting = invitingIds.includes(player.id);
                return (
                  <div 
                    key={player.id} 
                    style={{
                      display: "flex", alignItems: "center", gap: 16, padding: "16px",
                      borderRadius: 16, transition: "all 0.2s",
                      border: "1px solid rgba(0,0,0,0.06)",
                      background: "white",
                      boxShadow: "0 2px 10px rgba(0,0,0,0.02)"
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.transform = "translateY(-2px)"}
                    onMouseLeave={(e) => e.currentTarget.style.transform = "translateY(0)"}
                  >
                    <div style={{ width: 48, height: 48, borderRadius: "50%", background: "#f3f4f6", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20 }}>
                      👤
                    </div>
                    
                    <div style={{ flex: 1 }}>
                      <p style={{ fontSize: 15, fontWeight: 700, color: "#111827", margin: "0 0 2px 0" }}>{player.firstName} {player.lastName}</p>
                      <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
                        <span style={{ fontSize: 13, color: "#6b7280", fontWeight: 500 }}>@{player.username || "kullanici"}</span>
                        <span style={{ width: 4, height: 4, borderRadius: "50%", background: "#d1d5db" }}></span>
                        <span style={{ fontSize: 13, color: "#2E7D32", fontWeight: 700 }}>{player.position || "Belirtilmemiş"}</span>
                        <span style={{ width: 4, height: 4, borderRadius: "50%", background: "#d1d5db" }}></span>
                        <span style={{ fontSize: 13, color: "#D97706", fontWeight: 700, display: "flex", alignItems: "center", gap: 2 }}>
                          <Star size={12} style={{ fill: "#D97706" }} /> {(player.averageRating || 0).toFixed(1)}
                        </span>
                      </div>
                    </div>

                    <div>
                      <button 
                        onClick={() => handleInvite(player.id)}
                        disabled={isInviting}
                        style={{ 
                          padding: "8px 20px", 
                          background: isInviting ? "#E8F5E9" : "#2E7D32", 
                          color: isInviting ? "#2E7D32" : "white", 
                          border: "none", 
                          borderRadius: 20, 
                          fontWeight: 700, 
                          fontSize: 13, 
                          cursor: isInviting ? "default" : "pointer", 
                          display: "flex", 
                          alignItems: "center", 
                          gap: 6, 
                          transition: "all 0.2s" 
                        }}
                      >
                        {isInviting ? (
                          <>Gönderildi <Check size={14} /></>
                        ) : (
                          <>Davet Et <Send size={14} /></>
                        )}
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

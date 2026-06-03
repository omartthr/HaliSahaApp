"use client";

import { useMemo, useState, useEffect } from "react";
import Link from "next/link";
import Navbar from "@/frontend/components/common/Navbar";
import { ChevronLeft, MapPin, Star, Trophy, Building2, User } from "lucide-react";
import { getFieldsRealtime, FieldRecord } from "@/backend/services/fieldService";
import { getAllPlayers, UserProfile } from "@/backend/services/userService";
import { useAuth } from "@/frontend/context/AuthContext";
import { toast } from "react-hot-toast";

export default function FavoritesPage() {
  const { user } = useAuth();
  const [fields, setFields] = useState<FieldRecord[]>([]);
  const [players, setPlayers] = useState<UserProfile[]>([]);
  const [activeTab, setActiveTab] = useState<"fields" | "players">("fields");

  // In a real app, these would come from the user's favorites array in Firestore
  // For now, we simulate favorites by randomly picking some items, or letting the user toggle them locally
  const [favoriteFieldIds, setFavoriteFieldIds] = useState<string[]>([]);
  const [favoritePlayerIds, setFavoritePlayerIds] = useState<string[]>([]);

  useEffect(() => {
    const unsubFields = getFieldsRealtime((data) => {
      setFields(data);
      if (data.length > 0 && favoriteFieldIds.length === 0) {
        setFavoriteFieldIds(data.slice(0, 2).map(f => f.id!));
      }
    });

    getAllPlayers().then(data => {
      setPlayers(data);
      if (data.length > 0 && favoritePlayerIds.length === 0) {
        setFavoritePlayerIds(data.slice(0, 3).map(p => p.id));
      }
    });

    return () => unsubFields();
  }, []);

  const toggleFavoriteField = (id: string) => {
    setFavoriteFieldIds(prev => 
      prev.includes(id) ? prev.filter(fId => fId !== id) : [...prev, id]
    );
    toast.success(favoriteFieldIds.includes(id) ? "Favorilerden çıkarıldı" : "Favorilere eklendi");
  };

  const toggleFavoritePlayer = (id: string) => {
    setFavoritePlayerIds(prev => 
      prev.includes(id) ? prev.filter(pId => pId !== id) : [...prev, id]
    );
    toast.success(favoritePlayerIds.includes(id) ? "Favorilerden çıkarıldı" : "Favorilere eklendi");
  };

  const favFields = useMemo(() => fields.filter(f => favoriteFieldIds.includes(f.id!)), [fields, favoriteFieldIds]);
  const favPlayers = useMemo(() => players.filter(p => favoritePlayerIds.includes(p.id)), [players, favoritePlayerIds]);

  return (
    <div className="page-wrapper groups-page-wrapper">
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
        <div style={{ position: "absolute", top: 80, left: 16 }}>
          <button
            onClick={() => window.history.back()}
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

        <div
          style={{
            position: "absolute",
            bottom: -118,
            left: 0,
            width: "100%",
            lineHeight: 0,
            zIndex: 0,
            pointerEvents: "none",
          }}
        >
          <svg
            data-name="Layer 1"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 1200 120"
            preserveAspectRatio="none"
            style={{ display: "block", width: "calc(100% + 1.3px)", height: 120, overflow: "visible" }}
          >
            <defs>
              <filter id="favorites-wave-soft-shadow" x="-8%" y="-8%" width="116%" height="180%">
                <feGaussianBlur stdDeviation="7" />
              </filter>
            </defs>
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="rgba(0,0,0,0.22)"
              transform="translate(0, 14)"
              filter="url(#favorites-wave-soft-shadow)"
            />
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="#1A754E"
            />
          </svg>
        </div>
      </div>

      <div className="content-container groups-main-content" style={{ position: "relative", zIndex: 2, marginTop: -220, paddingTop: 24, paddingBottom: 100, maxWidth: 1000, width: "95%" }}>
        <div className="auth-dynamo-glass match-dynamo-card groups-main-card" style={{ padding: 24, borderRadius: 24, display: "flex", flexDirection: "column" }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 14, gap: 12, flexWrap: "wrap" }}>
            <h2 style={{ fontSize: 18, fontWeight: 700, color: "#111827", display: "flex", alignItems: "center", gap: 8 }}>
              <Star size={18} style={{ color: "#E65100", fill: "#E65100" }} /> Favorilerim
            </h2>
          </div>

          <div style={{ display: "flex", gap: 8, borderRadius: 14, padding: 4, background: "rgba(255,255,255,0.56)", border: "1px solid rgba(17,75,50,0.08)", marginBottom: 20 }}>
            <button
              onClick={() => setActiveTab("fields")}
              style={{
                flex: 1, padding: "14px 0", borderRadius: 12, fontWeight: 700, fontSize: 15, cursor: "pointer", transition: "all 0.2s", display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
                background: activeTab === "fields" ? "#2E7D32" : "transparent",
                color: activeTab === "fields" ? "white" : "#4b5563",
                border: "none"
              }}
            >
              <Building2 size={18} /> Favori Sahalar ({favFields.length})
            </button>
            <button
              onClick={() => setActiveTab("players")}
              style={{
                flex: 1, padding: "14px 0", borderRadius: 12, fontWeight: 700, fontSize: 15, cursor: "pointer", transition: "all 0.2s", display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
                background: activeTab === "players" ? "#2E7D32" : "transparent",
                color: activeTab === "players" ? "white" : "#4b5563",
                border: "none"
              }}
            >
              <User size={18} /> Favori Oyuncular ({favPlayers.length})
            </button>
          </div>

          <div style={{ minHeight: 400 }}>
            {activeTab === "fields" && (
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(300px, 1fr))", gap: 16 }}>
                {favFields.length === 0 ? (
                  <p style={{ color: "#6b7280", textAlign: "center", marginTop: 40, fontSize: 15, gridColumn: "1 / -1" }}>Henüz favori sahanız bulunmuyor.</p>
                ) : favFields.map((field) => (
                  <div key={field.id} style={{
                    borderRadius: 18, padding: "20px", border: "1px solid rgba(15,23,42,0.08)", background: "rgba(255,255,255,0.82)", boxShadow: "0 8px 24px rgba(0,0,0,0.04)", transition: "all 0.2s ease"
                  }}>
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
                      <p style={{ fontWeight: 800, fontSize: 16, color: "#111827", margin: 0 }}>{field.name as string}</p>
                      <button onClick={() => toggleFavoriteField(field.id!)} style={{ background: "none", border: "none", cursor: "pointer" }}>
                        <Star size={20} style={{ color: "#F59E0B", fill: "#F59E0B" }} />
                      </button>
                    </div>
                    <p style={{ display: "flex", alignItems: "center", gap: 6, color: "#6b7280", fontSize: 13, marginBottom: 12 }}>
                      <MapPin size={13} /> {field.address as string}
                    </p>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", borderTop: "1px solid #f3f4f6", paddingTop: 12 }}>
                      <span style={{ fontSize: 13, color: "#2E7D32", fontWeight: 700 }}>₺{field.price || 350}/saat</span>
                      <Link href={`/fields/${field.id}`} style={{ background: "#E8F5E9", color: "#2E7D32", borderRadius: 8, padding: "6px 16px", fontSize: 13, fontWeight: 700, textDecoration: "none" }}>
                        İncele
                      </Link>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {activeTab === "players" && (
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(300px, 1fr))", gap: 16 }}>
                {favPlayers.length === 0 ? (
                  <p style={{ color: "#6b7280", textAlign: "center", marginTop: 40, fontSize: 15, gridColumn: "1 / -1" }}>Henüz favori oyuncunuz bulunmuyor.</p>
                ) : favPlayers.map((player) => (
                  <div key={player.id} style={{
                    borderRadius: 18, padding: "20px", border: "1px solid rgba(15,23,42,0.08)", background: "rgba(255,255,255,0.82)", boxShadow: "0 8px 24px rgba(0,0,0,0.04)", transition: "all 0.2s ease"
                  }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 12 }}>
                      <div style={{ width: 48, height: 48, borderRadius: "50%", background: "#E8F5E9", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20 }}>
                        👤
                      </div>
                      <div style={{ flex: 1 }}>
                        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                          <p style={{ fontWeight: 800, fontSize: 16, color: "#111827", margin: 0 }}>{player.firstName} {player.lastName}</p>
                          <button onClick={() => toggleFavoritePlayer(player.id)} style={{ background: "none", border: "none", cursor: "pointer" }}>
                            <Star size={20} style={{ color: "#F59E0B", fill: "#F59E0B" }} />
                          </button>
                        </div>
                        <p style={{ fontSize: 13, color: "#6b7280", margin: "2px 0 0" }}>@{player.username || "kullanici"}</p>
                      </div>
                    </div>
                    
                    <div style={{ display: "flex", gap: 8, marginBottom: 12 }}>
                      {player.position && (
                        <span style={{ background: "#FEF3C7", color: "#D97706", borderRadius: 12, padding: "4px 10px", fontSize: 12, fontWeight: 700 }}>
                          {player.position}
                        </span>
                      )}
                      <span style={{ display: "flex", alignItems: "center", gap: 4, background: "#F3F4F6", color: "#4B5563", borderRadius: 12, padding: "4px 10px", fontSize: 12, fontWeight: 700 }}>
                        <Trophy size={12} /> {(player.averageRating || 0).toFixed(1)} Puan
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

"use client";

import { useMemo, useState } from "react";
import dynamic from "next/dynamic";
import Link from "next/link";
import Navbar from "@/frontend/components/common/Navbar";
import { ArrowRight, ChevronLeft, MapPin, Users } from "lucide-react";
import { useEffect } from "react";
import { getActiveMatchPostsRealtime, MatchPost, applyToMatchPost } from "@/backend/services/matchPostService";
import { getFieldsRealtime, FieldRecord } from "@/backend/services/fieldService";
import { getUserProfile, UserProfile } from "@/backend/services/userService";
import { useAuth } from "@/frontend/context/AuthContext";
import { toast } from "react-hot-toast";

export type Listing = {
  id: string;
  title: string;
  district: string;
  address: string;
  date: string;
  neededPlayers: number;
  level: string;
  lat: number;
  lng: number;
  isPositionMatch: boolean;
  preferredPositions?: string[];
  description?: string;
  costPerPlayer?: number;
};

const formatFirestoreDate = (dateVal: any) => {
  if (!dateVal) return "";
  if (typeof dateVal === "string") return dateVal;
  if (typeof dateVal === "number") return new Date(dateVal).toLocaleDateString("tr-TR");
  if (dateVal.seconds) return new Date(dateVal.seconds * 1000).toLocaleDateString("tr-TR");
  if (dateVal.toDate) return dateVal.toDate().toLocaleDateString("tr-TR");
  return String(dateVal);
};

const GroupsListingsMap = dynamic(() => import("@/frontend/components/map/GroupsListingsMap"), {
  ssr: false,
  loading: () => (
    <div className="h-full w-full bg-gray-100 animate-pulse flex items-center justify-center text-gray-400">
      Harita yukleniyor...
    </div>
  ),
});

export default function GroupsPage() {
  const { user } = useAuth();
  const [matchPosts, setMatchPosts] = useState<MatchPost[]>([]);
  const [fields, setFields] = useState<FieldRecord[]>([]);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [selectedListingId, setSelectedListingId] = useState<string | null>(null);

  useEffect(() => {
    const unsubFields = getFieldsRealtime(setFields);
    return () => unsubFields();
  }, []);

  useEffect(() => {
    if (user) {
      getUserProfile(user.uid).then(setUserProfile);
    }
  }, [user]);

  useEffect(() => {
    let unsubPosts: (() => void) | undefined;
    if (user) {
      unsubPosts = getActiveMatchPostsRealtime(setMatchPosts);
    } else {
      setMatchPosts([]);
    }
    return () => {
      if (unsubPosts) unsubPosts();
    };
  }, [user]);

  const listings: Listing[] = useMemo(() => {
    const arr = matchPosts.map(post => {
      const field = fields.find(f => f.id === post.facilityId);
      const district = post.facilityAddress ? post.facilityAddress.split(',')[0] : "İlçe";
      
      const isPositionMatch = Boolean(
        userProfile?.position && 
        post.preferredPositions && 
        post.preferredPositions.includes(userProfile.position)
      );

      return {
        id: post.id!,
        title: post.title,
        district: district,
        address: post.facilityName,
        date: `${formatFirestoreDate(post.matchDate)} ${post.startHour}:00`,
        neededPlayers: post.maxPlayers - post.currentPlayers,
        level: post.skillLevel,
        lat: (field?.location as any)?.lat || 41.0082,
        lng: (field?.location as any)?.lng || 28.9784,
        isPositionMatch,
        preferredPositions: post.preferredPositions,
        description: post.description,
        costPerPlayer: post.costPerPlayer,
      };
    });

    return arr.sort((a, b) => {
      if (a.isPositionMatch && !b.isPositionMatch) return -1;
      if (!a.isPositionMatch && b.isPositionMatch) return 1;
      return 0;
    });
  }, [matchPosts, fields, userProfile]);

  // Set the first listing as selected by default once loaded
  useEffect(() => {
    if (listings.length > 0 && !selectedListingId) {
      setSelectedListingId(listings[0].id);
    }
  }, [listings, selectedListingId]);

  const selectedPost = useMemo(
    () => matchPosts.find(p => p.id === selectedListingId),
    [matchPosts, selectedListingId]
  );

  const hasApplied = selectedPost && user && selectedPost.applicantIds?.includes(user.uid);
  const isCreator = selectedPost && user && selectedPost.creatorId === user.uid;

  const handleApply = async () => {
    if (!user) return toast.error("Giriş yapmalısınız!");
    if (!selectedPost?.id) return;
    try {
      await applyToMatchPost(selectedPost.id, user.uid);
      toast.success("İstek başarıyla gönderildi!");
    } catch (error) {
      toast.error("İstek gönderilemedi.");
    }
  };

  const selectedListingData = listings.find(l => l.id === selectedListingId);

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
              <filter id="groups-wave-soft-shadow" x="-8%" y="-8%" width="116%" height="180%">
                <feGaussianBlur stdDeviation="7" />
              </filter>
            </defs>
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="rgba(0,0,0,0.22)"
              transform="translate(0, 14)"
              filter="url(#groups-wave-soft-shadow)"
            />
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="#1A754E"
            />
          </svg>
        </div>
      </div>

      <div className="content-container groups-main-content" style={{ position: "relative", zIndex: 2, marginTop: -220, paddingTop: 24, paddingBottom: 100, maxWidth: 1400, width: "95%" }}>
        <div className="auth-dynamo-glass match-dynamo-card groups-main-card" style={{ padding: 24, borderRadius: 24, display: "flex", flexDirection: "column" }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 14, gap: 12, flexWrap: "wrap" }}>
            <h2 style={{ fontSize: 18, fontWeight: 700, color: "#111827", display: "flex", alignItems: "center", gap: 8 }}>
              <Users size={18} style={{ color: "#2E7D32" }} /> Oyuncu Aranan Ilanlar
            </h2>
            <span className="pill pill-outline">Toplam {listings.length} ilan</span>
          </div>

          <div className="groups-split-grid" style={{ display: "grid", gap: 16, flex: 1, minHeight: 0 }}>
            <div className="groups-map-panel" style={{ borderRadius: 20, overflow: "hidden", height: "100%", boxShadow: "0 8px 32px rgba(0,0,0,0.1)" }}>
              <GroupsListingsMap
                center={selectedListingData ? [selectedListingData.lat, selectedListingData.lng] : [41.0082, 28.9784]}
                listings={listings}
              />
            </div>

            <div className="groups-list-panel" style={{ height: "100%", overflowY: "auto", overflowX: "hidden", borderRadius: 12 }}>
              <div style={{ display: "flex", flexDirection: "column", gap: 12, paddingRight: 4 }}>
                {listings.length === 0 ? (
                  <p style={{ color: "#6b7280", textAlign: "center", marginTop: 40, fontSize: 15 }}>Şu an aktif oyuncu arayan maç ilanı bulunmuyor.</p>
                ) : listings.map((listing) => {
                  const isSelected = listing.id === selectedListingId;

                  return (
                    <button
                      key={listing.id}
                      onClick={() => setSelectedListingId(listing.id)}
                      style={{
                        textAlign: "left",
                        borderRadius: 18,
                        padding: "14px 16px",
                        border: `1px solid ${isSelected ? "#2E7D32" : listing.isPositionMatch ? "#F59E0B" : "rgba(15,23,42,0.08)"}`,
                        background: isSelected ? "rgba(232,245,233,0.85)" : listing.isPositionMatch ? "rgba(254,243,199,0.5)" : "rgba(255,255,255,0.82)",
                        boxShadow: isSelected ? "0 10px 26px rgba(46,125,50,0.12)" : "0 8px 24px rgba(0,0,0,0.04)",
                        cursor: "pointer",
                        transition: "all 0.2s ease",
                      }}
                    >
                      {listing.isPositionMatch && (
                        <div style={{ fontSize: 11, fontWeight: "bold", color: "#B45309", marginBottom: 6, display: "flex", alignItems: "center", gap: 4 }}>
                          ⭐ Mevkinize Uygun
                        </div>
                      )}
                      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 10, marginBottom: 8 }}>
                        <p style={{ fontWeight: 800, fontSize: 16, color: "#111827", lineHeight: 1.3 }}>{listing.title}</p>
                        <span style={{ background: "#2E7D32", color: "white", borderRadius: 999, padding: "4px 10px", fontSize: 12, fontWeight: 700, whiteSpace: "nowrap" }}>
                          {listing.neededPlayers} kişi aranıyor
                        </span>
                      </div>

                      {listing.preferredPositions && listing.preferredPositions.length > 0 && (
                        <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 10 }}>
                          {listing.preferredPositions.map((pos: string) => (
                            <span key={pos} style={{ background: "#FEF3C7", color: "#D97706", borderRadius: 12, padding: "2px 8px", fontSize: 11, fontWeight: 700 }}>
                              {pos}
                            </span>
                          ))}
                        </div>
                      )}

                      <p style={{ fontSize: 12, color: "#2E7D32", fontWeight: 700, letterSpacing: "0.06em", textTransform: "uppercase", marginBottom: 4 }}>
                        {listing.district}
                      </p>

                      <p style={{ display: "flex", alignItems: "center", gap: 6, color: "#6b7280", fontSize: 13, marginBottom: 6 }}>
                        <MapPin size={13} /> {listing.address}
                      </p>

                      {listing.description && (
                        <p style={{ fontSize: 13, color: "#4B5563", marginBottom: 8, fontStyle: "italic" }}>
                          "{listing.description}"
                        </p>
                      )}

                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: 13, borderTop: "1px solid #f3f4f6", paddingTop: 8, marginTop: 4 }}>
                        <span style={{ color: "#9ca3af", fontWeight: 500 }}>{listing.date}</span>
                        <div style={{ display: "flex", gap: 8 }}>
                          <span style={{ color: "#2E7D32", fontWeight: 700, background: "#E8F5E9", padding: "2px 8px", borderRadius: 8 }}>{listing.level}</span>
                          {listing.costPerPlayer && (
                            <span style={{ color: "#0369a1", fontWeight: 700, background: "#e0f2fe", padding: "2px 8px", borderRadius: 8 }}>₺{listing.costPerPlayer}/kişi</span>
                          )}
                        </div>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="match-booking-bar bg-white border-t border-gray-100 p-4 sticky bottom-0 z-50 shadow-[0_-10px_40px_rgba(0,0,0,0.05)]">
        {selectedPost ? (
          isCreator ? (
            <button className="match-booking-button bg-gray-200 text-gray-500 rounded-xl py-3 w-full font-bold cursor-not-allowed">
              Bu Sizin İlanınız
            </button>
          ) : hasApplied ? (
            <button className="match-booking-button bg-green-100 text-green-700 rounded-xl py-3 w-full font-bold cursor-not-allowed flex items-center justify-center gap-2">
              <ArrowRight size={18} /> İstek Gönderildi
            </button>
          ) : (
            <button 
              onClick={handleApply}
              className="match-booking-button bg-[#2E7D32] hover:bg-[#1B5E20] text-white rounded-xl py-3 w-full font-bold transition-colors flex items-center justify-center gap-2"
            >
              Katılmak İstiyorum <ArrowRight size={18} />
            </button>
          )
        ) : (
          <button className="match-booking-button bg-gray-200 text-gray-400 rounded-xl py-3 w-full font-bold cursor-not-allowed">
            Lütfen Bir İlan Seçin
          </button>
        )}
      </div>
    </div>
  );
}

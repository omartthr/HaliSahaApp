"use client";

import { useMemo, useState } from "react";
import dynamic from "next/dynamic";
import Link from "next/link";
import Navbar from "@/frontend/components/common/Navbar";
import { ArrowRight, ChevronLeft, MapPin, Users } from "lucide-react";

type Listing = {
  id: string;
  title: string;
  district: string;
  address: string;
  date: string;
  neededPlayers: number;
  level: string;
  lat: number;
  lng: number;
};

const listings: Listing[] = [
  {
    id: "g1",
    title: "5v5 Akşam Maçı - Kadıköy",
    district: "Kadıköy",
    address: "Moda Sahili Halı Saha",
    date: "Bugün 21:00",
    neededPlayers: 3,
    level: "Orta Seviye",
    lat: 40.9857,
    lng: 29.0265,
  },
  {
    id: "g2",
    title: "7v7 Hafta Sonu - Üsküdar",
    district: "Üsküdar",
    address: "Bağlarbaşı Spor Tesisi",
    date: "Cumartesi 19:00",
    neededPlayers: 5,
    level: "İleri Seviye",
    lat: 41.0243,
    lng: 29.0209,
  },
  {
    id: "g3",
    title: "Dostluk Maçı - Beşiktaş",
    district: "Beşiktaş",
    address: "Abbasağa Halı Saha",
    date: "Pazar 18:00",
    neededPlayers: 2,
    level: "Başlangıç",
    lat: 41.0437,
    lng: 29.0047,
  },
  {
    id: "g4",
    title: "Gece Maçı - Ataşehir",
    district: "Ataşehir",
    address: "Kayışdağı Arena",
    date: "Cuma 22:30",
    neededPlayers: 4,
    level: "Orta Seviye",
    lat: 40.9918,
    lng: 29.1283,
  },
];

const GroupsListingsMap = dynamic(() => import("@/frontend/components/map/GroupsListingsMap"), {
  ssr: false,
  loading: () => (
    <div className="h-full w-full bg-gray-100 animate-pulse flex items-center justify-center text-gray-400">
      Harita yukleniyor...
    </div>
  ),
});

export default function GroupsPage() {
  const [selectedListingId, setSelectedListingId] = useState(listings[0].id);

  const selectedListing = useMemo(
    () => listings.find((listing) => listing.id === selectedListingId) ?? listings[0],
    [selectedListingId]
  );

  const canBook = Boolean(selectedListingId);

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

      <div className="content-container groups-main-content" style={{ position: "relative", zIndex: 2, marginTop: -220, paddingTop: 24, paddingBottom: 100 }}>
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
                center={[selectedListing.lat, selectedListing.lng]}
                listings={listings}
              />
            </div>

            <div className="groups-list-panel" style={{ height: "100%", overflowY: "auto", overflowX: "hidden", borderRadius: 12 }}>
              <div style={{ display: "flex", flexDirection: "column", gap: 12, paddingRight: 4 }}>
                {listings.map((listing) => {
                  const isSelected = listing.id === selectedListingId;

                  return (
                    <button
                      key={listing.id}
                      onClick={() => setSelectedListingId(listing.id)}
                      style={{
                        textAlign: "left",
                        borderRadius: 18,
                        padding: "14px 16px",
                        border: `1px solid ${isSelected ? "#2E7D32" : "rgba(15,23,42,0.08)"}`,
                        background: isSelected ? "rgba(232,245,233,0.85)" : "rgba(255,255,255,0.82)",
                        boxShadow: isSelected ? "0 10px 26px rgba(46,125,50,0.12)" : "0 8px 24px rgba(0,0,0,0.04)",
                        cursor: "pointer",
                        transition: "all 0.2s ease",
                      }}
                    >
                      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 10, marginBottom: 6 }}>
                        <p style={{ fontWeight: 700, fontSize: 15, color: "#111827", lineHeight: 1.3 }}>{listing.title}</p>
                        <span style={{ background: "#2E7D32", color: "white", borderRadius: 999, padding: "4px 10px", fontSize: 12, fontWeight: 700 }}>
                          {listing.neededPlayers} kisi
                        </span>
                      </div>

                      <p style={{ fontSize: 12, color: "#2E7D32", fontWeight: 700, letterSpacing: "0.06em", textTransform: "uppercase", marginBottom: 4 }}>
                        {listing.district}
                      </p>

                      <p style={{ display: "flex", alignItems: "center", gap: 6, color: "#6b7280", fontSize: 13, marginBottom: 8 }}>
                        <MapPin size={13} /> {listing.address}
                      </p>

                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: 13 }}>
                        <span style={{ color: "#9ca3af" }}>{listing.date}</span>
                        <span style={{ color: "#2E7D32", fontWeight: 700 }}>{listing.level}</span>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="match-booking-bar">
        <Link
          className={`match-booking-button ${canBook ? "is-active" : "is-disabled"}`}
          href={canBook ? `/booking/${selectedListing.id}` : "#"}
          style={{
            textDecoration: "none",
            pointerEvents: canBook ? "auto" : "none",
          }}
        >
          Rezervasyon Yap <ArrowRight size={18} />
        </Link>
      </div>
    </div>
  );
}

"use client";

import React from "react";
import dynamic from "next/dynamic";

const MapContainer = dynamic(() => import("react-leaflet").then((mod) => mod.MapContainer), { ssr: false });
const TileLayer = dynamic(() => import("react-leaflet").then((mod) => mod.TileLayer), { ssr: false });
const Marker = dynamic(() => import("react-leaflet").then((mod) => mod.Marker), { ssr: false });

import "leaflet/dist/leaflet.css";

interface StaticMapProps {
  latitude: number;
  longitude: number;
}

const StaticLocationMap = ({ latitude, longitude }: StaticMapProps) => {
  if (typeof window !== "undefined") {
    const L = require("leaflet");
    const DefaultIcon = L.icon({
      iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
      shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
      iconSize: [25, 41],
      iconAnchor: [12, 41],
    });
    L.Marker.prototype.options.icon = DefaultIcon;
  }

  const openGoogleMaps = () => {
    window.open(`https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}`, "_blank");
  };

  return (
    <div 
      onClick={openGoogleMaps}
      style={{ width: "100%", height: "200px", position: "relative", zIndex: 0, borderRadius: "24px", overflow: "hidden", border: "1px solid rgba(0,0,0,0.06)", cursor: "pointer", boxShadow: "0 4px 12px rgba(0,0,0,0.05)" }}
    >
      <div style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", zIndex: 400, background: "transparent" }}></div>
      <MapContainer
        center={[latitude, longitude]}
        zoom={14}
        style={{ height: "100%", width: "100%", pointerEvents: "none" }}
        zoomControl={false}
        dragging={false}
        scrollWheelZoom={false}
        doubleClickZoom={false}
      >
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <Marker position={[latitude, longitude]} />
      </MapContainer>
      <div style={{ position: "absolute", bottom: 12, left: "50%", transform: "translateX(-50%)", zIndex: 401 }}>
        <div style={{ background: "#2E7D32", color: "white", padding: "6px 14px", borderRadius: 20, fontSize: 12, fontWeight: 700, boxShadow: "0 4px 12px rgba(46,125,50,0.3)", display: "flex", alignItems: "center", gap: 6 }}>
          📍 Haritada Aç
        </div>
      </div>
    </div>
  );
};

export default StaticLocationMap;

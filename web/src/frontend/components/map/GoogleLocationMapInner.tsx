"use client";

import React, { useEffect } from "react";
import { MapContainer, TileLayer, Marker, useMapEvents, useMap } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import L from "leaflet";

// Fix for default Leaflet icons in Next.js
const DefaultIcon = L.icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});
L.Marker.prototype.options.icon = DefaultIcon;

interface GoogleLocationMapProps {
  position: [number, number];
  onChange?: (pos: [number, number]) => void;
  readOnly?: boolean;
}

const LocationMarker = ({ position, onChange, readOnly }: GoogleLocationMapProps) => {
  const map = useMap();
  
  useMapEvents({
    click(e) {
      if (!readOnly && onChange) {
        onChange([e.latlng.lat, e.latlng.lng]);
      }
    },
  });

  useEffect(() => {
    if (position && position[0] && position[1]) {
      map.flyTo(position, map.getZoom(), { animate: false });
    }
  }, []);

  return position && position[0] && position[1] ? <Marker position={position} /> : null;
};

const GoogleLocationMapInner = ({ position, onChange, readOnly = false }: GoogleLocationMapProps) => {
  const center = position && position[0] ? position : [41.0082, 28.9784];

  return (
    <div style={{ width: "100%", height: "100%", position: "relative", borderRadius: "12px", overflow: "hidden", border: "1px solid #E5E7EB" }}>
      <MapContainer
        center={center as [number, number]}
        zoom={14}
        style={{ height: "100%", width: "100%", zIndex: 0 }}
        zoomControl={!readOnly}
        dragging={!readOnly}
        scrollWheelZoom={!readOnly}
        doubleClickZoom={!readOnly}
      >
        <TileLayer
          attribution='&copy; Google Maps'
          url="http://mt0.google.com/vt/lyrs=m&hl=tr&x={x}&y={y}&z={z}"
        />
        <LocationMarker position={position} onChange={onChange} readOnly={readOnly} />
      </MapContainer>
      
      {readOnly && (
        <div style={{ position: "absolute", bottom: 12, left: "50%", transform: "translateX(-50%)", zIndex: 400 }}>
          <button 
            onClick={() => window.open(`https://www.google.com/maps/search/?api=1&query=${position[0]},${position[1]}`, "_blank")}
            style={{ background: "#2E7D32", color: "white", padding: "8px 20px", borderRadius: 20, fontSize: 13, fontWeight: 700, boxShadow: "0 4px 12px rgba(46,125,50,0.3)", border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: 6 }}
          >
            📍 Google Haritalar'da Aç
          </button>
        </div>
      )}
    </div>
  );
};

export default GoogleLocationMapInner;

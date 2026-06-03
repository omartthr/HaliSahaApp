"use client";

import React from "react";
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

interface LocationPickerProps {
  position: [number, number];
  onChange: (pos: [number, number]) => void;
}

const LocationMarker = ({ position, onChange }: LocationPickerProps) => {
  const map = useMap();
  
  useMapEvents({
    click(e) {
      onChange([e.latlng.lat, e.latlng.lng]);
    },
  });

  // When position changes from outside (e.g. initial load), center map
  React.useEffect(() => {
    if (position && position[0] && position[1]) {
      map.flyTo(position, map.getZoom(), { animate: false });
    }
  }, []);

  return position && position[0] && position[1] ? <Marker position={position} /> : null;
};

const LocationPickerMapInner = ({ position, onChange }: LocationPickerProps) => {
  const center = position && position[0] ? position : [41.0082, 28.9784];

  return (
    <div style={{ width: "100%", height: "250px", position: "relative", zIndex: 0, borderRadius: "12px", overflow: "hidden", border: "1px solid #E5E7EB" }}>
      <MapContainer
        center={center as [number, number]}
        zoom={12}
        style={{ height: "100%", width: "100%" }}
        zoomControl={false}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <LocationMarker position={position} onChange={onChange} />
      </MapContainer>
      <div style={{ position: "absolute", top: 8, left: 8, right: 8, zIndex: 400, pointerEvents: "none" }}>
        <div style={{ background: "rgba(255,255,255,0.9)", backdropFilter: "blur(8px)", padding: "8px 12px", borderRadius: 8, boxShadow: "0 2px 4px rgba(0,0,0,0.1)", fontSize: 12, fontWeight: 600, color: "#374151", textAlign: "center", border: "1px solid #E5E7EB" }}>
          📍 Harita üzerinde tıklayarak tesisinizin tam konumunu işaretleyin
        </div>
      </div>
    </div>
  );
};

export default LocationPickerMapInner;

"use client";

import React, { useEffect, useRef, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import L from "leaflet";
import { db } from "@/database/firebase";
import { collection, onSnapshot } from "firebase/firestore";
import { Star } from "lucide-react";

// Fix for default Leaflet icons in Next.js
const DefaultIcon = L.icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});
L.Marker.prototype.options.icon = DefaultIcon;

interface Field {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  address: string;
  phone: string;
  averageRating: number;
  features?: string[];
}

/** Haritayı tıklanana kadar kilitler, tıklanınca aktif eder */
function MapActivator({ isActive }: { isActive: boolean }) {
  const map = useMap();

  useEffect(() => {
    if (isActive) {
      map.dragging.enable();
      map.scrollWheelZoom.enable();
      map.touchZoom.enable();
      map.doubleClickZoom.enable();
    } else {
      map.dragging.disable();
      map.scrollWheelZoom.disable();
      map.touchZoom.disable();
      map.doubleClickZoom.disable();
    }
  }, [isActive, map]);

  return null;
}

const FieldMap = ({ onSelectField }: { onSelectField: (field: Field) => void }) => {
  const [fields, setFields] = useState<Field[]>([]);
  const [center] = useState<[number, number]>([41.0082, 28.9784]);
  const [isActive, setIsActive] = useState(false);

  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, "facilities"), (snapshot) => {
      const fieldList = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Field[];
      setFields(fieldList);
    });
    return () => unsubscribe();
  }, []);

  return (
    <div
      className="h-full w-full relative z-0"
      style={{ cursor: isActive ? "grab" : "pointer" }}
      onClick={() => { if (!isActive) setIsActive(true); }}
    >
      {/* Harita aktif değilken overlay — scroll geçmesini tamamen engeller */}
      {!isActive && (
        <div
          style={{
            position: "absolute",
            inset: 0,
            zIndex: 1000,
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
          onClick={() => setIsActive(true)}
        >
          <div style={{
            background: "rgba(255,255,255,0.82)",
            backdropFilter: "blur(8px)",
            WebkitBackdropFilter: "blur(8px)",
            border: "1px solid rgba(255,255,255,0.9)",
            borderRadius: 16,
            padding: "10px 20px",
            fontWeight: 700,
            fontSize: 14,
            color: "#1B5E20",
            boxShadow: "0 4px 16px rgba(0,0,0,0.1)",
            display: "flex",
            alignItems: "center",
            gap: 8,
            pointerEvents: "none",
          }}>
            <span style={{ fontSize: 18 }}>🗺️</span> Haritayla etkileşmek için dokun
          </div>
        </div>
      )}

      <MapContainer
        center={center}
        zoom={13}
        style={{ height: "100%", width: "100%" }}
        zoomControl={false}
        scrollWheelZoom={false}
        dragging={false}
        touchZoom={false}
        doubleClickZoom={false}
      >
        <MapActivator isActive={isActive} />
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {fields
          .filter(field => typeof field.latitude === "number" && typeof field.longitude === "number")
          .map((field) => (
            <Marker
              key={field.id}
              position={[field.latitude, field.longitude]}
              eventHandlers={{ click: () => onSelectField(field) }}
            >
              <Popup>
                <div className="p-2">
                  <h3 className="font-bold text-lg text-emerald-700">{field.name}</h3>
                  <div className="flex items-center gap-1 text-yellow-500 my-1">
                    <Star size={16} fill="currentColor" />
                    <span className="text-sm font-semibold">{field.averageRating || "Puanlanmamış"}</span>
                  </div>
                  <p className="text-sm text-gray-600 mb-2">{field.address}</p>
                  <button
                    onClick={() => onSelectField(field)}
                    className="w-full bg-emerald-600 text-white py-1 rounded text-sm hover:bg-emerald-700 transition"
                  >
                    Detayları Gör
                  </button>
                </div>
              </Popup>
            </Marker>
          ))}
      </MapContainer>
    </div>
  );
};

export default FieldMap;

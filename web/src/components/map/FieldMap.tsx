"use client";

import React, { useEffect, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import L from "leaflet";
import { db } from "@/lib/firebase";
import { collection, onSnapshot } from "firebase/firestore";
import { Star, Phone, Info } from "lucide-react";

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
  location: {
    lat: number;
    lng: number;
  };
  address: string;
  phone: string;
  rating: number;
  features: string[];
}

const FieldMap = ({ onSelectField }: { onSelectField: (field: Field) => void }) => {
  const [fields, setFields] = useState<Field[]>([]);
  const [center, setCenter] = useState<[number, number]>([41.0082, 28.9784]); // Default to Istanbul

  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, "football_fields"), (snapshot) => {
      const fieldList = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Field[];
      setFields(fieldList);
    });

    return () => unsubscribe();
  }, []);

  return (
    <div className="h-full w-full relative z-0">
      <MapContainer
        center={center}
        zoom={13}
        style={{ height: "100%", width: "100%" }}
        zoomControl={false}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        
        {fields.map((field) => (
          <Marker 
            key={field.id} 
            position={[field.location.lat, field.location.lng]}
            eventHandlers={{
              click: () => onSelectField(field),
            }}
          >
            <Popup>
              <div className="p-2">
                <h3 className="font-bold text-lg text-emerald-700">{field.name}</h3>
                <div className="flex items-center gap-1 text-yellow-500 my-1">
                  <Star size={16} fill="currentColor" />
                  <span className="text-sm font-semibold">{field.rating || "Puanlanmamış"}</span>
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

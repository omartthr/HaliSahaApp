"use client";

import React from "react";
import { Star, MapPin, Phone, Info, Clock, CheckCircle, XCircle } from "lucide-react";
import Link from "next/link";

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

const FieldDetailsPanel = ({ field, onClose }: { field: Field | null, onClose: () => void }) => {
  if (!field) return null;

  return (
    <div className="absolute top-4 left-4 z-40 w-80 bg-white shadow-2xl rounded-2xl overflow-hidden border border-gray-100 flex flex-col max-h-[calc(100vh-8rem)]">
      {/* Header Image Placeholder */}
      <div className="h-40 bg-emerald-700 relative flex items-center justify-center">
        <span className="text-white font-bold opacity-30 text-4xl">⚽</span>
        <button 
          onClick={onClose}
          className="absolute top-2 right-2 bg-black/20 hover:bg-black/40 text-white rounded-full p-1 transition"
        >
          <XCircle size={20} />
        </button>
      </div>

      <div className="p-5 flex-1 overflow-y-auto">
        <h2 className="text-2xl font-bold text-gray-900 mb-1">{field.name}</h2>
        <div className="flex items-center gap-1 text-yellow-500 mb-4">
          <Star size={18} fill="currentColor" />
          <span className="font-bold">{field.rating || "Puanlanmamış"}</span>
          <span className="text-gray-400 text-sm ml-1 font-normal">(12 Değerlendirme)</span>
        </div>

        <div className="space-y-4 text-sm text-gray-600">
          <div className="flex items-start gap-3">
            <MapPin className="text-emerald-600 shrink-0" size={18} />
            <p>{field.address}</p>
          </div>
          <div className="flex items-center gap-3">
            <Phone className="text-emerald-600 shrink-0" size={18} />
            <p>{field.phone}</p>
          </div>
        </div>

        <div className="mt-6">
          <h3 className="font-bold text-gray-900 mb-3 flex items-center gap-2">
            <Info size={18} className="text-emerald-600" /> Saha Özellikleri
          </h3>
          <div className="grid grid-cols-2 gap-2">
            {field.features?.map((feature, idx) => (
              <div key={idx} className="flex items-center gap-2 text-xs bg-emerald-50 text-emerald-700 px-2 py-1.5 rounded-lg border border-emerald-100">
                <CheckCircle size={14} /> {feature}
              </div>
            ))}
          </div>
        </div>

        {/* Empty State for Features */}
        {(!field.features || field.features.length === 0) && (
          <p className="text-xs text-gray-400 italic">Bu saha için özellik bilgisi girilmemiş.</p>
        )}
      </div>

      <div className="p-4 bg-gray-50 border-t border-gray-100">
        <Link
          href={`/booking/${field.id}`}
          className="w-full bg-emerald-600 text-white py-3 rounded-xl font-bold hover:bg-emerald-700 transition flex items-center justify-center gap-2 shadow-lg"
        >
          <Clock size={20} /> Boş Saatleri Gör
        </Link>
      </div>
    </div>
  );
};

export default FieldDetailsPanel;

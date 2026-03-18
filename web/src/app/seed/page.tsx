"use client";

import React from "react";
import { db } from "@/lib/firebase";
import { collection, addDoc } from "firebase/firestore";
import { toast } from "react-hot-toast";
import Navbar from "@/components/common/Navbar";

const SeedPage = () => {
  const seedData = async () => {
    const fields = [
      {
        name: "Kadıköy Merkez Halı Saha",
        location: { lat: 40.991, lng: 29.025 },
        address: "Zühtüpaşa, Şükrü Saracoğlu Stadı Yanı, Kadıköy/İstanbul",
        phone: "0216 123 45 67",
        rating: 4.8,
        features: ["Soyunma Odası", "Otopark", "Kantin", "Duş"],
      },
      {
        name: "Beşiktaş Vadi Saha",
        location: { lat: 41.042, lng: 29.008 },
        address: "Vişnezade, Bayıldım Cd., Beşiktaş/İstanbul",
        phone: "0212 987 65 43",
        rating: 4.5,
        features: ["Lavabo", "Otopark", "Kantin", "Tribün"],
      },
      {
        name: "Üsküdar Sahil Halı Saha",
        location: { lat: 41.026, lng: 29.015 },
        address: "Mimar Sinan, Sahil Yolu, Üsküdar/İstanbul",
        phone: "0216 555 44 33",
        rating: 4.2,
        features: ["Soyunma Odası", "Lavabo", "Kantin"],
      },
    ];

    try {
      for (const field of fields) {
        await addDoc(collection(db, "football_fields"), field);
      }
      toast.success("Veriler başarıyla eklendi!");
    } catch (error) {
      toast.error("Hata oluştu: " + error);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      <Navbar />
      <div className="flex-1 flex items-center justify-center">
        <div className="bg-white p-10 rounded-2xl shadow-xl text-center">
          <h1 className="text-2xl font-bold mb-6">Veritabanı Hazırlama</h1>
          <p className="text-gray-600 mb-8">
            Haritada görünecek örnek halı saha verilerini eklemek için butona basın.
          </p>
          <button
            onClick={seedData}
            className="bg-emerald-600 text-white px-8 py-3 rounded-lg font-bold hover:bg-emerald-700 transition"
          >
            Örnek Verileri Yükle
          </button>
        </div>
      </div>
    </div>
  );
};

export default SeedPage;

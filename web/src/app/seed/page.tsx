"use client";

import React from "react";
import { db } from "@/database/firebase";
import { collection, addDoc } from "firebase/firestore";
import { toast } from "react-hot-toast";
import Navbar from "@/frontend/components/common/Navbar";

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
        await addDoc(collection(db, "facilities"), field);
      }
      toast.success("Halı sahalar başarıyla eklendi!");
    } catch (error) {
      toast.error("Hata oluştu: " + error);
    }
  };

  const seedMatchPosts = async () => {
    const dummyPosts = [
      {
        creatorId: "user1",
        creatorName: "Ahmet Yılmaz",
        bookingId: "booking1",
        facilityId: "field1",
        facilityName: "Kadıköy Merkez Halı Saha",
        facilityAddress: "Kadıköy/İstanbul",
        pitchName: "Saha 1",
        matchDate: "2026-06-05",
        startHour: 20,
        endHour: 21,
        title: "Eksik 2 Defans Aranıyor",
        neededPlayers: 2,
        currentPlayers: 12,
        maxPlayers: 14,
        preferredPositions: ["Defans", "Kaleci"],
        skillLevel: "intermediate",
        applicantIds: [],
        acceptedIds: [],
        rejectedIds: [],
        status: "active",
      },
      {
        creatorId: "user2",
        creatorName: "Mehmet Kaya",
        bookingId: "booking2",
        facilityId: "field2",
        facilityName: "Beşiktaş Vadi Saha",
        facilityAddress: "Beşiktaş/İstanbul",
        pitchName: "Saha 2",
        matchDate: "2026-06-06",
        startHour: 21,
        endHour: 22,
        title: "Orta Saha Lazım",
        neededPlayers: 1,
        currentPlayers: 13,
        maxPlayers: 14,
        preferredPositions: ["Orta Saha"],
        skillLevel: "advanced",
        applicantIds: [],
        acceptedIds: [],
        rejectedIds: [],
        status: "active",
      }
    ];

    try {
      for (const post of dummyPosts) {
        await addDoc(collection(db, "match_posts"), post);
      }
      toast.success("Maç ilanları başarıyla eklendi!");
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
          <div className="flex flex-col gap-4">
            <button
              onClick={seedData}
              className="bg-emerald-600 text-white px-8 py-3 rounded-lg font-bold hover:bg-emerald-700 transition"
            >
              Halı Sahaları Yükle
            </button>
            <button
              onClick={seedMatchPosts}
              className="bg-[#2E7D32] text-white px-8 py-3 rounded-lg font-bold hover:bg-[#1B5E20] transition"
            >
              Örnek Maç İlanları Yükle
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SeedPage;

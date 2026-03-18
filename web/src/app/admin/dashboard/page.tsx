"use client";

import React, { useState, useEffect } from "react";
import { db, auth } from "@/lib/firebase";
import { collection, query, where, onSnapshot, updateDoc, doc, getDoc } from "firebase/firestore";
import { useAuth } from "@/context/AuthContext";
import Navbar from "@/components/common/Navbar";
import { toast } from "react-hot-toast";
import { CheckCircle, XCircle, Clock, MapPin, Settings } from "lucide-react";

const AdminDashboard = () => {
  const { user, userData } = useAuth();
  const [reservations, setReservations] = useState<any[]>([]);
  const [field, setField] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) return;

    // Fetch the admin's field
    // Note: In a real app, an admin might have multiple fields or their ID is linked to a field
    const fetchField = async () => {
      // For demo, we assume the admin's business name matches a field or they have a fieldId
      // Let's assume there's a mapping in field.adminId or similar
      // For now, let's just fetch ALL to show functionality
      const q = query(collection(db, "football_fields"));
      const unsubscribe = onSnapshot(q, (snapshot) => {
        const fieldData = snapshot.docs[0]; // Just take the first one for demo
        if (fieldData) {
          setField({ id: fieldData.id, ...fieldData.data() });
        }
      });
      return unsubscribe;
    };

    fetchField();

    // Fetch reservations for this admin's fields
    const resQuery = query(collection(db, "reservations"));
    const unsubscribeRes = onSnapshot(resQuery, (snapshot) => {
      const resList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setReservations(resList);
      setLoading(false);
    });

    return () => {
      unsubscribeRes();
    };
  }, [user]);

  const handleStatusUpdate = async (resId: string, newStatus: string) => {
    try {
      await updateDoc(doc(db, "reservations", resId), {
        status: newStatus
      });
      toast.success("Durum güncellendi.");
    } catch (error) {
      toast.error("Hata: " + error);
    }
  };

  if (loading) return <div className="p-20 text-center font-bold">Yükleniyor...</div>;

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      <Navbar />
      <div className="max-w-7xl mx-auto w-full p-4 lg:p-8">
        <header className="flex justify-between items-end mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 leading-tight">İşletme Yönetim Paneli</h1>
            <p className="text-gray-500 mt-1">{field?.name || "Yükleniyor..."}</p>
          </div>
          <button className="flex items-center gap-2 bg-white border border-gray-200 px-4 py-2 rounded-xl text-sm font-bold text-gray-700 hover:bg-gray-50 transition drop-shadow-sm">
            <Settings size={18} /> Saha Bilgilerini Düzenle
          </button>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Reservation List */}
          <div className="lg:col-span-2 space-y-6">
            <h2 className="text-xl font-bold text-gray-800 flex items-center gap-2">
              <Clock size={22} className="text-emerald-600" /> Bekleyen Randevular
            </h2>
            
            <div className="space-y-4">
              {reservations.length === 0 && (
                <div className="bg-white p-12 rounded-2xl text-center text-gray-400 border-2 border-dashed border-gray-100 italic">
                  Henüz bir randevu talebi bulunmuyor.
                </div>
              )}
              {reservations.map((res) => (
                <div key={res.id} className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex flex-col md:flex-row md:items-center justify-between gap-4">
                  <div>
                    <div className="flex items-center gap-3 mb-2">
                       <span className="font-bold text-lg text-gray-900">{res.userName}</span>
                       <span className={`px-3 py-1 rounded-full text-xs font-bold uppercase ${
                         res.status === "pending_payment" ? "bg-amber-100 text-amber-700" : 
                         res.status === "approved" ? "bg-emerald-100 text-emerald-700" : "bg-gray-100 text-gray-600"
                       }`}>
                         {res.status === "pending_payment" ? "Kapora Bekliyor" : 
                          res.status === "approved" ? "Onaylandı" : res.status}
                       </span>
                    </div>
                    <div className="flex flex-wrap gap-4 text-sm text-gray-500 font-medium">
                      <span className="flex items-center gap-1"><Clock size={16} /> {res.date} | {res.timeSlot}</span>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    {res.status === "pending_payment" && (
                      <>
                        <button 
                          onClick={() => handleStatusUpdate(res.id, "approved")}
                          className="bg-emerald-600 text-white px-4 py-2 rounded-xl text-sm font-bold hover:bg-emerald-700 transition flex items-center gap-2"
                        >
                          <CheckCircle size={18} /> Ödeme Alındı & Onayla
                        </button>
                        <button 
                          onClick={() => handleStatusUpdate(res.id, "cancelled")}
                          className="bg-white border border-red-200 text-red-600 px-4 py-2 rounded-xl text-sm font-bold hover:bg-red-50 transition flex items-center gap-2"
                        >
                          <XCircle size={18} /> İptal Et
                        </button>
                      </>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Stats / Quick Info */}
          <div className="lg:col-span-1 space-y-6">
            <div className="bg-emerald-600 rounded-3xl p-8 text-white shadow-xl shadow-emerald-100">
              <h3 className="text-lg font-bold opacity-80 mb-2 font-mono uppercase tracking-widest text-emerald-100">Toplam Kazanç</h3>
              <p className="text-5xl font-extrabold mb-8 tracking-tighter">₺2.400,00</p>
              <div className="flex justify-between items-end">
                <p className="text-sm opacity-90 leading-6 border-l-2 border-emerald-400 pl-4 font-medium">Bu hafta <br/>12 tamamlanmış randevu</p>
                <div className="bg-emerald-500 p-3 rounded-2xl">⚡</div>
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
                <MapPin size={18} className="text-emerald-600" /> Saha Konumu
              </h3>
              <p className="text-sm text-gray-500 leading-relaxed font-medium">
                {field?.address}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminDashboard;

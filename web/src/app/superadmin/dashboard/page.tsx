"use client";

import React, { useState, useEffect } from "react";
import { db } from "@/lib/firebase";
import { collection, query, where, onSnapshot, updateDoc, doc } from "firebase/firestore";
import Navbar from "@/components/common/Navbar";
import { toast } from "react-hot-toast";
import { ShieldCheck, UserCheck, UserX, AlertCircle, Building } from "lucide-react";

const SuperAdminDashboard = () => {
  const [pendingAdmins, setPendingAdmins] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(
      collection(db, "admins"),
      where("status", "==", "pending")
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setPendingAdmins(list);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const approveAdmin = async (adminId: string) => {
    try {
      await updateDoc(doc(db, "admins", adminId), {
        status: "approved"
      });
      toast.success("Yönetici onaylandı.");
    } catch (error) {
      toast.error("Hata: " + error);
    }
  };

  const rejectAdmin = async (adminId: string) => {
    try {
      await updateDoc(doc(db, "admins", adminId), {
        status: "rejected"
      });
      toast.success("Yönetici reddedildi.");
    } catch (error) {
      toast.error("Hata: " + error);
    }
  };

  if (loading) return <div className="p-20 text-center font-bold">Yükleniyor...</div>;

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      <Navbar />
      <div className="max-w-6xl mx-auto w-full p-4 lg:p-12">
        <header className="mb-12">
          <div className="flex items-center gap-4 mb-2">
            <div className="bg-emerald-600 p-3 rounded-2xl text-white shadow-lg shadow-emerald-200">
               <ShieldCheck size={32} />
            </div>
            <h1 className="text-4xl font-black text-gray-900 tracking-tighter uppercase italic">Süper Panel</h1>
          </div>
          <p className="text-gray-500 font-medium">Platforma yeni katılan işletmelerin onay süreci.</p>
        </header>

        <div className="space-y-6">
          <h2 className="text-xl font-bold text-gray-800 flex items-center gap-2">
            <AlertCircle size={22} className="text-amber-500" /> Onay Bekleyen İşletmeler ({pendingAdmins.length})
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {pendingAdmins.length === 0 && (
              <div className="col-span-full bg-white p-16 rounded-3xl text-center text-gray-400 border-4 border-dashed border-gray-100 italic">
                Şu an onay bekleyen herhangi bir işletme bulunmuyor.
              </div>
            )}
            {pendingAdmins.map((admin) => (
              <div key={admin.id} className="bg-white rounded-3xl p-8 border border-gray-100 shadow-sm hover:shadow-xl transition-all duration-300 group">
                <div className="flex items-center gap-4 mb-6">
                   <div className="bg-gray-100 p-4 rounded-2xl text-gray-400 group-hover:bg-emerald-100 group-hover:text-emerald-600 transition-colors">
                      <Building size={24} />
                   </div>
                   <div>
                     <h3 className="text-2xl font-bold text-gray-900 leading-tight">{admin.businessName}</h3>
                     <p className="text-xs text-gray-400 font-bold uppercase tracking-widest mt-1">Vergi No: {admin.taxNumber}</p>
                   </div>
                </div>

                <div className="space-y-3 mb-8">
                   <div className="flex justify-between text-sm">
                      <span className="text-gray-400 font-medium">Sahip:</span>
                      <span className="text-gray-900 font-bold italic underline">{admin.email}</span>
                   </div>
                   <div className="flex justify-between text-sm">
                      <span className="text-gray-400 font-medium">Telefon:</span>
                      <span className="text-gray-900 font-bold">{admin.phone}</span>
                   </div>
                </div>

                <div className="flex gap-3">
                  <button 
                    onClick={() => approveAdmin(admin.id)}
                    className="flex-1 bg-emerald-600 text-white py-4 rounded-2xl font-black hover:bg-emerald-700 transition flex items-center justify-center gap-2 shadow-lg shadow-emerald-200 uppercase tracking-tighter"
                  >
                    <UserCheck size={20} /> Onayla
                  </button>
                  <button 
                    onClick={() => rejectAdmin(admin.id)}
                    className="flex-1 bg-red-50 text-red-600 py-4 rounded-2xl font-black hover:bg-red-100 transition flex items-center justify-center gap-2 uppercase tracking-tighter"
                  >
                    <UserX size={20} /> Reddet
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default SuperAdminDashboard;

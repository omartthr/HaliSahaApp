"use client";

import React, { useState, useEffect } from "react";
import { db, auth } from "@/lib/firebase";
import { collection, query, onSnapshot, addDoc, serverTimestamp, doc, getDoc } from "firebase/firestore";
import { useAuth } from "@/context/AuthContext";
import Navbar from "@/components/common/Navbar";
import { toast } from "react-hot-toast";
import { Users, Plus, MessageCircle, ChevronRight, UserPlus } from "lucide-react";
import Link from "next/link";

const GroupsPage = () => {
  const { user } = useAuth();
  const [groups, setGroups] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newGroupName, setNewGroupName] = useState("");

  useEffect(() => {
    const q = query(collection(db, "groups"));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const groupList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setGroups(groupList);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const createGroup = async () => {
    if (!user) return toast.error("Grup oluşturmak için giriş yapmalısınız.");
    if (!newGroupName) return toast.error("Grup ismi gerekli.");

    try {
      await addDoc(collection(db, "groups"), {
        name: newGroupName,
        createdBy: user.uid,
        creatorName: user.displayName || "Kullanıcı",
        members: [user.uid],
        createdAt: serverTimestamp(),
      });
      setNewGroupName("");
      setShowCreateModal(false);
      toast.success("Grup oluşturuldu!");
    } catch (error) {
      toast.error("Hata: " + error);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      <Navbar />
      <div className="max-w-5xl mx-auto w-full p-4 lg:p-8">
        <header className="flex justify-between items-center mb-10">
          <div>
            <h1 className="text-4xl font-extrabold text-gray-900 tracking-tight">Ekipler & Gruplar</h1>
            <p className="text-gray-500 mt-2 font-medium">Arkadaşlarınla maç organize et veya yeni ekiplere katıl.</p>
          </div>
          <button 
            onClick={() => setShowCreateModal(true)}
            className="bg-emerald-600 text-white px-6 py-3 rounded-2xl font-bold hover:bg-emerald-700 transition flex items-center gap-2 shadow-xl shadow-emerald-100"
          >
            <Plus size={20} /> Yeni Grup Kur
          </button>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {groups.length === 0 && !loading && (
            <div className="col-span-full py-20 text-center bg-white rounded-3xl border-2 border-dashed border-gray-100 italic text-gray-400">
              Henüz bir grup bulunmuyor. İlk grubu sen kur!
            </div>
          )}
          {groups.map((group) => (
            <div key={group.id} className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
              <div className="flex justify-between items-start mb-6">
                <div className="bg-emerald-100 p-4 rounded-2xl text-emerald-600 group-hover:bg-emerald-600 group-hover:text-white transition-colors duration-300">
                  <Users size={28} />
                </div>
                <span className="text-xs font-bold text-gray-400 uppercase tracking-widest">{group.members?.length || 1} Üye</span>
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-2 truncate">{group.name}</h3>
              <p className="text-gray-500 text-sm mb-8 line-clamp-1 font-medium italic">Kurucu: {group.creatorName}</p>
              
              <div className="flex gap-2">
                <Link
                  href={`/groups/${group.id}`}
                  className="flex-1 bg-gray-900 text-white py-3 rounded-xl font-bold text-center hover:bg-black transition flex items-center justify-center gap-2"
                >
                  <MessageCircle size={18} /> Sohbet
                </Link>
                <button className="bg-gray-100 text-gray-600 p-3 rounded-xl hover:bg-emerald-50 hover:text-emerald-600 transition">
                  <UserPlus size={20} />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Create Group Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl shadow-2xl w-full max-w-sm p-8 scale-in">
            <h2 className="text-2xl font-bold text-gray-900 mb-6 tracking-tight">Ekibini Kur</h2>
            <input
              type="text"
              placeholder="Grup İsmi (örn: Mahalle Muhtarları)"
              className="w-full px-5 py-4 rounded-2xl border border-gray-200 mb-6 focus:ring-4 focus:ring-emerald-500/10 focus:border-emerald-500 outline-none transition font-medium"
              value={newGroupName}
              onChange={(e) => setNewGroupName(e.target.value)}
            />
            <div className="flex gap-3">
              <button 
                onClick={() => setShowCreateModal(false)}
                className="flex-1 px-6 py-4 rounded-2xl font-bold text-gray-500 hover:bg-gray-100 transition"
              >
                Vazgeç
              </button>
              <button 
                onClick={createGroup}
                className="flex-1 bg-emerald-600 text-white px-6 py-4 rounded-2xl font-bold hover:bg-emerald-700 transition shadow-lg shadow-emerald-600/20"
              >
                Oluştur
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default GroupsPage;

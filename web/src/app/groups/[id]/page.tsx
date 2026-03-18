"use client";

import React, { useState, useEffect, useRef } from "react";
import { useParams, useRouter } from "next/navigation";
import { db, auth } from "@/lib/firebase";
import { collection, query, onSnapshot, addDoc, serverTimestamp, doc, getDoc, orderBy, limit } from "firebase/firestore";
import { useAuth } from "@/context/AuthContext";
import Navbar from "@/components/common/Navbar";
import { toast } from "react-hot-toast";
import { Send, ChevronLeft, Users, Shield } from "lucide-react";
import { format } from "date-fns";

const ChatPage = () => {
  const { id } = useParams();
  const { user } = useAuth();
  const [group, setGroup] = useState<any>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [newMessage, setNewMessage] = useState("");
  const [loading, setLoading] = useState(true);
  const router = useRouter();
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const fetchGroup = async () => {
      const groupDoc = await getDoc(doc(db, "groups", id as string));
      if (groupDoc.exists()) {
        setGroup({ id: groupDoc.id, ...groupDoc.data() });
      }
      setLoading(false);
    };

    fetchGroup();

    const q = query(
      collection(db, "groups", id as string, "messages"),
      orderBy("createdAt", "asc"),
      limit(100)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const msgList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setMessages(msgList);
      // Auto scroll to bottom
      messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    });

    return () => unsubscribe();
  }, [id]);

  const sendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || !newMessage.trim()) return;

    try {
      await addDoc(collection(db, "groups", id as string, "messages"), {
        text: newMessage,
        senderId: user.uid,
        senderName: user.displayName || "Kullanıcı",
        createdAt: serverTimestamp(),
      });
      setNewMessage("");
    } catch (error) {
      toast.error("Mesaj gönderilemedi.");
    }
  };

  if (loading) return <div className="p-20 text-center font-bold">Sohbet Yükleniyor...</div>;
  if (!group) return <div className="p-20 text-center font-bold">Grup bulunamadı.</div>;

  return (
    <div className="h-screen flex flex-col bg-gray-50 overflow-hidden">
      <Navbar />

      {/* Chat Header */}
      <div className="bg-white border-b border-gray-100 p-4 shadow-sm flex items-center justify-between z-10">
        <div className="flex items-center gap-4">
          <button onClick={() => router.back()} className="p-2 hover:bg-gray-100 rounded-xl transition text-gray-500">
            <ChevronLeft size={24} />
          </button>
          <div className="flex items-center gap-3">
             <div className="bg-emerald-100 p-3 rounded-2xl text-emerald-600">
                <Users size={20} />
             </div>
             <div>
               <h2 className="font-bold text-gray-900 leading-tight">{group.name}</h2>
               <p className="text-xs text-emerald-600 font-bold flex items-center gap-1 uppercase tracking-wider">
                 <Shield size={12} fill="currentColor" /> {group.creatorName} • Kurucu
               </p>
             </div>
          </div>
        </div>
      </div>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-[url('https://www.transparenttextures.com/patterns/asfalt-light.png')]">
        {messages.map((msg) => {
          const isOwn = msg.senderId === user?.uid;
          return (
            <div key={msg.id} className={`flex ${isOwn ? "justify-end" : "justify-start"}`}>
              <div className={`max-w-[75%] rounded-3xl px-6 py-4 shadow-sm ${
                isOwn ? "bg-emerald-600 text-white" : "bg-white text-gray-800"
              }`}>
                {!isOwn && <p className="text-[10px] font-bold uppercase opacity-50 mb-1">{msg.senderName}</p>}
                <p className="text-[15px] font-medium leading-relaxed">{msg.text}</p>
                <p className={`text-[10px] mt-2 text-right opacity-40 font-bold`}>
                  {msg.createdAt?.toDate ? format(msg.createdAt.toDate(), "HH:mm") : "..."}
                </p>
              </div>
            </div>
          );
        })}
        <div ref={messagesEndRef} />
      </div>

      {/* Message Input */}
      <div className="p-6 bg-white border-t border-gray-100 shadow-[0_-10px_20px_-15px_rgba(0,0,0,0.1)]">
        <form onSubmit={sendMessage} className="max-w-4xl mx-auto flex gap-4">
          <input
            type="text"
            placeholder="Mesajınızı yazın..."
            className="flex-1 px-6 py-4 rounded-2xl border border-gray-200 focus:ring-4 focus:ring-emerald-500/10 focus:border-emerald-500 outline-none transition font-medium"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
          />
          <button 
            type="submit"
            className="bg-emerald-600 text-white p-4 rounded-2xl hover:bg-emerald-700 transition shadow-lg shadow-emerald-200 hover:scale-110 active:scale-95 duration-200"
          >
            <Send size={24} />
          </button>
        </form>
      </div>
    </div>
  );
};

export default ChatPage;

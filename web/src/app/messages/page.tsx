"use client";

import { useEffect, useState, useRef } from "react";
import Navbar from "@/frontend/components/common/Navbar";
import { useAuth } from "@/frontend/context/AuthContext";
import { 
  getMyGroupsRealtime, 
  getGroupMessagesRealtime, 
  sendGroupMessage, 
  GroupRecord, 
  GroupMessageRecord 
} from "@/backend/services/groupService";
import { Send, MessageCircle } from "lucide-react";
import { toast } from "react-hot-toast";

export default function MessagesPage() {
  const { user } = useAuth();
  const [chats, setChats] = useState<GroupRecord[]>([]);
  const [selectedChat, setSelectedChat] = useState<GroupRecord | null>(null);
  const [messages, setMessages] = useState<GroupMessageRecord[]>([]);
  const [inputText, setInputText] = useState("");
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!user) return;
    const unsub = getMyGroupsRealtime(user.uid, (data) => {
      setChats(data);
    });
    return () => unsub();
  }, [user]);

  useEffect(() => {
    if (!selectedChat) return;
    const unsub = getGroupMessagesRealtime(selectedChat.id, (data) => {
      setMessages(data);
      setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: "smooth" }), 100);
    });
    return () => unsub();
  }, [selectedChat]);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim() || !user || !selectedChat) return;

    try {
      const text = inputText;
      setInputText("");
      await sendGroupMessage(selectedChat.id, {
        content: text,
        senderId: user.uid,
        senderName: user.displayName || "Kullanıcı"
      });
    } catch (error) {
      toast.error("Mesaj gönderilemedi.");
    }
  };

  const getChatName = (chat: GroupRecord) => {
    if (chat.isDirectMessage) {
      return chat.name?.toString().replace(user?.displayName || "Kullanıcı", "").replace("&", "").trim() || "Kullanıcı";
    }
    return chat.name || "Grup Sohbeti";
  };

  return (
    <div className="page-wrapper min-h-screen bg-[#F6F8F6] flex flex-col">
      <Navbar />

      <div className="content-container flex-1 flex flex-col pt-6 pb-6 h-[calc(100vh-80px)]">
        <div className="bg-white rounded-3xl shadow-sm border border-gray-100 flex overflow-hidden flex-1">
          
          {/* Sol Panel: Sohbet Listesi */}
          <div className="w-1/3 border-r border-gray-100 flex flex-col">
            <div className="p-6 border-b border-gray-100">
              <h2 className="text-xl font-black text-gray-900">Sohbetler</h2>
            </div>
            <div className="overflow-y-auto flex-1 p-3">
              {chats.length === 0 ? (
                <div className="text-center py-10 text-gray-400">
                  <MessageCircle size={32} className="mx-auto mb-2 opacity-50" />
                  <p className="text-sm">Henüz mesajınız yok.</p>
                </div>
              ) : (
                chats.map(chat => (
                  <button
                    key={chat.id}
                    onClick={() => setSelectedChat(chat)}
                    className={`w-full text-left p-4 rounded-2xl flex items-center gap-4 transition-colors mb-2 ${
                      selectedChat?.id === chat.id ? "bg-[#E8F5E9]" : "hover:bg-gray-50"
                    }`}
                  >
                    <div className="w-12 h-12 rounded-full bg-[#2E7D32] text-white flex items-center justify-center font-bold text-lg flex-shrink-0">
                      {getChatName(chat).substring(0, 2).toUpperCase()}
                    </div>
                    <div className="flex-1 overflow-hidden">
                      <h3 className={`font-bold truncate ${selectedChat?.id === chat.id ? "text-[#1B5E20]" : "text-gray-900"}`}>
                        {getChatName(chat)}
                      </h3>
                      {chat.lastMessage && (
                        <p className="text-sm text-gray-500 truncate">
                          {(chat.lastMessage as any).content || "Sohbet başladı"}
                        </p>
                      )}
                    </div>
                  </button>
                ))
              )}
            </div>
          </div>

          {/* Sağ Panel: Aktif Sohbet */}
          <div className="flex-1 flex flex-col bg-gray-50/50">
            {selectedChat ? (
              <>
                <div className="p-6 border-b border-gray-100 bg-white">
                  <h2 className="text-xl font-bold text-gray-900">{getChatName(selectedChat)}</h2>
                </div>
                
                <div className="flex-1 p-6 overflow-y-auto flex flex-col gap-4">
                  {messages.map(msg => {
                    const isMine = msg.senderId === user?.uid;
                    return (
                      <div key={msg.id} className={`flex ${isMine ? "justify-end" : "justify-start"}`}>
                        <div className={`max-w-[70%] rounded-2xl p-4 ${
                          isMine 
                            ? "bg-[#2E7D32] text-white rounded-tr-sm" 
                            : "bg-white border border-gray-100 text-gray-800 rounded-tl-sm shadow-sm"
                        }`}>
                          {!isMine && !selectedChat.isDirectMessage && (
                            <p className="text-xs font-bold mb-1 opacity-60">{msg.senderName}</p>
                          )}
                          <p className="leading-relaxed">{msg.content}</p>
                        </div>
                      </div>
                    );
                  })}
                  <div ref={messagesEndRef} />
                </div>

                <div className="p-4 bg-white border-t border-gray-100">
                  <form onSubmit={handleSend} className="flex gap-3">
                    <input
                      type="text"
                      value={inputText}
                      onChange={e => setInputText(e.target.value)}
                      placeholder="Bir mesaj yazın..."
                      className="flex-1 bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 outline-none focus:border-[#2E7D32] transition-colors"
                    />
                    <button 
                      type="submit"
                      disabled={!inputText.trim()}
                      className="bg-[#2E7D32] hover:bg-[#1B5E20] disabled:opacity-50 text-white rounded-xl px-5 flex items-center justify-center transition-colors"
                    >
                      <Send size={20} />
                    </button>
                  </form>
                </div>
              </>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center text-gray-400">
                <MessageCircle size={48} className="mb-4 opacity-50" />
                <h3 className="text-lg font-bold text-gray-600 mb-2">Sohbet Seçin</h3>
                <p>Mesajlaşmaya başlamak için soldaki menüden bir sohbet seçin.</p>
              </div>
            )}
          </div>

        </div>
      </div>
    </div>
  );
}

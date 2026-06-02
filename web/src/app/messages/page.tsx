"use client";

import { useEffect, useState, useRef } from "react";
import Navbar from "@/frontend/components/common/Navbar";
import { useAuth } from "@/frontend/context/AuthContext";
import {
  getMyGroupsRealtime,
  getGroupMessagesRealtime,
  sendGroupMessage,
  GroupRecord,
  GroupMessageRecord,
} from "@/backend/services/groupService";
import { Send, MessageCircle, Users, Hash, Search, ChevronLeft } from "lucide-react";
import { toast } from "react-hot-toast";

export default function MessagesPage() {
  const { user } = useAuth();
  const [chats, setChats] = useState<GroupRecord[]>([]);
  const [selectedChat, setSelectedChat] = useState<GroupRecord | null>(null);
  const [messages, setMessages] = useState<GroupMessageRecord[]>([]);
  const [inputText, setInputText] = useState("");
  const [search, setSearch] = useState("");
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!user) return;
    const unsub = getMyGroupsRealtime(user.uid, (data) => setChats(data));
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
        senderName: user.displayName || "Kullanıcı",
      });
    } catch {
      toast.error("Mesaj gönderilemedi.");
    }
  };

  const getChatName = (chat: GroupRecord) => {
    if (chat.isDirectMessage) {
      return (chat.name as string)
        ?.replace(user?.displayName || "Kullanıcı", "")
        .replace("&", "")
        .trim() || "Kullanıcı";
    }
    return (chat.name as string) || "Grup Sohbeti";
  };

  const filteredChats = chats.filter((c) =>
    getChatName(c).toLowerCase().includes(search.toLowerCase())
  );

  const formatTime = (ts: any) => {
    if (!ts?.toDate) return "";
    return (ts.toDate() as Date).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" });
  };

  return (
    <div className="page-wrapper">
      <Navbar />

      {/* ── Hero — aynı Maç Kur stili ── */}
      <div
        className="match-hero"
        style={{
          height: 280,
          background: "linear-gradient(180deg, #114B32 0%, #1A754E 100%)",
          position: "relative",
          zIndex: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <div style={{ position: "absolute", top: 80, left: 16 }}>
          <button
            onClick={() => window.history.back()}
            style={{
              display: "flex", alignItems: "center", justifyContent: "center",
              width: 40, height: 40, borderRadius: "50%",
              background: "rgba(0,0,0,0.3)", backdropFilter: "blur(8px)",
              border: "none", color: "white", cursor: "pointer",
            }}
          >
            <ChevronLeft size={20} />
          </button>
        </div>

        <div style={{ textAlign: "center", color: "white", zIndex: 1 }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 10, marginBottom: 6 }}>
            <MessageCircle size={26} />
            <h1 style={{ fontSize: 26, fontWeight: 800, margin: 0 }}>Mesajlar</h1>
          </div>
          <p style={{ fontSize: 13, opacity: 0.7, margin: 0 }}>Grup ve direkt sohbetleriniz</p>
        </div>

        {/* Wave — birebir Maç Kur ile aynı */}
        <div style={{ position: "absolute", bottom: -118, left: 0, width: "100%", lineHeight: 0, zIndex: 0, pointerEvents: "none" }}>
          <svg
            data-name="Layer 1"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 1200 120"
            preserveAspectRatio="none"
            style={{ display: "block", width: "calc(100% + 1.3px)", height: 120, overflow: "visible" }}
          >
            <defs>
              <filter id="msg-wave-soft-shadow" x="-8%" y="-8%" width="116%" height="180%">
                <feGaussianBlur stdDeviation="7" />
              </filter>
            </defs>
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="rgba(0,0,0,0.22)"
              transform="translate(0, 14)"
              filter="url(#msg-wave-soft-shadow)"
            />
            <path
              d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"
              fill="#1A754E"
            />
          </svg>
        </div>
      </div>

      {/* ── Messenger Panel ── */}
      <div
        className="content-container match-main-content"
        style={{
          position: "relative",
          zIndex: 2,
          marginTop: -220,
          paddingTop: 24,
          paddingBottom: 60,
          maxWidth: 1200,
          width: "95%",
        }}
      >
        <div
          className="auth-dynamo-glass match-dynamo-card match-card"
          style={{
            padding: 0,
            borderRadius: 24,
            overflow: "hidden",
            display: "flex",
            height: "calc(100vh - 160px)",
            minHeight: 540,
          }}
        >
          {/* ── Sidebar ── */}
          <aside
            style={{
              width: 300,
              minWidth: 260,
              display: "flex",
              flexDirection: "column",
              borderRight: "1px solid rgba(0,0,0,0.07)",
              background: "rgba(255,255,255,0.72)",
            }}
          >
            <div style={{ padding: "20px 18px 14px", borderBottom: "1px solid rgba(0,0,0,0.06)" }}>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
                <h2 style={{ fontSize: 16, fontWeight: 800, color: "#111827", margin: 0 }}>Sohbetler</h2>
                <span style={{ fontSize: 11, fontWeight: 700, color: "#16a34a", background: "#f0fdf4", border: "1px solid #bbf7d0", padding: "2px 8px", borderRadius: 20 }}>
                  {chats.length}
                </span>
              </div>
              <div style={{ position: "relative" }}>
                <Search size={14} style={{ position: "absolute", left: 10, top: "50%", transform: "translateY(-50%)", color: "#9ca3af", pointerEvents: "none" }} />
                <input
                  type="text"
                  placeholder="Ara..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  style={{
                    width: "100%", padding: "8px 12px 8px 30px",
                    borderRadius: 10, border: "1px solid rgba(0,0,0,0.08)",
                    background: "rgba(255,255,255,0.8)", fontSize: 13,
                    outline: "none", boxSizing: "border-box", color: "#111827",
                  }}
                />
              </div>
            </div>

            <div style={{ flex: 1, overflowY: "auto", padding: "8px" }}>
              {filteredChats.length === 0 ? (
                <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", height: 160, color: "#9ca3af", gap: 8 }}>
                  <MessageCircle size={28} style={{ opacity: 0.3 }} />
                  <p style={{ fontSize: 13, margin: 0 }}>{search ? "Sonuç yok" : "Sohbet bulunmuyor"}</p>
                </div>
              ) : (
                filteredChats.map((chat) => {
                  const name = getChatName(chat);
                  const isSelected = selectedChat?.id === chat.id;
                  const isDM = !!chat.isDirectMessage;

                  return (
                    <button
                      key={chat.id}
                      onClick={() => setSelectedChat(chat)}
                      style={{
                        width: "100%", display: "flex", alignItems: "center", gap: 12,
                        padding: "11px 12px", borderRadius: 14, border: "none",
                        background: isSelected ? "rgba(22,163,74,0.1)" : "transparent",
                        boxShadow: isSelected ? "inset 0 0 0 1.5px rgba(22,163,74,0.3)" : "none",
                        cursor: "pointer", textAlign: "left", marginBottom: 3, transition: "all 0.15s",
                      }}
                      onMouseEnter={(e) => { if (!isSelected) e.currentTarget.style.background = "rgba(0,0,0,0.04)"; }}
                      onMouseLeave={(e) => { if (!isSelected) e.currentTarget.style.background = "transparent"; }}
                    >
                      <div style={{
                        width: 44, height: 44, borderRadius: "50%", flexShrink: 0,
                        display: "flex", alignItems: "center", justifyContent: "center",
                        fontWeight: 800, fontSize: 14,
                        color: isSelected ? "#fff" : "#065f46",
                        background: isSelected ? "linear-gradient(135deg, #16a34a, #15803d)" : "linear-gradient(135deg, #bbf7d0, #86efac)",
                        transition: "all 0.15s",
                      }}>
                        {isDM ? name.substring(0, 2).toUpperCase() : <Hash size={17} />}
                      </div>

                      <div style={{ flex: 1, overflow: "hidden" }}>
                        <p style={{ fontSize: 13, fontWeight: 700, color: isSelected ? "#15803d" : "#111827", margin: 0, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                          {name}
                        </p>
                        <p style={{ fontSize: 11, color: "#9ca3af", margin: "2px 0 0", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                          {(chat.lastMessage as any)?.content || (isDM ? "Direkt mesaj" : "Grup sohbeti")}
                        </p>
                      </div>

                      {!isDM && <Users size={12} style={{ color: "#9ca3af", flexShrink: 0 }} />}
                    </button>
                  );
                })
              )}
            </div>
          </aside>

          {/* ── Chat Area ── */}
          <div style={{ flex: 1, display: "flex", flexDirection: "column", minWidth: 0 }}>
            {selectedChat ? (
              <>
                {/* Topbar */}
                <div style={{
                  padding: "0 20px", height: 62,
                  borderBottom: "1px solid rgba(0,0,0,0.07)",
                  display: "flex", alignItems: "center", gap: 12,
                  background: "rgba(255,255,255,0.8)", backdropFilter: "blur(8px)", flexShrink: 0,
                }}>
                  <div style={{ width: 38, height: 38, borderRadius: "50%", background: "linear-gradient(135deg, #16a34a, #15803d)", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 800, fontSize: 12, color: "white" }}>
                    {selectedChat.isDirectMessage ? getChatName(selectedChat).substring(0, 2).toUpperCase() : <Hash size={15} />}
                  </div>
                  <div>
                    <p style={{ fontSize: 14, fontWeight: 700, color: "#111827", margin: 0 }}>{getChatName(selectedChat)}</p>
                    <p style={{ fontSize: 11, color: "#9ca3af", margin: 0 }}>{selectedChat.isDirectMessage ? "Direkt mesaj" : "Grup sohbeti"}</p>
                  </div>
                </div>

                {/* Messages */}
                <div style={{
                  flex: 1, overflowY: "auto", padding: "20px 32px",
                  display: "flex", flexDirection: "column", gap: 4,
                  background: "#efeae2",
                  backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23000000' fill-opacity='0.025'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
                }}>
                  {messages.length === 0 && (
                    <div style={{ margin: "auto", background: "rgba(255,255,255,0.85)", borderRadius: 14, padding: "12px 20px", color: "#6b7280", fontSize: 13, boxShadow: "0 1px 4px rgba(0,0,0,0.1)" }}>
                      Henüz mesaj yok. İlk mesajı gönderin!
                    </div>
                  )}
                  {messages.map((msg, i) => {
                    const isMine = msg.senderId === user?.uid;
                    const showName = !isMine && !selectedChat.isDirectMessage &&
                      (i === 0 || messages[i - 1]?.senderId !== msg.senderId);
                    return (
                      <div key={msg.id} style={{ display: "flex", justifyContent: isMine ? "flex-end" : "flex-start", marginTop: showName ? 10 : 0 }}>
                        <div style={{ maxWidth: "62%", minWidth: 80 }}>
                          {showName && (
                            <p style={{ fontSize: 11, fontWeight: 700, color: "#16a34a", margin: "0 0 3px 12px" }}>
                              {msg.senderName}
                            </p>
                          )}
                          <div style={{
                            padding: "8px 12px 10px",
                            borderRadius: isMine ? "14px 14px 4px 14px" : "14px 14px 14px 4px",
                            background: isMine ? "#dcf8c6" : "#ffffff",
                            boxShadow: "0 1px 2px rgba(0,0,0,0.1)",
                          }}>
                            <p style={{ fontSize: 13.5, color: "#111827", margin: 0, lineHeight: 1.5, wordBreak: "break-word" }}>
                              {msg.content}
                            </p>
                            <p style={{ fontSize: 10, color: "#9ca3af", margin: "3px 0 0", textAlign: "right" }}>
                              {formatTime(msg.createdAt)}
                            </p>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                  <div ref={messagesEndRef} />
                </div>

                {/* Input */}
                <div style={{ padding: "10px 16px", background: "rgba(255,255,255,0.9)", borderTop: "1px solid rgba(0,0,0,0.07)", flexShrink: 0 }}>
                  <form onSubmit={handleSend} style={{ display: "flex", alignItems: "center", gap: 10, background: "#f3f4f6", borderRadius: 24, padding: "5px 5px 5px 18px", border: "1px solid rgba(0,0,0,0.07)" }}>
                    <input
                      type="text"
                      value={inputText}
                      onChange={(e) => setInputText(e.target.value)}
                      placeholder="Bir mesaj yazın..."
                      style={{ flex: 1, border: "none", outline: "none", fontSize: 13.5, color: "#111827", background: "transparent", padding: "6px 0" }}
                    />
                    <button
                      type="submit"
                      disabled={!inputText.trim()}
                      style={{
                        width: 40, height: 40, borderRadius: "50%", border: "none",
                        background: inputText.trim() ? "linear-gradient(135deg, #2E7D32, #1A754E)" : "#e5e7eb",
                        color: inputText.trim() ? "#fff" : "#9ca3af",
                        display: "flex", alignItems: "center", justifyContent: "center",
                        cursor: inputText.trim() ? "pointer" : "default",
                        transition: "all 0.2s", flexShrink: 0,
                        boxShadow: inputText.trim() ? "0 4px 10px rgba(46,125,50,0.35)" : "none",
                      }}
                    >
                      <Send size={16} />
                    </button>
                  </form>
                </div>
              </>
            ) : (
              <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", background: "rgba(249,250,251,0.6)", gap: 14 }}>
                <div style={{ width: 72, height: 72, borderRadius: "50%", background: "linear-gradient(135deg, #bbf7d0, #6ee7b7)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  <MessageCircle size={32} style={{ color: "#065f46" }} />
                </div>
                <div style={{ textAlign: "center" }}>
                  <h2 style={{ fontSize: 18, fontWeight: 800, color: "#111827", margin: "0 0 6px" }}>Sohbet Seçin</h2>
                  <p style={{ fontSize: 13, color: "#9ca3af", margin: 0 }}>Sol panelden bir sohbet seçerek başlayın.</p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

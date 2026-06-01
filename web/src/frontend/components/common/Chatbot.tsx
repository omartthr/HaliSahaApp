"use client";

import { useState, useRef, useEffect } from "react";
import { MessageCircle, X, Send, Bot, User, Loader2 } from "lucide-react";

type Message = {
  role: "user" | "assistant";
  text: string;
};

export default function Chatbot() {
  const [open, setOpen] = useState(false);
  const [messages, setMessages] = useState<Message[]>([
    {
      role: "assistant",
      text: "Merhaba! Ben ALO Bot 👋 Saha rezervasyonu, maç organizasyonu veya platform hakkında sorularını yanıtlamak için buradayım.",
    },
  ]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [hasUnread, setHasUnread] = useState(true);
  const bottomRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Yeni mesaj gelince aşağı kaydır
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, loading]);

  // Açıldığında input'a odaklan
  useEffect(() => {
    if (open) {
      setHasUnread(false);
      setTimeout(() => inputRef.current?.focus(), 100);
    }
  }, [open]);

  const sendMessage = async (directText?: string) => {
    const text = (directText ?? input).trim();
    if (!text || loading) return;

    const newUserMsg: Message = { role: "user", text };
    const updatedMessages = [...messages, newUserMsg];
    setMessages(updatedMessages);
    if (!directText) setInput("");
    setLoading(true);

    try {
      // Sistem mesajını hariç tut (sadece konuşma geçmişini gönder)
      const history = messages.map((m) => ({
        role: m.role === "user" ? "user" : "model",
        text: m.text,
      }));

      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: text, history }),
      });

      const data = await res.json();

      if (data.reply) {
        setMessages((prev) => [...prev, { role: "assistant", text: data.reply }]);
      } else {
        setMessages((prev) => [
          ...prev,
          { role: "assistant", text: "Üzgünüm, şu anda yanıt veremiyorum. Lütfen tekrar dene." },
        ]);
      }
    } catch {
      setMessages((prev) => [
        ...prev,
        { role: "assistant", text: "Bağlantı hatası oluştu. İnternet bağlantını kontrol et." },
      ]);
    } finally {
      setLoading(false);
    }
  };

  const handleKey = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <>
      {/* Floating Trigger Button */}
      <button
        onClick={() => setOpen((v) => !v)}
        aria-label="Chatbotu aç"
        style={{
          position: "fixed",
          bottom: 28,
          left: 28,
          width: 60,
          height: 60,
          borderRadius: "50%",
          background: "linear-gradient(135deg, #1A754E 0%, #2E7D32 100%)",
          border: "none",
          cursor: "pointer",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          boxShadow: "0 8px 32px rgba(46,125,50,0.38)",
          zIndex: 9998,
          transition: "transform 0.2s cubic-bezier(0.16,1,0.3,1), box-shadow 0.2s",
          transform: open ? "scale(0.9) rotate(10deg)" : "scale(1)",
        }}
        onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.transform = open ? "scale(0.9) rotate(10deg)" : "scale(1.08)"; }}
        onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.transform = open ? "scale(0.9) rotate(10deg)" : "scale(1)"; }}
      >
        {open ? (
          <X size={24} color="white" />
        ) : (
          <MessageCircle size={26} color="white" />
        )}
        {/* Unread badge */}
        {!open && hasUnread && (
          <span style={{
            position: "absolute",
            top: 6,
            right: 6,
            width: 12,
            height: 12,
            background: "#ef4444",
            borderRadius: "50%",
            border: "2px solid white",
          }} />
        )}
      </button>

      {/* Chat Window */}
      <div
        style={{
          position: "fixed",
          bottom: 100,
          left: 28,
          width: 370,
          maxWidth: "calc(100vw - 32px)",
          height: 520,
          maxHeight: "calc(100vh - 120px)",
          borderRadius: 24,
          background: "rgba(255,255,255,0.96)",
          backdropFilter: "blur(24px)",
          WebkitBackdropFilter: "blur(24px)",
          boxShadow: "0 24px 80px rgba(0,0,0,0.18), 0 0 0 1px rgba(255,255,255,0.8)",
          display: "flex",
          flexDirection: "column",
          overflow: "hidden",
          zIndex: 9997,
          // Smooth mount/unmount animation
          opacity: open ? 1 : 0,
          pointerEvents: open ? "all" : "none",
          transform: open ? "translateY(0) scale(1)" : "translateY(16px) scale(0.97)",
          transition: "opacity 0.25s cubic-bezier(0.16,1,0.3,1), transform 0.25s cubic-bezier(0.16,1,0.3,1)",
        }}
      >
        {/* Header */}
        <div style={{
          padding: "18px 20px 14px",
          background: "linear-gradient(135deg, #1A754E 0%, #2E7D32 100%)",
          display: "flex",
          alignItems: "center",
          gap: 12,
        }}>
          <div style={{
            width: 40,
            height: 40,
            borderRadius: "50%",
            background: "rgba(255,255,255,0.2)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexShrink: 0,
          }}>
            <Bot size={22} color="white" />
          </div>
          <div>
            <p style={{ color: "white", fontWeight: 700, fontSize: 15, margin: 0 }}>ALO Bot</p>
            <p style={{ color: "rgba(255,255,255,0.75)", fontSize: 12, margin: 0, display: "flex", alignItems: "center", gap: 4 }}>
              <span style={{ width: 7, height: 7, borderRadius: "50%", background: "#4ade80", display: "inline-block" }} />
              Çevrimiçi · Gemini 2.5 Flash
            </p>
          </div>
          <button
            onClick={() => setOpen(false)}
            style={{ marginLeft: "auto", background: "none", border: "none", cursor: "pointer", color: "rgba(255,255,255,0.7)", padding: 4, borderRadius: 8 }}
          >
            <X size={18} />
          </button>
        </div>

        {/* Messages */}
        <div style={{
          flex: 1,
          overflowY: "auto",
          padding: "16px 14px",
          display: "flex",
          flexDirection: "column",
          gap: 12,
        }}>
          {messages.map((msg, i) => (
            <div
              key={i}
              style={{
                display: "flex",
                justifyContent: msg.role === "user" ? "flex-end" : "flex-start",
                gap: 8,
                alignItems: "flex-end",
              }}
            >
              {/* Bot avatar */}
              {msg.role === "assistant" && (
                <div style={{
                  width: 28,
                  height: 28,
                  borderRadius: "50%",
                  background: "linear-gradient(135deg, #1A754E, #2E7D32)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  flexShrink: 0,
                }}>
                  <Bot size={14} color="white" />
                </div>
              )}
              <div style={{
                maxWidth: "78%",
                padding: "10px 14px",
                borderRadius: msg.role === "user" ? "18px 18px 4px 18px" : "18px 18px 18px 4px",
                background: msg.role === "user"
                  ? "linear-gradient(135deg, #1A754E, #2E7D32)"
                  : "rgba(243,244,246,0.95)",
                color: msg.role === "user" ? "white" : "#111827",
                fontSize: 14,
                lineHeight: 1.5,
                boxShadow: msg.role === "user"
                  ? "0 4px 14px rgba(46,125,50,0.2)"
                  : "0 2px 8px rgba(0,0,0,0.06)",
              }}>
                {msg.text}
              </div>
              {/* User avatar */}
              {msg.role === "user" && (
                <div style={{
                  width: 28,
                  height: 28,
                  borderRadius: "50%",
                  background: "#e5e7eb",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  flexShrink: 0,
                }}>
                  <User size={14} color="#6b7280" />
                </div>
              )}
            </div>
          ))}

          {/* Loading indicator */}
          {loading && (
            <div style={{ display: "flex", gap: 8, alignItems: "flex-end" }}>
              <div style={{
                width: 28, height: 28, borderRadius: "50%",
                background: "linear-gradient(135deg, #1A754E, #2E7D32)",
                display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
              }}>
                <Bot size={14} color="white" />
              </div>
              <div style={{
                padding: "12px 16px",
                borderRadius: "18px 18px 18px 4px",
                background: "rgba(243,244,246,0.95)",
                display: "flex",
                alignItems: "center",
                gap: 6,
              }}>
                <span style={{
                  display: "inline-flex",
                  gap: 3,
                  alignItems: "center",
                }}>
                  {[0, 0.15, 0.3].map((delay, i) => (
                    <span
                      key={i}
                      style={{
                        width: 7,
                        height: 7,
                        borderRadius: "50%",
                        background: "#9ca3af",
                        animation: "chatbotBounce 1s ease-in-out infinite",
                        animationDelay: `${delay}s`,
                      }}
                    />
                  ))}
                </span>
              </div>
            </div>
          )}

          <div ref={bottomRef} />
        </div>

        {/* Quick suggestions */}
        {messages.length === 1 && (
          <div style={{ padding: "0 14px 10px", display: "flex", gap: 6, flexWrap: "wrap" }}>
            {[
              "Nasıl rezervasyon yapılır?",
              "Maç nasıl kurulur?",
              "Kapora iadesi var mı?",
            ].map((q) => (
              <button
                key={q}
                onClick={() => sendMessage(q)}
                style={{
                  padding: "6px 12px",
                  borderRadius: 20,
                  border: "1px solid rgba(46,125,50,0.25)",
                  background: "rgba(232,245,233,0.7)",
                  color: "#2E7D32",
                  fontSize: 12,
                  fontWeight: 600,
                  cursor: "pointer",
                  transition: "all 0.15s",
                }}
              >
                {q}
              </button>
            ))}
          </div>
        )}

        {/* Input */}
        <div style={{
          padding: "12px 14px 14px",
          borderTop: "1px solid rgba(0,0,0,0.06)",
          display: "flex",
          gap: 8,
          alignItems: "center",
          background: "rgba(255,255,255,0.8)",
        }}>
          <input
            ref={inputRef}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKey}
            placeholder="Bir soru sor..."
            disabled={loading}
            style={{
              flex: 1,
              padding: "10px 14px",
              borderRadius: 16,
              border: "1.5px solid rgba(46,125,50,0.2)",
              background: "rgba(243,244,246,0.8)",
              fontSize: 14,
              outline: "none",
              color: "#111827",
              transition: "border-color 0.15s",
            }}
            onFocus={(e) => { e.target.style.borderColor = "#2E7D32"; }}
            onBlur={(e) => { e.target.style.borderColor = "rgba(46,125,50,0.2)"; }}
          />
          <button
            onClick={() => sendMessage()}
            disabled={loading || !input.trim()}
            style={{
              width: 40,
              height: 40,
              borderRadius: "50%",
              border: "none",
              background: input.trim() && !loading
                ? "linear-gradient(135deg, #1A754E, #2E7D32)"
                : "#e5e7eb",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              cursor: input.trim() && !loading ? "pointer" : "not-allowed",
              transition: "all 0.2s",
              flexShrink: 0,
            }}
          >
            {loading
              ? <Loader2 size={16} color="#9ca3af" style={{ animation: "spin 1s linear infinite" }} />
              : <Send size={16} color={input.trim() ? "white" : "#9ca3af"} />
            }
          </button>
        </div>
      </div>

      {/* Keyframe CSS */}
      <style>{`
        @keyframes chatbotBounce {
          0%, 60%, 100% { transform: translateY(0); opacity: 0.5; }
          30% { transform: translateY(-6px); opacity: 1; }
        }
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
      `}</style>
    </>
  );
}

"use client";

import { useState, useRef, useEffect } from "react";
import { MessageCircle, X, Send, Bot, User, Loader2, Sparkles } from "lucide-react";

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
          bottom: 32,
          right: 32, // Moved to right for typical standard or left as previous? The user had it on left in the image: "left: 28". Let's keep it left for consistency or right? Image shows left. I'll keep it left.
          left: 28,
          width: 64,
          height: 64,
          borderRadius: "50%",
          background: "linear-gradient(135deg, #10B981 0%, #047857 100%)",
          border: "none",
          cursor: "pointer",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          boxShadow: "0 12px 36px rgba(16, 185, 129, 0.4)",
          zIndex: 9998,
          transition: "all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)",
          transform: open ? "scale(0.8) rotate(-15deg)" : "scale(1) rotate(0deg)",
        }}
        onMouseEnter={(e) => {
          if (!open) e.currentTarget.style.transform = "scale(1.08) translateY(-4px)";
        }}
        onMouseLeave={(e) => {
          if (!open) e.currentTarget.style.transform = "scale(1) translateY(0)";
        }}
      >
        {open ? (
          <X size={28} color="white" />
        ) : (
          <Sparkles size={28} color="white" />
        )}
        {/* Unread badge */}
        {!open && hasUnread && (
          <span style={{
            position: "absolute",
            top: 4,
            right: 4,
            width: 14,
            height: 14,
            background: "#EF4444",
            borderRadius: "50%",
            border: "3px solid white",
            boxShadow: "0 2px 8px rgba(239, 68, 68, 0.4)",
          }} />
        )}
      </button>

      {/* Chat Window */}
      <div
        style={{
          position: "fixed",
          bottom: 110,
          left: 28,
          width: 380,
          maxWidth: "calc(100vw - 40px)",
          height: 600,
          maxHeight: "calc(100vh - 140px)",
          borderRadius: 28,
          background: "rgba(255, 255, 255, 0.85)",
          backdropFilter: "blur(40px)",
          WebkitBackdropFilter: "blur(40px)",
          boxShadow: "0 30px 80px rgba(0, 0, 0, 0.15), inset 0 0 0 1px rgba(255, 255, 255, 0.5)",
          display: "flex",
          flexDirection: "column",
          overflow: "hidden",
          zIndex: 9997,
          opacity: open ? 1 : 0,
          pointerEvents: open ? "all" : "none",
          transform: open ? "translateY(0) scale(1)" : "translateY(20px) scale(0.95)",
          transformOrigin: "bottom left",
          transition: "opacity 0.3s ease, transform 0.4s cubic-bezier(0.22, 1, 0.36, 1)",
        }}
      >
        {/* Header */}
        <div style={{
          padding: "20px 24px 16px",
          background: "linear-gradient(135deg, #10B981 0%, #047857 100%)",
          display: "flex",
          alignItems: "center",
          gap: 14,
          position: "relative",
          overflow: "hidden"
        }}>
          {/* Decorative background glow */}
          <div style={{
            position: "absolute", top: -20, right: -20, width: 100, height: 100,
            background: "radial-gradient(circle, rgba(255,255,255,0.2) 0%, rgba(255,255,255,0) 70%)",
            borderRadius: "50%"
          }} />
          
          <div style={{
            width: 44,
            height: 44,
            borderRadius: "50%",
            background: "rgba(255,255,255,0.2)",
            backdropFilter: "blur(10px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexShrink: 0,
            border: "1px solid rgba(255,255,255,0.3)",
            boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
          }}>
            <Bot size={24} color="white" />
          </div>
          <div style={{ zIndex: 1 }}>
            <p style={{ color: "white", fontWeight: 800, fontSize: 16, margin: 0, letterSpacing: "-0.01em" }}>ALO Bot</p>
            <p style={{ color: "rgba(255,255,255,0.85)", fontSize: 13, margin: "2px 0 0", display: "flex", alignItems: "center", gap: 5, fontWeight: 500 }}>
              <span style={{ 
                width: 8, height: 8, borderRadius: "50%", background: "#4ade80", 
                display: "inline-block", boxShadow: "0 0 8px #4ade80",
                animation: "pulseOnline 2s infinite" 
              }} />
              Çevrimiçi
            </p>
          </div>
          <button
            onClick={() => setOpen(false)}
            style={{ 
              marginLeft: "auto", background: "rgba(255,255,255,0.15)", border: "none", 
              cursor: "pointer", color: "white", width: 32, height: 32, borderRadius: "50%",
              display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1,
              transition: "background 0.2s"
            }}
            onMouseEnter={e => e.currentTarget.style.background = "rgba(255,255,255,0.25)"}
            onMouseLeave={e => e.currentTarget.style.background = "rgba(255,255,255,0.15)"}
          >
            <X size={18} strokeWidth={2.5} />
          </button>
        </div>

        {/* Messages */}
        <div style={{
          flex: 1,
          overflowY: "auto",
          padding: "20px",
          display: "flex",
          flexDirection: "column",
          gap: 16,
        }}>
          {messages.map((msg, i) => (
            <div
              key={i}
              style={{
                display: "flex",
                justifyContent: msg.role === "user" ? "flex-end" : "flex-start",
                gap: 10,
                alignItems: "flex-end",
              }}
            >
              {/* Bot avatar */}
              {msg.role === "assistant" && (
                <div style={{
                  width: 32,
                  height: 32,
                  borderRadius: "50%",
                  background: "linear-gradient(135deg, #10B981, #047857)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  flexShrink: 0,
                  boxShadow: "0 4px 10px rgba(16, 185, 129, 0.3)"
                }}>
                  <Bot size={16} color="white" />
                </div>
              )}
              <div style={{
                maxWidth: "80%",
                padding: "12px 16px",
                borderRadius: msg.role === "user" ? "20px 20px 4px 20px" : "20px 20px 20px 4px",
                background: msg.role === "user"
                  ? "linear-gradient(135deg, #10B981, #047857)"
                  : "#FFFFFF",
                color: msg.role === "user" ? "white" : "#1F2937",
                fontSize: 14.5,
                lineHeight: 1.5,
                fontWeight: 500,
                boxShadow: msg.role === "user"
                  ? "0 8px 24px rgba(16, 185, 129, 0.25)"
                  : "0 4px 20px rgba(0,0,0,0.06)",
                border: msg.role === "user" ? "none" : "1px solid rgba(0,0,0,0.04)"
              }}>
                {msg.text}
              </div>
            </div>
          ))}

          {/* Loading indicator */}
          {loading && (
            <div style={{ display: "flex", gap: 10, alignItems: "flex-end" }}>
              <div style={{
                width: 32, height: 32, borderRadius: "50%",
                background: "linear-gradient(135deg, #10B981, #047857)",
                display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
                boxShadow: "0 4px 10px rgba(16, 185, 129, 0.3)"
              }}>
                <Bot size={16} color="white" />
              </div>
              <div style={{
                padding: "16px 20px",
                borderRadius: "20px 20px 20px 4px",
                background: "#FFFFFF",
                display: "flex",
                alignItems: "center",
                gap: 6,
                boxShadow: "0 4px 20px rgba(0,0,0,0.06)",
                border: "1px solid rgba(0,0,0,0.04)"
              }}>
                <span style={{
                  display: "inline-flex",
                  gap: 4,
                  alignItems: "center",
                }}>
                  {[0, 0.15, 0.3].map((delay, i) => (
                    <span
                      key={i}
                      style={{
                        width: 8,
                        height: 8,
                        borderRadius: "50%",
                        background: "#10B981",
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
          <div style={{ padding: "0 20px 16px", display: "flex", gap: 8, flexWrap: "wrap" }}>
            {[
              "Nasıl rezervasyon yapılır?",
              "Maç nasıl kurulur?",
              "Kapora iadesi var mı?",
            ].map((q) => (
               <button
                key={q}
                onClick={() => sendMessage(q)}
                style={{
                  padding: "8px 14px",
                  borderRadius: 24,
                  border: "1px solid #A7F3D0",
                  background: "#ECFDF5",
                  color: "#047857",
                  fontSize: 13,
                  fontWeight: 600,
                  cursor: "pointer",
                  transition: "all 0.2s",
                }}
                onMouseEnter={e => {
                  e.currentTarget.style.background = "#D1FAE5";
                  e.currentTarget.style.transform = "translateY(-2px)";
                }}
                onMouseLeave={e => {
                  e.currentTarget.style.background = "#ECFDF5";
                  e.currentTarget.style.transform = "translateY(0)";
                }}
              >
                {q}
              </button>
            ))}
          </div>
        )}

        {/* Input */}
        <div style={{
          padding: "16px 20px",
          background: "rgba(255,255,255,0.9)",
          backdropFilter: "blur(20px)",
          borderTop: "1px solid rgba(0,0,0,0.05)",
          display: "flex",
          gap: 12,
          alignItems: "center",
        }}>
          <input
            ref={inputRef}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKey}
            placeholder="Bir soru sorun..."
            disabled={loading}
            style={{
              flex: 1,
              padding: "14px 18px",
              borderRadius: 24,
              border: "1px solid #E5E7EB",
              background: "#F9FAFB",
              fontSize: 15,
              outline: "none",
              color: "#111827",
              fontWeight: 500,
              transition: "all 0.2s",
              boxShadow: "inset 0 2px 4px rgba(0,0,0,0.02)"
            }}
            onFocus={(e) => { 
              e.target.style.borderColor = "#10B981"; 
              e.target.style.background = "#FFFFFF";
              e.target.style.boxShadow = "0 0 0 4px rgba(16, 185, 129, 0.1)";
            }}
            onBlur={(e) => { 
              e.target.style.borderColor = "#E5E7EB"; 
              e.target.style.background = "#F9FAFB";
              e.target.style.boxShadow = "inset 0 2px 4px rgba(0,0,0,0.02)";
            }}
          />
          <button
            onClick={() => sendMessage()}
            disabled={loading || !input.trim()}
            style={{
              width: 48,
              height: 48,
              borderRadius: "50%",
              border: "none",
              background: input.trim() && !loading
                ? "linear-gradient(135deg, #10B981, #047857)"
                : "#F3F4F6",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              cursor: input.trim() && !loading ? "pointer" : "not-allowed",
              transition: "all 0.2s",
              flexShrink: 0,
              boxShadow: input.trim() && !loading ? "0 4px 14px rgba(16, 185, 129, 0.3)" : "none",
              color: input.trim() && !loading ? "white" : "#9CA3AF"
            }}
            onMouseEnter={e => {
              if (input.trim() && !loading) e.currentTarget.style.transform = "scale(1.05)";
            }}
            onMouseLeave={e => {
              e.currentTarget.style.transform = "scale(1)";
            }}
          >
            {loading
              ? <Loader2 size={20} style={{ animation: "spin 1s linear infinite" }} />
              : <Send size={20} style={{ marginLeft: 2 }} />
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
        @keyframes pulseOnline {
          0% { box-shadow: 0 0 0 0 rgba(74, 222, 128, 0.7); }
          70% { box-shadow: 0 0 0 6px rgba(74, 222, 128, 0); }
          100% { box-shadow: 0 0 0 0 rgba(74, 222, 128, 0); }
        }
      `}</style>
    </>
  );
}

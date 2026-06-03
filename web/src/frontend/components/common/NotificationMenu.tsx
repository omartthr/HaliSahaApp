"use client";

import React, { useState, useEffect, useRef } from "react";
import { Bell, Check, Users } from "lucide-react";
import { useAuth } from "@/frontend/context/AuthContext";
import { getMyNotificationsRealtime, updateNotificationStatus, NotificationRecord } from "@/backend/services/notificationService";
import { formatDistanceToNow } from "date-fns";
import { tr } from "date-fns/locale";

interface NotificationMenuProps {
  scrolled?: boolean;
}

export default function NotificationMenu({ scrolled = false }: NotificationMenuProps) {
  const { user } = useAuth();
  const [notifications, setNotifications] = useState<NotificationRecord[]>([]);
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!user) return;
    const unsub = getMyNotificationsRealtime(user.uid, (data) => {
      // Sort by creation date descending
      const sorted = data.sort((a, b) => {
        const timeA = a.createdAt?.toMillis ? a.createdAt.toMillis() : 0;
        const timeB = b.createdAt?.toMillis ? b.createdAt.toMillis() : 0;
        return timeB - timeA;
      });
      setNotifications(sorted);
    });
    return () => unsub();
  }, [user]);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  if (!user) return null;

  const unreadCount = notifications.filter(n => !n.isRead).length;

  const handleAction = async (notifId: string, status: string, e: React.MouseEvent) => {
    e.stopPropagation();
    await updateNotificationStatus(notifId, status);
  };

  return (
    <div className="relative" ref={menuRef} style={{ position: "relative" }}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        style={{
          display: "flex", alignItems: "center", justifyContent: "center",
          width: 38, height: 38, borderRadius: "50%",
          background: scrolled ? "rgba(0,0,0,0.05)" : "rgba(255,255,255,0.15)", 
          border: scrolled ? "1px solid rgba(0,0,0,0.1)" : "1px solid rgba(255,255,255,0.3)",
          color: scrolled ? "#374151" : "white", 
          cursor: "pointer", position: "relative",
          transition: "all 0.2s ease"
        }}
        onMouseEnter={(e) => e.currentTarget.style.background = scrolled ? "rgba(0,0,0,0.1)" : "rgba(255,255,255,0.25)"}
        onMouseLeave={(e) => e.currentTarget.style.background = scrolled ? "rgba(0,0,0,0.05)" : "rgba(255,255,255,0.15)"}
      >
        <Bell size={18} />
        {unreadCount > 0 && (
          <span style={{
            position: "absolute", top: -2, right: -2, background: "#ef4444", color: "white",
            fontSize: 10, fontWeight: "bold", width: 18, height: 18,
            display: "flex", alignItems: "center", justifyContent: "center",
            borderRadius: "50%", border: "2px solid #114B32"
          }}>
            {unreadCount > 9 ? "9+" : unreadCount}
          </span>
        )}
      </button>

      {isOpen && (
        <div style={{
          position: "absolute", top: "calc(100% + 12px)", right: 0,
          width: 320, background: "white", borderRadius: 16,
          boxShadow: "0 10px 40px rgba(0,0,0,0.15)", border: "1px solid #e5e7eb",
          overflow: "hidden", zIndex: 100, transformOrigin: "top right",
          animation: "notifFadeIn 0.2s ease-out"
        }}>
          <div style={{ padding: "16px", borderBottom: "1px solid #f3f4f6", display: "flex", justifyContent: "space-between", alignItems: "center", background: "#fafafa" }}>
            <h3 style={{ fontSize: 16, fontWeight: 700, margin: 0, color: "#111827" }}>Bildirimler</h3>
            {unreadCount > 0 && (
              <span style={{ fontSize: 12, color: "#2E7D32", fontWeight: 600, background: "#E8F5E9", padding: "4px 8px", borderRadius: 12 }}>
                {unreadCount} yeni
              </span>
            )}
          </div>

          <div style={{ maxHeight: 400, overflowY: "auto" }}>
            {notifications.length === 0 ? (
              <div style={{ padding: "40px 20px", textAlign: "center", color: "#9ca3af" }}>
                <Bell size={32} style={{ margin: "0 auto 12px", opacity: 0.2 }} />
                <p style={{ margin: 0, fontSize: 14, fontWeight: 500 }}>Henüz bildiriminiz yok.</p>
              </div>
            ) : (
              notifications.map((notif) => (
                <div key={notif.id} style={{
                  padding: "16px", borderBottom: "1px solid #f3f4f6",
                  background: notif.isRead ? "white" : "#F4FDF8",
                  display: "flex", gap: 12, cursor: "pointer",
                  transition: "background 0.2s"
                }} onClick={() => !notif.isRead && updateNotificationStatus(notif.id, "read")}>
                  <div style={{
                    width: 40, height: 40, borderRadius: "50%", flexShrink: 0,
                    background: notif.type === "invite" ? "#E8F5E9" : "#F3F4F6",
                    display: "flex", alignItems: "center", justifyContent: "center"
                  }}>
                    {notif.type === "invite" ? <Users size={18} color="#2E7D32" /> : <Bell size={18} color="#6b7280" />}
                  </div>
                  
                  <div style={{ flex: 1 }}>
                    <p style={{ margin: "0 0 4px", fontSize: 14, fontWeight: notif.isRead ? 500 : 700, color: "#111827" }}>
                      {notif.title}
                    </p>
                    <p style={{ margin: 0, fontSize: 13, color: "#6b7280", lineHeight: 1.4 }}>
                      {notif.body}
                    </p>
                    
                    {notif.createdAt && (
                      <p style={{ margin: "6px 0 0", fontSize: 11, color: "#9ca3af", fontWeight: 500 }}>
                        {formatDistanceToNow(notif.createdAt.toDate(), { addSuffix: true, locale: tr })}
                      </p>
                    )}

                    {notif.type === "invite" && notif.status === "pending" && (
                      <div style={{ display: "flex", gap: 8, marginTop: 12 }}>
                        <button
                          onClick={(e) => handleAction(notif.id, "accepted", e)}
                          style={{ flex: 1, padding: "6px", fontSize: 12, fontWeight: 600, background: "#2E7D32", color: "white", border: "none", borderRadius: 6, cursor: "pointer" }}>
                          Kabul Et
                        </button>
                        <button
                          onClick={(e) => handleAction(notif.id, "rejected", e)}
                          style={{ flex: 1, padding: "6px", fontSize: 12, fontWeight: 600, background: "#f3f4f6", color: "#4b5563", border: "none", borderRadius: 6, cursor: "pointer" }}>
                          Reddet
                        </button>
                      </div>
                    )}

                    {notif.type === "invite" && notif.status !== "pending" && notif.status !== "read" && (
                      <div style={{ marginTop: 8, fontSize: 12, fontWeight: 600, color: notif.status === "accepted" ? "#2E7D32" : "#9ca3af" }}>
                        {notif.status === "accepted" ? "✅ Kabul edildi" : "❌ Reddedildi"}
                      </div>
                    )}
                  </div>
                  
                  {!notif.isRead && (
                    <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#10B981", marginTop: 6 }} />
                  )}
                </div>
              ))
            )}
          </div>
        </div>
      )}
      <style>{`
        @keyframes notifFadeIn {
          from { opacity: 0; transform: translateY(10px) scale(0.95); }
          to { opacity: 1; transform: translateY(0) scale(1); }
        }
      `}</style>
    </div>
  );
}

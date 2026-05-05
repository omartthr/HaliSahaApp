const fs = require('fs');
const file = 'src/app/profile/page.tsx';
let content = fs.readFileSync(file, 'utf8');

// 1. Change page-wrapper
content = content.replace(
  '<div className="page-wrapper" style={{ minHeight: "100vh" }}>',
  '<div className="page-wrapper" style={{ height: "100vh", overflow: "hidden" }}>'
);

// 2. Re-layout the grid
const newGrid = `      <div className="content-container" style={{ position: "relative", zIndex: 2, marginTop: -170, paddingTop: 24, paddingBottom: 40 }}>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 items-start" style={{ gridTemplateColumns: "minmax(0, 1.08fr) minmax(0, 1fr)" }}>
          {/* Sol Kolon */}
          <div style={{ display: "flex", flexDirection: "column", gap: 18, height: "calc(100vh - 160px)", overflowY: "auto", paddingRight: 8 }}>
            <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ padding: 30, borderRadius: 24 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 20, flexWrap: "wrap" }}>
                <div style={{ width: 92, height: 92, borderRadius: "50%", background: "rgba(17,75,50,0.12)", border: "2px solid rgba(17,75,50,0.22)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 38, fontWeight: 900, flexShrink: 0, color: "#114B32" }}>
                  {initials}
                </div>
                <div style={{ flex: 1 }}>
                  <h1 style={{ fontSize: 38, fontWeight: 900, marginBottom: 6, color: "#0f172a", lineHeight: 1.05 }}>{fullName}</h1>
                  <p style={{ color: "#2E7D32", fontSize: 22, fontWeight: 700, marginBottom: 4 }}>@{userData?.username || "kullanici"}</p>
                  <p style={{ color: "#64748b", fontSize: 18, marginBottom: 6 }}>{user.email}</p>
                  {userData?.position && (
                    <span style={{ display: "inline-block", background: "#E8F5E9", color: "#2E7D32", padding: "6px 14px", borderRadius: 12, fontSize: 14, fontWeight: 700, marginTop: 4 }}>
                      ⚽ Mevki: {userData.position}
                    </span>
                  )}
                </div>
              </div>

              <div style={{ display: "flex", gap: 14, marginTop: 24, flexWrap: "wrap" }}>
                {[{ label: "Randevu", value: reservations.length.toString() }, { label: "Puan", value: Math.round(userRating * 100).toString() }, { label: "Maç", value: reservations.filter(r => r.status === "completed").length.toString() }].map((s) => (
                  <div key={s.label} style={{ background: "rgba(255,255,255,0.72)", backdropFilter: "blur(8px)", borderRadius: 14, padding: "14px 24px", border: "1px solid rgba(17,75,50,0.08)" }}>
                    <p style={{ fontSize: 26, fontWeight: 900, color: "#0f172a", lineHeight: 1 }}>{s.value}</p>
                    <p style={{ fontSize: 13, color: "#64748b", fontWeight: 700, marginTop: 6 }}>{s.label}</p>
                  </div>
                ))}
              </div>
            </div>

            <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 20, padding: "24px 28px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
                  <Star size={18} style={{ color: "#FCD34D" }} />
                  <span style={{ fontWeight: 700, fontSize: 16, color: "#0f172a" }}>Oyuncu Puanı</span>
                </div>
                <p style={{ fontSize: 48, fontWeight: 900, color: "#0f172a", lineHeight: 1 }}>
                  {userRating.toFixed(2)}
                </p>
                <p style={{ fontSize: 14, color: "#64748b", marginTop: 8 }}>1-5 yıldız ortalaması</p>
              </div>
              <div style={{ textAlign: "right" }}>
                <Star size={52} style={{ color: "rgba(17,75,50,0.12)", fill: "rgba(17,75,50,0.12)" }} />
              </div>
            </div>

            <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 20, padding: "24px 28px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
                  <Trophy size={18} style={{ color: "#FCD34D" }} />
                  <span style={{ fontWeight: 700, fontSize: 16, color: "#0f172a" }}>Sadakat Puanı</span>
                </div>
                <p style={{ fontSize: 48, fontWeight: 900, color: "#0f172a", lineHeight: 1 }}>450</p>
                <p style={{ fontSize: 14, color: "#64748b", marginTop: 8 }}>Sonraki seviye için 50 puan kaldı!</p>
              </div>
              <div style={{ textAlign: "right" }}>
                <Trophy size={52} style={{ color: "rgba(17,75,50,0.12)", fill: "rgba(17,75,50,0.12)" }} />
              </div>
            </div>
          </div>

          {/* Sağ Kolon */}
          <div style={{ display: "flex", flexDirection: "column", gap: 18, height: "calc(100vh - 160px)", overflowY: "auto", paddingRight: 8 }}>
            <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ padding: 20, borderRadius: 20 }}>
              <div style={{ display: "flex", gap: 8, borderRadius: 14, padding: 4 }}>
                {[{ key: "bookings", label: "Randevularım" }, { key: "settings", label: "Ayarlar" }].map((tab) => (
                  <button
                    key={tab.key}
                    onClick={() => setActiveTab(tab.key as "bookings" | "settings")}
                    style={{
                      flex: 1,
                      padding: "14px 0",
                      borderRadius: 12,
                      fontWeight: 700,
                      fontSize: 17,
                      border: "1px solid rgba(255,255,255,0.9)",
                      cursor: "pointer",
                      transition: "all 0.2s",
                      background: activeTab === tab.key ? "rgba(255,255,255,0.88)" : "rgba(255,255,255,0.56)",
                      color: activeTab === tab.key ? "#111827" : "#475569",
                      boxShadow: activeTab === tab.key ? "0 6px 16px rgba(15,23,42,0.08), inset 0 1px 0 rgba(255,255,255,0.7)" : "inset 0 1px 0 rgba(255,255,255,0.45)",
                    }}
                  >
                    {tab.label}
                  </button>
                ))}
              </div>
            </div>

            {activeTab === "bookings" && (
              <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                {reservations.length === 0 ? (
                  <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 20, padding: "56px 20px", textAlign: "center" }}>
                    <div style={{ fontSize: 48, marginBottom: 16 }}>📅</div>
                    <p style={{ fontWeight: 700, color: "#374151", marginBottom: 8 }}>Henüz Randevun Yok</p>
                    <p style={{ color: "#9ca3af", fontSize: 14, marginBottom: 20 }}>İlk randevunu alarak başla!</p>
                    <Link href="#map" className="btn-primary" style={{ textDecoration: "none", display: "inline-flex" }}>
                      Saha Bul
                    </Link>
                  </div>
                ) : (
                  reservations.map((res) => (
                    <div key={res.id} className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 16, padding: "20px" }}>
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 12 }}>
                        <h3 style={{ fontSize: 16, fontWeight: 700, color: "#111827" }}>{res.fieldName}</h3>
                        <span style={{ fontSize: 11, fontWeight: 700, padding: "4px 12px", borderRadius: 20, background: res.status === "completed" ? "#E0F2F1" : res.status === "approved" ? "#E8F5E9" : "#FFF3E0", color: res.status === "completed" ? "#00695C" : res.status === "approved" ? "#2E7D32" : "#E65100" }}>
                          {res.status === "completed" ? "✓ Tamamlandı" : res.status === "approved" ? "✓ Onaylandı" : "⏳ Bekliyor"}
                        </span>
                      </div>
                      <div style={{ display: "flex", gap: 16, color: "#9ca3af", fontSize: 13, marginBottom: 12 }}>
                        <span style={{ display: "flex", alignItems: "center", gap: 4 }}>
                          <Calendar size={13} /> {res.date}
                        </span>
                        <span style={{ display: "flex", alignItems: "center", gap: 4 }}>
                          <Clock size={13} /> {res.timeSlot}
                        </span>
                      </div>
                      {res.status === "completed" && (
                        <button
                          onClick={() => setRatingModal({ show: true, resId: res.id, opponentIds: [] })}
                          style={{ fontSize: 12, fontWeight: 700, padding: "6px 12px", borderRadius: 8, border: "none", background: "#2E7D32", color: "#fff", cursor: "pointer" }}
                        >
                          ⭐ Takım Arkadaşlarını Puanla
                        </button>
                      )}
                    </div>
                  ))
                )}
              </div>
            )}

            {activeTab === "settings" && (
              <div>
                <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 20, overflow: "hidden", marginBottom: 16 }}>
                  {settingsItems.map((item, idx) => {
                    const Icon = item.icon;
                    return (
                      <div
                        key={item.label}
                        style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "16px 20px", borderBottom: idx < settingsItems.length - 1 ? "1px solid rgba(17,75,50,0.08)" : "none", cursor: "pointer" }}
                        className="hover:bg-gray-50 transition-colors"
                      >
                        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                          <div style={{ width: 36, height: 36, borderRadius: 10, background: `${item.color}15`, display: "flex", alignItems: "center", justifyContent: "center" }}>
                            <Icon size={18} style={{ color: item.color }} />
                          </div>
                          <span style={{ fontWeight: 600, fontSize: 15, color: "#374151" }}>{item.label}</span>
                        </div>
                        <ChevronRight size={16} style={{ color: "#d1d5db" }} />
                      </div>
                    );
                  })}
                </div>

                <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 20, overflow: "hidden" }}>
                  <button
                    onClick={handleDeleteAccount}
                    style={{ width: "100%", display: "flex", alignItems: "center", gap: 12, padding: "16px 20px", background: "none", border: "none", cursor: "pointer" }}
                    className="hover:bg-red-50 transition-colors"
                  >
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: "#FFEBEE", display: "flex", alignItems: "center", justifyContent: "center" }}>
                      <Trash2 size={18} style={{ color: "#C62828" }} />
                    </div>
                    <span style={{ fontWeight: 600, fontSize: 15, color: "#C62828" }}>Hesabı Sil</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>`;

const regex = /<div className="content-container"[\s\S]*?(?=\{ratingModal\.show && \()/;
content = content.replace(regex, newGrid + "\n\n      ");

fs.writeFileSync(file, content);
console.log("Done");

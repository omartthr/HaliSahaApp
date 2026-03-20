import Navbar from "@/components/common/Navbar";
import Link from "next/link";
import { Search, MapPin, Calendar, Users, ArrowRight, Star, Shield, Clock, ChevronRight } from "lucide-react";
import MapSection from "@/components/map/MapSection";
import Aurora from "@/components/ui/Aurora/Aurora";

const featuredFields = [
  { id: "1", name: "Kadıköy Merkez Halı Saha", address: "Zühtüpaşa, Kadıköy / İstanbul", rating: 4.8, reviews: 124, features: ["🚿", "🅿️", "🍔", "💡"], color: "from-emerald-700 to-teal-600" },
  { id: "2", name: "Beşiktaş Vadi Saha", address: "Vişnezade, Beşiktaş / İstanbul", rating: 4.5, reviews: 87, features: ["🚿", "🅿️", "☕", "🏆"], color: "from-green-700 to-emerald-500" },
  { id: "3", name: "Üsküdar Sahil Halı Saha", address: "Mimar Sinan, Üsküdar / İstanbul", rating: 4.2, reviews: 53, features: ["🚿", "🍔", "💡"], color: "from-teal-700 to-cyan-600" },
];

const upcomingMatches = [
  { id: "1", title: "5v5 Maç — Kadıköy Merkez", creator: "Ahmet Y.", date: "Bugün 20:00", facility: "Kadıköy Merkez", available: 3, total: 10, current: 7, skill: "⚡ Orta Seviye", cost: "₺60/kişi" },
  { id: "2", title: "Hafta sonu maçı arayanlar — Beşiktaş", creator: "Mert K.", date: "Cumartesi 18:00", facility: "Beşiktaş Vadi", available: 5, total: 10, current: 5, skill: "🔥 Profesyonel", cost: "₺80/kişi" },
];

const quickActions = [
  { icon: Search, title: "Saha Bul", subtitle: "Yakındaki sahaları keşfet", color: "#2E7D32", href: "#map" },
  { icon: Users, title: "Maç Kur", subtitle: "Arkadaşlarınla maç organize et", color: "#1565C0", href: "/groups" },
  { icon: Calendar, title: "Randevularım", subtitle: "Rezervasyonlarını yönet", color: "#E65100", href: "/profile" },
  { icon: Star, title: "Favoriler", subtitle: "Kaydettiğin sahalar", color: "#6A1B9A", href: "/profile" },
];

export default function Home() {
  return (
    <div className="page-wrapper">
      <Navbar />

      {/* Hero Section */}
      {/* Hero Section */}
      <section style={{
        position: "relative",
        background: "linear-gradient(180deg, #114B32 0%, #1A754E 100%)",
        padding: "4rem 5% 3rem 5%", // Bıraktığımız padding
        color: "white",
      }}>
        {/* Hero İçerik */}
        <div style={{ textAlign: "center", maxWidth: 800, margin: "0 auto", position: "relative", zIndex: 2, paddingTop: "3rem", paddingBottom: "2rem" }}>
          <h1 style={{ fontSize: "3.5rem", lineHeight: 1.2, marginBottom: "1rem", fontWeight: 700 }}>
            Sahayı Bul, Ekibi Topla,<br />Maçı Başlat!
          </h1>
          <p style={{ fontSize: "1.1rem", marginBottom: "2rem", opacity: 0.9 }}>
            En yakın halı sahada anında randevu al veya takımınla maç organize et.
          </p>
          <div style={{ display: "flex", justifyContent: "center", gap: "1rem", flexWrap: "wrap" }}>
            <Link href="#map" style={{
              display: "inline-flex", alignItems: "center", gap: 8,
              padding: "0.85rem 1.8rem", borderRadius: 30, fontWeight: 700, fontSize: "1rem",
              background: "rgba(255, 255, 255, 0.95)", color: "#114B32", textDecoration: "none",
              backdropFilter: "blur(10px)", WebkitBackdropFilter: "blur(10px)",
              border: "1px solid rgba(255,255,255,1)",
              boxShadow: "0 4px 20px rgba(0,0,0,0.08)",
              transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)",
            }} className="brand-btn-glass solid-light">
              <MapPin size={18} /> Haritada Ara
            </Link>
            <Link href="/register" style={{
              display: "inline-flex", alignItems: "center", gap: 8,
              padding: "0.85rem 1.8rem", borderRadius: 30, fontWeight: 700, fontSize: "1rem",
              background: "rgba(255,255,255,0.15)", color: "white", textDecoration: "none",
              backdropFilter: "blur(10px)", WebkitBackdropFilter: "blur(10px)",
              border: "1px solid rgba(255,255,255,0.4)",
              transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)",
            }} className="brand-btn-glass ghost-light">
              <Users size={18} /> Hemen Üye Ol
            </Link>
          </div>
        </div>

        {/* Dalgalı Geçiş (Wave) — Subpixel gap oluşmasın diye kasıtlı olarak 2px içeri sokuldu (-118px) */}
        <div style={{ position: "absolute", bottom: "-118px", left: 0, width: "100%", lineHeight: 0, zIndex: 1 }}>
          <svg data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 120" preserveAspectRatio="none" style={{ display: "block", width: "calc(100% + 1.3px)", height: 120, overflow: "visible" }}>
            <defs>
              <filter id="wave-shadow" x="-10%" y="-10%" width="120%" height="150%">
                <feDropShadow dx="0" dy="12" stdDeviation="10" floodColor="#000000" floodOpacity="0.45" />
              </filter>
            </defs>
            {/* Gölgeli Alt Katman: Gölgeyi oluşturur ama kendi rengi tarayıcı filtresinde hafif solabilir */}
            <path d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z" fill="#1A754E" filter="url(#wave-shadow)" />
            {/* Temiz Üst Katman: Filtre olmadığı için üstteki ana alanla %100 aynı piksel renginde çizilir! */}
            <path d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z" fill="#1A754E" />
          </svg>
        </div>
      </section>

      {/* Glassmorphism Kartlar */}
      <section style={{
        display: "flex", justifyContent: "center", gap: "1.5rem",
        padding: "0 5%",
        marginTop: -30, // Kartları Hero içine hafifçe itiyor
        position: "relative", zIndex: 10,
        flexWrap: "wrap",
      }}>
        {quickActions.map((qa, i) => {
          const bgColors: Record<string, string> = {
            "#2E7D32": "#e8f5e9", // icon-green
            "#1565C0": "#e3f2fd", // icon-blue
            "#E65100": "#fff3e0", // icon-orange
            "#6A1B9A": "#f3e5f5"  // icon-purple
          };

          return (
            <Link key={qa.title} href={qa.href} className="interactive-glass-card">
              <div className="card-icon-box" style={{
                width: 54, height: 54, borderRadius: "50%",
                display: "flex", alignItems: "center", justifyContent: "center",
                marginBottom: "1.25rem",
                background: bgColors[qa.color] || "#f0f0f0", color: qa.color,
              }}>
                <qa.icon size={26} />
              </div>
              <h3 style={{ fontSize: "1.2rem", marginBottom: "0.25rem", color: "#1a1a1a", fontWeight: 700 }}>{qa.title}</h3>
              <p style={{ fontSize: "0.9rem", color: "#666", lineHeight: 1.4 }}>{qa.subtitle}</p>
            </Link>
          );
        })}
      </section>

      {/* Map + Location Cards */}
      <section style={{ padding: "2rem 5% 3rem 5%", background: "#f5f5f7" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "1.5rem" }}>
          <h2 style={{ fontSize: "1.5rem", fontWeight: 700, color: "#111827", display: "flex", alignItems: "center", gap: 8 }}>
            <MapPin size={22} style={{ color: "#2E7D32" }} /> Yakındaki Sahalar
          </h2>
        </div>

        {/* Split layout */}
        <div style={{ display: "flex", gap: "1.5rem", alignItems: "stretch" }}>

          {/* LEFT: Map */}
          <div style={{ flex: "0 0 58%", borderRadius: 20, overflow: "hidden", boxShadow: "0 8px 32px rgba(0,0,0,0.10)", minHeight: 520 }}>
            <div id="map" style={{ height: "100%", minHeight: 520 }}>
              <MapSection />
            </div>
          </div>

          {/* RIGHT: Location Cards — outer wrapper scrolls, inner wrapper gives padding so scale() doesn't clip */}
          <div style={{ flex: 1, overflowY: "auto", overflowX: "hidden", maxHeight: 520, borderRadius: 8 }}>
            <div style={{ display: "flex", flexDirection: "column", gap: "1rem", padding: "6px 6px 6px 2px" }}>
              {/* Placeholder cards – user will fill in later */}
              {[
                { name: "Saha 1", district: "İlçe", address: "Adres bilgisi gelecek" },
                { name: "Saha 2", district: "İlçe", address: "Adres bilgisi gelecek" },
                { name: "Saha 3", district: "İlçe", address: "Adres bilgisi gelecek" },
                { name: "Saha 4", district: "İlçe", address: "Adres bilgisi gelecek" },
                { name: "Saha 5", district: "İlçe", address: "Adres bilgisi gelecek" },
                { name: "Saha 6", district: "İlçe", address: "Adres bilgisi gelecek" },
              ].map((saha, i) => (
                <a
                  key={i}
                  href="#"
                  className="location-card">
                  <span style={{ fontSize: 11, fontWeight: 700, color: "#2E7D32", letterSpacing: "0.08em", textTransform: "uppercase" }}>{saha.district}</span>
                  <span style={{ fontSize: "1.05rem", fontWeight: 700, color: "#111827" }}>{saha.name}</span>
                  <span style={{ fontSize: "0.85rem", color: "#6b7280", display: "flex", alignItems: "center", gap: 4 }}>
                    <MapPin size={12} /> {saha.address}
                  </span>
                </a>
              ))}
            </div>
          </div>

        </div>
      </section>

      {/* Featured Facilities */}
      <section className="section" style={{ background: "#f5f5f7" }}>
        <div className="content-container">
          <div className="section-header">
            <h2 className="section-title">
              <Star size={18} style={{ color: "#F59E0B" }} /> Öne Çıkan Sahalar
            </h2>
            <Link href="#map" style={{ fontSize: "14px", fontWeight: 600, color: "#2E7D32", display: "flex", alignItems: "center", gap: 4, textDecoration: "none" }}>
              Tümü <ChevronRight size={15} />
            </Link>
          </div>
          <div className="scroll-x">
            {featuredFields.map(field => (
              <Link key={field.id} href={`/fields/${field.id}`}
                className="interactive-glass-card"
                style={{
                  textDecoration: "none",
                  flexShrink: 0,
                  width: 270,
                  padding: 0,
                  overflow: "hidden",
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "stretch",
                }}>
                {/* Card Image */}
                <div className={`h-36 bg-gradient-to-br ${field.color} relative flex items-center justify-center`}
                  style={{ borderRadius: "20px 20px 0 0", flexShrink: 0 }}>
                  <span style={{ fontSize: 48, opacity: 0.25 }}>⚽</span>
                  <div style={{ position: "absolute", bottom: 12, left: 12, background: "rgba(0,0,0,0.4)", backdropFilter: "blur(6px)", borderRadius: 20, padding: "4px 10px", display: "flex", alignItems: "center", gap: 4 }}>
                    <Star size={12} style={{ color: "#FCD34D", fill: "#FCD34D" }} />
                    <span style={{ color: "white", fontSize: 13, fontWeight: 700 }}>{field.rating}</span>
                    <span style={{ color: "rgba(255,255,255,0.7)", fontSize: 11 }}>({field.reviews})</span>
                  </div>
                </div>
                {/* Card Info */}
                <div style={{ padding: "16px 18px" }}>
                  <p className="font-bold text-sm truncate" style={{ color: "#111827" }}>{field.name}</p>
                  <p className="text-xs mt-1 truncate" style={{ color: "#9ca3af" }}>
                    <MapPin size={11} style={{ display: "inline", marginRight: 3 }} />{field.address}
                  </p>
                  <div style={{ display: "flex", gap: 4, marginTop: 10 }}>
                    {field.features.map(f => (
                      <span key={f} style={{ fontSize: 14, background: "#f3f4f6", borderRadius: 6, padding: "3px 7px" }}>{f}</span>
                    ))}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Aurora Wrapper Section (Upcoming Matches + Trust Row + CTA + Footer) */}
      <section className="relative overflow-hidden" style={{ background: "#f5f5f7" }}>
        {/* Ortak Arka Plan: Aurora — ters çevrilmiş, aşağıdan yukarı bakar */}
        <div style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", zIndex: 0, opacity: 1, transform: "scaleY(-1)" }}>
          <Aurora
            colorStops={["#114B32", "#2E7D32", "#4CAF50"]}
            amplitude={3.0}
            blend={0.4}
          />
        </div>

        {/* --- Oyuncu Aranan Maçlar (Upcoming Matches) --- */}
        <div className="relative z-10" style={{ padding: "48px 0 24px 0" }}>
          <div className="content-container">
            <div className="section-header">
              <h2 className="section-title">
                <Users size={18} style={{ color: "#2E7D32" }} /> Oyuncu Aranan Maçlar
              </h2>
              <Link href="/groups" style={{ fontSize: "14px", fontWeight: 600, color: "#2E7D32", textDecoration: "none", display: "flex", alignItems: "center", gap: 4 }}>
                Tümü <ChevronRight size={15} />
              </Link>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
              {upcomingMatches.map(match => (
                <div key={match.id}
                  className="match-glass-card"
                  style={{
                    background: "rgba(255, 255, 255, 0.88)",
                    borderRadius: "24px",
                    padding: "24px",
                    boxShadow: "0 10px 40px rgba(0,0,0,0.06)",
                    border: "1px solid rgba(255,255,255,1)",
                    backdropFilter: "blur(20px)",
                    WebkitBackdropFilter: "blur(20px)",
                    width: "100%",
                    transition: "all 0.5s cubic-bezier(0.16, 1, 0.3, 1)",
                  }}>
                  <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 12 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                      <div style={{ width: 40, height: 40, borderRadius: "50%", background: "#E8F5E9", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, color: "#2E7D32", fontSize: 16 }}>
                        {match.creator[0]}
                      </div>
                      <div>
                        <p style={{ fontWeight: 600, fontSize: 13, color: "#374151" }}>{match.creator}</p>
                        <p style={{ fontSize: 12, color: "#9ca3af" }}>{match.date}</p>
                      </div>
                    </div>
                    <span style={{ background: "#2E7D32", color: "white", borderRadius: 20, padding: "4px 12px", fontSize: 12, fontWeight: 700 }}>
                      👤 {match.available} kişi
                    </span>
                  </div>
                  <p style={{ fontWeight: 700, fontSize: 15, color: "#111827", marginBottom: 8 }}>{match.title}</p>
                  <div style={{ display: "flex", gap: 16, color: "#9ca3af", fontSize: 12, marginBottom: 12 }}>
                    <span>📍 {match.facility}</span>
                    <span>🕐 {match.date}</span>
                  </div>
                  {/* Progress bar */}
                  <div style={{ marginBottom: 6 }}>
                    <div style={{ background: "#f0f0f0", borderRadius: 4, height: 6 }}>
                      <div style={{ background: "#2E7D32", height: 6, borderRadius: 4, width: `${(match.current / match.total) * 100}%` }} />
                    </div>
                    <div style={{ display: "flex", justifyContent: "space-between", marginTop: 4, fontSize: 12 }}>
                      <span style={{ color: "#9ca3af" }}>{match.current}/{match.total} oyuncu</span>
                      <span style={{ color: "#2E7D32", fontWeight: 700 }}>{match.cost}</span>
                    </div>
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 12 }}>
                    <span style={{ fontSize: 12, color: "#9ca3af" }}>{match.skill}</span>
                    <Link href="/groups"
                      className="katil-btn"
                      style={{ background: "#E8F5E9", color: "#2E7D32", borderRadius: 8, padding: "6px 16px", fontSize: 13, fontWeight: 700, textDecoration: "none" }}>
                      Katıl
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* --- Güvenli Ödeme Kartları (Trust Row) --- */}
        <div className="relative z-10" style={{ padding: "48px 0 16px 0" }}>
          <div className="content-container">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {[
                { icon: Shield, color: "#2E7D32", bg: "#e8f5e9", title: "Güvenli Ödeme", desc: "256-bit SSL şifreli, güvenli altyapı." },
                { icon: Clock, color: "#1565C0", bg: "#e3f2fd", title: "7/24 Destek", desc: "Her zaman yanınızdayız, anında çözüm." },
                { icon: Star, color: "#E65100", bg: "#fff3e0", title: "Doğrulanmış Sahalar", desc: "Tüm sahalar yerinde ziyaret edilerek onaylandı." },
              ].map(item => {
                const Icon = item.icon;
                return (
                  <div key={item.title} style={{
                    display: "flex", flexDirection: "column", alignItems: "flex-start",
                    padding: "28px", gap: 0,
                    background: "rgba(255, 255, 255, 0.88)",
                    backdropFilter: "blur(20px)",
                    WebkitBackdropFilter: "blur(20px)",
                    borderRadius: "24px",
                    border: "1px solid rgba(255,255,255,1)",
                    boxShadow: "0 10px 40px rgba(0,0,0,0.06)",
                    transition: "all 0.5s cubic-bezier(0.16,1,0.3,1)",
                    cursor: "default",
                  }}
                    className="hover:-translate-y-1 hover:shadow-xl transition-all duration-300"
                  >
                    <div style={{
                      width: 54, height: 54, borderRadius: "50%",
                      background: item.bg, color: item.color,
                      display: "flex", alignItems: "center", justifyContent: "center",
                      marginBottom: "1.25rem",
                    }}>
                      <Icon size={26} />
                    </div>
                    <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: "#1a1a1a", marginBottom: "0.25rem" }}>{item.title}</h3>
                    <p style={{ fontSize: "0.9rem", color: "#666", lineHeight: 1.4 }}>{item.desc}</p>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* --- CTA İçeriği --- */}
        <div className="relative py-16 px-4" style={{ zIndex: 1 }}>
          <div className="content-container text-center relative" style={{ display: "flex", justifyContent: "center" }}>
            <div style={{
              background: "rgba(255, 255, 255, 0.8)",
              marginBottom: "48px",
              backdropFilter: "blur(20px)",
              WebkitBackdropFilter: "blur(20px)",
              border: "1px solid rgba(255, 255, 255, 1)",
              borderRadius: "30px",
              padding: "48px 56px",
              boxShadow: "0 10px 40px rgba(0,0,0,0.06)",
              maxWidth: 560,
              width: "100%",
              alignItems: "center",
              display: "flex",
              flexDirection: "column",
            }}>
              <div style={{ fontSize: 48, marginBottom: 16 }}>⚽</div>
              <h2 className="text-4xl font-black mb-3 tracking-tight" style={{ color: "#1a1a1a" }}>Hemen Başla, Ücretsiz</h2>
              <p className="mb-12 text-lg" style={{ color: "#666" }}>
                Binlerce kullanıcıyla saha kirasında zaman ve para kaybetme.
              </p>
              <Link
                href="/register"
                style={{
                  display: "inline-flex", alignItems: "center", gap: 8,
                  background: "white", color: "#2E7D32",
                  padding: "16px 36px", borderRadius: "16px",
                  fontWeight: 800, fontSize: 16,
                  boxShadow: "0 8px 24px rgba(0,0,0,0.12)",
                  textDecoration: "none",
                }}
                className="cta-register-btn"
              >
                Ücretsiz Üye Ol <ArrowRight size={20} />
              </Link>
            </div>
          </div>
        </div>

        {/* --- Footer İçeriği --- */}
        <footer className="relative text-white pb-8 px-4" style={{ zIndex: 1, borderTop: "1px solid rgba(255,255,255,0.1)", paddingTop: "8px" }}>
          <div className="content-container">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-8 mb-10">
              <div>
                <p className="text-2xl font-black tracking-tight">
                  Halı<span style={{ color: "#4CAF50" }}>SahaApp</span>
                </p>
                <p style={{ fontSize: 13, color: "rgba(255,255,255, 0.7)", marginTop: 4 }}>Türkiye&apos;nin halı saha rezervasyon platformu.</p>
              </div>
              <div style={{ display: "flex", flexWrap: "wrap", gap: "24px" }}>
                {[["Ana Sayfa", "/"], ["Sahalar", "#map"], ["Gruplar", "/groups"], ["Giriş Yap", "/login"], ["Kayıt Ol", "/register"]].map(([label, href]) => (
                  <Link key={label} href={href} style={{ color: "rgba(255,255,255, 0.7)", fontSize: 14, textDecoration: "none" }}
                    className="hover:text-white transition-colors">
                    {label}
                  </Link>
                ))}
              </div>
            </div>
            <div style={{ borderTop: "1px solid rgba(255,255,255,0.1)", paddingTop: "24px", textAlign: "center", color: "rgba(255,255,255, 0.5)", fontSize: 13 }}>
              © 2026 HalıSahaApp. Tüm hakları saklıdır.
            </div>
          </div>
        </footer>
      </section>
    </div>
  );
}

"use client";

import { useState, useEffect, useMemo, useCallback } from "react";
import Navbar from "@/frontend/components/common/Navbar";
import Link from "next/link";
import { Search, MapPin, Calendar, Users, ArrowRight, Star, Shield, Clock, ChevronRight, User, Droplets, Car, Utensils, Lightbulb, Trophy, Coffee, CreditCard, Headphones, BadgeCheck, Zap, LogIn, UserPlus, X } from "lucide-react";
import MapSection from "@/frontend/components/map/MapSection";
import Aurora from "@/frontend/components/ui/Aurora/Aurora";
import { useAuth } from "@/frontend/context/AuthContext";
import { getFieldsRealtime, FieldRecord } from "@/backend/services/fieldService";
import { getActiveMatchPostsRealtime, MatchPost } from "@/backend/services/matchPostService";
import { useScrollReveal } from "@/frontend/hooks/useScrollReveal";
import GradientText from "@/frontend/components/ui/GradientText/GradientText";
import AdminDashboardContent from "@/app/admin/dashboard/AdminDashboardContent";

const featuredFields = [
  { id: "1", name: "Kadıköy Merkez Halı Saha", address: "Zühtüpaşa, Kadıköy / İstanbul", rating: 4.8, reviews: 124, features: ["shower", "parking", "food", "light"], color: "from-emerald-700 to-teal-600" },
  { id: "2", name: "Beşiktaş Vadi Saha", address: "Vişnezade, Beşiktaş / İstanbul", rating: 4.5, reviews: 87, features: ["shower", "parking", "coffee", "trophy"], color: "from-green-700 to-emerald-500" },
  { id: "3", name: "Üsküdar Sahil Halı Saha", address: "Mimar Sinan, Üsküdar / İstanbul", rating: 4.2, reviews: 53, features: ["shower", "food", "light"], color: "from-emerald-700 to-green-600" },
];

// removed upcomingMatches hardcoded data

const quickActions = [
  { icon: Users, title: "Gruplar", subtitle: "Acilan mac gruplarini kesfet", color: "#2E7D32", href: "/groups", requireAuth: false },
  { icon: Users, title: "Maç Kur", subtitle: "Arkadaşlarınla maç organize et", color: "#1565C0", href: "/groups/create", requireAuth: false },
  { icon: Star, title: "Favorilerim", subtitle: "Favori saha ve oyuncuların", color: "#E65100", href: "/favorites", requireAuth: true },
  { icon: Calendar, title: "Randevularım", subtitle: "Rezervasyonlarını yönet", color: "#6A1B9A", href: "/profile", requireAuth: true },
];

const formatFirestoreDate = (dateVal: any) => {
  if (!dateVal) return "";
  if (typeof dateVal === "string") return dateVal;
  if (typeof dateVal === "number") return new Date(dateVal).toLocaleDateString("tr-TR");
  if (dateVal.seconds) return new Date(dateVal.seconds * 1000).toLocaleDateString("tr-TR");
  if (dateVal.toDate) return dateVal.toDate().toLocaleDateString("tr-TR");
  return String(dateVal);
};

const nearbyFields = [
  { name: "Saha 1", district: "İlçe", address: "Adres bilgisi gelecek" },
  { name: "Saha 2", district: "İlçe", address: "Adres bilgisi gelecek" },
  { name: "Saha 3", district: "İlçe", address: "Adres bilgisi gelecek" },
  { name: "Saha 4", district: "İlçe", address: "Adres bilgisi gelecek" },
  { name: "Saha 5", district: "İlçe", address: "Adres bilgisi gelecek" },
  { name: "Saha 6", district: "İlçe", address: "Adres bilgisi gelecek" },
];

export default function Home() {
  const [fieldSearch, setFieldSearch] = useState("");
  const { user, isAdmin, loading } = useAuth();
  const [realFields, setRealFields] = useState<FieldRecord[]>([]);
  const [matchPosts, setMatchPosts] = useState<MatchPost[]>([]);
  const [showAuthModal, setShowAuthModal] = useState(false);
  useScrollReveal();

  useEffect(() => {
    const unsubFields = getFieldsRealtime((fields) => {
      setRealFields(fields);
    });
    return () => unsubFields();
  }, []);

  useEffect(() => {
    let unsubPosts: (() => void) | undefined;
    if (user) {
      unsubPosts = getActiveMatchPostsRealtime((posts) => {
        setMatchPosts(posts);
      });
    } else {
      setMatchPosts([]);
    }
    return () => {
      if (unsubPosts) unsubPosts();
    };
  }, [user]);

  const filteredFields = useMemo(() => {
    const normalizedQuery = fieldSearch.trim().toLocaleLowerCase("tr-TR");
    if (!normalizedQuery) return realFields;

    return realFields.filter((field) =>
      [field.name, field.address]
        .join(" ")
        .toLocaleLowerCase("tr-TR")
        .includes(normalizedQuery)
    );
  }, [realFields, fieldSearch]);

  const sortedTopFields = useMemo(() => {
    return [...realFields]
      .sort((a, b) => ((b.averageRating as number) || 0) - ((a.averageRating as number) || 0))
      .slice(0, 2);
  }, [realFields]);

  const handleSearchChange = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    setFieldSearch(event.target.value);
  }, []);

  if (loading) {
    return (
      <div className="page-wrapper" style={{ minHeight: "100vh", display: "flex", flexDirection: "column" }}>
        <Navbar />
        <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <div style={{ textAlign: "center" }}>
            <div style={{ width: 40, height: 40, border: "3px solid #E8F5E9", borderTopColor: "#2E7D32", borderRadius: "50%", animation: "spin 1s linear infinite", margin: "0 auto 16px" }} />
            <p style={{ color: "#9CA3AF", fontWeight: 600 }}>Yükleniyor...</p>
          </div>
        </div>
        <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
      </div>
    );
  }

  return (
    <div className="page-wrapper">
      <Navbar />

      {/* Hero Section */}
      {/* Hero Section */}
      <section className="home-hero-section" style={{
        position: "relative",
        padding: "4rem 5% 3rem 5%", // Bıraktığımız padding
        color: "white",
        zIndex: 10,
      }}>
        <div
          aria-hidden="true"
          style={{
            position: "absolute",
            inset: 0,
            zIndex: 0,
            pointerEvents: "none",
            opacity: 1,
          }}
        >
          <Aurora
            colorStops={["#114B32", "#1A754E", "#49B37D"]}
            amplitude={0.55}
            blend={1}
            speed={0.6}
          />
        </div>

        <div
          aria-hidden="true"
          style={{
            position: "absolute",
            inset: 0,
            zIndex: 1,
            pointerEvents: "none",
            background: "linear-gradient(180deg, #114B32 0%, #1A754E 100%)",
          }}
        />

        {/* Hero İçerik */}
        {isAdmin ? (
          <div className="home-hero-content" style={{ position: "relative", zIndex: 2, height: "168px" }}></div>
        ) : (
          <div className="home-hero-content" style={{ textAlign: "center", maxWidth: 800, margin: "0 auto", position: "relative", zIndex: 2, paddingTop: "3rem", paddingBottom: "2rem" }}>
          <h1 className="home-hero-title" style={{ fontSize: "3.5rem", lineHeight: 1.2, marginBottom: "1rem", fontWeight: 700 }}>
            <GradientText
              colors={["#ffffff", "#4CAF50", "#1A754E", "#ffffff"]}
              animationSpeed={5}
              showBorder={false}
              className="inline-block"
            >
              Sahayı Bul, Ekibi Topla,<br />Maçı Başlat!
            </GradientText>
          </h1>
          <p className="home-hero-subtitle" style={{ fontSize: "1.1rem", marginBottom: "2rem", opacity: 0.9 }}>
            En yakın halı sahada anında randevu al veya takımınla maç organize et.
          </p>
          <div style={{ display: "flex", justifyContent: "center", gap: "1rem", flexWrap: "wrap", marginTop: "1rem" }}>
            <Link href="#map" className="brand-btn-glass solid-light">
              <MapPin size={18} /> Haritada Ara
            </Link>

            <Link href="/players" className="brand-btn-glass ghost-light" style={{ background: "rgba(255, 255, 255, 0.15)", border: "1px solid rgba(255, 255, 255, 0.4)" }}>
              <Search size={18} /> Oyuncu Ara
            </Link>

            {!user && (
              <Link href="/register" className="brand-btn-glass ghost-light">
                <User size={18} /> Hemen Üye Ol
              </Link>
            )}
          </div>
        </div>
        )}

        {/* Dalgalı Geçiş (Wave) — Subpixel gap oluşmasın diye kasıtlı olarak 2px içeri sokuldu (-118px) */}
        <div style={{ position: "absolute", bottom: "-118px", left: 0, width: "100%", lineHeight: 0, zIndex: 1, pointerEvents: "none" }}>
          <svg data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 120" preserveAspectRatio="none" style={{ display: "block", width: "calc(100% + 1.3px)", height: 120, overflow: "visible" }}>
            <defs>
              <filter id="wave-soft-shadow" x="-8%" y="-8%" width="116%" height="180%">
                <feGaussianBlur stdDeviation="7" />
              </filter>
            </defs>
            {/* Yumuşak gölge: ayrik ve asagi kaydirilmis katman, keskin cizgi olusturmaz */}
            <path d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z" fill="rgba(0,0,0,0.22)" transform="translate(0, 14)" filter="url(#wave-soft-shadow)" />
            {/* Temiz Üst Katman: Filtre olmadığı için üstteki ana alanla %100 aynı piksel renginde çizilir! */}
            <path d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z" fill="#1A754E" />
          </svg>
        </div>
      </section>

      {isAdmin ? (
        <AdminDashboardContent />
      ) : (
        <>
          {/* Glassmorphism Kartlar */}
          <section className="home-quick-actions" style={{
        display: "flex", justifyContent: "center", gap: "1.5rem",
        padding: "0 5%",
        marginTop: -30,
        position: "relative", zIndex: 10,
        flexWrap: "wrap",
      }}>
        {quickActions.map((qa, idx) => {
          const bgColors: Record<string, string> = {
            "#2E7D32": "#e8f5e9",
            "#1565C0": "#e3f2fd",
            "#E65100": "#fff3e0",
            "#6A1B9A": "#f3e5f5"
          };
          const delayClass = `reveal-delay-${idx + 1}` as string;
          const needsAuth = qa.requireAuth && !user;
          if (needsAuth) {
            return (
              <button
                key={qa.title}
                onClick={() => setShowAuthModal(true)}
                className={`interactive-glass-card reveal ${delayClass}`}
                style={{ textAlign: "left", width: 280, cursor: "pointer" }}
              >
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
              </button>
            );
          }
          return (
            <Link key={qa.title} href={qa.href} className={`interactive-glass-card reveal ${delayClass}`}>
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
      <section className="relative z-10 home-map-section reveal" style={{ padding: "2rem 5% 3rem 5%" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "1.5rem" }}>
          <h2 style={{ fontSize: "1.5rem", fontWeight: 700, color: "#111827", display: "flex", alignItems: "center", gap: 8 }}>
            <MapPin size={22} style={{ color: "#2E7D32" }} />
            <span className="hidden-mobile">Yakındaki Sahalar</span>
          </h2>
        </div>

        {/* Split layout */}
        <div className="home-map-split" style={{ display: "flex", gap: "1.5rem", alignItems: "stretch" }}>

          {/* LEFT: Map */}
          <div className="home-map-box" style={{ flex: "0 0 58%", borderRadius: 20, overflow: "hidden", boxShadow: "0 8px 32px rgba(0,0,0,0.10)", minHeight: 520 }}>
            <div id="map" style={{ height: "100%", minHeight: 520 }}>
              <MapSection />
            </div>
          </div>

          {/* RIGHT: Location Cards — outer wrapper scrolls, inner wrapper keeps comfortable spacing */}
          <div className="home-list-box" style={{ flex: 1, overflowY: "auto", overflowX: "hidden", maxHeight: 520, borderRadius: 8 }}>
            <div style={{ position: "sticky", top: 0, zIndex: 2, padding: "0 6px 12px 2px", background: "linear-gradient(180deg, rgba(246,248,246,0.98) 0%, rgba(246,248,246,0.88) 100%)", backdropFilter: "blur(12px)", WebkitBackdropFilter: "blur(12px)" }}>
              <label style={{ display: "flex", alignItems: "center", gap: 10, borderRadius: 20, padding: "0.95rem 1rem", background: "rgba(255,255,255,0.88)", border: "1px solid rgba(17,75,50,0.12)", boxShadow: "0 10px 30px rgba(0,0,0,0.05)" }}>
                <Search size={18} style={{ color: "#2E7D32", flexShrink: 0 }} />
                <input
                  type="search"
                  value={fieldSearch}
                  onChange={handleSearchChange}
                  placeholder="Saha ara"
                  aria-label="Saha ara"
                  style={{ width: "100%", border: "none", outline: "none", background: "transparent", color: "#111827", fontSize: "0.98rem", fontWeight: 500 }}
                />
              </label>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: "1rem", padding: "6px 6px 6px 2px" }}>
              {filteredFields.length === 0 ? (
                <div style={{ borderRadius: 24, padding: "1.5rem", background: "rgba(255,255,255,0.82)", border: "1px solid rgba(255,255,255,0.95)", boxShadow: "0 10px 30px rgba(0,0,0,0.05)", color: "#6b7280" }}>
                  Aramana uygun saha bulunamadi.
                </div>
              ) : filteredFields.map((saha, i) => (
                <Link
                  key={saha.id || i}
                  href={`/fields/${saha.id}`}
                  className={`location-card reveal reveal-delay-${Math.min(i + 1, 6)}`}
                  style={{ textDecoration: "none" }}>
                  <span style={{ fontSize: 11, fontWeight: 700, color: "#2E7D32", letterSpacing: "0.08em", textTransform: "uppercase" }}>
                    {typeof saha.address === 'string' ? saha.address.split(',')[0] : "İlçe"}
                  </span>
                  <span style={{ fontSize: "1.05rem", fontWeight: 700, color: "#111827" }}>{saha.name as string}</span>
                  <span style={{ fontSize: "0.85rem", color: "#6b7280", display: "flex", alignItems: "center", gap: 4 }}>
                    <MapPin size={12} /> {saha.address as string}
                  </span>
                </Link>
              ))}
            </div>
          </div>

        </div>
      </section>



      {/* --- Öne Çıkan Sahalar --- */}
      <div className="relative z-10" style={{ padding: "48px 0 24px 0" }}>
        <div className="content-container">
          <div className="section-header">
            <h2 className="section-title">
              <Star size={18} style={{ color: "#F59E0B" }} /> Öne Çıkan Sahalar
            </h2>
            <Link href="#map" style={{ fontSize: "14px", fontWeight: 600, color: "#2E7D32", textDecoration: "none", display: "flex", alignItems: "center", gap: 4 }}>
              Tümü <ChevronRight size={15} />
            </Link>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            {sortedTopFields.map((field, fi) => {
              const rating = (field.averageRating as number) || 0;
              const reviews = (field.totalReviews as number) || 0;
              const name = (field.name as string) || "İsimsiz Saha";
              return (
                <div key={field.id}
                  className={`match-glass-card reveal reveal-delay-${fi + 1}`}
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
                        {name[0]}
                      </div>
                      <div>
                        <p style={{ fontWeight: 600, fontSize: 13, color: "#374151" }}>Önerilen Saha</p>
                        <p style={{ fontSize: 12, color: "#9ca3af" }}>{reviews} değerlendirme</p>
                      </div>
                    </div>
                    <span style={{ background: "#2E7D32", color: "white", borderRadius: 20, padding: "4px 12px", fontSize: 12, fontWeight: 700, display: "inline-flex", alignItems: "center", gap: 4 }}>
                      <Star size={11} fill="white" /> {rating.toFixed(1)}
                    </span>
                  </div>
                  <p style={{ fontWeight: 700, fontSize: 15, color: "#111827", marginBottom: 8 }}>{name}</p>
                  <div style={{ display: "flex", gap: 16, color: "#9ca3af", fontSize: 12, marginBottom: 12, flexWrap: "wrap" }}>
                    <span style={{ display: "inline-flex", alignItems: "center", gap: 4 }}><MapPin size={12} /> {field.address as string}</span>
                    <span style={{ display: "inline-flex", alignItems: "center", gap: 4 }}><Star size={12} /> {reviews} yorum</span>
                  </div>
                  {/* Progress bar */}
                  <div style={{ marginBottom: 6 }}>
                    <div style={{ background: "#f0f0f0", borderRadius: 4, height: 6 }}>
                      <div style={{ background: "#2E7D32", height: 6, borderRadius: 4, width: `${(rating / 5) * 100}%` }} />
                    </div>
                    <div style={{ display: "flex", justifyContent: "space-between", marginTop: 4, fontSize: 12 }}>
                      <span style={{ color: "#9ca3af" }}>Puan: {rating.toFixed(1)}/5</span>
                      <span style={{ color: "#2E7D32", fontWeight: 700 }}>{reviews} yorum</span>
                    </div>
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 12 }}>
                    <span style={{ fontSize: 12, color: "#9ca3af" }}></span>
                    <Link href={`/fields/${field.id}`}
                      className="katil-btn"
                      style={{ background: "#E8F5E9", color: "#2E7D32", borderRadius: 8, padding: "6px 16px", fontSize: 13, fontWeight: 700, textDecoration: "none" }}>
                      İncele
                    </Link>
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      </div>
      </>
      )}

      {/* Aurora Background Wrapping from Trust Row to Footer */}
      <section className="home-aurora-section home-bottom-aurora relative overflow-hidden" style={{ marginTop: "-880px", paddingTop: "880px" }}>
        {/* Ortak Arka Plan: Aurora — ters çevrilmiş, aşağıdan yukarı bakar */}
        <div className="aurora-bg-layer" style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", zIndex: 0, opacity: 1, transform: "scaleY(-1)", backgroundColor: "transparent" }}>
          <Aurora
            colorStops={["#114B32", "#2E7D32", "#4CAF50"]}
            amplitude={1.0}
            blend={0.8}
          />
        </div>

        {/* --- Güvenli Ödeme Kartları (Trust Row) --- */}
        <div className="relative z-10" style={{ padding: "48px 0 16px 0" }}>
          <div className="content-container">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {[
                { icon: CreditCard, color: "#2E7D32", bg: "#e8f5e9", title: "Güvenli Ödeme", desc: "256-bit SSL şifreli, güvenli altyapı." },
                { icon: Clock, color: "#1565C0", bg: "#e3f2fd", title: "7/24 Destek", desc: "Her zaman yanınızdayız, anında çözüm." },
                { icon: BadgeCheck, color: "#E65100", bg: "#fff3e0", title: "Doğrulanmış Sahalar", desc: "Tüm sahalar yerinde ziyaret edilerek onaylandı." },
              ].map((item, ti) => {
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
                    className={`hover:-translate-y-1 hover:shadow-xl transition-all duration-300 reveal reveal-delay-${ti + 1}`}
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
        {!user && (
          <div className="relative py-16 px-4" style={{ zIndex: 1 }}>
            <div className="content-container text-center relative" style={{ display: "flex", justifyContent: "center" }}>
              <div className="home-cta-card reveal" style={{
                background: "rgba(255, 255, 255, 0.8)",
                marginBottom: "48px",
                backdropFilter: "blur(20px)",
                WebkitBackdropFilter: "blur(20px)",
                border: "1px solid rgba(255, 255, 255, 1)",
                borderRadius: "30px",
                padding: "48px 56px",
                boxShadow: "0 10px 40px rgba(0,0,0,0.06)",
                width: "100%",
                alignItems: "center",
                display: "flex",
                flexDirection: "column",
              }}>
                <div style={{ display: "flex", justifyContent: "center", marginBottom: 16, color: "#2E7D32" }}><Zap size={48} strokeWidth={1.4} /></div>
                <h2 className="text-4xl font-black mb-3 tracking-tight home-cta-title" style={{ color: "#1a1a1a" }}>Hemen Başla, Ücretsiz</h2>
                <p className="mb-12 text-lg home-cta-desc" style={{ color: "#666" }}>
                  Binlerce kullanıcıyla saha kirasında zaman ve para kaybetme.
                </p>
                <Link
                  href="/register"
                  style={{
                    display: "inline-flex", alignItems: "center", gap: 8,
                    color: "#2E7D32",
                    padding: "16px 36px", borderRadius: "16px",
                    fontWeight: 800, fontSize: 16,
                    textDecoration: "none",
                  }}
                  className="cta-register-btn"
                >
                  Kayıt Ol <ArrowRight size={20} />
                </Link>
              </div>
            </div>
          </div>
        )}

        {/* --- Footer İçeriği --- */}
        <footer className="relative pb-8 px-4" style={{ color: "rgba(255,255,255,0.9)", zIndex: 1, borderTop: "1px solid rgba(255,255,255,0.12)" }}>
          <div className="content-container">
            <div style={{ padding: "32px 0 32px 0", display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 16 }}>
              <p style={{ fontSize: 16, color: "rgba(255,255,255,0.9)", fontWeight: 500, letterSpacing: "0.2px", margin: 0 }}>Türkiye&apos;nin halısaha rezervasyon platformu.</p>

              {/* Store Badges */}
              <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
                {/* Google Play */}
                <a href="#" style={{ display: "flex", alignItems: "center", gap: 10, padding: "8px 16px", borderRadius: 12, background: "rgba(0,0,0,0.35)", border: "1px solid rgba(255,255,255,0.18)", textDecoration: "none", color: "white", backdropFilter: "blur(8px)" }}>
                  <svg width="20" height="22" viewBox="0 0 20 22" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M0.978516 0.399902C0.632812 0.766113 0.427734 1.33301 0.427734 2.06592V19.9341C0.427734 20.667 0.632812 21.2339 0.978516 21.6001L1.06348 21.6826L11.1865 11.5596V11.3228V11.086L1.06348 0.963867L0.978516 0.399902Z" fill="url(#gg1)" />
                    <path d="M14.4883 14.8721L11.1875 11.5596V11.3228V11.086L14.4883 7.77344L14.5957 7.83887L18.5107 10.0938C19.6162 10.7197 19.6162 11.7373 18.5107 12.3633L14.5957 14.6182L14.4883 14.8721Z" fill="url(#gg2)" />
                    <path d="M14.5957 14.6182L11.1875 11.21L0.978516 21.6001C1.35059 21.9951 1.97168 22.043 2.66699 21.6475L14.5957 14.6182Z" fill="url(#gg3)" />
                    <path d="M14.5957 7.83887L2.66699 0.809571C1.97168 0.414063 1.35059 0.461914 0.978516 0.856934L11.1875 11.2578L14.5957 7.83887Z" fill="url(#gg4)" />
                    <defs>
                      <linearGradient id="gg1" x1="10.3672" y1="1.29492" x2="-4.08301" y2="15.7451" gradientUnits="userSpaceOnUse"><stop stopColor="#00A0FF" /><stop offset="0.0066" stopColor="#00A1FF" /><stop offset="0.2601" stopColor="#00BEFF" /><stop offset="0.5122" stopColor="#00D2FF" /><stop offset="0.7604" stopColor="#00DFFF" /><stop offset="1" stopColor="#00E3FF" /></linearGradient>
                      <linearGradient id="gg2" x1="19.8262" y1="11.3228" x2="0.175781" y2="11.3228" gradientUnits="userSpaceOnUse"><stop stopColor="#FFE000" /><stop offset="0.4087" stopColor="#FFBD00" /><stop offset="0.7754" stopColor="#FFA500" /><stop offset="1" stopColor="#FF9C00" /></linearGradient>
                      <linearGradient id="gg3" x1="12.8262" y1="13.208" x2="-4.84277" y2="30.8779" gradientUnits="userSpaceOnUse"><stop stopColor="#FF3A44" /><stop offset="1" stopColor="#C31162" /></linearGradient>
                      <linearGradient id="gg4" x1="-1.97363" y1="-5.63477" x2="7.42871" y2="3.7666" gradientUnits="userSpaceOnUse"><stop stopColor="#32A071" /><stop offset="0.0685" stopColor="#2DA771" /><stop offset="0.4762" stopColor="#15CF74" /><stop offset="0.8009" stopColor="#06E775" /><stop offset="1" stopColor="#00F076" /></linearGradient>
                    </defs>
                  </svg>
                  <div>
                    <p style={{ fontSize: 9, margin: 0, opacity: 0.75, lineHeight: 1 }}>GET IT ON</p>
                    <p style={{ fontSize: 13, fontWeight: 700, margin: 0, lineHeight: 1.3 }}>Google Play</p>
                  </div>
                </a>

                {/* App Store */}
                <a href="#" style={{ display: "flex", alignItems: "center", gap: 10, padding: "8px 16px", borderRadius: 12, background: "rgba(0,0,0,0.35)", border: "1px solid rgba(255,255,255,0.18)", textDecoration: "none", color: "white", backdropFilter: "blur(8px)" }}>
                  <svg width="18" height="22" viewBox="-6 -3 27 30" fill="white" xmlns="http://www.w3.org/2000/svg">
                    <path d="M14.9902 11.6729C14.9795 9.60547 16.041 8.05762 18.1816 6.91504C16.9805 5.19531 15.1504 4.25098 12.7227 4.08594C10.4316 3.92676 7.93164 5.39941 7.01758 5.39941C6.04883 5.39941 3.85449 4.14648 2.08496 4.14648C-1.56543 4.20703 -5.5 7.02832 -5.5 12.7666C-5.5 14.4316 -5.19434 16.1504 -4.58301 17.9229C-3.76074 20.2676 -0.541992 26.1592 2.81348 26.0537C4.45215 26.0107 5.60059 24.9258 7.74023 24.9258C9.81934 24.9258 10.8848 26.0537 12.7227 26.0537C16.1064 26.0059 19.0234 20.6768 19.7969 18.3252C15.6514 16.3682 14.9902 11.7871 14.9902 11.6729ZM11.3301 1.89746C13.0752 -0.151367 12.917 -2.02344 12.8652 -2.67285C11.3223 -2.58301 9.53906 -1.64453 8.52441 -0.507813C7.41016 0.722656 6.75391 2.2334 6.89355 3.99121C8.56348 4.11816 10.0859 3.27344 11.3301 1.89746Z" />
                  </svg>
                  <div>
                    <p style={{ fontSize: 9, margin: 0, opacity: 0.75, lineHeight: 1 }}>Download on the</p>
                    <p style={{ fontSize: 13, fontWeight: 700, margin: 0, lineHeight: 1.3 }}>App Store</p>
                  </div>
                </a>
              </div>
            </div>

            <div style={{ borderTop: "1px solid rgba(255,255,255,0.12)", paddingTop: "24px", textAlign: "center", color: "rgba(255,255,255,0.68)", fontSize: 13 }}>
              © 2026 ALO Halısaha. Tüm hakları saklıdır.
            </div>
          </div>
        </footer>
      </section>

      {/* Auth Modal */}
      {showAuthModal && (
        <div
          onClick={() => setShowAuthModal(false)}
          style={{
            position: "fixed", inset: 0, zIndex: 1000,
            background: "rgba(0,0,0,0.55)",
            backdropFilter: "blur(8px)",
            WebkitBackdropFilter: "blur(8px)",
            display: "flex", alignItems: "center", justifyContent: "center",
            padding: 20,
          }}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              background: "rgba(255,255,255,0.97)",
              borderRadius: 28,
              padding: "40px 36px",
              maxWidth: 420,
              width: "100%",
              boxShadow: "0 32px 80px rgba(0,0,0,0.2)",
              border: "1px solid rgba(255,255,255,1)",
              textAlign: "center",
              position: "relative",
            }}
          >
            <button
              onClick={() => setShowAuthModal(false)}
              style={{ position: "absolute", top: 16, right: 16, background: "#f3f4f6", border: "none", borderRadius: "50%", width: 32, height: 32, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "#6b7280" }}
            >
              <X size={16} />
            </button>

            <div style={{ width: 72, height: 72, borderRadius: 20, background: "linear-gradient(135deg, #114B32, #1A754E)", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 20px" }}>
              <LogIn size={32} style={{ color: "white" }} />
            </div>

            <h2 style={{ fontSize: 24, fontWeight: 800, color: "#111827", marginBottom: 8 }}>
              Devam etmek için giriş yap
            </h2>
            <p style={{ fontSize: 15, color: "#6b7280", lineHeight: 1.6, marginBottom: 28 }}>
              Bu özelliği kullanmak için hesabınıza giriş yapmanız gerekiyor. Hesabınız yoksa ücretsiz kayıt olabilirsiniz.
            </p>

            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              <Link
                href="/login"
                style={{
                  display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
                  background: "linear-gradient(135deg, #114B32, #1A754E)",
                  color: "white", textDecoration: "none",
                  padding: "14px 24px", borderRadius: 14,
                  fontWeight: 700, fontSize: 15,
                  boxShadow: "0 4px 16px rgba(17,75,50,0.3)",
                }}
              >
                <LogIn size={18} /> Giriş Yap
              </Link>
              <Link
                href="/register"
                style={{
                  display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
                  background: "#f3f4f6",
                  color: "#111827", textDecoration: "none",
                  padding: "14px 24px", borderRadius: 14,
                  fontWeight: 700, fontSize: 15,
                }}
              >
                <UserPlus size={18} /> Ücretsiz Kayıt Ol
              </Link>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}

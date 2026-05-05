"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/frontend/context/AuthContext";
import { auth, db } from "@/database/firebase";
import { signOut } from "firebase/auth";
import { collection, onSnapshot, query, where } from "firebase/firestore";
import { toast } from "react-hot-toast";
import { LogOut, User, Menu, X } from "lucide-react";

const Navbar = () => {
  const { user, loading, isAdmin } = useAuth();
  const [scrolled, setScrolled] = useState(false);
  const [isDemo, setIsDemo] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 60);
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  useEffect(() => {
    if (!user || !isAdmin) {
      setIsDemo(false);
      return;
    }
    const q = query(collection(db, "football_fields"), where("ownerId", "==", user.uid));
    const unsub = onSnapshot(q, (snap) => {
      setIsDemo(snap.empty);
    });
    return () => unsub();
  }, [user, isAdmin]);

  useEffect(() => {
    setMobileMenuOpen(false);
  }, [pathname]);

  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth > 768) {
        setMobileMenuOpen(false);
      }
    };

    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  const handleLogout = async () => {
    try {
      await signOut(auth);
      toast.success("Başarıyla çıkış yapıldı.");
    } catch {
      toast.error("Çıkış yapılırken bir hata oluştu.");
    }
  };

  return (
    <nav style={{
      position: "fixed", top: 0, left: 0, right: 0, zIndex: 50,
      transition: "all 0.4s ease",
      background: scrolled ? "rgba(255,255,255,0.95)" : "transparent",
      backdropFilter: scrolled ? "blur(20px)" : "none",
      WebkitBackdropFilter: scrolled ? "blur(20px)" : "none",
      borderBottom: scrolled ? "1px solid rgba(0,0,0,0.06)" : "none",
      boxShadow: scrolled ? "0 4px 20px rgba(0,0,0,0.06)" : "none",
    }}>
      <div style={{ maxWidth: 1200, margin: "0 auto", padding: "0 16px" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", height: 64 }}>

          {/* Logo */}
          <Link href="/" style={{
            textDecoration: "none", display: "flex", alignItems: "center", gap: 10,
            fontSize: "1.5rem", fontWeight: 700,
            color: scrolled ? "#111827" : "white",
            transition: "color 0.4s",
          }}>
            <span></span> HalıSahaApp
          </Link>

          {/* Desktop Nav Links */}
          <div className="hidden-mobile" style={{ display: "flex", alignItems: "center", gap: "2rem" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              {isDemo && pathname.startsWith("/admin") && (
                <span style={{ fontSize: 11, color: "#92400E", background: "#FEF3C7", border: "1px solid #FCD34D", padding: "4px 8px", borderRadius: 12, fontWeight: 700 }}>
                  Demo
                </span>
              )}
              <Link href="/" className="nav-text-link" style={{ color: scrolled ? "#374151" : "white" }}>
                Ana Sayfa
              </Link>
            </div>

            {!loading && (
              <>
                {user ? (
                  <>
                    <Link href={isAdmin ? "/admin/dashboard" : "/profile"} className="nav-text-link" style={{ color: scrolled ? "#374151" : "white" }}>
                      <User size={15} /> {isAdmin ? "Panelim" : "Profilim"}
                    </Link>
                    <button onClick={handleLogout} style={{
                      color: scrolled ? "#dc2626" : "rgba(255,200,200,1)",
                      background: scrolled ? "#fef2f2" : "transparent",
                      border: "none", fontWeight: 500, fontSize: 14,
                      cursor: "pointer", display: "flex", alignItems: "center", gap: 6,
                      transition: "all 0.3s",
                    }}>
                      <LogOut size={15} /> Çıkış
                    </button>
                  </>
                ) : (
                  <>
                    <Link href="/login" className="nav-text-link" style={{ color: scrolled ? "#374151" : "white" }}>
                      Giriş Yap
                    </Link>
                    <Link href="/register" style={{
                      color: "white",
                      textDecoration: "none", fontWeight: 700, fontSize: 14,
                      padding: "0.6rem 1.5rem",
                      borderRadius: 25,
                      display: "inline-flex", alignItems: "center",
                      background: scrolled ? "#114B32" : "rgba(255,255,255,0.18)",
                      border: scrolled ? "1px solid #114B32" : "1px solid rgba(255,255,255,0.4)",
                      backdropFilter: scrolled ? "none" : "blur(10px)",
                      WebkitBackdropFilter: scrolled ? "none" : "blur(10px)",
                      boxShadow: scrolled ? "0 4px 15px rgba(17,75,50,0.2)" : "none",
                      transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)",
                    }} className="brand-btn-glass">
                      Kayıt Ol
                    </Link>
                  </>
                )}
              </>
            )}
          </div>

          <button
            type="button"
            className="show-mobile-only"
            onClick={() => setMobileMenuOpen((prev) => !prev)}
            aria-label={mobileMenuOpen ? "Menüyü kapat" : "Menüyü aç"}
            aria-expanded={mobileMenuOpen}
            style={{
              width: 40,
              height: 40,
              borderRadius: 12,
              border: "1px solid rgba(255,255,255,0.45)",
              background: scrolled ? "rgba(17,24,39,0.06)" : "rgba(255,255,255,0.14)",
              color: scrolled ? "#111827" : "white",
              alignItems: "center",
              justifyContent: "center",
              cursor: "pointer",
            }}
          >
            {mobileMenuOpen ? <X size={18} /> : <Menu size={18} />}
          </button>
        </div>

        {mobileMenuOpen && (
          <div
            className="show-mobile-only-block"
            style={{
              marginBottom: 10,
              padding: 14,
              borderRadius: 16,
              background: "rgba(255,255,255,0.94)",
              border: "1px solid rgba(255,255,255,1)",
              boxShadow: "0 12px 36px rgba(0,0,0,0.08)",
            }}
          >
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                {isDemo && pathname.startsWith("/admin") && (
                  <span style={{ fontSize: 11, color: "#92400E", background: "#FEF3C7", border: "1px solid #FCD34D", padding: "4px 8px", borderRadius: 12, fontWeight: 700 }}>
                    Demo
                  </span>
                )}
                <Link href="/" className="nav-text-link" style={{ color: "#374151" }}>
                  Ana Sayfa
                </Link>
              </div>

              {!loading && (
                <>
                  {user ? (
                    <>
                      <Link href={isAdmin ? "/admin/dashboard" : "/profile"} className="nav-text-link" style={{ color: "#374151" }}>
                        <User size={15} /> {isAdmin ? "Panelim" : "Profilim"}
                      </Link>
                      <button
                        onClick={handleLogout}
                        style={{
                          color: "#dc2626",
                          background: "#fef2f2",
                          border: "none",
                          fontWeight: 600,
                          fontSize: 14,
                          cursor: "pointer",
                          display: "flex",
                          alignItems: "center",
                          gap: 6,
                          padding: "10px 12px",
                          borderRadius: 10,
                          width: "fit-content",
                        }}
                      >
                        <LogOut size={15} /> Çıkış
                      </button>
                    </>
                  ) : (
                    <>
                      <Link href="/login" className="nav-text-link" style={{ color: "#374151" }}>
                        Giriş Yap
                      </Link>
                      <Link
                        href="/register"
                        style={{
                          color: "white",
                          textDecoration: "none",
                          fontWeight: 700,
                          fontSize: 14,
                          padding: "0.65rem 1.2rem",
                          borderRadius: 25,
                          display: "inline-flex",
                          alignItems: "center",
                          justifyContent: "center",
                          background: "#114B32",
                          border: "1px solid #114B32",
                          width: "100%",
                        }}
                      >
                        Kayıt Ol
                      </Link>
                    </>
                  )}
                </>
              )}
            </div>
          </div>
        )}
      </div>
    </nav>
  );
};

export default Navbar;

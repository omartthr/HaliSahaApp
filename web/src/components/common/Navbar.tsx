"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { useAuth } from "@/context/AuthContext";
import { auth } from "@/lib/firebase";
import { signOut } from "firebase/auth";
import { toast } from "react-hot-toast";
import { LogOut, User } from "lucide-react";

const Navbar = () => {
  const { user, loading } = useAuth();
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 60);
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
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
      <div style={{ maxWidth: 1200, margin: "0 auto", padding: "0%" }}>
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

          {/* Nav Links */}
          <div style={{ display: "flex", alignItems: "center", gap: "2rem" }}>
            <Link href="/" className="nav-text-link" style={{ color: scrolled ? "#374151" : "white" }}>
              Ana Sayfa
            </Link>
            <Link href="/groups" className="nav-text-link" style={{ color: scrolled ? "#374151" : "white" }}>
              Gruplar
            </Link>

            {!loading && (
              <>
                {user ? (
                  <>
                    <Link href="/profile" className="nav-text-link" style={{ color: scrolled ? "#374151" : "white" }}>
                      <User size={15} /> Profilim
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
        </div>
      </div>
    </nav>
  );
};

export default Navbar;

"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { toast } from "react-hot-toast";
import { Mail, Lock, ArrowRight } from "lucide-react";

const LoginPage = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await signInWithEmailAndPassword(auth, email, password);
      toast.success("Başarıyla giriş yapıldı!");
      router.push("/");
    } catch (error: any) {
      const msg = error.code === "auth/invalid-credential" ? "E-posta veya şifre hatalı." : "Giriş yapılamadı.";
      toast.error(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ minHeight: "100vh", background: "linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%)", display: "flex", flexDirection: "column" }}>
      {/* Top bar */}
      <div style={{ padding: "20px 24px" }}>
        <Link href="/" style={{ display: "inline-flex", alignItems: "center", gap: 8, textDecoration: "none" }}>
          <span style={{ fontSize: 18, fontWeight: 900, color: "#111827" }}>
            Halı<span style={{ color: "#2E7D32" }}>SahaApp</span>
          </span>
        </Link>
      </div>

      <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", padding: "20px 16px" }}>
        <div className="auth-card">
          {/* Header */}
          <div style={{ textAlign: "center", marginBottom: 32 }}>
            <div style={{ width: 64, height: 64, background: "#E8F5E9", borderRadius: 20, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 16px", fontSize: 28 }}>
              ⚽
            </div>
            <h1 style={{ fontSize: 26, fontWeight: 900, color: "#111827", marginBottom: 6 }}>Tekrar Hoş Geldin!</h1>
            <p style={{ color: "#9ca3af", fontSize: 15 }}>Devam etmek için giriş yapın.</p>
          </div>

          <form onSubmit={handleLogin} style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            <div>
              <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 6 }}>E-posta Adresi</label>
              <div style={{ position: "relative" }}>
                <Mail size={17} style={{ position: "absolute", left: 14, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                <input type="email" required value={email} onChange={e => setEmail(e.target.value)}
                  className="input-field" style={{ paddingLeft: 42 }} placeholder="ornek@mail.com" />
              </div>
            </div>

            <div>
              <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 6 }}>Şifre</label>
              <div style={{ position: "relative" }}>
                <Lock size={17} style={{ position: "absolute", left: 14, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                <input type="password" required value={password} onChange={e => setPassword(e.target.value)}
                  className="input-field" style={{ paddingLeft: 42 }} placeholder="••••••••" />
              </div>
            </div>

            <button type="submit" disabled={loading} className="btn-primary"
              style={{ marginTop: 8, padding: "14px", fontSize: 16, borderRadius: 14, opacity: loading ? 0.7 : 1, width: "100%" }}>
              {loading ? "Giriş Yapılıyor..." : (<>Giriş Yap <ArrowRight size={18} /></>)}
            </button>
          </form>

          {/* Divider */}
          <div style={{ display: "flex", alignItems: "center", gap: 12, margin: "24px 0" }}>
            <div style={{ flex: 1, height: 1, background: "#e5e7eb" }} />
            <span style={{ fontSize: 13, color: "#9ca3af", fontStyle: "italic" }}>veya</span>
            <div style={{ flex: 1, height: 1, background: "#e5e7eb" }} />
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 12, textAlign: "center" }}>
            <p style={{ fontSize: 14, color: "#6b7280" }}>
              Hesabınız yok mu?{" "}
              <Link href="/register" style={{ color: "#2E7D32", fontWeight: 700, textDecoration: "none" }}>Kayıt Ol</Link>
            </p>
            <Link href="/" style={{ fontSize: 14, color: "#9ca3af", textDecoration: "none" }}>
              Üye olmadan devam et
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;

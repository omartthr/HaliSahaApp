"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { loginWithEmailPassword, loginWithGoogle } from "@/backend/services/authService";
import { createUserProfile } from "@/backend/services/adminService";
import { getUserProfile } from "@/backend/services/userService";
import { toast } from "react-hot-toast";
import { Mail, Lock, ArrowRight, Shield } from "lucide-react";
import Aurora from "@/frontend/components/ui/Aurora/Aurora";
import GradientText from "@/frontend/components/ui/GradientText/GradientText";

const GoogleIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
    <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
    <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
    <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
    <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
  </svg>
);

const LoginPage = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await loginWithEmailPassword(email, password);
      toast.success("Başarıyla giriş yapıldı!");
      router.push("/");
    } catch (error: any) {
      const msg =
        error?.message === "admin_not_approved"
          ? "Hesabınız henüz onaylanmadı. Lütfen yönetici onayını bekleyin."
          : error?.code === "auth/invalid-credential"
          ? "E-posta veya şifre hatalı."
          : "Giriş yapılamadı.";
      toast.error(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleLogin = async () => {
    setLoading(true);
    try {
      const { user, admin, isNewUser } = await loginWithGoogle();
      
      const existingProfile = await getUserProfile(user.uid);
      if (!existingProfile && !admin) {
        // Fallback to providerData or email if displayName is missing
        const displayName = user.displayName || user.providerData?.[0]?.displayName || "";
        const emailName = user.email?.split('@')[0] || "kullanici";
        
        await createUserProfile(user.uid, {
          firstName: displayName ? displayName.split(' ')[0] : emailName,
          lastName: displayName ? displayName.split(' ').slice(1).join(' ') : "",
          username: emailName + Math.floor(Math.random() * 1000),
          email: user.email,
          userType: "player",
          createdAt: new Date().toISOString(),
        });
      }
      
      toast.success("Google ile başarıyla giriş yapıldı!");
      router.push("/");
    } catch (error: any) {
      if (error?.message === "admin_not_approved") {
        toast.error("Hesabınız henüz onaylanmadı. Lütfen yönetici onayını bekleyin.");
      } else {
        toast.error("Google ile giriş yapılamadı.");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="home-aurora-section" style={{ position: "fixed", inset: 0, background: "#f5f5f7", display: "flex", flexDirection: "column", overflow: "hidden" }}>
      <div className="aurora-bg-layer" style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", zIndex: 0, opacity: 1, transform: "scaleY(-1)", pointerEvents: "none" }}>
        <Aurora
          colorStops={["#114B32", "#2E7D32", "#4CAF50"]}
          amplitude={2.2}
          blend={0.7}
        />
      </div>

      {/* Top bar */}
      <div
        className="auth-topbar-dynamo"
        style={{
          position: "relative",
          zIndex: 10,
          margin: "6px 16px 0",
          padding: "10px 20px",
          borderRadius: 24,
          background: "rgba(255, 255, 255, 0.86)",
          backdropFilter: "blur(20px)",
          WebkitBackdropFilter: "blur(20px)",
          border: "1px solid rgba(255, 255, 255, 1)",
          boxShadow: "0 10px 40px rgba(0,0,0,0.04)",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: 16,
          flexWrap: "wrap",
        }}
      >
        <Link href="/" style={{ display: "inline-flex", alignItems: "center", gap: 8, textDecoration: "none" }}>
          <span style={{ fontSize: 18, fontWeight: 900, color: "#111827" }}>
            ALO <GradientText
                  colors={["#1A754E", "#4CAF50", "#065F46", "#1A754E"]}
                  animationSpeed={4}
                  showBorder={false}
                  className="inline-block"
                >
                  Halısaha
                </GradientText>
          </span>
        </Link>

        <div className="auth-topbar-links" style={{ display: "flex", alignItems: "center", gap: 28, marginLeft: "auto" }}>
          <Link href="/" className="auth-topbar-link" style={{ fontSize: 15, fontWeight: 700, color: "#374151", textDecoration: "none", padding: "6px 10px", borderRadius: 10 }}>
            Ana Sayfa
          </Link>
        </div>
      </div>

      <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", padding: "10px 16px", position: "relative", zIndex: 10, minHeight: 0 }}>
        <div className="auth-card auth-dynamo-glass" style={{ maxHeight: "100%", display: "flex", flexDirection: "column", justifyContent: "center" }}>
          {/* Header */}
          <div style={{ textAlign: "center", marginBottom: 16 }}>
            <div style={{ width: 40, height: 40, background: "#E8F5E9", borderRadius: 16, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 10px" }}>
              <Shield size={20} style={{ color: "#2E7D32" }} />
            </div>
            <h1 style={{ fontSize: 24, fontWeight: 900, color: "#111827", marginBottom: 4 }}>Tekrar Hoş Geldin!</h1>
            <p style={{ color: "#9ca3af", fontSize: 14 }}>Devam etmek için giriş yapın.</p>
          </div>

          <form onSubmit={handleLogin} style={{ display: "flex", flexDirection: "column", gap: 10 }}>
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
              style={{ marginTop: 4, padding: "12px", fontSize: 16, borderRadius: 14, opacity: loading ? 0.7 : 1, width: "100%" }}>
              {loading ? "Giriş Yapılıyor..." : (<>Giriş Yap <ArrowRight size={18} /></>)}
            </button>
          </form>

          <div style={{ display: "flex", alignItems: "center", gap: 12, margin: "16px 0" }}>
            <div style={{ flex: 1, height: 1, background: "#e5e7eb" }} />
            <span style={{ fontSize: 13, color: "#9ca3af", fontStyle: "italic" }}>veya</span>
            <div style={{ flex: 1, height: 1, background: "#e5e7eb" }} />
          </div>

          <button
            type="button"
            onClick={handleGoogleLogin}
            disabled={loading}
            style={{
              display: "flex", alignItems: "center", justifyContent: "center", gap: 12,
              background: "#fff", border: "1px solid #d1d5db", borderRadius: 14,
              padding: "10px", width: "100%", fontSize: 15, fontWeight: 600, color: "#374151",
              cursor: "pointer", marginBottom: 16, transition: "all 0.2s"
            }}
          >
            <GoogleIcon /> Google ile Devam Et
          </button>

          <div style={{ display: "flex", flexDirection: "column", gap: 8, textAlign: "center" }}>
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

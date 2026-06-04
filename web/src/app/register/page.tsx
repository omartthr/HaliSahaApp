"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createAdminProfile, createUserProfile } from "@/backend/services/adminService";
import { registerAuthUser, signOutCurrentUser, loginWithGoogle } from "@/backend/services/authService";
import { getUserProfile } from "@/backend/services/userService";
import { toast } from "react-hot-toast";
import { Mail, Lock, User, AtSign, ArrowRight, Check, Building2, Phone, FileText, AlertTriangle, Trophy, Warehouse, UserRound } from "lucide-react";
import Aurora from "@/frontend/components/ui/Aurora/Aurora";
import CustomSelect from "@/frontend/components/common/CustomSelect";
import GradientText from "@/frontend/components/ui/GradientText/GradientText";

const GoogleIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
    <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
    <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
    <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
    <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
  </svg>
);

const RegisterPage = () => {
  const [tab, setTab] = useState<"user" | "admin">("user");
  const [userForm, setUserForm] = useState({
    firstName: "", lastName: "", username: "", email: "", password: "", confirmPassword: "", position: "",
  });
  const [adminForm, setAdminForm] = useState({
    businessName: "", taxNumber: "", phone: "", email: "", password: "", confirmPassword: "",
  });
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleUserRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (userForm.password !== userForm.confirmPassword) return toast.error("Şifreler uyuşmuyor!");
    if (userForm.password.length < 6) return toast.error("Şifre en az 6 karakter olmalı.");
    setLoading(true);
    try {
      const user = await registerAuthUser(userForm.email, userForm.password);
      await createUserProfile(user.uid, {
        firstName: userForm.firstName,
        lastName: userForm.lastName,
        username: userForm.username,
        email: userForm.email,
        position: userForm.position,
        userType: "player",
        createdAt: new Date().toISOString(),
      });
      toast.success("Hesap başarıyla oluşturuldu!");
      router.push("/");
    } catch (error: any) {
      const msg = error.code === "auth/email-already-in-use" ? "Bu e-posta zaten kullanılıyor." : "Kayıt yapılamadı.";
      toast.error(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleAdminRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (adminForm.password !== adminForm.confirmPassword) return toast.error("Şifreler uyuşmuyor!");
    if (adminForm.password.length < 6) return toast.error("Şifre en az 6 karakter olmalı.");
    setLoading(true);
    try {
      const user = await registerAuthUser(adminForm.email, adminForm.password);
      await createUserProfile(user.uid, {
        firstName: adminForm.businessName,
        lastName: "Admin",
        email: adminForm.email,
        userType: "admin",
        createdAt: new Date().toISOString(),
      });
      
      await createAdminProfile(user.uid, {
        businessName: adminForm.businessName,
        taxNumber: adminForm.taxNumber,
        phone: adminForm.phone,
        email: adminForm.email,
        approvalStatus: "pending",
        createdAt: new Date().toISOString(),
      });
      toast.success("Kayıt talebiniz alındı! Yönetici onayı bekleniyor.");
      await signOutCurrentUser();
      router.push("/login");
    } catch (error: any) {
      const msg = error.code === "auth/email-already-in-use" ? "Bu e-posta zaten kullanılıyor." : "Kayıt yapılamadı.";
      toast.error(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleRegister = async () => {
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
      
      toast.success("Google ile başarıyla kayıt olundu!");
      router.push("/");
    } catch (error: any) {
      if (error?.message === "admin_not_approved") {
        toast.error("Hesabınız henüz onaylanmadı.");
      } else {
        toast.error("Google ile kayıt yapılamadı.");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleUserChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setUserForm({ ...userForm, [e.target.name]: e.target.value });
  };

  const handleAdminChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setAdminForm({ ...adminForm, [e.target.name]: e.target.value });
  };

  const perks = tab === "user"
    ? ["Ücretsiz kayıt", "Anında rezervasyon", "Maç organizasyonu"]
    : ["İşletme kaydı", "Saha yönetimi", "Rezervasyon takibi"];

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

      <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", padding: "6px 16px", position: "relative", zIndex: 10, minHeight: 0 }}>
        <div className="auth-card auth-dynamo-glass auth-register-wide" style={{ margin: "auto", maxWidth: 800, width: "100%", padding: "12px 20px", maxHeight: "100%", display: "flex", flexDirection: "column", justifyContent: "center" }}>
          {/* Header */}
          <div style={{ textAlign: "center", marginBottom: 8 }}>
            <div style={{ width: tab === "admin" ? 36 : 40, height: tab === "admin" ? 36 : 40, background: "#E8F5E9", borderRadius: 16, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 6px" }}>
              {tab === "user" ? <Trophy size={20} style={{ color: "#2E7D32" }} /> : <Warehouse size={18} style={{ color: "#2E7D32" }} />}
            </div>
            <h1 style={{ fontSize: 20, fontWeight: 900, color: "#111827", marginBottom: 0 }}>Hesap Oluştur</h1>
            <p style={{ color: "#9ca3af", fontSize: 13, lineHeight: 1.25 }}>
              {tab === "user" ? "Ücretsiz üye ol, hemen randevu al!" : "İşletmenizi kaydedin, sahanızı yönetin."}
            </p>
          </div>

          {/* Tab Switcher */}
          <div style={{ display: "flex", background: "#f0f4f8", borderRadius: 14, padding: 4, marginBottom: 8, gap: 4 }}>
            <button
              type="button"
              onClick={() => setTab("user")}
              style={{
                flex: 1, padding: "6px 0", borderRadius: 11, border: "none", cursor: "pointer",
                fontSize: 14, fontWeight: 700, transition: "all 0.2s",
                display: "flex", alignItems: "center", justifyContent: "center", gap: 6,
                background: tab === "user" ? "#fff" : "transparent",
                color: tab === "user" ? "#2E7D32" : "#6b7280",
                boxShadow: tab === "user" ? "0 2px 8px rgba(0,0,0,0.08)" : "none",
              }}
            >
              <UserRound size={15} /> Normal Kullanıcı
            </button>
            <button
              type="button"
              onClick={() => setTab("admin")}
              style={{
                flex: 1, padding: "6px 0", borderRadius: 11, border: "none", cursor: "pointer",
                fontSize: 14, fontWeight: 700, transition: "all 0.2s",
                display: "flex", alignItems: "center", justifyContent: "center", gap: 6,
                background: tab === "admin" ? "#fff" : "transparent",
                color: tab === "admin" ? "#2E7D32" : "#6b7280",
                boxShadow: tab === "admin" ? "0 2px 8px rgba(0,0,0,0.08)" : "none",
              }}
            >
              <Warehouse size={15} /> Admin / İşletme
            </button>
          </div>

          {/* Perks */}
          <div style={{ display: "flex", gap: 10, marginBottom: 8, flexWrap: "wrap", justifyContent: "center" }}>
            {perks.map(p => (
              <div key={p} style={{ display: "flex", alignItems: "center", gap: 6, background: "#E8F5E9", borderRadius: 20, padding: "3px 10px" }}>
                <Check size={13} style={{ color: "#2E7D32" }} />
                <span style={{ fontSize: 12, fontWeight: 600, color: "#2E7D32" }}>{p}</span>
              </div>
            ))}
          </div>

          {/* ───── NORMAL KULLANICI FORMU ───── */}
          {tab === "user" && (
            <form onSubmit={handleUserRegister} style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 2 }}>İsim</label>
                  <div style={{ position: "relative" }}>
                    <User size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="firstName" required value={userForm.firstName} onChange={handleUserChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14, height: 38 }} placeholder="Ahmet" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 2 }}>Soyisim</label>
                  <div style={{ position: "relative" }}>
                    <User size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="lastName" required value={userForm.lastName} onChange={handleUserChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14, height: 38 }} placeholder="Yılmaz" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 2 }}>Kullanıcı Adı</label>
                  <div style={{ position: "relative" }}>
                    <AtSign size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="username" required value={userForm.username} onChange={handleUserChange}
                      className="input-field" style={{ paddingLeft: 36, height: 38 }} placeholder="ahmet_123" />
                  </div>
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: 8 }}>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 2 }}>E-posta</label>
                  <div style={{ position: "relative" }}>
                    <Mail size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="email" type="email" required value={userForm.email} onChange={handleUserChange}
                      className="input-field" style={{ paddingLeft: 36, height: 38 }} placeholder="ahmet@example.com" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 2 }}>Mevki</label>
                  <CustomSelect 
                    value={userForm.position} 
                    onChange={(val) => setUserForm({...userForm, position: val})}
                    options={[
                      { value: "Kaleci", label: "Kaleci" },
                      { value: "Defans", label: "Defans" },
                      { value: "Orta Saha", label: "Orta Saha" },
                      { value: "Forvet", label: "Forvet" },
                    ]}
                  />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8 }}>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 2 }}>Şifre</label>
                  <div style={{ position: "relative" }}>
                    <Lock size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="password" type="password" required value={userForm.password} onChange={handleUserChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14, height: 38 }} placeholder="••••••" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 2 }}>Tekrar</label>
                  <div style={{ position: "relative" }}>
                    <Lock size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="confirmPassword" type="password" required value={userForm.confirmPassword} onChange={handleUserChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14, height: 38 }} placeholder="••••••" />
                  </div>
                </div>
              </div>

              <button type="submit" disabled={loading} className="btn-primary"
                style={{ marginTop: -2, padding: "8px", fontSize: 14, borderRadius: 12, opacity: loading ? 0.7 : 1, width: "100%" }}>
                {loading ? "Kayıt Yapılıyor..." : (<>Üye Ol <ArrowRight size={18} /></>)}
              </button>
              
              <div style={{ display: "flex", alignItems: "center", gap: 12, margin: "4px 0" }}>
                <div style={{ flex: 1, height: 1, background: "#e5e7eb" }} />
                <span style={{ fontSize: 13, color: "#9ca3af", fontStyle: "italic" }}>veya</span>
                <div style={{ flex: 1, height: 1, background: "#e5e7eb" }} />
              </div>

              <button
                type="button"
                onClick={handleGoogleRegister}
                disabled={loading}
                style={{
                  display: "flex", alignItems: "center", justifyContent: "center", gap: 12,
                  background: "#fff", border: "1px solid #d1d5db", borderRadius: 12,
                  padding: "8px", width: "100%", fontSize: 14, fontWeight: 600, color: "#374151",
                  cursor: "pointer", transition: "all 0.2s"
                }}
              >
                <GoogleIcon /> Google ile Kayıt Ol
              </button>
            </form>
          )}

          {/* ───── ADMİN / İŞLETME FORMU ───── */}
          {tab === "admin" && (
            <form onSubmit={handleAdminRegister} style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              <div style={{ display: "grid", gridTemplateColumns: "1.5fr 1fr 1fr", gap: 8 }}>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 2 }}>İşletme Adı</label>
                  <div style={{ position: "relative" }}>
                    <Building2 size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="businessName" required value={adminForm.businessName} onChange={handleAdminChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14, height: 38 }} placeholder="Örnek Halı Saha" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 2 }}>Vergi No / Belge</label>
                  <div style={{ position: "relative" }}>
                    <FileText size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="taxNumber" required value={adminForm.taxNumber} onChange={handleAdminChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14, height: 38 }} placeholder="1234567890" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 2 }}>Telefon</label>
                  <div style={{ position: "relative" }}>
                    <Phone size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="phone" required value={adminForm.phone} onChange={handleAdminChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14, height: 38 }} placeholder="05xx ..." />
                  </div>
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1.5fr 1fr 1fr", gap: 8 }}>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 2 }}>İşletme E-posta</label>
                  <div style={{ position: "relative" }}>
                    <Mail size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="email" type="email" required value={adminForm.email} onChange={handleAdminChange}
                      className="input-field" style={{ paddingLeft: 36, height: 38 }} placeholder="isletme@example.com" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 2 }}>Şifre</label>
                  <div style={{ position: "relative" }}>
                    <Lock size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="password" type="password" required value={adminForm.password} onChange={handleAdminChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14, height: 38 }} placeholder="••••••" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 2 }}>Tekrar</label>
                  <div style={{ position: "relative" }}>
                    <Lock size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="confirmPassword" type="password" required value={adminForm.confirmPassword} onChange={handleAdminChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14, height: 38 }} placeholder="••••••" />
                  </div>
                </div>
              </div>

              <div style={{ background: "#FFF8E1", border: "1px solid #FFE082", borderRadius: 10, padding: "8px 12px", fontSize: 11, color: "#B45309", fontWeight: 600, lineHeight: 1.2, display: "flex", alignItems: "center", gap: 6 }}>
                <AlertTriangle size={13} /> Admin kaydı yönetici onayına tabidir. Onaylandıktan sonra giriş yapabilirsiniz.
              </div>

              <button type="submit" disabled={loading} className="btn-primary"
                style={{ marginTop: -2, padding: "8px", fontSize: 14, borderRadius: 12, opacity: loading ? 0.7 : 1, width: "100%" }}>
                {loading ? "Kayıt Yapılıyor..." : (<>Başvuru Gönder <ArrowRight size={18} /></>)}
              </button>
            </form>
          )}

          <div style={{ marginTop: tab === "admin" ? 6 : 8, textAlign: "center" }}>
            <p style={{ fontSize: 14, color: "#6b7280" }}>
              Zaten hesabınız var mı?{" "}
              <Link href="/login" style={{ color: "#2E7D32", fontWeight: 700, textDecoration: "none" }}>Giriş Yap</Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RegisterPage;

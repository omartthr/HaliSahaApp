"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createAdminProfile, createUserProfile } from "@/backend/services/adminService";
import { registerAuthUser, signOutCurrentUser } from "@/backend/services/authService";
import { toast } from "react-hot-toast";
import { Mail, Lock, User, AtSign, ArrowRight, Check, Building2, Phone, FileText } from "lucide-react";
import Aurora from "@/frontend/components/ui/Aurora/Aurora";

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
        role: "user",
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
      await createAdminProfile(user.uid, {
        businessName: adminForm.businessName,
        taxNumber: adminForm.taxNumber,
        phone: adminForm.phone,
        email: adminForm.email,
        role: "admin",
        status: "pending",
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
    <div className="home-aurora-section" style={{ height: "100vh", background: "#f5f5f7", display: "flex", flexDirection: "column", position: "relative", overflow: "hidden" }}>
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
          margin: "12px 16px 0",
          padding: "14px 28px",
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
            Halı<span style={{ color: "#2E7D32" }}>SahaApp</span>
          </span>
        </Link>

        <div className="auth-topbar-links" style={{ display: "flex", alignItems: "center", gap: 28, marginLeft: "auto" }}>
          <Link href="/" className="auth-topbar-link" style={{ fontSize: 15, fontWeight: 700, color: "#374151", textDecoration: "none", padding: "6px 10px", borderRadius: 10 }}>
            Ana Sayfa
          </Link>
          <Link href="/groups" className="auth-topbar-link" style={{ fontSize: 15, fontWeight: 700, color: "#374151", textDecoration: "none", padding: "6px 10px", borderRadius: 10 }}>
            Gruplar
          </Link>
        </div>
      </div>

      <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", padding: "6px 16px 10px", position: "relative", zIndex: 10 }}>
        <div className="auth-card auth-dynamo-glass auth-register-wide">
          {/* Header */}
          <div style={{ textAlign: "center", marginBottom: tab === "admin" ? 10 : 16 }}>
            <div style={{ width: tab === "admin" ? 56 : 64, height: tab === "admin" ? 56 : 64, background: "#E8F5E9", borderRadius: 20, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 10px", fontSize: tab === "admin" ? 24 : 28 }}>
              {tab === "user" ? "🏆" : "🏟️"}
            </div>
            <h1 style={{ fontSize: 26, fontWeight: 900, color: "#111827", marginBottom: 6 }}>Hesap Oluştur</h1>
            <p style={{ color: "#9ca3af", fontSize: 15, lineHeight: 1.25 }}>
              {tab === "user" ? "Ücretsiz üye ol, hemen randevu al!" : "İşletmenizi kaydedin, sahanızı yönetin."}
            </p>
          </div>

          {/* Tab Switcher */}
          <div style={{ display: "flex", background: "#f0f4f8", borderRadius: 14, padding: 4, marginBottom: 16, gap: 4 }}>
            <button
              type="button"
              onClick={() => setTab("user")}
              style={{
                flex: 1, padding: "9px 0", borderRadius: 11, border: "none", cursor: "pointer",
                fontSize: 14, fontWeight: 700, transition: "all 0.2s",
                background: tab === "user" ? "#fff" : "transparent",
                color: tab === "user" ? "#2E7D32" : "#6b7280",
                boxShadow: tab === "user" ? "0 2px 8px rgba(0,0,0,0.08)" : "none",
              }}
            >
              👤 Normal Kullanıcı
            </button>
            <button
              type="button"
              onClick={() => setTab("admin")}
              style={{
                flex: 1, padding: "9px 0", borderRadius: 11, border: "none", cursor: "pointer",
                fontSize: 14, fontWeight: 700, transition: "all 0.2s",
                background: tab === "admin" ? "#fff" : "transparent",
                color: tab === "admin" ? "#2E7D32" : "#6b7280",
                boxShadow: tab === "admin" ? "0 2px 8px rgba(0,0,0,0.08)" : "none",
              }}
            >
              🏟️ Admin / İşletme
            </button>
          </div>

          {/* Perks */}
          <div style={{ display: "flex", gap: 10, marginBottom: tab === "admin" ? 10 : 16, flexWrap: "wrap" }}>
            {perks.map(p => (
              <div key={p} style={{ display: "flex", alignItems: "center", gap: 6, background: "#E8F5E9", borderRadius: 20, padding: "5px 12px" }}>
                <Check size={13} style={{ color: "#2E7D32" }} />
                <span style={{ fontSize: 12, fontWeight: 600, color: "#2E7D32" }}>{p}</span>
              </div>
            ))}
          </div>

          {/* ───── NORMAL KULLANICI FORMU ───── */}
          {tab === "user" && (
            <form onSubmit={handleUserRegister} style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              <div className="auth-register-grid" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>İsim</label>
                  <div style={{ position: "relative" }}>
                    <User size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="firstName" required value={userForm.firstName} onChange={handleUserChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14 }} placeholder="Ahmet" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>Soyisim</label>
                  <div style={{ position: "relative" }}>
                    <User size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="lastName" required value={userForm.lastName} onChange={handleUserChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14 }} placeholder="Yılmaz" />
                  </div>
                </div>
              </div>

              <div className="auth-register-grid" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>Kullanıcı Adı</label>
                  <div style={{ position: "relative" }}>
                    <AtSign size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="username" required value={userForm.username} onChange={handleUserChange}
                      className="input-field" style={{ paddingLeft: 36 }} placeholder="ahmet_123" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>Mevki</label>
                  <select name="position" required value={userForm.position} onChange={handleUserChange}
                    className="input-field" style={{ paddingLeft: 12, fontSize: 14 }}>
                    <option value="">Mevki seçin...</option>
                    <option value="Kaleci">🧤 Kaleci</option>
                    <option value="Defans">🛡️ Defans</option>
                    <option value="Orta Saha">⚽ Orta Saha</option>
                    <option value="Forvet">🎯 Forvet</option>
                  </select>
                </div>
              </div>

              <div>
                <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>E-posta</label>
                <div style={{ position: "relative" }}>
                  <Mail size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                  <input name="email" type="email" required value={userForm.email} onChange={handleUserChange}
                    className="input-field" style={{ paddingLeft: 36 }} placeholder="ahmet@example.com" />
                </div>
              </div>

              <div className="auth-register-grid" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>Şifre</label>
                  <div style={{ position: "relative" }}>
                    <Lock size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="password" type="password" required value={userForm.password} onChange={handleUserChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14 }} placeholder="••••••" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>Tekrar</label>
                  <div style={{ position: "relative" }}>
                    <Lock size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="confirmPassword" type="password" required value={userForm.confirmPassword} onChange={handleUserChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14 }} placeholder="••••••" />
                  </div>
                </div>
              </div>

              <button type="submit" disabled={loading} className="btn-primary"
                style={{ marginTop: 8, padding: "14px", fontSize: 16, borderRadius: 14, opacity: loading ? 0.7 : 1, width: "100%" }}>
                {loading ? "Kayıt Yapılıyor..." : (<>Üye Ol <ArrowRight size={18} /></>)}
              </button>
            </form>
          )}

          {/* ───── ADMİN / İŞLETME FORMU ───── */}
          {tab === "admin" && (
            <form onSubmit={handleAdminRegister} style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              <div>
                <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>İşletme Adı</label>
                <div style={{ position: "relative" }}>
                  <Building2 size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                  <input name="businessName" required value={adminForm.businessName} onChange={handleAdminChange}
                    className="input-field" style={{ paddingLeft: 36, fontSize: 14 }} placeholder="Örnek Halı Saha" />
                </div>
              </div>

              <div className="auth-register-grid" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>Vergi No / Belge</label>
                  <div style={{ position: "relative" }}>
                    <FileText size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="taxNumber" required value={adminForm.taxNumber} onChange={handleAdminChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14 }} placeholder="1234567890" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>Telefon</label>
                  <div style={{ position: "relative" }}>
                    <Phone size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="phone" required value={adminForm.phone} onChange={handleAdminChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14 }} placeholder="05xx ..." />
                  </div>
                </div>
              </div>

              <div className="auth-register-grid-3" style={{ display: "grid", gridTemplateColumns: "1.4fr 1fr 1fr", gap: 10 }}>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>İşletme E-posta</label>
                  <div style={{ position: "relative" }}>
                    <Mail size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="email" type="email" required value={adminForm.email} onChange={handleAdminChange}
                      className="input-field" style={{ paddingLeft: 36 }} placeholder="isletme@example.com" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>Şifre</label>
                  <div style={{ position: "relative" }}>
                    <Lock size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="password" type="password" required value={adminForm.password} onChange={handleAdminChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14 }} placeholder="••••••" />
                  </div>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>Tekrar</label>
                  <div style={{ position: "relative" }}>
                    <Lock size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                    <input name="confirmPassword" type="password" required value={adminForm.confirmPassword} onChange={handleAdminChange}
                      className="input-field" style={{ paddingLeft: 36, fontSize: 14 }} placeholder="••••••" />
                  </div>
                </div>
              </div>

              <div style={{ background: "#FFF8E1", border: "1px solid #FFE082", borderRadius: 10, padding: "8px 12px", fontSize: 11, color: "#B45309", fontWeight: 600, lineHeight: 1.2 }}>
                ⚠️ Admin kaydı yönetici onayına tabidir. Onaylandıktan sonra giriş yapabilirsiniz.
              </div>

              <button type="submit" disabled={loading} className="btn-primary"
                style={{ marginTop: 2, padding: "12px", fontSize: 16, borderRadius: 14, opacity: loading ? 0.7 : 1, width: "100%" }}>
                {loading ? "Kayıt Yapılıyor..." : (<>Başvuru Gönder <ArrowRight size={18} /></>)}
              </button>
            </form>
          )}

          <div style={{ marginTop: tab === "admin" ? 10 : 20, textAlign: "center" }}>
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

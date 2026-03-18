"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { auth, db } from "@/lib/firebase";
import { doc, setDoc } from "firebase/firestore";
import { toast } from "react-hot-toast";
import { Mail, Lock, User, AtSign, ArrowRight, Check } from "lucide-react";

const RegisterPage = () => {
  const [formData, setFormData] = useState({
    firstName: "", lastName: "", username: "", email: "", password: "", confirmPassword: "",
  });
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (formData.password !== formData.confirmPassword) {
      return toast.error("Şifreler uyuşmuyor!");
    }
    if (formData.password.length < 6) {
      return toast.error("Şifre en az 6 karakter olmalı.");
    }
    setLoading(true);
    try {
      const userCredential = await createUserWithEmailAndPassword(auth, formData.email, formData.password);
      await setDoc(doc(db, "users", userCredential.user.uid), {
        firstName: formData.firstName,
        lastName: formData.lastName,
        username: formData.username,
        email: formData.email,
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

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const perks = ["Ücretsiz kayıt", "Anında rezervasyon", "Maç organizasyonu"];

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

      <div style={{ flex: 1, display: "flex", alignItems: "flex-start", justifyContent: "center", padding: "20px 16px 40px" }}>
        <div className="auth-card" style={{ maxWidth: 480 }}>
          {/* Header */}
          <div style={{ textAlign: "center", marginBottom: 28 }}>
            <div style={{ width: 64, height: 64, background: "#E8F5E9", borderRadius: 20, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 16px", fontSize: 28 }}>
              🏆
            </div>
            <h1 style={{ fontSize: 26, fontWeight: 900, color: "#111827", marginBottom: 6 }}>Hesap Oluştur</h1>
            <p style={{ color: "#9ca3af", fontSize: 15 }}>Ücretsiz üye ol, hemen randevu al!</p>
          </div>

          {/* Perks */}
          <div style={{ display: "flex", gap: 12, marginBottom: 24, flexWrap: "wrap" }}>
            {perks.map(p => (
              <div key={p} style={{ display: "flex", alignItems: "center", gap: 6, background: "#E8F5E9", borderRadius: 20, padding: "5px 12px" }}>
                <Check size={13} style={{ color: "#2E7D32" }} />
                <span style={{ fontSize: 12, fontWeight: 600, color: "#2E7D32" }}>{p}</span>
              </div>
            ))}
          </div>

          <form onSubmit={handleRegister} style={{ display: "flex", flexDirection: "column", gap: 14 }}>
            {/* Name row */}
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
              <div>
                <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>İsim</label>
                <div style={{ position: "relative" }}>
                  <User size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                  <input name="firstName" required value={formData.firstName} onChange={handleChange}
                    className="input-field" style={{ paddingLeft: 36, fontSize: 14 }} placeholder="Ahmet" />
                </div>
              </div>
              <div>
                <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>Soyisim</label>
                <div style={{ position: "relative" }}>
                  <User size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                  <input name="lastName" required value={formData.lastName} onChange={handleChange}
                    className="input-field" style={{ paddingLeft: 36, fontSize: 14 }} placeholder="Yılmaz" />
                </div>
              </div>
            </div>

            <div>
              <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>Kullanıcı Adı</label>
              <div style={{ position: "relative" }}>
                <AtSign size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                <input name="username" required value={formData.username} onChange={handleChange}
                  className="input-field" style={{ paddingLeft: 36 }} placeholder="ahmet_123" />
              </div>
            </div>

            <div>
              <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>E-posta</label>
              <div style={{ position: "relative" }}>
                <Mail size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                <input name="email" type="email" required value={formData.email} onChange={handleChange}
                  className="input-field" style={{ paddingLeft: 36 }} placeholder="ahmet@example.com" />
              </div>
            </div>

            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
              <div>
                <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>Şifre</label>
                <div style={{ position: "relative" }}>
                  <Lock size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                  <input name="password" type="password" required value={formData.password} onChange={handleChange}
                    className="input-field" style={{ paddingLeft: 36, fontSize: 14 }} placeholder="••••••" />
                </div>
              </div>
              <div>
                <label style={{ display: "block", fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 5 }}>Tekrar</label>
                <div style={{ position: "relative" }}>
                  <Lock size={15} style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }} />
                  <input name="confirmPassword" type="password" required value={formData.confirmPassword} onChange={handleChange}
                    className="input-field" style={{ paddingLeft: 36, fontSize: 14 }} placeholder="••••••" />
                </div>
              </div>
            </div>

            <button type="submit" disabled={loading} className="btn-primary"
              style={{ marginTop: 8, padding: "14px", fontSize: 16, borderRadius: 14, opacity: loading ? 0.7 : 1, width: "100%" }}>
              {loading ? "Kayıt Yapılıyor..." : (<>Üye Ol <ArrowRight size={18} /></>)}
            </button>
          </form>

          <div style={{ marginTop: 20, textAlign: "center" }}>
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

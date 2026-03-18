"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth, db } from "@/lib/firebase";
import { doc, getDoc } from "firebase/firestore";
import { toast } from "react-hot-toast";
import Navbar from "@/components/common/Navbar";

const AdminLoginPage = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleAdminLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // Check if user is in admins collection and approved
      const adminDoc = await getDoc(doc(db, "admins", user.uid));
      
      if (adminDoc.exists()) {
        const adminData = adminDoc.data();
        if (adminData.status === "approved") {
          toast.success("Yönetici girişi başarılı!");
          router.push("/admin/dashboard");
        } else {
          toast.error("Hesabınız henüz onaylanmamış.");
          await auth.signOut();
        }
      } else {
        toast.error("Bu hesap yönetici yetkisine sahip değil.");
        await auth.signOut();
      }
    } catch (error: any) {
      toast.error("Giriş hatası: " + (error.message || "Bilinmeyen hata"));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-emerald-50 flex flex-col">
      <Navbar />
      <div className="flex-1 flex items-center justify-center p-4">
        <div className="max-w-md w-full bg-white rounded-2xl shadow-xl p-8 border-t-8 border-emerald-600">
          <div className="text-center mb-10">
            <h2 className="text-3xl font-bold text-gray-900 italic underline">İşletme Paneli</h2>
            <p className="text-gray-500 mt-2 font-medium">Lütfen yönetici bilgilerinizle giriş yapın.</p>
          </div>

          <form onSubmit={handleAdminLogin} className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Yönetici E-posta
              </label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:ring-2 focus:ring-emerald-500 outline-none transition"
                placeholder="isletme@mail.com"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Şifre
              </label>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:ring-2 focus:ring-emerald-500 outline-none transition"
                placeholder="••••••••"
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-emerald-700 text-white py-3 rounded-xl font-bold hover:bg-emerald-800 transition disabled:opacity-50"
            >
              {loading ? "Giriş Yapılıyor..." : "Yönetici Girişi"}
            </button>
          </form>

          <div className="mt-8 text-center">
            <p className="text-sm text-gray-600">
              İşletme sahibi misiniz?{" "}
              <Link href="/admin/register" className="text-emerald-700 font-bold hover:underline">
                İşletme Kaydı Yap
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminLoginPage;

"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { auth, db } from "@/lib/firebase";
import { doc, setDoc } from "firebase/firestore";
import { toast } from "react-hot-toast";
import Navbar from "@/components/common/Navbar";

const AdminRegisterPage = () => {
  const [formData, setFormData] = useState({
    businessName: "",
    taxNumber: "",
    phone: "",
    email: "",
    password: "",
    confirmPassword: "",
  });
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleAdminRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (formData.password !== formData.confirmPassword) {
      return toast.error("Şifreler uyuşmuyor!");
    }

    setLoading(true);
    try {
      const userCredential = await createUserWithEmailAndPassword(
        auth,
        formData.email,
        formData.password
      );
      const user = userCredential.user;

      // Save admin details to Firestore with "pending" status
      await setDoc(doc(db, "admins", user.uid), {
        businessName: formData.businessName,
        taxNumber: formData.taxNumber,
        phone: formData.phone,
        email: formData.email,
        role: "admin",
        status: "pending",
        createdAt: new Date().toISOString(),
      });

      toast.success("Kayıt talebiniz alındı! Yönetici onayı bekliyor.");
      await auth.signOut();
      router.push("/admin/login");
    } catch (error: any) {
      toast.error("Hata: " + (error.message || "Kayıt yapılamadı"));
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  return (
    <div className="min-h-screen bg-emerald-50 flex flex-col">
      <Navbar />
      <div className="flex-1 flex items-center justify-center p-4">
        <div className="max-w-md w-full bg-white rounded-2xl shadow-xl p-8 my-8 border-t-8 border-emerald-600">
          <div className="text-center mb-10">
            <h2 className="text-3xl font-bold text-gray-900">İşletme Kaydı</h2>
            <p className="text-gray-500 mt-2 font-medium">Lütfen işletme bilgilerinizi eksiksiz girin.</p>
          </div>

          <form onSubmit={handleAdminRegister} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">İşletme Adı</label>
              <input
                name="businessName"
                required
                value={formData.businessName}
                onChange={handleChange}
                className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:ring-2 focus:ring-emerald-500 outline-none transition"
                placeholder="Örnek Halı Saha"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Vergi No / belge</label>
                <input
                  name="taxNumber"
                  required
                  value={formData.taxNumber}
                  onChange={handleChange}
                  className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:ring-2 focus:ring-emerald-500 outline-none transition"
                  placeholder="1234567890"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Telefon</label>
                <input
                  name="phone"
                  required
                  value={formData.phone}
                  onChange={handleChange}
                  className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:ring-2 focus:ring-emerald-500 outline-none transition"
                  placeholder="05xx ..."
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">İşletme E-posta</label>
              <input
                name="email"
                type="email"
                required
                value={formData.email}
                onChange={handleChange}
                className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:ring-2 focus:ring-emerald-500 outline-none transition"
                placeholder="isletme@mail.com"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Şifre</label>
              <input
                name="password"
                type="password"
                required
                value={formData.password}
                onChange={handleChange}
                className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:ring-2 focus:ring-emerald-500 outline-none transition"
                placeholder="••••••••"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Şifre Tekrar</label>
              <input
                name="confirmPassword"
                type="password"
                required
                value={formData.confirmPassword}
                onChange={handleChange}
                className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:ring-2 focus:ring-emerald-500 outline-none transition"
                placeholder="••••••••"
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-emerald-700 text-white py-3 rounded-xl font-bold hover:bg-emerald-800 transition disabled:opacity-50"
            >
              {loading ? "Kaydediliyor..." : "İşletme Kaydını Gönder"}
            </button>
          </form>

          <div className="mt-8 text-center text-sm text-gray-600">
            <p>
              Zaten kaydınız var mı?{" "}
              <Link href="/admin/login" className="text-emerald-700 font-bold hover:underline">
                Yönetici Girişi
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminRegisterPage;

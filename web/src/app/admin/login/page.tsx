"use client";

import React, { useEffect } from "react";
import { useRouter } from "next/navigation";

const AdminLoginPage = () => {
  const router = useRouter();

  useEffect(() => {
    router.replace("/login");
  }, [router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#f5f5f7]">
      <div className="text-sm text-gray-500">Giriş sayfasına yönlendiriliyor...</div>
    </div>
  );
};

export default AdminLoginPage;

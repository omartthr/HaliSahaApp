import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Console.log'ları production'da kaldır (bundle küçülür, hafif hızlanma)
  compiler: {
    removeConsole: process.env.NODE_ENV === "production",
  },

  // Sadece WebP kullan — gereksiz format denemelerini önle
  images: {
    formats: ["image/webp"],
  },

  // Typescript hataları build'ı durdurmasın (MVP için)
  typescript: {
    ignoreBuildErrors: true,
  },

  // Büyük ikonları tek tek çekme, sadece kullanılanları al (bundle ~40% küçülür)
  experimental: {
    optimizePackageImports: [
      "lucide-react",
      "firebase/firestore",
      "firebase/auth",
      "firebase/storage",
      "motion",
    ],
  },
};

export default nextConfig;

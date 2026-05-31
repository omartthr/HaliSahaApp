import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Gereksiz React prop-types'ı production'dan kaldır
  compiler: {
    removeConsole: process.env.NODE_ENV === "production",
  },
  // Büyük resim olmadığı için image optimizasyonunu sadece WebP'ye kısıt
  images: {
    formats: ["image/webp"],
  },
  // Typescript hatalarını production build'ı engellemesin
  typescript: {
    ignoreBuildErrors: false,
  },
};

export default nextConfig;

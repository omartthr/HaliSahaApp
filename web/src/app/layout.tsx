import type { Metadata } from "next";
import { Poppins } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/context/AuthContext";
import { Toaster } from "react-hot-toast";

const poppins = Poppins({
  weight: ["400", "500", "600", "700", "900"],
  subsets: ["latin"],
  variable: "--font-poppins",
});

export const metadata: Metadata = {
  title: "Halı Saha Randevu | Kolayca Randevu Al",
  description: "En yakın halı sahayı bul, boş saatleri gör ve hemen randevunu al.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="tr">
      <body className={`${poppins.variable} antialiased`} style={{ fontFamily: "var(--font-poppins), sans-serif" }}>
        <AuthProvider>
          {children}
          <Toaster position="top-right" />
        </AuthProvider>
      </body>
    </html>
  );
}

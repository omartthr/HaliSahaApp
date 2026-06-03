import type { Metadata } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/frontend/context/AuthContext";
import { Toaster } from "react-hot-toast";
import { cn } from "@/lib/utils";
import Chatbot from "@/frontend/components/common/Chatbot";
import MobileBottomNav from "@/frontend/components/common/MobileBottomNav";

const jakarta = Plus_Jakarta_Sans({
  weight: ["400", "500", "600", "700", "800"],
  subsets: ["latin"],
  variable: "--font-jakarta",
  display: "swap",
});

export const metadata: Metadata = {
  title: "ALO Halısaha | Kolayca Randevu Al",
  description: "En yakın halı sahayı bul, boş saatleri gör ve hemen randevunu al.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="tr" className={cn(jakarta.variable)}>
      <body className={`${jakarta.variable} antialiased`} style={{ fontFamily: "var(--font-jakarta), 'Segoe UI', sans-serif" }}>
        <AuthProvider>
          {children}
          <Toaster position="top-right" />
          <Chatbot />
          <MobileBottomNav />
        </AuthProvider>
      </body>
    </html>
  );
}

import { useAuth } from "@/frontend/context/AuthContext";
import Navbar from "@/frontend/components/common/Navbar";
import AdminDashboardContent from "./AdminDashboardContent";

export default function AdminDashboardPage() {
  const { loading } = useAuth();
  
  if (loading) return (
    <div style={{ minHeight: "100vh", display: "flex", flexDirection: "column" }}>
      <Navbar />
      <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div style={{ textAlign: "center" }}>
          <div style={{ width: 40, height: 40, border: "3px solid #E8F5E9", borderTopColor: "#2E7D32", borderRadius: "50%", animation: "spin 1s linear infinite", margin: "0 auto 16px" }} />
          <p style={{ color: "#9CA3AF", fontWeight: 600 }}>Yükleniyor...</p>
        </div>
      </div>
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
    </div>
  );

  return (
    <div className="page-wrapper" style={{ minHeight: "100vh", display: "flex", flexDirection: "column" }}>
      <Navbar />
      <div className="match-hero" style={{ height: 280, background: "linear-gradient(180deg, #114B32 0%, #1A754E 100%)", position: "relative", zIndex: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div style={{ position: "absolute", bottom: -118, left: 0, width: "100%", lineHeight: 0, zIndex: 0, pointerEvents: "none" }}>
          <svg data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 120" preserveAspectRatio="none" style={{ display: "block", width: "calc(100% + 1.3px)", height: 120, overflow: "visible" }}>
            <defs>
              <filter id="admin-wave-soft-shadow" x="-8%" y="-8%" width="116%" height="180%">
                <feGaussianBlur stdDeviation="7" />
              </filter>
            </defs>
            <path d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z" fill="rgba(0,0,0,0.22)" transform="translate(0, 14)" filter="url(#admin-wave-soft-shadow)" />
            <path d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z" fill="#1A754E" />
          </svg>
        </div>
      </div>
      <AdminDashboardContent />
    </div>
  );
}

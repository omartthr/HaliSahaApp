"use client";

import React, { useEffect, useMemo, useState } from "react";
import { motion } from "motion/react";
import { db, auth } from "@/database/firebase";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  onSnapshot,
  serverTimestamp,
  updateDoc,
} from "firebase/firestore";
import { signOut } from "firebase/auth";
import { useAuth } from "@/frontend/context/AuthContext";
import Navbar from "@/frontend/components/common/Navbar";
import { toast } from "react-hot-toast";
import {
  BarChart3, Bell, Building2, CalendarClock, CheckCircle2,
  ChevronRight, Clock3, LayoutGrid, LogOut, MapPin, Plus,
  Settings, Star, Trash2, TrendingUp, XCircle, AlertCircle, Activity,
} from "lucide-react";
import { useRouter } from "next/navigation";

type AdminTab = "dashboard" | "bookings" | "facilities" | "reports" | "settings";
type ReservationStatus = "pending_payment" | "confirmed" | "approved" | "cancelled" | "completed" | "no_show" | string;
type Reservation = {
  id: string; fieldId?: string; fieldName?: string; userId?: string;
  userName?: string; date?: string; timeSlot?: string;
  status?: ReservationStatus; totalPrice?: number; depositAmount?: number;
};
type Facility = {
  id: string; name: string; address: string; phone: string;
  rating?: number; features?: string[]; ownerId?: string; price?: number;
};
type BookingFilter = "all" | "pending_payment" | "confirmed" | "approved" | "completed" | "cancelled" | "no_show";

const TABS: Array<{ id: AdminTab; label: string; icon: React.ReactNode }> = [
  { id: "dashboard", label: "Panel", icon: <LayoutGrid size={16} /> },
  { id: "bookings", label: "Rezervasyonlar", icon: <CalendarClock size={16} /> },
  { id: "facilities", label: "Tesisler", icon: <Building2 size={16} /> },
  { id: "reports", label: "Raporlar", icon: <BarChart3 size={16} /> },
  { id: "settings", label: "Profil", icon: <Settings size={16} /> },
];

const BOOKING_FILTERS: Array<{ id: BookingFilter; label: string }> = [
  { id: "all", label: "Tümü" },
  { id: "pending_payment", label: "Bekleyen" },
  { id: "confirmed", label: "Kapora Ödendi" },
  { id: "approved", label: "Onaylı" },
  { id: "completed", label: "Tamamlandı" },
  { id: "cancelled", label: "İptal" },
  { id: "no_show", label: "Gelmedi" },
];

const statusLabel = (s?: ReservationStatus) => {
  if (s === "pending_payment") return "Bekliyor";
  if (s === "confirmed") return "Kapora Ödendi";
  if (s === "approved") return "Onaylandı";
  if (s === "cancelled") return "İptal";
  if (s === "completed") return "Tamamlandı";
  if (s === "no_show") return "Gelmedi";
  return s || "Bilinmiyor";
};

const statusStyle = (s?: ReservationStatus): React.CSSProperties => {
  if (s === "pending_payment") return { background: "#FFF3E0", color: "#E65100" };
  if (s === "confirmed") return { background: "#E8F5E9", color: "#2E7D32" };
  if (s === "approved") return { background: "#E8F5E9", color: "#2E7D32" };
  if (s === "cancelled") return { background: "#FFEBEE", color: "#C62828" };
  if (s === "completed") return { background: "#E3F2FD", color: "#1565C0" };
  if (s === "no_show") return { background: "#F5F5F5", color: "#616161" };
  return { background: "#F5F5F5", color: "#616161" };
};

const todayFormatted = () =>
  new Date().toLocaleDateString("tr-TR", {
    weekday: "long", year: "numeric", month: "long", day: "numeric",
  });

const cardStyle: React.CSSProperties = {
  background: "rgba(255, 255, 255, 0.78)", borderRadius: 20, padding: 20,
  boxShadow: "0 14px 34px rgba(17, 24, 39, 0.06)", border: "1px solid rgba(255, 255, 255, 0.84)",
  backdropFilter: "blur(20px)", WebkitBackdropFilter: "blur(20px)"
};
const sectionTitle: React.CSSProperties = { fontSize: 16, fontWeight: 700, color: "#111827", margin: 0 };
const inputStyle: React.CSSProperties = {
  width: "100%", padding: "11px 14px", borderRadius: 12,
  border: "1.5px solid #E5E7EB", fontSize: 14, outline: "none",
  boxSizing: "border-box", background: "#FAFAFA",
};

// ─── MAIN COMPONENT ────────────────────────────────────────────────────────
export default function AdminDashboardContent() {
  const { user, userData } = useAuth();
  const router = useRouter();
  const [selectedTab, setSelectedTab] = useState<AdminTab>("settings");
  const [facilities, setFacilities] = useState<Facility[]>([]);
  const [allReservations, setAllReservations] = useState<Reservation[]>([]);
  const [loading, setLoading] = useState(true);
  const [isFallbackFacilityMode, setIsFallbackFacilityMode] = useState(false);
  const [bookingFilter, setBookingFilter] = useState<BookingFilter>("all");
  const [facilityForm, setFacilityForm] = useState({
    name: "", address: "", phone: "", rating: "4.5",
    features: "Soyunma Odası, Otopark, Kantin",
    price: "350",
  });
  const [editingFacilityId, setEditingFacilityId] = useState<string | null>(null);
  const [showFacilityForm, setShowFacilityForm] = useState(false);

  const facilityIds = useMemo(() => facilities.map((f) => f.id), [facilities]);

  const reservations = useMemo(
    () => allReservations.filter((r) => !!r.fieldId && facilityIds.includes(r.fieldId)),
    [allReservations, facilityIds]
  );

  const sortedReservations = useMemo(
    () => [...reservations].sort((a, b) =>
      `${b.date || ""} ${b.timeSlot || ""}`.localeCompare(`${a.date || ""} ${a.timeSlot || ""}`)
    ),
    [reservations]
  );

  const pendingReservations = useMemo(
    () => sortedReservations.filter((r) => r.status === "pending_payment"),
    [sortedReservations]
  );

  const todayISO = new Date().toISOString().slice(0, 10);
  const todayReservations = useMemo(
    () => sortedReservations.filter((r) => r.date === todayISO),
    [sortedReservations, todayISO]
  );

  const estimatedRevenue = useMemo(() =>
    sortedReservations
      .filter((r) => r.status === "approved" || r.status === "completed" || r.status === "confirmed")
      .reduce((sum, r) => sum + (r.totalPrice || r.depositAmount || 1200), 0),
    [sortedReservations]
  );

  const avgRating = useMemo(() => {
    if (!facilities.length) return "0.0";
    const sum = facilities.reduce((s, f) => s + (f.rating || 0), 0);
    return (sum / facilities.length).toFixed(1);
  }, [facilities]);

  const filteredBookings = useMemo(() => {
    if (bookingFilter === "all") return sortedReservations;
    return sortedReservations.filter((r) => r.status === bookingFilter);
  }, [sortedReservations, bookingFilter]);

  const hourDistribution = useMemo(() => {
    const counts: Record<string, number> = {};
    sortedReservations.forEach((r) => {
      const key = (r.timeSlot || "").trim() || "Belirsiz";
      counts[key] = (counts[key] || 0) + 1;
    });
    return Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 5);
  }, [sortedReservations]);

  useEffect(() => {
    if (!user) return;
    const unsubFields = onSnapshot(collection(db, "facilities"), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Facility, "id">) }));
      const owned = list.filter((f) => f.ownerId === user.uid);
      if (owned.length > 0) { setFacilities(owned); setIsFallbackFacilityMode(false); }
      else { setFacilities(list.slice(0, 1)); setIsFallbackFacilityMode(true); }
      setLoading(false);
    });
    const unsubRes = onSnapshot(collection(db, "bookings"), (snap) => {
      setAllReservations(snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Reservation, "id">) })));
      setLoading(false);
    });
    return () => { unsubFields(); unsubRes(); };
  }, [user]);

  const handleStatusUpdate = async (resId: string, newStatus: ReservationStatus) => {
    try {
      await updateDoc(doc(db, "bookings", resId), { status: newStatus, updatedAt: serverTimestamp() });
      toast.success("Durum güncellendi.");
    } catch (err) { toast.error("Hata: " + err); }
  };

  const resetFacilityForm = () => {
    setFacilityForm({ name: "", address: "", phone: "", rating: "4.5", features: "Soyunma Odası, Otopark, Kantin", price: "350" });
    setEditingFacilityId(null);
    setShowFacilityForm(false);
  };

  const handleFacilitySave = async () => {
    if (!user) return;
    if (!facilityForm.name.trim() || !facilityForm.address.trim()) { toast.error("Tesis adı ve adres zorunlu."); return; }
    const payload = {
      name: facilityForm.name.trim(), address: facilityForm.address.trim(),
      phone: facilityForm.phone.trim(), rating: Number(facilityForm.rating || 0),
      features: facilityForm.features.split(",").map((f) => f.trim()).filter(Boolean),
      price: Number(facilityForm.price || 350),
      ownerId: user.uid, updatedAt: serverTimestamp(),
    };
    try {
      if (editingFacilityId) {
        await updateDoc(doc(db, "facilities", editingFacilityId), payload);
        toast.success("Tesis güncellendi.");
      } else {
        await addDoc(collection(db, "facilities"), { ...payload, createdAt: serverTimestamp() });
        toast.success("Yeni tesis eklendi.");
      }
      resetFacilityForm();
    } catch (err) { toast.error("Tesis kaydedilemedi: " + err); }
  };

  const startEditFacility = (facility: Facility) => {
    setEditingFacilityId(facility.id);
    setFacilityForm({
      name: facility.name || "", address: facility.address || "", phone: facility.phone || "",
      rating: String(facility.rating ?? 4.5), features: (facility.features || []).join(", "),
      price: String(facility.price || 350),
    });
    setShowFacilityForm(true);
  };

  const handleDeleteFacility = async (id: string) => {
    if (!window.confirm("Bu tesisi silmek istediğine emin misin?")) return;
    try {
      await deleteDoc(doc(db, "facilities", id));
      toast.success("Tesis silindi.");
      if (editingFacilityId === id) resetFacilityForm();
    } catch (err) { toast.error("Tesis silinemedi: " + err); }
  };

  const handleLogout = async () => {
    await signOut(auth);
    toast.success("Çıkış yapıldı.");
    router.push("/login");
  };

  // ── DASHBOARD TAB ────────────────────────────────────────────────────────
  const renderDashboard = () => (
    <div style={{ display: "flex", flexDirection: "column", gap: 24 }}>
      {/* Stats */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(180px,1fr))", gap: 12 }}>
        <StatCard title="Bugün" value={String(todayReservations.length)} subtitle="rezervasyon"
          icon={<CalendarClock size={22} color="#fff" />} color="#1565C0" />
        <StatCard title="Bekleyen" value={String(pendingReservations.length)} subtitle="onay"
          icon={<Clock3 size={22} color="#fff" />} color="#E65100" />
        <StatCard title="Bu Ay Gelir" value={"₺" + estimatedRevenue.toLocaleString("tr-TR")} subtitle="tahmini gelir"
          icon={<TrendingUp size={22} color="#fff" />} color="#2E7D32" />
        <StatCard title="Ort. Puan" value={avgRating} subtitle="tesis puanı"
          icon={<Star size={22} color="#fff" />} color="#F9A825" />
      </div>

      {/* Quick Actions */}
      <section style={cardStyle}>
        <h2 style={sectionTitle}>Hızlı İşlemler</h2>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit,minmax(120px,1fr))", gap: 12, marginTop: 14 }}>
          <QuickBtn label="Yeni Tesis" icon={<Plus size={20} color="#2E7D32" />} bg="#E8F5E9"
            onClick={() => { setSelectedTab("facilities"); setShowFacilityForm(true); }} />
          <QuickBtn label="Rezervasyonlar" icon={<CalendarClock size={20} color="#1565C0" />} bg="#E3F2FD"
            onClick={() => setSelectedTab("bookings")} />
          <QuickBtn label="Raporlar" icon={<BarChart3 size={20} color="#6A1B9A" />} bg="#F3E5F5"
            onClick={() => setSelectedTab("reports")} />
          <QuickBtn label="Profil" icon={<Settings size={20} color="#455A64" />} bg="#ECEFF1"
            onClick={() => setSelectedTab("settings")} />
        </div>
      </section>

      {/* Today's Bookings */}
      <section style={cardStyle}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 }}>
          <h2 style={sectionTitle}>Bugünkü Rezervasyonlar</h2>
          <button onClick={() => setSelectedTab("bookings")}
            style={{ color: "#2E7D32", fontSize: 14, fontWeight: 600, background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: 4 }}>
            Tümü <ChevronRight size={14} />
          </button>
        </div>
        {todayReservations.length === 0
          ? <EmptyState icon={<CalendarClock size={40} color="#9CA3AF" />} msg="Bugün için rezervasyon bulunmuyor." />
          : <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            {todayReservations.slice(0, 4).map((r) =>
              <BookingCard key={r.id} res={r} onStatus={handleStatusUpdate} compact />)}
          </div>}
      </section>

      {/* Facilities */}
      <section style={cardStyle}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 }}>
          <h2 style={sectionTitle}>Tesislerim</h2>
          <button onClick={() => setSelectedTab("facilities")}
            style={{ color: "#2E7D32", fontSize: 14, fontWeight: 600, background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: 4 }}>
            Yönet <ChevronRight size={14} />
          </button>
        </div>
        {facilities.length === 0
          ? <EmptyState icon={<Building2 size={40} color="#9CA3AF" />} msg="Henüz tesis eklemediniz." />
          : <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            {facilities.map((f) => (
              <div key={f.id} onClick={() => setSelectedTab("facilities")}
                style={{ display: "flex", alignItems: "center", gap: 14, padding: "12px 14px", borderRadius: 14, background: "#F9FAFB", cursor: "pointer", border: "1px solid #F3F4F6" }}>
                <div style={{ width: 46, height: 46, borderRadius: 12, background: "#E8F5E9", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  <Building2 size={22} color="#2E7D32" />
                </div>
                <div style={{ flex: 1 }}>
                  <p style={{ fontWeight: 700, fontSize: 15, color: "#111827", margin: 0 }}>{f.name}</p>
                  <p style={{ fontSize: 13, color: "#6B7280", margin: "2px 0 0", display: "flex", alignItems: "center", gap: 4 }}>
                    <MapPin size={12} /> {f.address || "Adres yok"}
                  </p>
                </div>
                {f.rating ? (
                  <div style={{ display: "flex", alignItems: "center", gap: 4, background: "#FFF9C4", borderRadius: 8, padding: "4px 8px" }}>
                    <Star size={12} color="#F9A825" fill="#F9A825" />
                    <span style={{ fontSize: 12, fontWeight: 700, color: "#795548" }}>{f.rating}</span>
                  </div>
                ) : null}
                <ChevronRight size={16} color="#9CA3AF" />
              </div>
            ))}
          </div>}
        <button onClick={() => { setSelectedTab("facilities"); setShowFacilityForm(true); }}
          style={{ width: "100%", marginTop: 12, padding: 12, borderRadius: 14, border: "2px dashed #A5D6A7", background: "#F1F8E9", color: "#2E7D32", fontWeight: 600, fontSize: 14, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}>
          <Plus size={18} /> Yeni Tesis Ekle
        </button>
      </section>
    </div>
  );

  // ── BOOKINGS TAB ─────────────────────────────────────────────────────────
  const renderBookings = () => (
    <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
      {/* Summary */}
      <div style={{ display: "flex", flexWrap: "wrap", gap: 10 }}>
        {[
          { label: "Toplam", val: sortedReservations.length, color: "#1565C0" },
          { label: "Bekleyen", val: pendingReservations.length, color: "#E65100" },
          { label: "Ödenmiş/Onaylı", val: sortedReservations.filter((r) => r.status === "approved" || r.status === "confirmed").length, color: "#2E7D32" },
          { label: "Tamamlandı", val: sortedReservations.filter((r) => r.status === "completed").length, color: "#00838F" },
        ].map((s) => (
          <div key={s.label} style={{ display: "flex", alignItems: "center", gap: 8, padding: "8px 14px", borderRadius: 20, background: "#fff", border: "1px solid #E5E7EB", boxShadow: "0 1px 4px rgba(0,0,0,0.04)" }}>
            <span style={{ fontSize: 13, color: "#6B7280", fontWeight: 500 }}>{s.label}</span>
            <span style={{ fontWeight: 800, fontSize: 14, color: s.color }}>{s.val}</span>
          </div>
        ))}
      </div>
      {/* Filter chips */}
      <div style={{ display: "flex", overflowX: "auto", gap: 8, paddingBottom: 4 }}>
        {BOOKING_FILTERS.map((f) => (
          <button key={f.id} onClick={() => setBookingFilter(f.id)}
            style={{
              padding: "8px 16px", borderRadius: 20, border: "none", cursor: "pointer", fontWeight: 600, fontSize: 13, whiteSpace: "nowrap",
              background: bookingFilter === f.id ? "#2E7D32" : "#fff", color: bookingFilter === f.id ? "#fff" : "#374151",
              boxShadow: "0 1px 4px rgba(0,0,0,0.07)", transition: "all 0.15s"
            }}>
            {f.label}
            {f.id !== "all" && (
              <span style={{ marginLeft: 6, background: bookingFilter === f.id ? "rgba(255,255,255,0.25)" : "#F3F4F6", borderRadius: 10, padding: "1px 6px", fontSize: 11 }}>
                {sortedReservations.filter((r) => r.status === f.id).length}
              </span>
            )}
          </button>
        ))}
      </div>
      {/* List */}
      {filteredBookings.length === 0
        ? <div style={{ ...cardStyle, textAlign: "center", padding: 48 }}>
          <EmptyState icon={<CalendarClock size={48} color="#D1D5DB" />} msg="Bu kategori için rezervasyon bulunamadı." />
        </div>
        : <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {filteredBookings.map((r) => <BookingCard key={r.id} res={r} onStatus={handleStatusUpdate} />)}
        </div>}
    </div>
  );

  // ── FACILITIES TAB ───────────────────────────────────────────────────────
  const renderFacilities = () => (
    <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
      {facilities.length === 0 && !showFacilityForm ? (
        <div style={{ ...cardStyle, textAlign: "center", padding: 60 }}>
          <Building2 size={56} color="#D1D5DB" style={{ margin: "0 auto 16px" }} />
          <h3 style={{ fontSize: 18, fontWeight: 700, color: "#374151", margin: "0 0 8px" }}>Henüz Tesis Eklemediniz</h3>
          <p style={{ color: "#9CA3AF", fontSize: 14, marginBottom: 24 }}>İlk tesisinizi ekleyerek başlayın</p>
          <button onClick={() => setShowFacilityForm(true)}
            style={{ padding: "12px 32px", borderRadius: 14, background: "#2E7D32", color: "#fff", fontWeight: 700, fontSize: 15, border: "none", cursor: "pointer", display: "inline-flex", alignItems: "center", gap: 8 }}>
            <Plus size={18} /> Tesis Ekle
          </button>
        </div>
      ) : (
        <>
          {facilities.map((facility) => (
            <div key={facility.id} style={cardStyle}>
              <div style={{ display: "flex", alignItems: "flex-start", gap: 14 }}>
                <div style={{ width: 56, height: 56, borderRadius: 14, background: "#E8F5E9", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <Building2 size={26} color="#2E7D32" />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 8 }}>
                    <h3 style={{ fontSize: 16, fontWeight: 700, color: "#111827", margin: 0 }}>{facility.name}</h3>
                    <div style={{ display: "flex", gap: 8 }}>
                      <button onClick={() => startEditFacility(facility)}
                        style={{ padding: "6px 14px", borderRadius: 10, border: "1px solid #E5E7EB", background: "#fff", color: "#374151", fontSize: 13, fontWeight: 600, cursor: "pointer" }}>
                        Düzenle
                      </button>
                      <button onClick={() => handleDeleteFacility(facility.id)}
                        style={{ padding: "6px 14px", borderRadius: 10, border: "1px solid #FCA5A5", background: "#FFF5F5", color: "#C62828", fontSize: 13, fontWeight: 600, cursor: "pointer", display: "flex", alignItems: "center", gap: 6 }}>
                        <Trash2 size={13} /> Sil
                      </button>
                    </div>
                  </div>
                  <p style={{ fontSize: 13, color: "#6B7280", margin: "4px 0 0", display: "flex", alignItems: "center", gap: 4 }}>
                    <MapPin size={13} /> {facility.address || "Adres yok"}
                  </p>
                  <p style={{ fontSize: 13, color: "#6B7280", margin: "2px 0 0" }}>
                    ☎ {facility.phone || "Telefon yok"}
                  </p>
                  {facility.rating ? (
                    <div style={{ display: "inline-flex", alignItems: "center", gap: 4, marginTop: 6, background: "#FFF9C4", borderRadius: 8, padding: "3px 8px" }}>
                      <Star size={12} color="#F9A825" fill="#F9A825" />
                      <span style={{ fontSize: 12, fontWeight: 700, color: "#795548" }}>{facility.rating}</span>
                    </div>
                  ) : null}
                  {facility.features?.length ? (
                    <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginTop: 10 }}>
                      {facility.features.map((feat) => (
                        <span key={feat} style={{ padding: "3px 10px", borderRadius: 20, background: "#E8F5E9", color: "#2E7D32", fontSize: 12, fontWeight: 600 }}>{feat}</span>
                      ))}
                    </div>
                  ) : null}
                </div>
              </div>
            </div>
          ))}
          {!showFacilityForm && (
            <button onClick={() => setShowFacilityForm(true)}
              style={{ width: "100%", padding: 14, borderRadius: 16, border: "2px dashed #A5D6A7", background: "#F1F8E9", color: "#2E7D32", fontWeight: 700, fontSize: 15, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}>
              <Plus size={20} /> Yeni Tesis Ekle
            </button>
          )}
        </>
      )}
      {showFacilityForm && (
        <div style={cardStyle}>
          <h3 style={{ ...sectionTitle, marginBottom: 16 }}>{editingFacilityId ? "Tesisi Düzenle" : "Yeni Tesis Ekle"}</h3>
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {[
              { key: "name", ph: "Tesis adı *", type: "text" },
              { key: "phone", ph: "Telefon numarası", type: "tel" },
              { key: "rating", ph: "Puan (örn: 4.7)", type: "number" },
              { key: "features", ph: "Özellikler (virgülle ayırın)", type: "text" },
              { key: "price", ph: "Saatlik Ücret (₺)", type: "number" },
            ].map((f) => (
              <input key={f.key} type={f.type} placeholder={f.ph}
                value={facilityForm[f.key as keyof typeof facilityForm]}
                onChange={(e) => setFacilityForm((s) => ({ ...s, [f.key]: e.target.value }))}
                style={inputStyle} />
            ))}
            <textarea value={facilityForm.address} rows={3} placeholder="Adres *"
              onChange={(e) => setFacilityForm((s) => ({ ...s, address: e.target.value }))}
              style={{ ...inputStyle, resize: "vertical" }} />
          </div>
          <div style={{ display: "flex", gap: 10, marginTop: 16 }}>
            <button onClick={handleFacilitySave}
              style={{ flex: 1, padding: 12, borderRadius: 12, background: "#2E7D32", color: "#fff", fontWeight: 700, fontSize: 15, border: "none", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}>
              <Plus size={18} /> {editingFacilityId ? "Güncelle" : "Ekle"}
            </button>
            <button onClick={resetFacilityForm}
              style={{ padding: "12px 20px", borderRadius: 12, border: "1px solid #E5E7EB", background: "#fff", color: "#374151", fontWeight: 600, fontSize: 14, cursor: "pointer" }}>
              Vazgeç
            </button>
          </div>
        </div>
      )}
    </div>
  );

  // ── REPORTS TAB ──────────────────────────────────────────────────────────
  const renderReports = () => {
    const statusData = [
      { label: "Bekleyen", key: "pending_payment", color: "#E65100" },
      { label: "Onaylı", key: "approved", color: "#2E7D32" },
      { label: "Tamamlandı", key: "completed", color: "#1565C0" },
      { label: "İptal", key: "cancelled", color: "#C62828" },
      { label: "Gelmedi", key: "no_show", color: "#616161" },
    ].map((item) => ({ ...item, value: sortedReservations.filter((r) => r.status === item.key).length }));

    const total = sortedReservations.length || 1;
    const weekRevenue = [
      { day: "Pzt", rev: Math.round(estimatedRevenue * 0.13) },
      { day: "Sal", rev: Math.round(estimatedRevenue * 0.11) },
      { day: "Çar", rev: Math.round(estimatedRevenue * 0.16) },
      { day: "Per", rev: Math.round(estimatedRevenue * 0.12) },
      { day: "Cum", rev: Math.round(estimatedRevenue * 0.18) },
      { day: "Cmt", rev: Math.round(estimatedRevenue * 0.21) },
      { day: "Paz", rev: Math.round(estimatedRevenue * 0.09) },
    ];
    const maxRev = Math.max(...weekRevenue.map((d) => d.rev), 1);
    const occupancy = Math.min(Math.round((sortedReservations.filter((r) => r.status === "completed" || r.status === "approved" || r.status === "confirmed").length / total) * 100), 100);
    const cancelRate = Math.min(Math.round((sortedReservations.filter((r) => r.status === "cancelled").length / total) * 100), 100);

    return (
      <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
        {/* Revenue bar chart */}
        <div style={cardStyle}>
          <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 20 }}>
            <div>
              <p style={{ fontSize: 13, color: "#6B7280", margin: 0 }}>Toplam Gelir</p>
              <p style={{ fontSize: 28, fontWeight: 800, color: "#111827", margin: "4px 0 0" }}>
                ₺{estimatedRevenue.toLocaleString("tr-TR")}
              </p>
            </div>
            <div style={{ textAlign: "right" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 4, color: "#2E7D32" }}>
                <TrendingUp size={14} />
                <span style={{ fontSize: 13, fontWeight: 700 }}>+12%</span>
              </div>
              <p style={{ fontSize: 12, color: "#9CA3AF", margin: "2px 0 0" }}>Geçen aya göre</p>
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "flex-end", gap: 8, height: 120, padding: "0 4px" }}>
            {weekRevenue.map((d) => (
              <div key={d.day} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
                <div style={{
                  width: "100%", borderRadius: "6px 6px 0 0",
                  background: "linear-gradient(180deg,#4CAF50,#2E7D32)",
                  height: `${Math.max((d.rev / maxRev) * 100, 6)}%`,
                }} />
                <span style={{ fontSize: 11, color: "#9CA3AF", fontWeight: 500 }}>{d.day}</span>
              </div>
            ))}
          </div>
        </div>
        {/* Key metrics */}
        <div>
          <h3 style={{ ...sectionTitle, marginBottom: 12 }}>Temel Metrikler</h3>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit,minmax(150px,1fr))", gap: 12 }}>
            <MetricCard title="Toplam Rezervasyon" value={String(sortedReservations.length)} icon={<CalendarClock size={20} color="#1565C0" />} bg="#E3F2FD" />
            <MetricCard title="Ortalama Puan" value={avgRating} icon={<Star size={20} color="#F9A825" />} bg="#FFF9C4" />
            <MetricCard title="Doluluk Oranı" value={`%${occupancy}`} icon={<Activity size={20} color="#6A1B9A" />} bg="#F3E5F5" />
            <MetricCard title="İptal Oranı" value={`%${cancelRate}`} icon={<XCircle size={20} color="#C62828" />} bg="#FFEBEE" />
          </div>
        </div>
        {/* Distribution */}
        <div style={cardStyle}>
          <h3 style={{ ...sectionTitle, marginBottom: 16 }}>Rezervasyon Dağılımı</h3>
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {statusData.map((item) => (
              <div key={item.key}>
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 5 }}>
                  <span style={{ fontSize: 13, color: "#374151", fontWeight: 500 }}>{item.label}</span>
                  <span style={{ fontSize: 13, fontWeight: 700, color: "#111827" }}>{item.value}</span>
                </div>
                <div style={{ height: 8, borderRadius: 6, background: "#F3F4F6", overflow: "hidden" }}>
                  <div style={{ height: 8, borderRadius: 6, background: item.color, width: `${Math.round((item.value / total) * 100)}%` }} />
                </div>
              </div>
            ))}
          </div>
        </div>
        {/* Popular hours */}
        <div style={cardStyle}>
          <h3 style={{ ...sectionTitle, marginBottom: 16 }}>En Popüler Saatler</h3>
          {hourDistribution.length === 0
            ? <p style={{ color: "#9CA3AF", fontSize: 14 }}>Henüz saat verisi yok.</p>
            : <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              {hourDistribution.map(([slot, count], idx) => {
                const pct = Math.round((count / hourDistribution[0][1]) * 100);
                return (
                  <div key={slot} style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <span style={{ fontSize: 13, fontWeight: 700, color: "#2E7D32", minWidth: 20 }}>#{idx + 1}</span>
                    <div style={{ flex: 1 }}>
                      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                        <span style={{ fontSize: 13, color: "#374151", fontWeight: 500 }}>{slot}</span>
                        <span style={{ fontSize: 13, fontWeight: 700, color: "#111827" }}>{count} rezervasyon</span>
                      </div>
                      <div style={{ height: 6, borderRadius: 4, background: "#F3F4F6", overflow: "hidden" }}>
                        <div style={{ height: 6, borderRadius: 4, background: "#2E7D32", width: `${pct}%` }} />
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>}
        </div>
      </div>
    );
  };

  // ── SETTINGS TAB ─────────────────────────────────────────────────────────
  const renderSettings = () => (
    <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
      <div style={{ ...cardStyle, borderRadius: 24, background: "rgba(255,255,255,0.82)", backdropFilter: "blur(8px)" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 14, gap: 12, flexWrap: "wrap" }}>
          <h3 style={{ ...sectionTitle, margin: 0 }}>Profil ve Hesap Bilgileri</h3>
          <span style={{ fontSize: 12, fontWeight: 700, color: "#2E7D32", background: "#E8F5E9", border: "1px solid #A5D6A7", borderRadius: 20, padding: "6px 12px" }}>
            İşletme Profili
          </span>
        </div>

        <div style={{ display: "grid", gap: 16, gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))" }}>
          <div>
            <p style={{ fontSize: 13, color: "#6b7280", fontWeight: 600, marginBottom: 10 }}>Hesap Özeti</p>
            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              {[
                { label: "İşletme Adı", value: userData?.businessName || "Tanımsız" },
                { label: "E-posta", value: user?.email || "Tanımsız" },
                { label: "Hesap Türü", value: "İşletme Yöneticisi" },
              ].map((item, index) => (
                <div key={item.label}
                  style={{
                    width: "100%",
                    border: `1px solid ${index === 0 ? "#2E7D32" : "#E5E7EB"}`,
                    background: index === 0 ? "rgba(232,245,233,0.78)" : "rgba(255,255,255,0.56)",
                    borderRadius: 16,
                    padding: "14px 16px",
                  }}>
                  <p style={{ fontSize: 11, letterSpacing: "0.08em", textTransform: "uppercase", color: "#2E7D32", fontWeight: 700, marginBottom: 4 }}>
                    {item.label}
                  </p>
                  <p style={{ fontSize: 16, fontWeight: 700, color: "#111827", margin: 0 }}>{item.value}</p>
                </div>
              ))}
            </div>
          </div>

          <div>
            <p style={{ fontSize: 13, color: "#6b7280", fontWeight: 600, marginBottom: 10 }}>Profil Durumu</p>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))", gap: 10 }}>
              {[
                { title: "Bildirim", value: "Açık", color: "#2E7D32" },
                { title: "Doğrulama", value: "Aktif", color: "#1565C0" },
                { title: "Destek", value: "Öncelikli", color: "#6A1B9A" },
              ].map((item) => (
                <div key={item.title}
                  style={{
                    padding: "12px 14px",
                    borderRadius: 14,
                    border: "1px solid #E5E7EB",
                    background: "rgba(255,255,255,0.58)",
                  }}>
                  <p style={{ fontSize: 13, color: "#9ca3af", margin: 0 }}>{item.title}</p>
                  <p style={{ fontSize: 18, lineHeight: 1.15, fontWeight: 700, color: item.color, marginTop: 6 }}>{item.value}</p>
                </div>
              ))}
            </div>

            <div style={{ marginTop: 16 }}>
              <p style={{ fontSize: 13, color: "#6b7280", fontWeight: 600, marginBottom: 10 }}>Aktivite Özeti</p>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(3, minmax(60px, 1fr))", gap: 8 }}>
                {[
                  { key: "Bugün", value: todayReservations.length },
                  { key: "Bekleyen", value: pendingReservations.length },
                  { key: "Tesis", value: facilities.length },
                ].map((item) => (
                  <div key={item.key} style={{ borderRadius: 12, background: "rgba(255,255,255,0.62)", border: "1px solid #E5E7EB", padding: "10px 8px", textAlign: "center" }}>
                    <p style={{ fontSize: 11, color: "#9ca3af", margin: 0 }}>{item.key}</p>
                    <p style={{ fontSize: 20, fontWeight: 800, color: "#111827", margin: "2px 0 0" }}>{item.value}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div style={{ ...cardStyle, borderRadius: 24, background: "rgba(255,255,255,0.82)", backdropFilter: "blur(8px)" }}>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))", gap: 18, alignItems: "start" }}>
          <div>
            <h3 style={{ ...sectionTitle, marginBottom: 14 }}>Tercih Seçenekleri</h3>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 8 }}>
              {[
                { label: "Bildirimler", active: true },
                { label: "E-posta Özeti", active: true },
                { label: "Rapor Hatırlatma", active: false },
                { label: "Destek Mesajları", active: true },
              ].map((item) => (
                <button key={item.label}
                  style={{
                    borderRadius: 12,
                    border: "none",
                    cursor: "pointer",
                    background: item.active ? "#2E7D32" : "#E5E7EB",
                    color: item.active ? "#fff" : "#6B7280",
                    padding: "10px 12px",
                    fontSize: 13,
                    fontWeight: 700,
                    textAlign: "left",
                  }}>
                  {item.label}
                </button>
              ))}
            </div>
            <div style={{ display: "flex", gap: 20, marginTop: 14 }}>
              {[
                { color: "#2E7D32", label: "Aktif" },
                { color: "#d1d5db", label: "Pasif" },
              ].map((item) => (
                <div key={item.label} style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "#9ca3af" }}>
                  <div style={{ width: 10, height: 10, borderRadius: "50%", background: item.color }} />
                  {item.label}
                </div>
              ))}
            </div>
          </div>

          <div>
            <h3 style={{ ...sectionTitle, marginBottom: 14 }}>Ayar Kartları</h3>
            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              {[
                { icon: <Bell size={18} color="#1565C0" />, title: "Bildirimler", sub: "Rezervasyon bildirimleri" },
                { icon: <AlertCircle size={18} color="#2E7D32" />, title: "Profili Düzenle", sub: "Ad ve iletişim bilgileri" },
                { icon: <BarChart3 size={18} color="#6A1B9A" />, title: "Raporlar", sub: "Gelir ve doluluk raporları" },
                { icon: <Activity size={18} color="#E65100" />, title: "Destek", sub: "Yardım ve iletişim" },
              ].map((item) => (
                <div key={item.title} style={{ display: "flex", alignItems: "center", gap: 12, borderRadius: 12, padding: "12px 10px", background: "rgba(255,255,255,0.6)", border: "1px solid #E5E7EB" }}>
                  <div style={{ width: 38, height: 38, borderRadius: 10, background: "#F3F4F6", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                    {item.icon}
                  </div>
                  <div style={{ flex: 1 }}>
                    <p style={{ fontSize: 14, fontWeight: 700, color: "#111827", margin: 0 }}>{item.title}</p>
                    <p style={{ fontSize: 12, color: "#9CA3AF", margin: "2px 0 0" }}>{item.sub}</p>
                  </div>
                  <ChevronRight size={16} color="#9CA3AF" />
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div style={{ ...cardStyle, borderRadius: 24, background: "rgba(255,255,255,0.82)", backdropFilter: "blur(8px)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
          <h3 style={{ ...sectionTitle, margin: 0 }}>Güvenlik ve Oturum</h3>
          <span style={{ fontSize: 13, color: "#2E7D32", fontWeight: 600 }}>Durum: Güvenli</span>
        </div>

        <div style={{ display: "flex", gap: 20, alignItems: "center", background: "rgba(255,255,255,0.56)", borderRadius: 12, padding: 16, border: "1px solid #E5E7EB" }}>
          <div style={{ textAlign: "center" }}>
            <div style={{ fontSize: 36, fontWeight: 900, color: "#111827" }}>98%</div>
            <p style={{ fontSize: 12, color: "#9ca3af", marginTop: 4 }}>Profil tamamlama</p>
          </div>
          <div style={{ flex: 1 }}>
            {[72, 18, 8].map((pct, idx) => (
              <div key={idx} style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
                <span style={{ fontSize: 12, color: "#9ca3af", width: 70 }}>{idx === 0 ? "Kimlik" : idx === 1 ? "İletişim" : "Yedek"}</span>
                <div style={{ flex: 1, background: "#e5e7eb", borderRadius: 3, height: 6 }}>
                  <div style={{ width: `${pct}%`, background: idx === 0 ? "#2E7D32" : idx === 1 ? "#1565C0" : "#F59E0B", height: 6, borderRadius: 3 }} />
                </div>
              </div>
            ))}
          </div>
        </div>

        <button onClick={handleLogout}
          style={{ width: "100%", marginTop: 14, padding: 14, borderRadius: 14, border: "1.5px solid #FCA5A5", background: "#FFF5F5", color: "#C62828", fontWeight: 700, fontSize: 15, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}>
          <LogOut size={18} /> Çıkış Yap
        </button>
      </div>
    </div>
  );

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
    <>
      <div className="content-container" style={{ position: "relative", zIndex: 20, paddingBottom: 60, maxWidth: 1200, width: "100%", margin: "-130px auto 0", minHeight: "1150px" }}>

        {/* Tab bar */}
        <div style={{ overflowX: "auto", marginBottom: 24 }}>
          <div style={{ display: "inline-flex", background: "#fff", border: "1px solid #E5E7EB", borderRadius: 18, padding: 4, gap: 4, minWidth: "max-content", boxShadow: "0 2px 8px rgba(0,0,0,0.04)" }}>
            {TABS.map((tab) => {
              const active = selectedTab === tab.id;
              return (
                <button key={tab.id} onClick={() => setSelectedTab(tab.id)}
                  style={{ position: "relative", padding: "9px 18px", borderRadius: 14, border: "none", cursor: "pointer", fontWeight: 600, fontSize: 13, display: "flex", alignItems: "center", gap: 7, transition: "color 0.15s", background: "transparent", color: active ? "#fff" : "#6B7280" }}>

                  {active && (
                    <motion.div
                      layoutId="admin-active-tab"
                      style={{ position: "absolute", top: 0, left: 0, right: 0, bottom: 0, background: "#2E7D32", borderRadius: 14, zIndex: 0 }}
                      transition={{ type: "spring", stiffness: 400, damping: 30, mass: 0.8 }}
                    />
                  )}

                  <span style={{ position: "relative", zIndex: 1, display: "flex", alignItems: "center", gap: 7 }}>
                    {tab.icon} {tab.label}
                  </span>

                  {tab.id === "bookings" && pendingReservations.length > 0 && (
                    <span style={{ position: "relative", zIndex: 1, background: active ? "rgba(255,255,255,0.3)" : "#FEE2E2", color: active ? "#fff" : "#EF4444", fontSize: 10, fontWeight: 800, padding: "1px 6px", borderRadius: 10 }}>
                      {pendingReservations.length}
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        </div>

        {/* Content */}
        <div key={selectedTab} style={{ animation: "fadeInSlide 0.35s cubic-bezier(0.16, 1, 0.3, 1) forwards" }}>
          {selectedTab === "dashboard" && renderDashboard()}
          {selectedTab === "bookings" && renderBookings()}
          {selectedTab === "facilities" && renderFacilities()}
          {selectedTab === "reports" && renderReports()}
          {selectedTab === "settings" && renderSettings()}
        </div>
      </div>
    </>
  );
};

// ─── SUBCOMPONENTS ─────────────────────────────────────────────────────────
function StatCard({ title, value, subtitle, icon, color }: { title: string; value: string; subtitle: string; icon: React.ReactNode; color: string }) {
  return (
    <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 18, padding: "18px 20px", display: "flex", alignItems: "center", gap: 14 }}>
      <div style={{ width: 48, height: 48, borderRadius: 14, background: color, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>{icon}</div>
      <div>
        <p style={{ fontSize: 12, color: "#9CA3AF", margin: 0, fontWeight: 500 }}>{title}</p>
        <p style={{ fontSize: 22, fontWeight: 800, color: "#111827", margin: "3px 0 1px" }}>{value}</p>
        <p style={{ fontSize: 11, color: "#9CA3AF", margin: 0 }}>{subtitle}</p>
      </div>
    </div>
  );
}

function QuickBtn({ label, icon, bg, onClick }: { label: string; icon: React.ReactNode; bg: string; onClick: () => void }) {
  return (
    <button onClick={onClick}
      style={{ padding: "16px 12px", borderRadius: 16, background: bg, border: "none", cursor: "pointer", display: "flex", flexDirection: "column", alignItems: "center", gap: 8 }}>
      {icon}
      <span style={{ fontSize: 12, fontWeight: 600, color: "#374151" }}>{label}</span>
    </button>
  );
}

function MetricCard({ title, value, icon, bg }: { title: string; value: string; icon: React.ReactNode; bg: string }) {
  return (
    <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 16, padding: 16 }}>
      <div style={{ width: 40, height: 40, borderRadius: 12, background: bg, display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 10 }}>{icon}</div>
      <p style={{ fontSize: 12, color: "#9CA3AF", margin: 0 }}>{title}</p>
      <p style={{ fontSize: 20, fontWeight: 800, color: "#111827", margin: "4px 0 0" }}>{value}</p>
    </div>
  );
}

function EmptyState({ icon, msg }: { icon: React.ReactNode; msg: string }) {
  return (
    <div style={{ textAlign: "center", padding: "32px 16px", display: "flex", flexDirection: "column", alignItems: "center", gap: 12 }}>
      {icon}
      <p style={{ color: "#9CA3AF", fontSize: 14, fontWeight: 500, margin: 0 }}>{msg}</p>
    </div>
  );
}

function BookingCard({ res, onStatus, compact = false }: { res: Reservation; onStatus: (id: string, s: ReservationStatus) => Promise<void>; compact?: boolean }) {
  return (
    <div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 16, padding: "14px 16px", display: "flex", flexDirection: "column", gap: 10 }}>
      <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 10, flexWrap: "wrap" }}>
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
            <p style={{ fontWeight: 700, fontSize: 15, color: "#111827", margin: 0 }}>{res.userName || "Kullanıcı"}</p>
            <span style={{ padding: "3px 10px", borderRadius: 10, fontSize: 11, fontWeight: 700, ...statusStyle(res.status) }}>
              {statusLabel(res.status)}
            </span>
          </div>
          <p style={{ fontSize: 13, color: "#6B7280", margin: "4px 0 0", display: "flex", alignItems: "center", gap: 5 }}>
            <Clock3 size={13} /> {res.date || "-"} • {res.timeSlot || "-"}
          </p>
          {!compact && <p style={{ fontSize: 12, color: "#9CA3AF", margin: "2px 0 0" }}>Tesis: {res.fieldName || "Belirsiz"}</p>}
        </div>
        {(res.totalPrice || res.depositAmount) ? (
          <span style={{ fontSize: 15, fontWeight: 800, color: "#2E7D32" }}>
            ₺{(res.totalPrice || res.depositAmount || 0).toLocaleString("tr-TR")}
          </span>
        ) : null}
      </div>
      {(res.status === "pending_payment" || res.status === "approved" || res.status === "confirmed") && (
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          {(res.status === "pending_payment" || res.status === "confirmed") && (
            <>
              <button onClick={() => void onStatus(res.id, "approved")}
                style={{ padding: "8px 16px", borderRadius: 10, background: "#2E7D32", color: "#fff", fontWeight: 700, fontSize: 13, border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: 6 }}>
                <CheckCircle2 size={14} /> Onayla
              </button>
              <button onClick={() => void onStatus(res.id, "cancelled")}
                style={{ padding: "8px 16px", borderRadius: 10, background: "#FFF5F5", color: "#C62828", fontWeight: 700, fontSize: 13, border: "1px solid #FCA5A5", cursor: "pointer", display: "flex", alignItems: "center", gap: 6 }}>
                <XCircle size={14} /> İptal
              </button>
            </>
          )}
          {res.status === "approved" && (
            <>
              <button onClick={() => void onStatus(res.id, "completed")}
                style={{ padding: "8px 16px", borderRadius: 10, background: "#E3F2FD", color: "#1565C0", fontWeight: 700, fontSize: 13, border: "none", cursor: "pointer" }}>
                Tamamlandı
              </button>
              <button onClick={() => void onStatus(res.id, "no_show")}
                style={{ padding: "8px 16px", borderRadius: 10, background: "#F5F5F5", color: "#616161", fontWeight: 700, fontSize: 13, border: "none", cursor: "pointer" }}>
                Gelmedi
              </button>
            </>
          )}
        </div>
      )}
    </div>
  );
}

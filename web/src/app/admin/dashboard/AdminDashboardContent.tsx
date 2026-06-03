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
  query,
  where,
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
  Settings, Star, Trash2, TrendingUp, XCircle, AlertCircle, Activity, X
} from "lucide-react";
import CustomSelect from "@/frontend/components/common/CustomSelect";
import { useRouter } from "next/navigation";
import GoogleLocationMap from "@/frontend/components/map/GoogleLocationMap";

type AdminTab = "dashboard" | "bookings" | "facilities" | "reports" | "settings";
type ReservationStatus = "pending_payment" | "confirmed" | "approved" | "cancelled" | "completed" | "no_show" | string;
type Reservation = {
  id: string; facilityId?: string; pitchId?: string; fieldId?: string; fieldName?: string; userId?: string;
  userFullName?: string; userName?: string; pitchName?: string; facilityName?: string;
  date?: string | any; startHour?: number; endHour?: number; timeSlot?: string;
  status?: ReservationStatus; totalPrice?: number; depositAmount?: number;
};
type Facility = {
  id: string; name: string; address: string; phone: string;
  averageRating?: number; totalReviews?: number; features?: string[]; ownerId?: string; price?: number;
};
type Pitch = {
  id: string; facilityId: string; name: string; description?: string;
  pitchType: string; surfaceType: string; size: string; capacity: number;
  pricing: { daytimePrice: number; eveningPrice: number }; isActive?: boolean;
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
  if (s === "pending_payment" || s === "pending") return "Bekliyor";
  if (s === "confirmed") return "Kapora Ödendi";
  if (s === "approved") return "Onaylandı";
  if (s === "cancelled") return "İptal";
  if (s === "completed") return "Tamamlandı";
  if (s === "no_show") return "Gelmedi";
  return s || "Bilinmiyor";
};

const statusStyle = (s?: ReservationStatus): React.CSSProperties => {
  if (s === "pending_payment" || s === "pending") return { background: "#FFF3E0", color: "#E65100" };
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

const formatDateForSort = (d: any): string => {
  if (!d) return "";
  if (typeof d === "string") return d;
  if (d.toDate) {
    const dt = d.toDate();
    // Use local timezone format to match date picker, yyyy-mm-dd
    return dt.toLocaleDateString('en-CA'); 
  }
  if (d.seconds) {
    return new Date(d.seconds * 1000).toLocaleDateString('en-CA');
  }
  return "";
};

const formatDateForUI = (d: any): string => {
  if (!d) return "-";
  if (typeof d === "string") return d;
  if (d.toDate) return d.toDate().toLocaleDateString("tr-TR");
  if (d.seconds) return new Date(d.seconds * 1000).toLocaleDateString("tr-TR");
  return "-";
};

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
    name: "", address: "", phone: "",
    features: "Soyunma Odası, Otopark, Kantin",
    price: "350",
    latitude: 41.0082,
    longitude: 28.9784,
  });
  const [editingFacilityId, setEditingFacilityId] = useState<string | null>(null);
  const [showFacilityForm, setShowFacilityForm] = useState(false);
  const [adminProfile, setAdminProfile] = useState<any>(null);

  const [pitches, setPitches] = useState<Pitch[]>([]);
  const [notifications, setNotifications] = useState<any[]>([]);
  const [showPitchForm, setShowPitchForm] = useState(false);
  const [showSupportModal, setShowSupportModal] = useState(false);
  const [supportMessage, setSupportMessage] = useState("");
  const [isSendingSupport, setIsSendingSupport] = useState(false);
  const [activeFacilityIdForPitch, setActiveFacilityIdForPitch] = useState<string | null>(null);
  const [pitchForm, setPitchForm] = useState({
    name: "", pitchType: "outdoor", surfaceType: "syntheticGrass", size: "7v7",
    capacity: "14", daytimePrice: "500", eveningPrice: "700"
  });

  const facilityIds = useMemo(() => facilities.map((f) => f.id), [facilities]);

  const reservations = useMemo(
    () => allReservations.filter((r) => (r.facilityId && facilityIds.includes(r.facilityId)) || (r.fieldId && facilityIds.includes(r.fieldId))),
    [allReservations, facilityIds]
  );

  const sortedReservations = useMemo(
    () => [...reservations].sort((a, b) =>
      `${formatDateForSort(b.date)} ${b.timeSlot || ""}`.localeCompare(`${formatDateForSort(a.date)} ${a.timeSlot || ""}`)
    ),
    [reservations]
  );

  const pendingReservations = useMemo(
    () => sortedReservations.filter((r) => r.status === "pending_payment" || r.status === "pending"),
    [sortedReservations]
  );

  const todayISO = new Date().toLocaleDateString('en-CA');
  const todayReservations = useMemo(
    () => sortedReservations.filter((r) => formatDateForSort(r.date) === todayISO),
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
    const sum = facilities.reduce((s, f) => s + (f.averageRating || 0), 0);
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
    const qFields = query(collection(db, "facilities"), where("ownerId", "==", user.uid));
    const unsubFields = onSnapshot(qFields, (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Facility, "id">) }));
      setFacilities(list);
      setIsFallbackFacilityMode(false);
      setLoading(false);
    });
    const unsubRes = onSnapshot(collection(db, "bookings"), (snap) => {
      setAllReservations(snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Reservation, "id">) })));
      setLoading(false);
    });
    const unsubAdmin = onSnapshot(doc(db, "admins", user.uid), (docSnap) => {
      if (docSnap.exists()) setAdminProfile(docSnap.data());
    });
    return () => { unsubFields(); unsubRes(); unsubAdmin(); };
  }, [user]);

  useEffect(() => {
    if (!facilities.length) {
      setPitches([]);
      return;
    }
    const unsubs: (() => void)[] = [];
    const pitchesMap = new Map<string, Pitch[]>();
    
    facilities.forEach(f => {
      const u = onSnapshot(collection(db, "facilities", f.id, "pitches"), (snap) => {
        pitchesMap.set(f.id, snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Pitch, "id">) })));
        const allPitches: Pitch[] = [];
        pitchesMap.forEach(ps => allPitches.push(...ps));
        setPitches(allPitches);
      });
      unsubs.push(u);
    });
    return () => unsubs.forEach(u => u());
  }, [facilities]);

  const handleStatusUpdate = async (resId: string, newStatus: ReservationStatus, resUserId?: string, resFieldName?: string) => {
    try {
      await updateDoc(doc(db, "bookings", resId), { status: newStatus, updatedAt: serverTimestamp() });
      toast.success("Durum güncellendi.");
    } catch (err) {
      toast.error("Rezervasyon onayı hatası: " + err);
      return; // If booking update fails, don't send notification
    }
      
    // Bildirim Gönderme
    if (resUserId && (newStatus === "approved" || newStatus === "cancelled")) {
      try {
        let title = "Rezervasyon Güncellendi";
        let body = `Rezervasyon durumunuz güncellendi.`;
        if (newStatus === "approved") {
           title = "Rezervasyonunuz Onaylandı! ✅";
           body = `${resFieldName || "Tesis"} için yaptığınız rezervasyon saha sahibi tarafından onaylandı. İyi maçlar!`;
        } else if (newStatus === "cancelled") {
           title = "Rezervasyonunuz İptal Edildi ❌";
           body = `${resFieldName || "Tesis"} için yaptığınız rezervasyon maalesef saha sahibi tarafından iptal edildi.`;
        }
        await addDoc(collection(db, "notifications"), {
           userId: resUserId,
           title,
           body,
           type: "system",
           isRead: false,
           createdAt: serverTimestamp()
        });
      } catch (err) {
        toast.error("Bildirim gönderme hatası: " + err);
      }
    }
  };

  const resetFacilityForm = () => {
    setFacilityForm({ 
      name: "", address: "", phone: "", features: "Soyunma Odası, Otopark, Kantin", price: "350",
      latitude: 41.0082, longitude: 28.9784 
    });
    setEditingFacilityId(null);
    setShowFacilityForm(false);
  };

  const handleFacilitySave = async () => {
    if (!user) return;
    if (!facilityForm.name.trim() || !facilityForm.address.trim()) { toast.error("Tesis adı ve adres zorunlu."); return; }
    
    // For updates, we don't send rating/reviews to avoid overwriting them
    const basePayload = {
      name: facilityForm.name.trim(), address: facilityForm.address.trim(),
      phone: facilityForm.phone.trim(),
      features: facilityForm.features.split(",").map((f) => f.trim()).filter(Boolean),
      price: Number(facilityForm.price || 350),
      latitude: facilityForm.latitude,
      longitude: facilityForm.longitude,
      ownerId: user.uid, updatedAt: serverTimestamp(),
    };

    try {
      if (editingFacilityId) {
        await updateDoc(doc(db, "facilities", editingFacilityId), basePayload);
        toast.success("Tesis güncellendi.");
      } else {
        await addDoc(collection(db, "facilities"), { 
          ...basePayload, 
          averageRating: 0,
          totalReviews: 0,
          createdAt: serverTimestamp() 
        });
        toast.success("Yeni tesis eklendi.");
      }
      resetFacilityForm();
    } catch (err) { toast.error("Tesis kaydedilemedi: " + err); }
  };

  const startEditFacility = (facility: Facility) => {
    setEditingFacilityId(facility.id);
    setFacilityForm({
      name: facility.name || "", address: facility.address || "", phone: facility.phone || "",
      features: (facility.features || []).join(", "),
      price: String(facility.price || 350),
      latitude: facility.latitude || 41.0082,
      longitude: facility.longitude || 28.9784,
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

  const resetPitchForm = () => {
    setActiveFacilityIdForPitch(null);
    setPitchForm({ name: "", pitchType: "outdoor", surfaceType: "syntheticGrass", size: "7v7", capacity: "14", daytimePrice: "500", eveningPrice: "700" });
    setShowPitchForm(false);
  };

  const startAddPitch = (facilityId: string) => {
    setActiveFacilityIdForPitch(facilityId);
    setPitchForm({ name: "", pitchType: "outdoor", surfaceType: "syntheticGrass", size: "7v7", capacity: "14", daytimePrice: "500", eveningPrice: "700" });
    setShowPitchForm(true);
  };

  const handlePitchSave = async () => {
    if (!activeFacilityIdForPitch) return;
    if (!pitchForm.name.trim()) { toast.error("Saha adı zorunlu."); return; }
    try {
      await addDoc(collection(db, "facilities", activeFacilityIdForPitch, "pitches"), {
        facilityId: activeFacilityIdForPitch,
        name: pitchForm.name.trim(),
        pitchType: pitchForm.pitchType,
        surfaceType: pitchForm.surfaceType,
        size: pitchForm.size,
        capacity: Number(pitchForm.capacity || 10),
        pricing: {
          daytimePrice: Number(pitchForm.daytimePrice || 500),
          eveningPrice: Number(pitchForm.eveningPrice || 700),
        },
        isActive: true,
        createdAt: serverTimestamp(),
      });
      toast.success("Alt Saha eklendi.");
      resetPitchForm();
    } catch (err) { toast.error("Saha kaydedilemedi: " + err); }
  };

  const handleDeletePitch = async (facilityId: string, pitchId: string) => {
    if (!window.confirm("Bu sahayı silmek istediğine emin misin?")) return;
    try {
      await deleteDoc(doc(db, "facilities", facilityId, "pitches", pitchId));
      toast.success("Saha silindi.");
    } catch (err) { toast.error("Saha silinemedi: " + err); }
  };

  const handleLogout = async () => {
    await signOut(auth);
    toast.success("Çıkış yapıldı.");
    router.push("/login");
  };

  const handleSendSupport = async () => {
    if (!user || !supportMessage.trim()) return;
    setIsSendingSupport(true);
    try {
      await addDoc(collection(db, "supportTickets"), {
        userId: user.uid,
        userEmail: user.email || "Email yok",
        message: supportMessage.trim(),
        status: "open",
        createdAt: serverTimestamp()
      });
      toast.success("Destek talebiniz başarıyla gönderildi!");
      setSupportMessage("");
      setShowSupportModal(false);
    } catch (error) {
      toast.error("Talep gönderilemedi. Lütfen bağlantınızı kontrol edin.");
    } finally {
      setIsSendingSupport(false);
    }
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
          <QuickBtn label="Yeni Tesis" icon={<Building2 size={20} color="#2E7D32" />} bg="#E8F5E9"
            onClick={() => { setSelectedTab("facilities"); setShowFacilityForm(true); }} />
          <QuickBtn label="Yeni Saha" icon={<Plus size={20} color="#2E7D32" />} bg="#E8F5E9"
            onClick={() => { setSelectedTab("facilities"); }} />
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
                {f.averageRating !== undefined && f.averageRating > 0 ? (
                  <div style={{ display: "flex", alignItems: "center", gap: 4, background: "#FFF9C4", borderRadius: 8, padding: "4px 8px" }}>
                    <Star size={12} color="#F9A825" fill="#F9A825" />
                    <span style={{ fontSize: 12, fontWeight: 700, color: "#795548" }}>{f.averageRating.toFixed(1)}</span>
                  </div>
                ) : (
                  <div style={{ display: "flex", alignItems: "center", gap: 4, background: "#F3F4F6", borderRadius: 8, padding: "4px 8px" }}>
                    <Star size={12} color="#9CA3AF" />
                    <span style={{ fontSize: 12, fontWeight: 600, color: "#6B7280" }}>Yeni Tesis</span>
                  </div>
                )}
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
                  {facility.averageRating !== undefined && facility.averageRating > 0 ? (
                    <div style={{ display: "inline-flex", alignItems: "center", gap: 4, marginTop: 6, background: "#FFF9C4", borderRadius: 8, padding: "3px 8px" }}>
                      <Star size={12} color="#F9A825" fill="#F9A825" />
                      <span style={{ fontSize: 12, fontWeight: 700, color: "#795548" }}>{facility.averageRating.toFixed(1)}</span>
                      <span style={{ fontSize: 10, color: "#9CA3AF", marginLeft: 2 }}>({facility.totalReviews || 0})</span>
                    </div>
                  ) : (
                    <div style={{ display: "inline-flex", alignItems: "center", gap: 4, marginTop: 6, background: "#F3F4F6", borderRadius: 8, padding: "3px 8px" }}>
                      <Star size={12} color="#9CA3AF" />
                      <span style={{ fontSize: 12, fontWeight: 600, color: "#6B7280" }}>Yeni Tesis</span>
                    </div>
                  )}
                  {facility.features?.length ? (
                    <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginTop: 10 }}>
                      {facility.features.map((feat) => (
                        <span key={feat} style={{ padding: "3px 10px", borderRadius: 20, background: "#E8F5E9", color: "#2E7D32", fontSize: 12, fontWeight: 600 }}>{feat}</span>
                      ))}
                    </div>
                  ) : null}

                  {/* Pitches List */}
                  <div style={{ marginTop: 16, paddingTop: 16, borderTop: "1px solid #E5E7EB" }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                      <h4 style={{ fontSize: 14, fontWeight: 700, color: "#374151", margin: 0 }}>
                        Alt Sahalar ({pitches.filter(p => p.facilityId === facility.id).length})
                      </h4>
                      <button onClick={() => startAddPitch(facility.id)}
                        style={{ color: "#2E7D32", fontSize: 13, fontWeight: 600, background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: 4 }}>
                        <Plus size={14} /> Saha Ekle
                      </button>
                    </div>
                    {pitches.filter(p => p.facilityId === facility.id).map(pitch => (
                      <div key={pitch.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 12px", background: "#FAFAFA", borderRadius: 10, marginTop: 8 }}>
                        <div>
                          <p style={{ margin: 0, fontSize: 14, fontWeight: 600, color: "#111827" }}>{pitch.name}</p>
                          <p style={{ margin: 0, fontSize: 12, color: "#6B7280" }}>
                            {pitch.size} • Kapasite: {pitch.capacity} Kişi • {pitch.pitchType === 'indoor' ? 'Kapalı' : 'Açık'}
                          </p>
                        </div>
                        <button onClick={() => handleDeletePitch(facility.id, pitch.id)}
                          style={{ color: "#EF4444", background: "none", border: "none", cursor: "pointer", padding: 4 }}>
                          <Trash2 size={16} />
                        </button>
                      </div>
                    ))}
                  </div>

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
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
            {/* Sol Taraf: Girdiler */}
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              {[
                { key: "name", ph: "Tesis adı *", type: "text" },
                { key: "phone", ph: "Telefon numarası", type: "tel" },
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
            
            {/* Sağ Taraf: Harita */}
            <div style={{ display: "flex", flexDirection: "column" }}>
              <p style={{ fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 8 }}>Harita Konumu (Zorunlu değil, ama önerilir)</p>
              <div style={{ flex: 1, minHeight: "250px" }}>
                <GoogleLocationMap 
                  position={[facilityForm.latitude, facilityForm.longitude]} 
                  onChange={([lat, lng]) => setFacilityForm(s => ({ ...s, latitude: lat, longitude: lng }))}
                />
              </div>
            </div>
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
      {showPitchForm && (
        <div style={cardStyle}>
          <h3 style={{ ...sectionTitle, marginBottom: 16 }}>Yeni Saha Ekle</h3>
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <input type="text" placeholder="Saha adı (örn: Saha A) *" value={pitchForm.name} onChange={e => setPitchForm(s => ({...s, name: e.target.value}))} style={inputStyle} />
            <CustomSelect
              options={[
                { value: "outdoor", label: "Açık Saha" },
                { value: "indoor", label: "Kapalı Saha" },
                { value: "covered", label: "Yarı Kapalı Saha" },
              ]}
              value={pitchForm.pitchType}
              onChange={(val) => setPitchForm(s => ({ ...s, pitchType: val }))}
            />
            <CustomSelect
              options={[
                { value: "syntheticGrass", label: "Sentetik Çim" },
                { value: "naturalGrass", label: "Doğal Çim" },
                { value: "hybrid", label: "Hibrit" },
                { value: "artificial", label: "Yapay Zemin" },
              ]}
              value={pitchForm.surfaceType}
              onChange={(val) => setPitchForm(s => ({ ...s, surfaceType: val }))}
            />
            <div style={{ display: "flex", gap: 10 }}>
              <input type="text" placeholder="Boyut (örn: 7v7)" value={pitchForm.size} onChange={e => setPitchForm(s => ({...s, size: e.target.value}))} style={{...inputStyle, flex: 1}} />
              <input type="number" placeholder="Kapasite (Kişi)" value={pitchForm.capacity} onChange={e => setPitchForm(s => ({...s, capacity: e.target.value}))} style={{...inputStyle, flex: 1}} />
            </div>
            <div style={{ display: "flex", gap: 10 }}>
              <input type="number" placeholder="Gündüz Ücreti (₺)" value={pitchForm.daytimePrice} onChange={e => setPitchForm(s => ({...s, daytimePrice: e.target.value}))} style={{...inputStyle, flex: 1}} />
              <input type="number" placeholder="Akşam Ücreti (₺)" value={pitchForm.eveningPrice} onChange={e => setPitchForm(s => ({...s, eveningPrice: e.target.value}))} style={{...inputStyle, flex: 1}} />
            </div>
          </div>
          <div style={{ display: "flex", gap: 10, marginTop: 16 }}>
            <button onClick={handlePitchSave} style={{ flex: 1, padding: 12, borderRadius: 12, background: "#2E7D32", color: "#fff", fontWeight: 700, fontSize: 15, border: "none", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}>
              <Plus size={18} /> Ekle
            </button>
            <button onClick={resetPitchForm} style={{ padding: "12px 20px", borderRadius: 12, border: "1px solid #E5E7EB", background: "#fff", color: "#374151", fontWeight: 600, fontSize: 14, cursor: "pointer" }}>
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
                { key: "pushNotificationsEnabled", label: "Bildirimler" },
                { key: "emailNotificationsEnabled", label: "E-posta Özeti" },
                { key: "autoConfirmBookings", label: "Otomatik Onay" },
              ].map((item) => {
                const active = adminProfile?.[item.key] ?? false;
                return (
                <button key={item.label}
                  onClick={async () => {
                    if(!user) return;
                    try {
                      await updateDoc(doc(db, "admins", user.uid), { [item.key]: !active, updatedAt: serverTimestamp() });
                      toast.success(`${item.label} güncellendi.`);
                    } catch (e) {
                      toast.error("Hata: Güncellenemedi.");
                    }
                  }}
                  style={{
                    borderRadius: 12,
                    border: "none",
                    cursor: "pointer",
                    background: active ? "#2E7D32" : "#E5E7EB",
                    color: active ? "#fff" : "#6B7280",
                    padding: "10px 12px",
                    fontSize: 13,
                    fontWeight: 700,
                    textAlign: "left",
                  }}>
                  {item.label}
                </button>
              )})}
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
                { icon: <AlertCircle size={18} color="#2E7D32" />, title: "Tesisleri Düzenle", sub: "Tesis bilgilerini güncelle", action: () => setSelectedTab("facilities") },
                { icon: <BarChart3 size={18} color="#6A1B9A" />, title: "Raporlar", sub: "Gelir ve doluluk raporları", action: () => setSelectedTab("reports") },
                { icon: <Activity size={18} color="#E65100" />, title: "Destek", sub: "Bize ulaşın ve geri bildirim verin", action: () => setShowSupportModal(true) },
              ].map((item) => (
                <div key={item.title} onClick={item.action} style={{ display: "flex", alignItems: "center", gap: 12, borderRadius: 12, padding: "12px 10px", background: "rgba(255,255,255,0.6)", border: "1px solid #E5E7EB", cursor: "pointer", transition: "all 0.2s" }}>
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

      {/* Support Modal Overlay */}
      {showSupportModal && (
        <div style={{ position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(0,0,0,0.5)", backdropFilter: "blur(4px)", zIndex: 100, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <div style={{ ...cardStyle, width: "90%", maxWidth: 400, position: "relative" }}>
            <button onClick={() => setShowSupportModal(false)}
              style={{ position: "absolute", top: 16, right: 16, background: "none", border: "none", cursor: "pointer", color: "#9CA3AF" }}>
              <X size={20} />
            </button>
            <h3 style={{ ...sectionTitle, marginBottom: 8 }}>Destek Talebi</h3>
            <p style={{ fontSize: 13, color: "#6B7280", marginBottom: 16, lineHeight: 1.4 }}>
              Karşılaştığınız bir sorunu veya önerinizi bize iletebilirsiniz. Ekibimiz en kısa sürede değerlendirecektir.
            </p>
            <textarea
              value={supportMessage}
              onChange={(e) => setSupportMessage(e.target.value)}
              placeholder="Mesajınızı buraya yazın..."
              rows={4}
              style={{ ...inputStyle, resize: "vertical", marginBottom: 16 }}
            />
            <div style={{ display: "flex", gap: 10 }}>
              <button onClick={() => setShowSupportModal(false)}
                style={{ flex: 1, padding: "10px", borderRadius: 12, border: "1px solid #E5E7EB", background: "#fff", color: "#374151", fontWeight: 600, cursor: "pointer" }}>
                İptal
              </button>
              <button onClick={handleSendSupport} disabled={isSendingSupport || !supportMessage.trim()}
                style={{ flex: 1, padding: "10px", borderRadius: 12, border: "none", background: supportMessage.trim() ? "#2E7D32" : "#A5D6A7", color: "#fff", fontWeight: 700, cursor: supportMessage.trim() ? "pointer" : "not-allowed", display: "flex", alignItems: "center", justifyContent: "center" }}>
                {isSendingSupport ? "Gönderiliyor..." : "Gönder"}
              </button>
            </div>
          </div>
        </div>
      )}
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

function BookingCard({ res, onStatus, compact = false }: { res: Reservation; onStatus: (id: string, s: ReservationStatus, userId?: string, fieldName?: string) => Promise<void>; compact?: boolean }) {
  const isPending = res.status === "pending_payment" || res.status === "pending";
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
            <Clock3 size={13} /> {formatDateForUI(res.date)} • {res.timeSlot || "-"}
          </p>
          {!compact && <p style={{ fontSize: 12, color: "#9CA3AF", margin: "2px 0 0" }}>Tesis: {res.fieldName || res.facilityName || "Belirsiz"}</p>}
          {!compact && res.pitchName && <p style={{ fontSize: 12, color: "#9CA3AF", margin: "2px 0 0" }}>Saha: {res.pitchName}</p>}
        </div>
        {(res.totalPrice || res.depositAmount) ? (
          <span style={{ fontSize: 15, fontWeight: 800, color: "#2E7D32" }}>
            ₺{(res.totalPrice || res.depositAmount || 0).toLocaleString("tr-TR")}
          </span>
        ) : null}
      </div>
      {(isPending || res.status === "approved" || res.status === "confirmed") && (
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          {(isPending || res.status === "confirmed") && (
            <>
              <button onClick={() => void onStatus(res.id, "approved", res.userId, res.fieldName || res.facilityName)}
                style={{ padding: "8px 16px", borderRadius: 10, background: "#2E7D32", color: "#fff", fontWeight: 700, fontSize: 13, border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: 6 }}>
                <CheckCircle2 size={14} /> Onayla
              </button>
              <button onClick={() => void onStatus(res.id, "cancelled", res.userId, res.fieldName || res.facilityName)}
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

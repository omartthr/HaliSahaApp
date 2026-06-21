// Backend Service: Admin ve kullanıcı yönetimi — Firestore koleksiyonları: admins, users

import {
  collection,
  doc,
  getDoc,
  setDoc,
  updateDoc,
  onSnapshot,
  query,
  where,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "@/database/firebase";

export type AdminRecord = {
  id: string;
  approvalStatus?: string;
  [key: string]: unknown;
};

/** Onay bekleyen adminleri realtime dinle */
export function getPendingAdminsRealtime(callback: (admins: AdminRecord[]) => void) {
  const q = query(collection(db, "admins"), where("approvalStatus", "==", "pending"));
  return onSnapshot(q, (snap) => {
    const admins = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    callback(admins);
  });
}

/** Admin onayla */
export async function approveAdmin(adminId: string) {
  return updateDoc(doc(db, "admins", adminId), {
    approvalStatus: "approved",
    approvedAt: serverTimestamp(),
  });
}

/** Admin reddet */
export async function rejectAdmin(adminId: string) {
  return updateDoc(doc(db, "admins", adminId), {
    approvalStatus: "rejected",
    rejectedAt: serverTimestamp(),
  });
}

/**
 * Web'de seçilen Türkçe mevki etiketini iOS `PlayerPosition` enum raw değerine çevirir.
 * iOS tarafı `preferredPosition`'ı ("goalkeeper" vb.) zorunlu enum olarak decode eder.
 */
const POSITION_TR_TO_RAW: Record<string, string> = {
  Kaleci: "goalkeeper",
  Defans: "defender",
  "Orta Saha": "midfielder",
  Forvet: "forward",
};

function toPositionRaw(value?: string): string {
  if (!value) return "unspecified";
  return POSITION_TR_TO_RAW[value] ?? value; // zaten enum raw olabilir
}

/**
 * Yeni kullanıcı kaydı (Firestore profil).
 *
 * ÖNEMLİ: iOS `User` modeli (User.swift) bir dizi alanı ZORUNLU (non-optional) bekler.
 * Bu alanlar eksikse iOS dökümanı decode edemez ve kullanıcı (ör. maç başvuruları
 * ekranında) hiç görünmez. Bu yüzden web kaydında iOS ile birebir uyumlu, tüm zorunlu
 * alanları varsayılanlarıyla içeren tam bir profil yazıyoruz.
 */
export async function createUserProfile(
  uid: string,
  data: Record<string, unknown>
) {
  const preferredPosition = toPositionRaw(
    (data.preferredPosition as string) ?? (data.position as string)
  );

  // iOS User modeliyle uyumlu zorunlu alan varsayılanları.
  const base: Record<string, unknown> = {
    email: "",
    firstName: "",
    lastName: "",
    username: "",
    phone: "",
    profileImageURL: null,
    userType: "player",
    followers: [],
    following: [],
    favoriteFields: [],
    reliabilityScore: 5.0,
    totalMatches: 0,
    attendedMatches: 0,
    isActive: true,
  };

  // `createdAt` iOS tarafında Date (Timestamp) olarak decode edilir; caller ISO
  // string gönderse bile yok sayıp serverTimestamp() ile gerçek Timestamp yazıyoruz.
  const merged: Record<string, unknown> = {
    ...base,
    ...data,
    preferredPosition, // normalize edilmiş enum raw — "position" da korunur (web gösterimi)
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };

  return setDoc(doc(db, "users", uid), merged, { merge: true });
}

/** Yeni admin kaydı (Firestore) */
export async function createAdminProfile(uid: string, data: object) {
  return setDoc(
    doc(db, "admins", uid),
    {
      uid,
      ...data,
      updatedAt: serverTimestamp(),
    },
    { merge: true }
  );
}

/** UID ile admin belgesi getir */
export async function getAdminByUid(uid: string) {
  const snap = await getDoc(doc(db, "admins", uid));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() } as AdminRecord;
}

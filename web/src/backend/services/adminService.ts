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

/** Yeni kullanıcı kaydı (Firestore profil) */
export async function createUserProfile(uid: string, data: object) {
  return setDoc(
    doc(db, "users", uid),
    {
      ...data,
      updatedAt: serverTimestamp(),
    },
    { merge: true }
  );
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

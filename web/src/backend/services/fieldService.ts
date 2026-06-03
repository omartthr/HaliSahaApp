// Backend Service: Saha (Field) işlemleri — Firestore koleksiyonu: facilities

import {
  collection,
  doc,
  getDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  query,
  where,
  serverTimestamp,
  getDocs,
} from "firebase/firestore";
import { db } from "@/database/firebase";

export type FieldRecord = {
  id: string;
  [key: string]: unknown;
};

const COLLECTION = "facilities";

/** Tüm sahaları çek */
export function getFieldsRealtime(callback: (fields: FieldRecord[]) => void) {
  const q = collection(db, COLLECTION);
  return onSnapshot(q, (snap) => {
    const fields = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    callback(fields);
  });
}

/** Belirli bir admin'e ait sahaları çek */
export function getFieldsByOwner(ownerId: string, callback: (fields: FieldRecord[]) => void) {
  const q = query(collection(db, COLLECTION), where("ownerId", "==", ownerId));
  return onSnapshot(q, (snap) => {
    const fields = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    callback(fields);
  });
}

/** Tek saha çek */
export async function getField(fieldId: string) {
  const ref = doc(db, COLLECTION, fieldId);
  const snap = await getDoc(ref);
  if (!snap.exists()) return null;
  
  const fieldData = { id: snap.id, ...snap.data() };
  
  // Alt sahaları (pitches) çek
  const pitchesSnap = await getDocs(collection(db, COLLECTION, fieldId, "pitches"));
  const pitches = pitchesSnap.docs.map(d => ({ id: d.id, ...d.data() }));
  
  return { ...fieldData, pitches };
}

/** Yeni saha ekle */
export async function addField(data: object) {
  return addDoc(collection(db, COLLECTION), { ...data, createdAt: serverTimestamp() });
}

/** Saha güncelle */
export async function updateField(fieldId: string, data: object) {
  return updateDoc(doc(db, COLLECTION, fieldId), { ...data, updatedAt: serverTimestamp() });
}

/** Saha sil */
export async function deleteField(fieldId: string) {
  return deleteDoc(doc(db, COLLECTION, fieldId));
}

/** Saha için ortalama puanı hesapla */
export async function getFieldAverageRating(fieldId: string): Promise<number> {
  const q = query(collection(db, "reviews"), where("fieldId", "==", fieldId));
  const snap = await getDocs(q);

  if (snap.empty) return 0;

  const ratings = snap.docs.map((d) => d.data().rating);
  const average = ratings.reduce((a, b) => a + b, 0) / ratings.length;

  return Math.round(average * 100) / 100;
}

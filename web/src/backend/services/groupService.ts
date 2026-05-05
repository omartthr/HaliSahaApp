// Backend Service: Grup ve chat işlemleri — Firestore koleksiyonları: groups, groups/{id}/messages

import {
  collection,
  doc,
  getDoc,
  addDoc,
  onSnapshot,
  query,
  orderBy,
  limit,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "@/database/firebase";

export type GroupRecord = {
  id: string;
  [key: string]: unknown;
};

export type GroupMessageRecord = {
  id: string;
  text?: string;
  senderId?: string;
  senderName?: string;
  createdAt?: unknown;
  [key: string]: unknown;
};

/** Tek grup getir */
export async function getGroupById(groupId: string) {
  const snap = await getDoc(doc(db, "groups", groupId));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() };
}

/** Gruba ait mesajları realtime dinle */
export function getGroupMessagesRealtime(groupId: string, callback: (messages: GroupMessageRecord[]) => void) {
  const q = query(
    collection(db, "groups", groupId, "messages"),
    orderBy("createdAt", "asc"),
    limit(100)
  );
  return onSnapshot(q, (snap) => {
    const messages = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    callback(messages);
  });
}

/** Gruba mesaj gönder */
export async function sendGroupMessage(
  groupId: string,
  data: { text: string; senderId: string; senderName: string }
) {
  return addDoc(collection(db, "groups", groupId, "messages"), {
    ...data,
    createdAt: serverTimestamp(),
  });
}

/** Yeni grup/maç ilanı oluştur */
export async function createGroup(data: object) {
  return addDoc(collection(db, "groups"), {
    ...data,
    createdAt: serverTimestamp(),
  });
}

/** Tüm grupları realtime dinle */
export function getGroupsRealtime(callback: (groups: GroupRecord[]) => void) {
  const q = query(collection(db, "groups"), orderBy("createdAt", "desc"));
  return onSnapshot(q, (snap) => {
    const groups = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    callback(groups);
  });
}

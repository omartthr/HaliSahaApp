// Backend Service: Grup ve chat işlemleri — Firestore koleksiyonları: groups, groups/{id}/messages

import {
  collection,
  doc,
  getDoc,
  getDocs,
  addDoc,
  onSnapshot,
  query,
  where,
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
  content?: string;
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
  data: { content: string; senderId: string; senderName: string }
) {
  return addDoc(collection(db, "groups", groupId, "messages"), {
    ...data,
    groupId,
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

/** Birebir (DM) sohbet getir veya oluştur */
export async function getOrCreateDirectChat(uid1: string, uid2: string, userName1: string, userName2: string) {
  const q = query(
    collection(db, "groups"),
    where("isDirectMessage", "==", true),
    where("memberIds", "array-contains", uid1)
  );
  const snap = await getDocs(q);
  const existingDoc = snap.docs.find(d => {
    const data = d.data();
    return data.memberIds && data.memberIds.includes(uid2);
  });

  if (existingDoc) {
    return { id: existingDoc.id, ...existingDoc.data() };
  }

  // Create new DM
  const newDoc = await addDoc(collection(db, "groups"), {
    isDirectMessage: true,
    memberIds: [uid1, uid2],
    maxMembers: 2,
    name: `${userName1} & ${userName2}`,
    creatorId: uid1,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  
  return { id: newDoc.id, isDirectMessage: true, memberIds: [uid1, uid2], name: `${userName1} & ${userName2}` };
}

/** Tüm grupları realtime dinle */
export function getGroupsRealtime(callback: (groups: GroupRecord[]) => void) {
  const q = query(collection(db, "groups"), orderBy("createdAt", "desc"));
  return onSnapshot(q, (snap) => {
    const groups = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    callback(groups);
  });
}

/** Kullanıcının dahil olduğu grupları realtime dinle */
export function getMyGroupsRealtime(userId: string, callback: (groups: GroupRecord[]) => void) {
  const q = query(
    collection(db, "groups"),
    where("memberIds", "array-contains", userId)
  );
  return onSnapshot(q, (snap) => {
    const groups = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    groups.sort((a, b) => ((b.updatedAt as any)?.toMillis?.() || 0) - ((a.updatedAt as any)?.toMillis?.() || 0));
    callback(groups);
  });
}

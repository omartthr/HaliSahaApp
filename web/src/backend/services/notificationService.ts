import { collection, addDoc, query, where, onSnapshot, doc, updateDoc, serverTimestamp } from "firebase/firestore";
import { db } from "@/database/firebase";

export type NotificationRecord = {
  id: string;
  userId: string;
  title: string;
  body: string;
  type: string;
  senderId?: string;
  senderName?: string;
  isRead?: boolean;
  status?: string; // 'pending', 'accepted', 'rejected'
  createdAt?: any;
};

export async function sendInviteNotification(targetUserId: string, senderId: string, senderName: string) {
  return addDoc(collection(db, "notifications"), {
    userId: targetUserId,
    title: "Yeni Davet",
    body: `${senderName} seni maçına davet ediyor.`,
    type: "invite",
    senderId,
    senderName,
    isRead: false,
    status: "pending",
    createdAt: serverTimestamp()
  });
}

export async function sendNotification(data: Partial<NotificationRecord> & { userId: string; type: string; title: string; body: string; relatedId?: string }) {
  return addDoc(collection(db, "notifications"), {
    ...data,
    isRead: false,
    status: data.type === "invite" ? "pending" : "unread",
    createdAt: serverTimestamp()
  });
}

export function getMyNotificationsRealtime(userId: string, callback: (notifs: NotificationRecord[]) => void) {
  const q = query(collection(db, "notifications"), where("userId", "==", userId));
  return onSnapshot(q, (snap) => {
    const notifs = snap.docs.map(d => ({ id: d.id, ...d.data() } as NotificationRecord));
    callback(notifs);
  });
}

export async function updateNotificationStatus(notifId: string, status: string) {
  return updateDoc(doc(db, "notifications", notifId), {
    status,
    isRead: true,
    updatedAt: serverTimestamp()
  });
}

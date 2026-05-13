// Backend Service: Rezervasyon işlemleri — Firestore koleksiyonu: bookings

import {
  collection,
  doc,
  addDoc,
  updateDoc,
  onSnapshot,
  query,
  where,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "@/database/firebase";

export type BookingRecord = {
  id: string;
  timeSlot?: string;
  [key: string]: unknown;
};

const COLLECTION = "bookings";

/** Yeni rezervasyon oluştur */
export async function createBooking(data: {
  fieldId: string;
  fieldName: string;
  userId: string;
  userName: string;
  date: string;
  timeSlot: string;
  status?: string;
}) {
  return addDoc(collection(db, COLLECTION), {
    ...data,
    status: data.status ?? "pending_payment",
    createdAt: serverTimestamp(),
  });
}

export function getUserBookingsRealtime(userId: string, callback: (bookings: BookingRecord[]) => void) {
  const q = query(collection(db, COLLECTION), where("userId", "==", userId));
  return onSnapshot(q, (snap) => {
    const bookings = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    callback(bookings);
  }, (error) => {
    console.warn("Error fetching user bookings (permission ignored for now):", error);
    callback([]);
  });
}

/** Belirli bir sahadaki dolu slotları realtime dinle */
export function getFieldBookedSlotsRealtime(
  fieldId: string,
  date: string,
  callback: (slots: string[]) => void
) {
  const q = query(
    collection(db, COLLECTION),
    where("fieldId", "==", fieldId),
    where("date", "==", date)
  );
  return onSnapshot(q, (snap) => {
    const slots = snap.docs
      .map((d) => (d.data() as { timeSlot?: string }).timeSlot)
      .filter((slot): slot is string => Boolean(slot));
    callback(slots);
  }, (error) => {
    console.error("Error fetching booked slots:", error);
    // Return empty array on error (e.g. permission denied)
    callback([]);
  });
}

/** Rezervasyon durumunu güncelle */
export async function updateBookingStatus(bookingId: string, status: string) {
  return updateDoc(doc(db, COLLECTION, bookingId), { status, updatedAt: serverTimestamp() });
}

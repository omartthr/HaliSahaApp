import {
  collection,
  doc,
  addDoc,
  updateDoc,
  onSnapshot,
  query,
  where,
  serverTimestamp,
  arrayUnion,
  arrayRemove,
  getDocs,
} from "firebase/firestore";
import { db } from "@/database/firebase";

export type MatchPostStatus = "active" | "full" | "completed" | "cancelled" | "expired";
export type SkillLevel = "beginner" | "intermediate" | "advanced" | "professional" | "any";

export type MatchPost = {
  id?: string;
  creatorId: string;
  creatorName: string;
  creatorProfileImage?: string;
  bookingId: string;
  facilityId: string;
  facilityName: string;
  facilityAddress: string;
  pitchName: string;
  matchDate: string; 
  startHour: number;
  endHour: number;
  title: string;
  description?: string;
  neededPlayers: number;
  currentPlayers: number;
  maxPlayers: number;
  preferredPositions?: string[];
  skillLevel: SkillLevel;
  costPerPlayer?: number;
  applicantIds: string[];
  acceptedIds: string[];
  rejectedIds: string[];
  status: MatchPostStatus;
  createdAt?: any;
  updatedAt?: any;
  expiresAt?: any;
};

const COLLECTION = "match_posts";

/** Yeni maç ilanı (MatchPost) oluştur */
export async function createMatchPost(data: Omit<MatchPost, "id" | "applicantIds" | "acceptedIds" | "rejectedIds" | "status" | "createdAt" | "updatedAt">) {
  // Check if active post already exists for this booking
  const q = query(
    collection(db, COLLECTION), 
    where("bookingId", "==", data.bookingId),
    where("status", "==", "active")
  );
  const snap = await getDocs(q);
  if (!snap.empty) {
    throw new Error("Bu randevu için zaten aktif bir maç ilanı var.");
  }

  return addDoc(collection(db, COLLECTION), {
    ...data,
    applicantIds: [],
    acceptedIds: [],
    rejectedIds: [],
    status: "active",
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
}

/** Maç ilanlarını realtime dinle */
export function getActiveMatchPostsRealtime(callback: (posts: MatchPost[]) => void) {
  const q = query(collection(db, COLLECTION), where("status", "==", "active"));
  return onSnapshot(q, (snap) => {
    const posts = snap.docs.map((d) => ({ id: d.id, ...d.data() } as MatchPost));
    callback(posts);
  });
}

/** Maça başvur (Apply) */
export async function applyToMatchPost(postId: string, userId: string) {
  return updateDoc(doc(db, COLLECTION, postId), {
    applicantIds: arrayUnion(userId),
    updatedAt: serverTimestamp()
  });
}

/** Başvuruyu kabul et */
export async function acceptApplication(postId: string, userId: string) {
  return updateDoc(doc(db, COLLECTION, postId), {
    acceptedIds: arrayUnion(userId),
    updatedAt: serverTimestamp()
  });
}

/** Başvuruyu reddet */
export async function rejectApplication(postId: string, userId: string) {
  return updateDoc(doc(db, COLLECTION, postId), {
    rejectedIds: arrayUnion(userId),
    updatedAt: serverTimestamp()
  });
}

/** İlan durumunu güncelle */
export async function updateMatchPostStatus(postId: string, status: MatchPostStatus) {
  return updateDoc(doc(db, COLLECTION, postId), {
    status,
    updatedAt: serverTimestamp()
  });
}

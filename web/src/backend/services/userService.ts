import { collection, getDocs, query, where, doc, getDoc } from "firebase/firestore";
import { db } from "@/database/firebase";

export type UserProfile = {
  id: string;
  firstName: string;
  lastName: string;
  username?: string;
  position?: string;
  userType: string;
  averageRating?: number; // Fetched from playerRatings
  matchCount?: number;
  [key: string]: any;
};

export async function getAllPlayers(): Promise<UserProfile[]> {
  const q = query(collection(db, "users"), where("userType", "==", "player"));
  const snap = await getDocs(q);
  return snap.docs.map(d => ({ id: d.id, ...d.data() } as UserProfile));
}

export async function getUserProfile(uid: string): Promise<UserProfile | null> {
  const snap = await getDoc(doc(db, "users", uid));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() } as UserProfile;
}

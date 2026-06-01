import {
  collection,
  doc,
  getDocs,
  query,
  setDoc,
  where,
  getDoc,
  QueryConstraint,
  serverTimestamp,
  Query,
} from "firebase/firestore";
import { db } from "@/database/firebase";

// ===== OYUNCU PUANLAMA =====

export async function ratePlayer(
  matchId: string,
  raterId: string,
  ratedId: string,
  rating: number
): Promise<void> {
  if (rating < 1 || rating > 5) throw new Error("Rating must be between 1 and 5");
  if (raterId === ratedId) throw new Error("Cannot rate yourself");

  const docId = `${matchId}_${raterId}_${ratedId}`;
  await setDoc(
    doc(collection(db, "playerRatings"), docId),
    {
      matchId,
      raterId,
      ratedId,
      rating,
      createdAt: serverTimestamp(),
    },
    { merge: true }
  );
}

export async function hasRatedPlayer(
  matchId: string,
  raterId: string,
  ratedId: string
): Promise<boolean> {
  const docId = `${matchId}_${raterId}_${ratedId}`;
  const snap = await getDoc(doc(collection(db, "playerRatings"), docId));
  return snap.exists();
}

export async function getMatchRatingsForUser(
  matchId: string,
  userId: string
): Promise<{ ratedId: string; rating: number }[]> {
  const q = query(
    collection(db, "playerRatings"),
    where("matchId", "==", matchId),
    where("raterId", "==", userId)
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({
    ratedId: d.data().ratedId,
    rating: d.data().rating,
  }));
}

export async function getUserAverageRating(userId: string): Promise<number> {
  const q = query(
    collection(db, "playerRatings"),
    where("ratedId", "==", userId)
  );
  const snap = await getDocs(q);

  if (snap.empty) return 0;

  const ratings = snap.docs.map((d) => d.data().rating);
  const average = ratings.reduce((a, b) => a + b, 0) / ratings.length;

  return Math.round(average * 100) / 100;
}

export function getUserAverageRatingRealtime(
  userId: string,
  callback: (rating: number) => void
) {
  const q = query(
    collection(db, "playerRatings"),
    where("ratedId", "==", userId)
  );

  const unsubscribe = getDocs(q).then((snap) => {
    if (snap.empty) {
      callback(0);
      return;
    }

    const ratings = snap.docs.map((d) => d.data().rating);
    const average = ratings.reduce((a, b) => a + b, 0) / ratings.length;
    callback(Math.round(average * 100) / 100);
  });

  return () => unsubscribe;
}

// ===== TESIS PUANLAMA =====

export async function rateField(
  fieldId: string,
  userId: string,
  reservationId: string,
  rating: number,
  comment: string = ""
): Promise<void> {
  if (rating < 1 || rating > 5) throw new Error("Rating must be between 1 and 5");

  const docId = `${reservationId}_${userId}`;
  await setDoc(
    doc(collection(db, "reviews"), docId),
    {
      fieldId,
      userId,
      reservationId,
      rating,
      comment,
      createdAt: serverTimestamp(),
    },
    { merge: true }
  );
}

export async function hasRatedField(
  reservationId: string,
  userId: string
): Promise<boolean> {
  const docId = `${reservationId}_${userId}`;
  const snap = await getDoc(doc(collection(db, "reviews"), docId));
  return snap.exists();
}

export async function getFieldReviews(fieldId: string): Promise<any[]> {
  const q = query(
    collection(db, "reviews"),
    where("fieldId", "==", fieldId)
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({
    id: d.id,
    ...d.data(),
  }));
}

export async function getFieldAverageRating(fieldId: string): Promise<number> {
  const q = query(
    collection(db, "reviews"),
    where("fieldId", "==", fieldId)
  );
  const snap = await getDocs(q);

  if (snap.empty) return 0;

  const ratings = snap.docs.map((d) => d.data().rating);
  const average = ratings.reduce((a, b) => a + b, 0) / ratings.length;

  return Math.round(average * 100) / 100;
}

export async function getUserFieldReviews(userId: string): Promise<any[]> {
  const q = query(
    collection(db, "reviews"),
    where("userId", "==", userId)
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({
    id: d.id,
    ...d.data(),
  }));
}

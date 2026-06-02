import { auth } from "@/database/firebase";
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  GoogleAuthProvider,
  signInWithPopup,
} from "firebase/auth";
import { getAdminByUid } from "@/backend/services/adminService";

export async function loginWithEmailPassword(email: string, password: string) {
  const credential = await signInWithEmailAndPassword(auth, email, password);
  const uid = credential.user.uid;
  const admin = await getAdminByUid(uid);

  if (admin && admin.status !== "approved") {
    await signOut(auth);
    throw new Error("admin_not_approved");
  }

  return {
    user: credential.user,
    admin,
  };
}

export async function registerAuthUser(email: string, password: string) {
  const credential = await createUserWithEmailAndPassword(auth, email, password);
  return credential.user;
}

export async function signOutCurrentUser() {
  return signOut(auth);
}

export async function loginWithGoogle() {
  const provider = new GoogleAuthProvider();
  const credential = await signInWithPopup(auth, provider);
  const uid = credential.user.uid;
  const admin = await getAdminByUid(uid);

  if (admin && admin.status !== "approved") {
    await signOut(auth);
    throw new Error("admin_not_approved");
  }

  return {
    user: credential.user,
    admin,
    isNewUser: credential.user.metadata.creationTime === credential.user.metadata.lastSignInTime
  };
}

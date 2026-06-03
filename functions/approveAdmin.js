const admin = require("firebase-admin");
admin.initializeApp();
async function run() {
  const db = admin.firestore();
  const snapshot = await db.collection("admins").get();
  for (const doc of snapshot.docs) {
    await db.collection("admins").doc(doc.id).update({ approvalStatus: "approved" });
    console.log("Approved admin:", doc.id);
  }
  console.log("Done");
}
run();

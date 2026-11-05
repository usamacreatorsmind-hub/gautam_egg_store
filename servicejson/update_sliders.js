const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

const serviceAccountDest = require("./dest-service-account.json");

const destApp = initializeApp({
  credential: cert(serviceAccountDest),
}, "destAppForSliders");

const destDb = getFirestore(destApp);

async function updateSliders() {
  console.log("Updating sliders in Firestore...");
  const snapshot = await destDb.collection("sliders").get();

  if (snapshot.empty) {
    console.log("No sliders found in collection 'sliders'.");
    process.exit(0);
  }

  const batch = destDb.batch();
  const now = new Date();
  const past = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
  const future = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000);

  let index = 0;
  snapshot.docs.forEach((doc) => {
    const docRef = destDb.collection("sliders").doc(doc.id);
    batch.update(docRef, {
      status: "active",
      isActive: true,
      sortOrder: index++,
      startDate: Timestamp.fromDate(past),
      endDate: Timestamp.fromDate(future),
      createdAt: doc.data().createdAt || Timestamp.fromDate(now),
    });
  });

  await batch.commit();
  console.log(`Successfully updated ${snapshot.docs.length} sliders with sortOrder and active status!`);
  process.exit(0);
}

updateSliders().catch((err) => {
  console.error("Error updating sliders:", err);
  process.exit(1);
});

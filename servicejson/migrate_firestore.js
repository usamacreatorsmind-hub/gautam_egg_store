/**
 * Firestore Migration Script: Vkart -> Gautam Egg Store
 * (Using modular firebase-admin SDK)
 */

const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

const serviceAccountSource = require("./source-service-account.json");
const serviceAccountDest = require("./dest-service-account.json");

// Initialize Source App (Vkart)
const sourceApp = initializeApp({
  credential: cert(serviceAccountSource),
}, "sourceApp");

// Initialize Destination App (Gautam Egg Store)
const destApp = initializeApp({
  credential: cert(serviceAccountDest),
}, "destApp");

const sourceDb = getFirestore(sourceApp);
const destDb = getFirestore(destApp);

// List of collections to migrate
const collectionsToMigrate = [
  "products",
  "variants",
  "inventory",
  "categories",
  "stores",
  "orders",
  "carts",
  "sliders",
  "addresses",
  "broadcastNotifications",
  "coupons",
  "coupon_usages",
  "stock_alerts",
  "fevorites",
  "subscriptions",
  "flash_sales",
  "settings",
  "brands",
  "business_kyc"
];

async function migrateCollection(collectionName) {
  console.log(`\n📦 Migrating collection: ${collectionName}...`);
  const snapshot = await sourceDb.collection(collectionName).get();

  if (snapshot.empty) {
    console.log(`   (Collection ${collectionName} is empty, skipping)`);
    return;
  }

  let batch = destDb.batch();
  let count = 0;
  let total = 0;

  for (const doc of snapshot.docs) {
    const docRef = destDb.collection(collectionName).doc(doc.id);
    batch.set(docRef, doc.data());
    count++;
    total++;

    // Firestore batch limit is 500 operations
    if (count >= 400) {
      await batch.commit();
      batch = destDb.batch();
      count = 0;
      console.log(`   Committed 400 docs for ${collectionName}...`);
    }
  }

  if (count > 0) {
    await batch.commit();
  }

  console.log(`✅ Successfully migrated ${total} documents in collection '${collectionName}'.`);
}

async function runMigration() {
  console.log("🚀 Starting Firestore Migration from Vkart to Gautam Egg Store...");

  for (const col of collectionsToMigrate) {
    try {
      await migrateCollection(col);
    } catch (error) {
      console.error(`❌ Error migrating collection ${col}:`, error.message);
    }
  }

  console.log("\n🎉 All collections migration completed!");
  process.exit(0);
}

runMigration();

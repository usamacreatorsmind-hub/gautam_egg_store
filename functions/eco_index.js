const admin = require("firebase-admin");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

// admin.initializeApp() is called once in index.js — do NOT call here
const db = admin.firestore();

// ======================================================
// Constants
// ======================================================

const NotificationType = {
  ORDER: "order",
  WALLET: "wallet",
  COUPON: "coupon",
  STOCK: "stock",
  SYSTEM: "system",
};

const NotificationTarget = {
  USER: "user",
  ADMIN: "admin",
};

// ======================================================
// Helper — save notification to Firestore
// ======================================================

async function saveNotification({
  userId,
  title,
  body,
  type = NotificationType.SYSTEM,
  target = NotificationTarget.USER,
  data = {},
}) {
  await db.collection("eco_notifications").add({
    userId,
    title,
    body,
    type,
    target,
    data,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// ======================================================
// Helper — get user FCM token
// ======================================================

async function getUserToken(userId) {
  console.log(`[eco] 🔑 Fetching FCM token for user: ${userId}`);
  const userDoc = await db.collection("eco_users").doc(userId).get();
  if (!userDoc.exists) {
    console.warn(`[eco] ⚠️ User doc not found: ${userId}`);
    return null;
  }
  const token = userDoc.data().fcmToken ?? null;
  console.log(`[eco] 🔑 FCM token ${token ? "found" : "not found"} for user: ${userId}`);
  return token;
}

// ======================================================
// Helper — send FCM + save notification
// ======================================================

async function notify({ token, title, body, userId, type, data = {} }) {
  if (token) {
    console.log(`[eco] 📲 Sending FCM to ${userId}: "${title}"`);
    await admin.messaging().send({
      token,
      notification: { title, body },
      data: { ...data, type },
    });
    console.log(`[eco] 📲 FCM sent successfully to ${userId}`);
  } else {
    console.warn(`[eco] ⚠️ No FCM token for ${userId} — saving notification only`);
  }
  await saveNotification({ userId, title, body, type, data });
}

// ======================================================
// 1. ECO ORDER PLACED
// ======================================================

exports.ecoNotifyOrderPlaced = onDocumentCreated(
  {
    document: "eco_orders/{orderId}",
    region: "asia-south1",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const order = snap.data();
    const { userId, orderNumber, deliveryType, subscriptionId } = order;
    console.log(`[eco] 📦 ecoNotifyOrderPlaced triggered — orderId: ${event.params.orderId}, userId: ${userId}, subscriptionId: ${subscriptionId ?? "none"}`);

    if (!userId) {
      console.warn("[eco] ⚠️ ecoNotifyOrderPlaced: no userId, skipping");
      return;
    }

    // Subscription orders get their own notification from ecoProcessSubscriptions
    if (subscriptionId) {
      console.log("[eco] ↩️ ecoNotifyOrderPlaced: subscription order, skipping (handled by ecoProcessSubscriptions)");
      return;
    }

    try {
      const token = await getUserToken(userId);

      const isQuick = deliveryType === "quick";
      const title = "Order Placed ✅";
      const body = `Order #${orderNumber || ""} placed — ${isQuick ? "Quick delivery on its way!" : "Scheduled for delivery."}`;

      await notify({
        token,
        title,
        body,
        userId,
        type: NotificationType.ORDER,
        data: { orderId: event.params.orderId, route: "order_details" },
      });

      console.log(`[eco] ✅ ecoNotifyOrderPlaced done: ${event.params.orderId}`);
    } catch (err) {
      console.error("[eco] ❌ ecoNotifyOrderPlaced:", err);
    }
  }
);

// ======================================================
// 2. ECO ORDER STATUS UPDATED
// ======================================================

exports.ecoNotifyOrderStatusUpdate = onDocumentUpdated(
  {
    document: "eco_orders/{orderId}",
    region: "asia-south1",
  },
  async (event) => {
    const change = event.data;
    const newData = change.after.data();
    const oldData = change.before.data();

    if (!newData || !oldData) return;

    console.log(`[eco] 🔄 ecoNotifyOrderStatusUpdate triggered — orderId: ${event.params.orderId}, ${oldData.status} → ${newData.status}`);

    if (newData.status === oldData.status) {
      console.log("[eco] ↩️ Status unchanged, skipping");
      return;
    }
    if (!oldData.status) {
      console.log("[eco] ↩️ First write (no old status), skipping");
      return;
    }

    const { userId, orderNumber } = newData;
    if (!userId) {
      console.warn("[eco] ⚠️ No userId on order, skipping");
      return;
    }

    try {
      const token = await getUserToken(userId);

      const status = (newData.status || "").toLowerCase();
      const statusMessages = {
        confirmed: ["Order Confirmed 🎉", `Order #${orderNumber} confirmed. We're preparing it.`],
        shipped:   ["Order Shipped 🚚",   `Order #${orderNumber} is out for delivery!`],
        delivered: ["Order Delivered 🎁", `Order #${orderNumber} delivered. Enjoy!`],
        cancelled: ["Order Cancelled ❌", `Order #${orderNumber} has been cancelled.`],
      };

      const [title, body] = statusMessages[status] ?? [
        "Order Update",
        `Your order status changed to ${newData.status}.`,
      ];

      await notify({
        token,
        title,
        body,
        userId,
        type: NotificationType.ORDER,
        data: {
          orderId: event.params.orderId,
          status: newData.status,
          route: "order_details",
        },
      });

      console.log(`[eco] ✅ ecoNotifyOrderStatusUpdate done: ${status}`);
    } catch (err) {
      console.error("[eco] ❌ ecoNotifyOrderStatusUpdate:", err);
    }
  }
);

// ======================================================
// 3. WALLET TRANSACTION CREATED
// ======================================================

exports.ecoNotifyWalletTransaction = onDocumentCreated(
  {
    document: "eco_wallet_transactions/{txId}",
    region: "asia-south1",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const tx = snap.data();
    const { userId, amount, type: txType, description } = tx;
    console.log(`[eco] 💰 ecoNotifyWalletTransaction triggered — txId: ${event.params.txId}, userId: ${userId}, type: ${txType}, amount: ${amount}`);

    if (!userId || amount == null) {
      console.warn("[eco] ⚠️ Missing userId or amount, skipping");
      return;
    }

    try {
      const token = await getUserToken(userId);

      const isCredit = txType === "credit";
      const title = isCredit ? "Wallet Credited 💰" : "Wallet Debited";
      const body = description || `₹${amount} ${isCredit ? "added to" : "deducted from"} your wallet.`;

      await notify({
        token,
        title,
        body,
        userId,
        type: NotificationType.WALLET,
        data: { txId: event.params.txId, route: "wallet" },
      });

      console.log(`[eco] ✅ ecoNotifyWalletTransaction done: ${event.params.txId}`);
    } catch (err) {
      console.error("[eco] ❌ ecoNotifyWalletTransaction:", err);
    }
  }
);

// ======================================================
// 4. LOW STOCK ALERT
// ======================================================

exports.ecoNotifyLowStock = onDocumentUpdated(
  {
    document: "eco_products/{productId}",
    region: "asia-south1",
  },
  async (event) => {
    const change = event.data;
    const newData = change.after.data();
    const oldData = change.before.data();

    if (!newData || !oldData) return;

    const LOW_STOCK_THRESHOLD = 10;
    const wasAbove = (oldData.stock ?? 0) > LOW_STOCK_THRESHOLD;
    const isBelow = (newData.stock ?? 0) <= LOW_STOCK_THRESHOLD;

    if (!wasAbove || !isBelow) return; // only trigger on crossing the threshold

    console.log(`[eco] ⚠️ ecoNotifyLowStock triggered — product: ${newData.name}, stock: ${newData.stock}`);

    try {
      await db.collection("eco_stock_alerts").add({
        productId: event.params.productId,
        productName: newData.name ?? "",
        stock: newData.stock ?? 0,
        warehouseId: newData.warehouseId ?? null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isResolved: false,
      });

      console.log(`[eco] ✅ Low stock alert saved: ${newData.name} (${newData.stock} left)`);
    } catch (err) {
      console.error("[eco] ❌ ecoNotifyLowStock:", err);
    }
  }
);

// ======================================================
// 5. SUBSCRIPTION RECURRING ORDER PROCESSOR
// ======================================================

// How many hours before the user's delivery time the order is auto-created.
// e.g. user wants delivery at 10am → order is placed at 6am (4h lead).
const LEAD_TIME_HOURS = 4;

const WEEKDAY_NUM = {
  sunday: 0, monday: 1, tuesday: 2, wednesday: 3,
  thursday: 4, friday: 5, saturday: 6,
};

// Returns the number of days from fromDay until targetDay (1–7, never 0).
function daysUntilNext(fromDay, targetDay) {
  const diff = (targetDay - fromDay + 7) % 7;
  return diff === 0 ? 7 : diff;
}

// Computes the next nextDeliveryAt timestamp based on the user's repeatSchedule.
// nextDeliveryAt = next delivery datetime − LEAD_TIME_HOURS.
function nextDeliveryDate(repeatSchedule, from = new Date()) {
  if (!repeatSchedule) {
    return new Date(from.getTime() + 24 * 60 * 60 * 1000);
  }

  const { frequency, weekday, weekdays, dayOfMonth, timeSlot } = repeatSchedule;
  const hour   = timeSlot?.hour   ?? 10;
  const minute = timeSlot?.minute ?? 0;

  let deliveryDate;

  switch (frequency) {
    case 'daily': {
      deliveryDate = new Date(from);
      deliveryDate.setDate(deliveryDate.getDate() + 1);
      deliveryDate.setHours(hour, minute, 0, 0);
      break;
    }

    case 'weekly': {
      const target = WEEKDAY_NUM[weekday] ?? 1;
      const days   = daysUntilNext(from.getDay(), target);
      deliveryDate = new Date(from);
      deliveryDate.setDate(deliveryDate.getDate() + days);
      deliveryDate.setHours(hour, minute, 0, 0);
      break;
    }

    case 'midWeekly': {
      const targets = (weekdays || []).map(d => WEEKDAY_NUM[d] ?? 1);
      const days    = Math.min(...targets.map(t => daysUntilNext(from.getDay(), t)));
      deliveryDate  = new Date(from);
      deliveryDate.setDate(deliveryDate.getDate() + days);
      deliveryDate.setHours(hour, minute, 0, 0);
      break;
    }

    case 'monthly': {
      const dom      = dayOfMonth || 1;
      deliveryDate   = new Date(from);
      deliveryDate.setDate(dom);
      deliveryDate.setHours(hour, minute, 0, 0);
      if (deliveryDate <= from) {
        deliveryDate.setMonth(deliveryDate.getMonth() + 1);
        deliveryDate.setDate(dom);
      }
      break;
    }

    default: {
      deliveryDate = new Date(from.getTime() + 24 * 60 * 60 * 1000);
    }
  }

  return new Date(deliveryDate.getTime() - LEAD_TIME_HOURS * 60 * 60 * 1000);
}

function generateOrderNumber() {
  const ts = Date.now();
  return `ORD${String(ts).slice(5)}${ts % 10000}`;
}

exports.ecoProcessSubscriptions = onSchedule(
  { schedule: "every 1 minutes", timeZone: "Asia/Kolkata", region: "asia-south1" },
  async () => {
    console.log("[eco] ⏰ ecoProcessSubscriptions triggered");
    const now = admin.firestore.Timestamp.now();

    const snap = await db
      .collection("eco_subscriptions")
      .where("status", "==", "active")
      .get();

    const dueDocs = snap.docs.filter(doc => {
      const nda = doc.data().nextDeliveryAt;
      return nda && nda.toMillis() <= now.toMillis();
    });

    if (dueDocs.length === 0) {
      console.log("[eco] 💤 No subscriptions due.");
      return;
    }

    for (const subDoc of dueDocs) {
      const sub = subDoc.data();
      const subId = subDoc.id;

      try {
        const orderNumber = generateOrderNumber();
        const orderRef = db.collection("eco_orders").doc(orderNumber);
        const nextDate = nextDeliveryDate(sub.repeatSchedule, new Date());

        await db.runTransaction(async (tx) => {

          // ============================
          // ✅ STEP 1: PREPARE REFS
          // ============================
          const variantRefs = {};
          for (const detail of Object.values(sub.productDetails || {})) {
            if (detail.packVariantId) {
              variantRefs[detail.packVariantId] =
                db.collection("eco_variants").doc(detail.packVariantId);
            }
          }

          const walletRef = db.collection("eco_wallets").doc(sub.userId);

          // ============================
          // ✅ STEP 2: READ ALL DATA FIRST
          // ============================
          const variantSnaps = {};
          for (const [id, ref] of Object.entries(variantRefs)) {
            variantSnaps[id] = await tx.get(ref);
          }

          const walletSnap = await tx.get(walletRef);

          // ============================
          // ✅ STEP 3: VALIDATION
          // ============================
          for (const detail of Object.values(sub.productDetails || {})) {
            const variantId = detail.packVariantId;
            if (!variantId) continue;

            const snap = variantSnaps[variantId];
            if (!snap.exists) {
              throw new Error(`Variant ${variantId} not found`);
            }

            const stock = snap.data().stock || 0;
            if (stock < detail.quantity) {
              throw new Error(`Insufficient stock for ${variantId}`);
            }
          }

          const wallet = walletSnap.exists ? walletSnap.data() : {};
          const total = wallet.total ?? 0;
          const reserved = wallet.reserved ?? 0;
          const orderAmt = sub.total ?? 0;

          if (total < orderAmt) {
            throw new Error(`Insufficient wallet balance`);
          }

          // ============================
          // ✅ STEP 4: ALL WRITES START HERE
          // ============================

          // 🔹 Update stock
          for (const detail of Object.values(sub.productDetails || {})) {
            const variantId = detail.packVariantId;
            if (!variantId) continue;

            const snap = variantSnaps[variantId];
            const stock = snap.data().stock || 0;

            tx.update(variantRefs[variantId], {
              stock: stock - detail.quantity,
            });
          }

          // 🔹 Wallet update
          const newTotal = total - orderAmt;
          const deductReserved = Math.min(reserved, orderAmt);

          tx.set(walletRef, {
            total: newTotal,
            reserved: reserved - deductReserved,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });

          // 🔹 Wallet transaction
          const txnRef = db.collection("eco_wallet_transactions").doc();
          tx.set(txnRef, {
            userId: sub.userId,
            type: "debit",
            amount: orderAmt,
            source: "subscription",
            referenceId: subId,
            orderId: orderRef.id,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // 🔹 Create order
          tx.set(orderRef, {
            id: orderRef.id,
            userId: sub.userId,
            user: sub.user,
            deliveryAddress: sub.deliveryAddress,
            warehouseId: sub.warehouseId,
            products: sub.products,
            productDetails: sub.productDetails,
            subtotal: sub.subtotal,
            discount: sub.discount || 0,
            deliveryCharge: sub.deliveryCharge || 0,
            appliedTaxAndCharges: sub.appliedTaxAndCharges,
            deliveryBoyChargeConfig: sub.deliveryBoyChargeConfig,
            appliedCouponCode: sub.appliedCouponCode || null,
            total: sub.total,
            orderNumber,
            status: "pending",
            deliveryType: "scheduled",
            paymentMethod: "wallet",
            paymentStatus: "paid",
            subscriptionId: subId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // 🔹 Update subscription nextDelivery
          tx.update(subDoc.ref, {
            lastOrderId: orderRef.id,
            nextDeliveryAt: admin.firestore.Timestamp.fromDate(nextDate),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        console.log(`[eco] ✅ Order created for sub ${subId} — next delivery: ${nextDate.toISOString()}`);

        // ============================
        // 🔔 Notification (outside tx)
        // ============================
        const token = await getUserToken(sub.userId);
        await notify({
          token,
          title: "Recurring Order Placed 🔁",
          body: `Order #${orderNumber} placed. ₹${sub.total} deducted.`,
          userId: sub.userId,
          type: NotificationType.ORDER,
          data: { orderId: orderRef.id },
        });

      } catch (err) {
        console.error(`[eco] ❌ FAILED sub ${subId}:`, err.message);

        // ✅ ONLY pause for business errors
        if (
          err.message.includes("Insufficient") ||
          err.message.includes("not found")
        ) {
          await subDoc.ref.update({
            status: "paused",
            pauseReason: err.message,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          console.log(`[eco] ⏸️ Paused sub ${subId}`);
        } else {
          console.log("[eco] ⚠️ System error — NOT pausing subscription");
        }
      }
    }

    console.log("[eco] ✅ Scheduler run complete");
  }
);


// ======================================================
// 6. ECO SUBSCRIPTION VERIFIED
// ======================================================

exports.ecoNotifySubscriptionVerified = onDocumentUpdated(
  {
    document: "eco_subscriptions/{subId}",
    region: "asia-south1",
  },
  async (event) => {
    const change = event.data;
    const newData = change.after.data();
    const oldData = change.before.data();

    if (!newData || !oldData) return;

    console.log(`[eco] 🔔 ecoNotifySubscriptionVerified triggered — subId: ${event.params.subId}, ${oldData.status} → ${newData.status}`);

    if (newData.status === oldData.status) {
      console.log("[eco] ↩️ Status unchanged, skipping");
      return;
    }
    if (newData.status !== "active") {
      console.log(`[eco] ↩️ Status is '${newData.status}', not 'active', skipping`);
      return;
    }

    const { userId } = newData;
    if (!userId) {
      console.warn("[eco] ⚠️ No userId on subscription, skipping");
      return;
    }

    console.log(`[eco]    userId: ${userId}`);
    console.log(`[eco]    nextDeliveryAt: ${newData.nextDeliveryAt ? newData.nextDeliveryAt.toDate().toISOString() : "NOT SET"}`);

    try {
      if (!newData.nextDeliveryAt) {
        const firstDelivery = nextDeliveryDate(newData.repeatSchedule, new Date());
        console.log(`[eco] 📅 nextDeliveryAt not set — computing from schedule: ${firstDelivery.toISOString()}`);
        await change.after.ref.update({
          nextDeliveryAt: admin.firestore.Timestamp.fromDate(firstDelivery),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        console.log(`[eco] ✅ nextDeliveryAt already set: ${newData.nextDeliveryAt.toDate().toISOString()}`);
      }

      const token = await getUserToken(userId);
      const title = "Subscription Verified ✅";
      const body = "Your subscription has been verified and is now active.";

      await notify({
        token,
        title,
        body,
        userId,
        type: NotificationType.SYSTEM,
        data: {
          subscriptionId: event.params.subId,
          route: "subscription_details",
        },
      });

      console.log(`[eco] ✅ ecoNotifySubscriptionVerified done: ${event.params.subId}`);
    } catch (err) {
      console.error("[eco] ❌ ecoNotifySubscriptionVerified:", err);
    }
  }
);

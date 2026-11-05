const admin = require("firebase-admin");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");

admin.initializeApp();

// ── Gautam Egg Store project functions ──────────────────────
Object.assign(exports, require("./eco_index"));
Object.assign(exports, require("./auth_functions"));

const db = admin.firestore();


// ======================================================
// ✅ Enum-like constants (JS safe)
// ======================================================

const NotificationType = {
  ORDER: "order",
  DELIVERY: "delivery",
  PRODUCT: "product",
  STOCK: "stock",
  OFFER: "offer",
  SYSTEM: "system",
};

const NotificationTarget = {
  USER: "user",
  DELIVERY_AGENT: "deliveryAgent",
  ADMIN: "admin",
};


// ======================================================
// ✅ Helper → Save notification to Firestore
// ======================================================

async function saveNotification({
  userId,
  title,
  body,
  orderId = null,
  productId = null,
  deliveryAgentId = null,
  type = NotificationType.SYSTEM,
  target = NotificationTarget.USER,
  data = {},
}) {
  await db.collection("notifications").add({
    userId,
    title,
    body,

    orderId,
    productId,
    deliveryAgentId,

    type,      // string (matches Flutter enum name)
    target,    // string

    data,

    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}


// ======================================================
// ✅ 1. ORDER PLACED
// ======================================================

exports.notifyOrderPlaced = onDocumentCreated(
  {
    document: "orders/{orderId}",
    region: "asia-south1",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const order = snap.data();
    const userId = order.userId;
    if (!userId) return;

    try {
      const userDoc = await db.collection("Users").doc(userId).get();
      if (!userDoc.exists) return;

      const token = userDoc.data().fcmToken;
      if (!token) return;

      const title = "Order Confirmed 🎉";
      const body = `Your order #${order.orderNumber || ""} has been placed successfully`;

      // ✅ Send FCM
      await admin.messaging().send({
        token,
        notification: { title, body },
        data: {
          orderId: event.params.orderId,
          type: "order_placed",
        },
      });

      // ✅ Save Firestore notification
      await saveNotification({
        userId,
        title,
        body,
        orderId: event.params.orderId,
        type: NotificationType.ORDER,
        target: NotificationTarget.USER,
        data: {
          route: "order_details",
          orderId: event.params.orderId,
        },
      });

      console.log("✅ Order placed notification sent");
    } catch (error) {
      console.error("❌ Error sending order placed notification:", error);
    }
  }
);


// ======================================================
// ✅ 2. ORDER STATUS UPDATE
// ======================================================

exports.notifyOrderStatusUpdate = onDocumentUpdated(
  {
    document: "orders/{orderId}",
    region: "asia-south1",
  },
  async (event) => {
    const change = event.data;

    const newData = change.after.data();
    const oldData = change.before.data();

    if (!newData || !oldData) return;

    // notify only if status changed
    if (newData.status === oldData.status) return;

    // Prevent duplicate notification if status is set for the first time (covered by Order Placed)
    if (!oldData.status) return;

    const userId = newData.userId;
    if (!userId) return;

    try {
      const userDoc = await db.collection("Users").doc(userId).get();
      if (!userDoc.exists) return;

      const token = userDoc.data().fcmToken;
      if (!token) return;

      let title = "Order Update";
      let body = `Your order status is now ${newData.status}`;

      const status = (newData.status || "").toLowerCase();

      if (status === "cancelled") {
        title = "Order Cancelled ❌";
        body = `Your order #${newData.orderNumber || ""} has been cancelled.`;
      } else if (status === "shipped") {
        title = "Order Shipped 🚚";
        body = `Your order #${newData.orderNumber || ""} is on its way!`;
      } else if (status === "delivered") {
        title = "Order Delivered 🎁";
        body = `Your order #${newData.orderNumber || ""} has been delivered.`;
      }

      // ✅ Send FCM
      await admin.messaging().send({
        token,
        notification: { title, body },
        data: {
          orderId: event.params.orderId,
          type: "order_status_update",
          status: newData.status,
        },
      });

      // ✅ Save Firestore notification
      await saveNotification({
        userId,
        title,
        body,
        orderId: event.params.orderId,
        type: NotificationType.ORDER,
        target: NotificationTarget.USER,
        data: {
          route: "order_details",
          status: newData.status,
        },
      });

      console.log(`✅ Order status notification sent: ${newData.status}`);
    } catch (error) {
      console.error("❌ Error sending status update notification:", error);
    }
  }
);


// ======================================================
// ✅ 3. BROADCAST NOTIFICATION (Admin Panel -> All Users)
// ======================================================

exports.notifyBroadcastNotification = onDocumentCreated(
  {
    document: "broadcastNotifications/{notificationId}",
    database: "(default)",
    region: "asia-south1",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const title = data.title || "New Offer 🎉";
    const body = data.message || data.body || "";

    try {
      // Send FCM message to topic 'all'
      await admin.messaging().send({
        topic: "all",
        notification: {
          title,
          body,
        },
        data: {
          type: "offer",
          id: event.params.notificationId,
        },
      });

      console.log(`✅ Broadcast FCM notification sent to topic 'all': ${title}`);
    } catch (error) {
      console.error("❌ Error sending broadcast FCM notification:", error);
    }
  }
);

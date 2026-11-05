const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

// Define secrets
const MSG91_AUTH_KEY = defineSecret("MSG91_AUTH_KEY");
const MSG91_TEMPLATE_ID = defineSecret("MSG91_TEMPLATE_ID");

/**
 * Sends OTP using MSG91
 */
exports.sendOTP = onCall(
  {
    region: "asia-south1",
    secrets: [MSG91_AUTH_KEY, MSG91_TEMPLATE_ID],
    enforceAppCheck: false,
    minInstances: 0,
    memory: "256MiB",
    timeoutSeconds: 15,
  },
  async (request) => {
    const phoneNumber = request.data.phoneNumber;

    if (!phoneNumber) {
      throw new HttpsError("invalid-argument", "Phone number is required.");
    }

    const authKey = MSG91_AUTH_KEY.value();
    const templateId = MSG91_TEMPLATE_ID.value();

    // 🛡️ Robust Number Formatting: Ensure no double 91
    let cleanPhone = phoneNumber;
    if (cleanPhone.startsWith("91") && cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(2);
    }

    // 🛡️ Bypass check for Play Console test account (9988998899)
    if (cleanPhone === "9988998899" || phoneNumber === "9988998899") {
      console.log(`Bypassing MSG91 sendOTP for test number: ${phoneNumber}`);
      return { success: true, message: "OTP sent successfully (Bypass)" };
    }

    // 💡 MSG91 API v5 OTP URL
    const url = `https://control.msg91.com/api/v5/otp?template_id=${templateId}&mobile=${cleanPhone}&authkey=${authKey}&country=91&otp_length=4`;

    try {
      console.log(`Sending OTP to: ${cleanPhone} (Country: 91)`);
      const response = await fetch(url, { method: "GET" });
      const result = await response.json();

      if (result.type === "success") {
        console.log(`MSG91 Success for ${phoneNumber}:`, result);
        return { success: true, message: "OTP sent successfully" };
      } else {
        console.error("MSG91 Error Response:", result);
        throw new HttpsError("internal", result.message || "Failed to send OTP via MSG91");
      }
    } catch (error) {
      console.error("Error calling MSG91:", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", error.message || "An error occurred while sending OTP.");
    }
  }
);

/**
 * Verifies OTP with MSG91 and returns Firebase Custom Token
 */
exports.verifyOTP = onCall(
  {
    region: "asia-south1",
    secrets: [MSG91_AUTH_KEY],
    enforceAppCheck: false,
    minInstances: 0,
    memory: "256MiB",
    timeoutSeconds: 15,
  },
  async (request) => {
    const { phoneNumber, otp } = request.data;

    if (!phoneNumber || !otp) {
      throw new HttpsError("invalid-argument", "Phone number and OTP are required.");
    }

    const authKey = MSG91_AUTH_KEY.value();

    // Ensure phone number is E.164 compliant for Firebase Auth (+91...)
    let firebasePhone = phoneNumber;
    if (!firebasePhone.startsWith("+")) {
      firebasePhone = "+" + firebasePhone;
    }

    let cleanPhone = phoneNumber;
    if (cleanPhone.startsWith("+")) {
      cleanPhone = cleanPhone.substring(1);
    }
    if (cleanPhone.startsWith("91") && cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(2);
    }

    const isBypass = (cleanPhone === "9988998899" || phoneNumber === "9988998899" || firebasePhone.endsWith("9988998899"));

    try {
      let verificationSuccess = false;

      if (isBypass) {
        if (otp !== "1234") {
          throw new HttpsError("permission-denied", "Invalid OTP. Use 1234 for test account.");
        }
        console.log(`Bypassing MSG91 verifyOTP for test number: ${firebasePhone}`);
        verificationSuccess = true;
      } else {
        const url = `https://control.msg91.com/api/v5/otp/verify?otp=${otp}&mobile=${phoneNumber}&authkey=${authKey}`;
        const response = await fetch(url, { method: "GET" });
        const result = await response.json();

        if (result.type === "success") {
          verificationSuccess = true;
        } else {
          console.error("MSG91 Verification Error:", result);
          throw new HttpsError("permission-denied", result.message || "Invalid OTP");
        }
      }

      if (verificationSuccess) {
        // OTP Verified! Now handle Firebase Auth
        let userRecord;
        try {
          // Check if user exists by phone number (Use formatted number)
          userRecord = await admin.auth().getUserByPhoneNumber(firebasePhone);
        } catch (error) {
          if (error.code === "auth/user-not-found") {
            // Create new user if not found
            userRecord = await admin.auth().createUser({
              phoneNumber: firebasePhone,
            });
          } else {
            throw error;
          }
        }

        // Generate Custom Token
        const customToken = await admin.auth().createCustomToken(userRecord.uid);
        return { success: true, token: customToken };
      }
    } catch (error) {
      console.error("Error verifying OTP:", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", error.message || "An error occurred during verification.");
    }
  }
);

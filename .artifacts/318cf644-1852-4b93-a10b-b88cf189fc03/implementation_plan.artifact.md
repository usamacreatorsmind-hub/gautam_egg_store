# Fix OTP Delivery Issues (MSG91 Integration)

The app is currently failing to send OTPs, with the error "Invalid mobile number" being returned by the MSG91 gateway. This plan involves robustifying the Cloud Function logic to handle MSG91's requirements more effectively and improving the debugging information.

## User Review Required

> [!IMPORTANT]
> **MSG91 Configuration**: Ensure that the `MSG91_AUTH_KEY` and `MSG91_TEMPLATE_ID` secrets are correctly set in the Google Cloud Secret Manager for the `vkart-grocery` project.
> **Template ID**: Verify that the `MSG91_TEMPLATE_ID` you are using is approved for the **OTP** route and matches the **4-digit** length expected by the app.

## Proposed Changes

### Cloud Functions

#### [MODIFY] [auth_functions.js](file:///Users/mohdusama/Desktop/Usama Flutter Projects/vkart_app/functions/auth_functions.js)
- Update the `sendOTP` function to include the `country` parameter (defaulting to 91 for India) in the MSG91 API call.
- Add `otp_length=4` to ensure the generated OTP matches the app's input field.
- Add detailed logging of the MSG91 response to help troubleshoot further issues.

### Flutter App

#### [MODIFY] [auth_service.dart](file:///Users/mohdusama/Desktop/Usama Flutter Projects/vkart_app/lib/services/auth_service.dart)
- Add a `debugPrint` to show the exact phone number string being sent to the Cloud Function.
- Improve error parsing to provide more context if the Cloud Function fails.

#### [MODIFY] [login_screen.dart](file:///Users/mohdusama/Desktop/Usama Flutter Projects/vkart_app/lib/screens/auth/login_screen.dart)
- Add a check to ensure the phone number doesn't accidentally include a leading `0` if it's already prefixed with `+91`.

## Verification Plan

### Manual Verification
1.  **Check Cloud Logs**: After making changes and deploying, attempt to "Get OTP" and check the Firebase Cloud Function logs for the new detailed MSG91 response.
2.  **Test Phone Numbers**: Verify with multiple Indian mobile numbers (starting with 6, 7, 8, 9).
3.  **OTP Length**: Confirm the received OTP is exactly 4 digits.

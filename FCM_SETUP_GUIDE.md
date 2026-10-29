# FCM (Firebase Cloud Messaging) Setup & Testing Guide

This document explains how to set up and test Firebase Cloud Messaging (FCM) in the Alif Flutter apps.

## Prerequisites

- Firebase CLI installed: `npm install -g firebase-tools`
- FlutterFire CLI installed: `dart pub global activate flutterfire_cli`
- A Firebase project created in Firebase Console (https://console.firebase.google.com)

## Setup Steps

### 1. Configure Firebase for Flutter Apps

Run the FlutterFire configuration command for each app:

```bash
# For student/teacher app
cd apps/alif_student_teacher
flutterfire configure --project=your-firebase-project-id

# For admin app
cd apps/alif_admin
flutterfire configure --project=your-firebase-project-id
```

This will:
- Create `lib/services/firebase_options.dart` with your Firebase credentials
- Set up Google Services configuration for Android
- Set up GoogleService-Info.plist for iOS

### 2. Update Firebase Credentials in Backend

Copy your Firebase service account credentials to the backend `.env` file:

```bash
cd services/api
# Copy your service account JSON from Firebase Console
# Extract these values and add to .env:
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-service-account-email@your-project-id.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

### 3. Install Dependencies

Run `flutter pub get` in both Flutter apps:

```bash
cd apps/alif_student_teacher && flutter pub get
cd ../alif_admin && flutter pub get
```

## Getting the FCM Token

Once Firebase is configured, the FCM token will be automatically retrieved when the app starts:

```dart
import 'package:alif_student_teacher/services/fcm_service.dart';

// Get the token
String? token = FcmService.getToken();
print('FCM Token: $token');

// Refresh the token if needed
String? newToken = await FcmService.refreshToken();
```

## Testing FCM

### Test Notification via API

Once the backend is running, you can send a test notification:

```bash
# Start the API server
npm run api:dev

# Send a test notification
curl -X POST http://localhost:4000/notifications/test \
  -H "Content-Type: application/json" \
  -d '{"token":"YOUR_FCM_TOKEN_HERE"}'
```

### Test Notification via Firebase Console

1. Go to Firebase Console → Your Project → Cloud Messaging
2. Click "Send your first message"
3. Enter notification title and body
4. Click "Send test message"
5. Select your app and device

## App Integration

### Student/Teacher App

The `FcmService` is initialized automatically in `main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await FcmService.initialize();
  } catch (e) {
    print('FCM initialization error: $e');
  }
  
  runApp(const StudentTeacherApp());
}
```

### Admin App

FCM is initialized in the admin app's `main.dart` similarly.

## Handling Notifications in Your Code

### Foreground Notifications

When the app is open, notifications are handled by the `_handleMessage` function in `FcmService`. You can customize this to:
- Show a snackbar or dialog
- Update UI with notification data
- Navigate to a specific screen

### Background Notifications

When the app is in the background or closed, Firebase automatically displays the notification. Tapping it will:
1. Wake up the app (if closed)
2. Call the `FirebaseMessaging.onMessageOpenedApp` handler

### Listen for Token Changes

```dart
FcmService.onTokenRefresh((newToken) {
  print('FCM token refreshed: $newToken');
  // Send new token to your backend
});
```

## Platform-Specific Setup

### Android

- Ensure your app is properly signed
- Enable Firebase Cloud Messaging in Firebase Console
- No additional setup required after `flutterfire configure`

### iOS

- Enable push notifications capability in Xcode
- Upload APNs certificate to Firebase Console
- Run on a physical device (simulator doesn't support push notifications)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Firebase not initialized" | Run `flutterfire configure` again |
| "No FCM token" | Ensure app has permission to receive notifications |
| Notifications not received | Check Firebase Console for errors, verify token is current |
| Android: "Cannot start Firebase app" | Ensure Google Services JSON is in correct location |
| iOS: Notifications not showing | Upload APNs certificate to Firebase Console |

## Next Steps

1. Integrate FCM token registration with your backend
2. Create API endpoint for storing user FCM tokens
3. Implement notification routing/deep linking based on notification data
4. Add notification history/logs in the apps

## References

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging](https://pub.dev/packages/firebase_messaging)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)

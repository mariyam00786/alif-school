# Firebase Setup (FCM only)

This project uses Firebase only for push notifications (FCM), as required by the FRD.
OTP login is handled by Supabase Auth.

## Initialize

1. Install CLI (already in root devDependencies):
   - `npm run firebase:login`
2. Create or select a Firebase project.
3. Copy `.firebaserc.example` to `.firebaserc` and update project id.
4. Create a service account key in Firebase Console and map values to `services/api/.env`.

## Client Configuration (Flutter)

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Configure Flutter apps with Firebase:
   ```bash
   # For student/teacher app
   cd apps/alif_student_teacher
   flutterfire configure --project=your-firebase-project

   # For admin app  
   cd apps/alif_admin
   flutterfire configure --project=your-firebase-project
   ```

   This will generate the correct `firebase_options.dart` files with your project credentials.

3. Ensure Android and iOS app IDs are registered in Firebase Console.

## Backend Configuration

Create or update `services/api/.env` with the Firebase service account details:

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-service-account-email@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
```

## Token Registration Flow

The app automatically:
1. Initializes Firebase on startup
2. Requests notification permissions (iOS) 
3. Gets the FCM device token
4. Registers the token with the backend API (`POST /notifications/device-tokens/register`)
5. Updates token preferences via backend

## Validate

1. Start API: `npm run api:dev`
2. Call `POST /notifications/device-tokens/register` with a valid device token (the app does this automatically)
3. Send test notification via `POST /notifications` with target type and ID
4. Verify notification delivery in app foreground/background/terminated states



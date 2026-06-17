# Firebase Setup (FCM only)

This project uses Firebase only for push notifications (FCM), as required by the FRD.
OTP login is handled by Supabase Auth.

## Initialize

1. Install CLI (already in root devDependencies):
   - `npm run firebase:login`
2. Create or select a Firebase project.
3. Copy `.firebaserc.example` to `.firebaserc` and update project id.
4. Create a service account key in Firebase Console and map values to `services/api/.env`.

## Validate

1. Start API: `npm run api:dev`
2. Call `POST /notifications/test` with a valid FCM token.


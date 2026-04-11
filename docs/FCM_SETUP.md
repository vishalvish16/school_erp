# Firebase Cloud Messaging (FCM) Setup

Push notifications for Parent and Student portals — foreground, background, and when app is closed.

## 1. Firebase Console

- Project: `school-erp-ai` (already configured)
- Web app: configured
- Android app: `com.schoolerp.school_erp_admin` — `google-services.json` in `android/app/`
- iOS app: add if needed, use bundle ID `com.schoolerp.schoolErpAdmin`

## 2. Backend: Service Account

1. Firebase Console → Project Settings → Service Accounts
2. Generate new private key (JSON)
3. Save as `backend/serviceAccountKey.json` (or any path)
4. Add to `.env`:
   ```
   FIREBASE_SERVICE_ACCOUNT_PATH=serviceAccountKey.json
   ```
   Or set `GOOGLE_APPLICATION_CREDENTIALS` to the full path.

## 3. Database Migration

```bash
cd backend
npx prisma migrate dev --name add_fcm_tokens
```

## 4. Web Push (optional)

For web push when browser is in background:
- Firebase Console → Project Settings → Cloud Messaging
- Add a web push certificate (VAPID key)
- Or use default — FCM will work for foreground web

## 5. Testing

1. Start backend: `cd backend && npm run dev`
2. Run Flutter: `flutter run -d chrome` (web) or `flutter run` (Android)
3. Log in as Parent or Student
4. From School Admin, send a notice to a student (target Parent + Student)
5. Parent/Student should receive:
   - **Foreground**: SnackBar (Socket.IO) + FCM in-app
   - **Background**: System notification
   - **Terminated**: System notification; tap → opens app → notices screen

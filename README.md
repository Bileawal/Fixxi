# Fixxi — Home Repair & Technician Booking (FYP)

Flutter app backed by **Firebase** (Auth, Firestore, FCM) + **Cloudinary** (ID card images).

## Requirements

- Flutter SDK
- Android Studio / VS Code
- Internet connection (mobile data or Wi‑Fi)
- Firebase project: `fixxi-f0d1c`
- Cloudinary account (free tier works)

**No local backend, MongoDB, or PC server required.**

## Firebase Console setup (one time)

1. Open [Firebase Console](https://console.firebase.google.com) → project **fixxi-f0d1c**
2. **Authentication** → Get started → **Email/Password** → Enable → Save
3. **Firestore Database** → Create database (if not created)
4. **Firestore → Rules** → paste content from `firestore.rules` → **Publish**

## Cloudinary setup (images — Step 3)

Technician ID cards upload to **Cloudinary**, not Firebase Storage.

1. Sign up / login: [https://cloudinary.com](https://cloudinary.com)
2. **Dashboard** → copy your **Cloud name** (e.g. `dabc123xyz`)
3. **Settings** (gear) → **Upload** tab → **Add upload preset**
   - **Preset name:** `fixxi_unsigned` (or any name you like)
   - **Signing mode:** **Unsigned**
   - **Folder:** optional `fixxi/id_cards`
   - Save preset
4. Open `lib/core/constants/cloudinary_config.dart` and set:

```dart
static const cloudName = 'YOUR_CLOUD_NAME';
static const uploadPreset = 'fixxi_unsigned';
```

5. Save file → run `flutter pub get` → rebuild app

Admin will see ID card images via Cloudinary URLs in the admin technician detail screen.

## Admin account (first time)

1. Run the app → Welcome screen → top-left **admin icon**
2. Email: `bilawal22204@gmail.com`
3. Password: `Bilawal1122`
4. Tap **Create Admin Account (First Time)**
5. Next time use **Admin Login** only

Passwords are stored in **Firebase Authentication** (hashed by Google), not in the app or Firestore.

## Run the app

```powershell
cd C:\Users\Bilaw\androidStudioProjects\fixxi
flutter pub get
flutter run
```

## Customer signup OTP (Firebase Cloud Functions)

OTP is sent by Cloud Functions via Gmail SMTP — not stored on the client.

### 1. Gmail App Password

1. Use a Gmail account (e.g. `bilawal22204@gmail.com`)
2. Google Account → **Security** → enable **2-Step Verification**
3. Security → **App passwords** → create app → name it `Fixxi OTP`
4. Copy the 16-character password (spaces don't matter)

### 2. Deploy Cloud Functions

```powershell
cd C:\Users\bilaw\AndroidStudioProjects\fixxi\functions
npm install
cd ..
firebase login
firebase use fixxi-f0d1c
firebase functions:secrets:set SMTP_USER
firebase functions:secrets:set SMTP_PASS
firebase deploy --only functions,firestore:rules
```

When prompted for secrets, enter your Gmail address and App Password.

Alternatively for local testing, set env vars before deploy:
`SMTP_USER=your@gmail.com` and `SMTP_PASS=your-app-password`

### 3. OTP rules

- 6-digit code, expires in **5 minutes**
- Max **5** wrong verify attempts
- Max **3** send requests per email per **15 minutes**
- Resend cooldown in app: **60 seconds**

## Project structure

- `lib/services/fixxi_api.dart` — Auth + Firestore data
- `lib/services/cloudinary_service.dart` — ID card image uploads
- `lib/core/constants/cloudinary_config.dart` — your Cloudinary keys
- `lib/firebase_options.dart` — Firebase config
- `functions/` — Cloud Functions (`sendOtp`, `verifyOtp`)
- `firestore.rules` — Firestore security rules (deploy to Console)
- `backend/` — legacy Node/MongoDB API (unused; safe to delete)

## Works anywhere?

Yes. Any phone with internet can use the app. Data on Firebase Cloud; images on Cloudinary.

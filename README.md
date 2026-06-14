# Fixxi (FYP)

Home repair booking app — Flutter + Node.js/Express + MongoDB.

## Project structure

- `lib/` — Flutter app
- `backend/` — REST API
- `assets/logo.png` — App logo (replace with your own)

## Backend setup

1. Install [MongoDB](https://www.mongodb.com/try/download/community) and [Node.js](https://nodejs.org/)
2. Terminal:

```bash
cd backend
copy .env.example .env
npm install
npm run seed
npm run dev
```

API runs at `http://localhost:3000`

### `.env` (important)

- `MONGODB_URI` — MongoDB connection
- `JWT_SECRET` — random secret string
- `SMTP_*` — Gmail app password for customer OTP emails  
  If SMTP is empty, OTP is printed in the **server console** (dev mode) and returned in API as `devOtp`.

**Default admin:** `admin@fixxi.com` / `admin123`

## Flutter setup

1. Install Flutter SDK
2. Start backend + MongoDB first
3. Terminal:

```bash
flutter pub get
flutter run
```

### API URL (physical device)

Edit [`lib/core/constants/api_config.dart`](lib/core/constants/api_config.dart):

- Emulator: `http://10.0.2.2:3000` (default)
- Real phone: `http://YOUR_PC_IP:3000` (same Wi‑Fi)

## User flows

### Customer
1. Sign up → name, phone, address, email → OTP → password
2. Login → book technicians, requests, chat, reviews

### Technician
1. Sign up (4 steps) → personal info, skills, ID front/back, password
2. Wait for **admin approval**
3. Take **skill test** (pass ≥ 60%)
4. Full app access

### Admin
1. Login → Pending technicians → view profile + ID images → Approve/Reject
2. View all technicians and test scores

## Logo

Replace `assets/logo.png` with your logo (square PNG recommended), then:

```bash
flutter pub get
```

## AI module

Icon only — “Coming soon” (no backend AI yet).

# Super Admin Setup Guide

The Super Admin portal connects to the backend database. If you see empty screens, follow these steps.

## Prerequisites

- PostgreSQL running (default: `localhost:5432`)
- Node.js 18+

## 1. Backend Environment

Create `backend/.env`:

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/school_erp"
PORT=3000
CORS_ORIGIN=*
JWT_SECRET=your-secret-key-min-32-chars
```

## 2. Database Setup

```bash
cd backend

# Run migrations (creates tables)
npx prisma migrate dev

# Seed Super Admin + demo data (plans, school)
npx prisma db seed
```

The seed creates:

- **Super Admin user**: `vishal.vish16@gmail.com` / `password123`
- **Platform plans**: Starter, Pro, Enterprise
- **Demo school**: Demo School (Mumbai)

## 3. Start Backend

```bash
cd backend
npm run dev
```

Backend runs at `http://localhost:3000`.

## 4. Flutter App

- **Web**: `flutter run -d chrome` — uses `localhost:3000` by default
- **Android emulator**: `flutter run -d android` — use `10.0.2.2:3000` (or `--dart-define=API_HOST=10.0.2.2`)

## 5. Login as Super Admin

1. Open the app at `http://localhost:PORT` (web) or your device
2. For **web**: Use `admin.vidyron.in` subdomain or `localhost` — the app auto-detects and sends `portal_type: super_admin`
3. Email: `vishal.vish16@gmail.com`
4. Password: `password123`
5. Device fingerprint is required — the login screen sends it automatically

## Troubleshooting

### No data showing

- **Run seed**: `npx prisma db seed` — adds demo plans and school
- **Check backend**: `curl http://localhost:3000/api/platform/auth/login` — should not 404

### 401 Unauthorized

- Login again — token may have expired
- Ensure you logged in with the Super Admin email and from admin/localhost

### 403 Super Admin access required

- Your user must have `school_id = null` and a PLATFORM role
- Run: `node scripts/verify-platform-admin.js` (from backend folder)

### Connection refused / Network error

- Ensure backend is running: `npm run dev` in backend folder
- Check `lib/core/config/api_config.dart` — `baseUrl` should point to your backend (default `http://localhost:3000`)

### Database connection failed

- Verify PostgreSQL is running
- Check `DATABASE_URL` in `backend/.env`

# Development Setup — See Data in Super Admin

## Login Credentials

| Portal | Email | Password |
|--------|-------|----------|
| Super Admin | vishal.vish16@gmail.com | password123 |
| School Admin | admin@{school-domain} | School@12345 |
| Teacher (Staff) | teacher@{school-domain} | School@12345 |
| Non-Teaching (Clerk) | clerk@{school-domain} | School@12345 |

**Note:** `{school-domain}` is derived from the first school's contact email (e.g. admin@sunriseschool.in → sunriseschool.in). Teacher and staff credentials require running `npm run seed:staff` in the backend folder after schools exist. Use the Staff portal and select the school (by subdomain or school_id).

## 1. Start the Backend (required)

The Flutter app needs the backend running. **Start it first.**

```bash
cd backend
npm install   # required — installs express-rate-limit and other deps
npm run dev   # or: yarn dev
```

You must see: `Server is running in development mode on port 3000`

If you see `EADDRINUSE: address already in use` → something is already on port 3000 (backend may already be running).

## 2. Run Flutter Web

```bash
# From project root
flutter pub get
flutter run -d chrome
```

## 3. Login

Use your Super Admin credentials. The dashboard will load data from `http://localhost:3000`.

## Troubleshooting

- **"Connection errored" / "XMLHttpRequest onError"** → The backend is not running or not reachable.
  1. Open a terminal and run: `cd backend && npm run dev`
  2. Wait until you see "Server is running... on port 3000"
  3. Restart the Flutter app (hot restart or stop and run again)
- **CORS errors** → Backend now allows all origins in development. Restart the backend after pulling changes.
- **Empty data** → Database may need seeding. Run `cd backend && npx prisma db seed` if you have a seed script.
- **Teacher/Staff login** → Run `cd backend && npm run seed:staff` to create demo teacher and clerk credentials (password: School@12345).

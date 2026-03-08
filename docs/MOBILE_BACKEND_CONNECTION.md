# Mobile Backend Connection Guide

When the app shows "Could not connect" or network errors from a mobile device, follow these steps.

---

## Android Emulator

**1. Start the backend first:**
```bash
cd backend && npm run dev
```

**2. Verify from PC:**
```bash
curl "http://localhost:3000/api/public/schools/search?q=test"
```

**3. Run the app** — default uses `10.0.2.2:3000` (emulator → host).

**If you get connection timeout** (firewall blocking):
```bash
adb reverse tcp:3000 tcp:3000
flutter run --dart-define=API_HOST=127.0.0.1
```

**If you get connection refused** — backend is not running. Start it with `npm run dev`.

---

## 1. Find Your PC's IP Address

**Windows (PowerShell):**
```powershell
ipconfig | findstr /i "IPv4"
```

**macOS / Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Use the IP of the adapter your phone uses (usually WiFi, e.g. `192.168.1.100`).

---

## 2. Run the App with Your IP

**Physical device (Android/iOS):**
```bash
flutter run --dart-define=API_HOST=192.168.1.100
```
Replace `192.168.1.100` with your actual IP.

**Android emulator** (uses default `10.0.2.2` = localhost):
```bash
flutter run
```

**Web:**
```bash
flutter run -d chrome
```
Uses `localhost` automatically.

---

## 3. Ensure Backend is Reachable

1. **Backend must listen on all interfaces** — Already set to `0.0.0.0` in `server.js`.

2. **Start the backend:**
   ```bash
   cd backend && npm run dev
   ```

3. **Test from your PC:**
   ```bash
   curl "http://localhost:3000/api/public/schools/search?q=test"
   ```

4. **Test from your phone's network** (use your PC IP):
   ```bash
   curl "http://192.168.1.100:3000/api/public/schools/search?q=test"
   ```

---

## 4. Firewall

**Windows:** Allow Node.js through the firewall for private networks.
- Settings → Firewall → Allow an app → Node.js (enable Private)

**Or temporarily disable firewall** to test.

---

## 5. Same Network

Phone and PC must be on the same WiFi/LAN. If the phone uses mobile data, it cannot reach your PC's local IP.

---

## 6. iOS: HTTP Allowed

iOS blocks plain HTTP by default. Add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

Or for development only, use `NSAllowsLocalNetworking` (allows local network HTTP).

---

## Quick Reference

| Scenario              | Setup                           | Command                                      |
|-----------------------|---------------------------------|----------------------------------------------|
| Android emulator      | Backend running                 | `flutter run` (uses 10.0.2.2)                |
| Android emulator      | 10.0.2.2 timeout? Use adb       | `adb reverse tcp:3000 tcp:3000` then `flutter run --dart-define=API_HOST=127.0.0.1` |
| Android physical      | —                               | `flutter run --dart-define=API_HOST=192.168.1.100` |
| iOS simulator         | —                               | `flutter run`                                |
| iOS physical          | —                               | `flutter run --dart-define=API_HOST=192.168.1.100` |
| Web                   | —                               | `flutter run -d chrome`                      |

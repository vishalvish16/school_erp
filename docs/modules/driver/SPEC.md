# Driver Portal — Full Module Plan

**Build scope**: Login → Dashboard → Profile → All related models (Driver, Vehicle, Route, etc.)

---

## 1. Overview

The **Driver Portal** is a mobile-only app for bus drivers. Drivers log in via QR code (auto-assigns vehicle) or email/password, then view their dashboard, assigned vehicle, today's route, student count, and manage their profile.

**URL/Platform**: Mobile app only (Android, iOS) — no web
**Portal Type** (JWT): `driver`
**API Base**: `/api/driver/`
**Accent Color**: `#FF9800` (orange), badge `#E65100` (dark orange)

---

## 2. User Roles and Access

| Role | Access Level |
|------|-------------|
| Driver | Self-scoped only — sees own profile, assigned vehicle, today's route, students on route |

---

## 3. Features and User Stories

### 3.1 Login

- As a driver, I can log in with email + password (same as staff login) so that I access the app when QR is unavailable
- As a driver, I can log in by scanning QR on my Vidyron ID card so that my vehicle is auto-assigned
- As a driver, I am redirected to the driver dashboard after successful login
- As a driver, I can use OTP verification if device is new or untrusted

**Auth flow**: Reuse existing staff login (`/api/auth/school-admin/login` or `/api/auth/school-staff/login`) with `portal_type: 'driver'`. JWT payload includes `portal_type: 'driver'`, `school_id`, `user_id`.

**QR login**: `POST /api/auth/driver/qr-login` — decode `qr_token`, verify school, assign vehicle from driver record, return session.

### 3.2 Dashboard

- As a driver, I can see my assigned vehicle (number, capacity) on the dashboard
- As a driver, I can see today's route name and stop count
- As a driver, I can see how many students are on my route today
- As a driver, I can see today's trip status (NOT_STARTED | IN_PROGRESS | COMPLETED)
- As a driver, I can start/end my trip (Phase 2: triggers GPS tracking)
- As a driver, I can see my school name and logo

### 3.3 Profile

- As a driver, I can view my profile (name, phone, email, photo, license number, expiry)
- As a driver, I can see my assigned vehicle and route
- As a driver, I can update my phone number (if not linked to login)
- As a driver, I can change my password
- As a driver, I can log out

### 3.4 Route & Students (Phase 2 — RFID + GPS)

- As a driver, I can view my route stops in order
- As a driver, I can scan student RFID to record pickup/drop
- As a driver, I can see live GPS tracking status (optional)

---

## 4. Data Models (Prisma)

### 4.1 Driver (existing concept — new table)

```prisma
model Driver {
  id              String    @id @default(uuid()) @db.Uuid
  schoolId        String    @map("school_id") @db.Uuid
  userId          String?   @unique @map("user_id") @db.Uuid   // links to User for login
  employeeNo      String    @map("employee_no") @db.VarChar(50)
  firstName       String    @map("first_name") @db.VarChar(100)
  lastName        String    @map("last_name") @db.VarChar(100)
  gender         String    @db.VarChar(10)
  dateOfBirth    DateTime? @map("date_of_birth") @db.Date
  phone          String?   @db.VarChar(20)
  email          String    @db.VarChar(255)
  licenseNumber  String?   @map("license_number") @db.VarChar(50)
  licenseExpiry  DateTime? @map("license_expiry") @db.Date
  photoUrl        String?   @map("photo_url") @db.Text
  address         String?   @db.Text
  emergencyContactName  String?   @map("emergency_contact_name") @db.VarChar(100)
  emergencyContactPhone String?   @map("emergency_contact_phone") @db.VarChar(20)
  isActive        Boolean   @default(true) @map("is_active")
  deletedAt       DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt       DateTime  @default(now()) @map("created_at")
  updatedAt       DateTime  @default(now()) @updatedAt @map("updated_at")

  school   School    @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  user     User?     @relation("DriverUser", fields: [userId], references: [id], onDelete: SetNull)
  vehicle  Vehicle?  @relation("DriverVehicle")

  @@unique([schoolId, employeeNo])
  @@index([schoolId])
  @@index([userId])
  @@map("drivers")
}
```

### 4.2 Vehicle

```prisma
model Vehicle {
  id           String   @id @default(uuid()) @db.Uuid
  schoolId     String   @map("school_id") @db.Uuid
  driverId     String?  @unique @map("driver_id") @db.Uuid
  vehicleNo    String   @map("vehicle_no") @db.VarChar(50)
  capacity     Int      @default(30)
  gpsDeviceId  String?  @map("gps_device_id") @db.VarChar(100)
  isActive     Boolean  @default(true) @map("is_active")
  deletedAt    DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt    DateTime @default(now()) @map("created_at")
  updatedAt    DateTime @default(now()) @updatedAt @map("updated_at")

  school  School  @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  driver  Driver? @relation("DriverVehicle", fields: [driverId], references: [id], onDelete: SetNull)
  route   TransportRoute? @relation("VehicleRoute")

  @@unique([schoolId, vehicleNo])
  @@index([schoolId])
  @@index([driverId])
  @@map("vehicles")
}
```

### 4.3 TransportRoute

```prisma
model TransportRoute {
  id          String   @id @default(uuid()) @db.Uuid
  schoolId    String   @map("school_id") @db.Uuid
  vehicleId   String?  @unique @map("vehicle_id") @db.Uuid
  name        String   @db.VarChar(100)
  description String?  @db.Text
  isActive    Boolean  @default(true) @map("is_active")
  deletedAt   DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt   DateTime @default(now()) @map("created_at")
  updatedAt   DateTime @default(now()) @updatedAt @map("updated_at")

  school School       @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  vehicle Vehicle?    @relation("VehicleRoute", fields: [vehicleId], references: [id], onDelete: SetNull)
  stops  RouteStop[]

  @@index([schoolId])
  @@index([vehicleId])
  @@map("transport_routes")
}
```

### 4.4 RouteStop

```prisma
model RouteStop {
  id          String   @id @default(uuid()) @db.Uuid
  routeId     String   @map("route_id") @db.Uuid
  sequence    Int      @db.SmallInt
  name        String   @db.VarChar(100)
  address     String?  @db.Text
  lat         Decimal? @db.Decimal(10, 7)
  lng         Decimal? @db.Decimal(10, 7)
  estimatedArrival String? @map("estimated_arrival") @db.VarChar(8)
  createdAt   DateTime @default(now()) @map("created_at")
  updatedAt   DateTime @default(now()) @updatedAt @map("updated_at")

  route TransportRoute @relation(fields: [routeId], references: [id], onDelete: Cascade)

  @@unique([routeId, sequence])
  @@index([routeId])
  @@map("route_stops")
}
```

### 4.5 User relation (add to User model)

```prisma
// Add to User model:
driverProfile Driver? @relation("DriverUser")
```

### 4.6 School relation (add to School model)

```prisma
// Add to School model:
drivers  Driver[]
vehicles Vehicle[]
transportRoutes TransportRoute[]
```

---

## 5. API Contract

### Base Path
`/api/driver/` — all routes require `verifyAccessToken` + `requireDriver` middleware.

### Middleware

- `requireDriver`: Check JWT `portal_type === 'driver'`, `school_id` present. Load `Driver` by `userId` and inject `req.driverId`, `req.driver`.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/driver/dashboard/stats` | Dashboard stats (vehicle, route, student count, trip status) |
| GET | `/api/driver/profile` | Full driver profile with vehicle and route |
| PUT | `/api/driver/profile` | Update driver profile (phone, emergency contact) |
| POST | `/api/driver/auth/change-password` | Change password |

### Auth Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/driver/login` | Login with email+password, returns JWT with portal_type=driver |
| POST | `/api/auth/driver/qr-login` | QR login — decode token, assign vehicle, return session |

### Response Shapes

**GET /api/driver/dashboard/stats**
```json
{
  "success": true,
  "data": {
    "driver": {
      "id": "uuid",
      "firstName": "Ramesh",
      "lastName": "Kumar",
      "photoUrl": null
    },
    "school": {
      "id": "uuid",
      "name": "DPS Noida",
      "logoUrl": null
    },
    "vehicle": {
      "id": "uuid",
      "vehicleNo": "DL-01-AB-1234",
      "capacity": 30
    },
    "route": {
      "id": "uuid",
      "name": "Route A - Sector 50",
      "stopCount": 8
    },
    "studentCount": 24,
    "tripStatus": "NOT_STARTED"
  }
}
```

**GET /api/driver/profile**
```json
{
  "success": true,
  "data": {
    "driver": {
      "id": "uuid",
      "employeeNo": "DRV-001",
      "firstName": "Ramesh",
      "lastName": "Kumar",
      "gender": "MALE",
      "dateOfBirth": "1985-03-15",
      "phone": "9876543210",
      "email": "ramesh@school.in",
      "licenseNumber": "DL-123456789",
      "licenseExpiry": "2027-01-31",
      "photoUrl": null,
      "address": "Sector 30, Noida",
      "emergencyContactName": "Sita Kumar",
      "emergencyContactPhone": "9876543211",
      "isActive": true
    },
    "vehicle": {
      "id": "uuid",
      "vehicleNo": "DL-01-AB-1234",
      "capacity": 30
    },
    "route": {
      "id": "uuid",
      "name": "Route A - Sector 50",
      "stopCount": 8
    },
    "user": {
      "userId": "uuid",
      "email": "ramesh@school.in",
      "lastLogin": "2026-03-16T08:30:00Z"
    }
  }
}
```

**PUT /api/driver/profile**
Request body (partial update):
```json
{
  "phone": "9876543210",
  "emergencyContactName": "Sita Kumar",
  "emergencyContactPhone": "9876543211",
  "address": "Sector 30, Noida"
}
```

---

## 6. Flutter Structure

### 6.1 Routes

- `/login/driver` — Driver login (email/password) — same as staff login with portal_type=driver
- `/driver/dashboard` — Driver dashboard
- `/driver/profile` — Driver profile
- `/driver/change-password` — Change password

### 6.2 Shell Layout (Mobile)

- **BottomNavigationBar**: Dashboard, Profile
- **AppBar**: School name, logo, logout
- **Drawer**: Dashboard, Profile, Change Password, Logout

### 6.3 Files to Create

```
lib/
├── core/
│   ├── config/api_config.dart          # Add driver endpoints
│   └── services/driver_service.dart     # Driver API calls
├── models/
│   └── driver/
│       ├── driver_dashboard_model.dart
│       └── driver_profile_model.dart
├── features/
│   └── driver/
│       ├── presentation/
│       │   ├── driver_shell.dart
│       │   ├── providers/
│       │   │   ├── driver_dashboard_provider.dart
│       │   │   └── driver_profile_provider.dart
│       │   └── screens/
│       │       ├── driver_dashboard_screen.dart
│       │       ├── driver_profile_screen.dart
│       │       └── driver_change_password_screen.dart
│       └── data/
│           └── (if needed)
```

### 6.4 Auth

- Driver login: Use `schoolStaffLoginProvider` with `portalType: 'driver'`, `schoolIdentity` from saved school or QR.
- Add route `/login/driver` — similar to staff login screen.
- After login, redirect to `/driver/dashboard` when `portalType == 'driver'`.

---

## 7. Cross-Cutting Concerns

| Concern | Owner | Detail |
|---------|-------|--------|
| Driver ↔ User link | Backend | Driver.userId → User.id. JWT has userId; find Driver by userId. |
| Portal type in JWT | Auth | `portal_type: 'driver'` must be set on login. |
| Tenant isolation | Backend | All queries filter by `req.user.school_id` and `driver.school_id`. |
| Mobile-only | Flutter | All driver screens use mobile layout (no web sidebar). |

---

## 8. Validation

### Database
- `drivers` table created
- `vehicles` table created
- `transport_routes` table created
- `route_stops` table created
- Driver CRUD by school admin (future)

### Backend
- `GET /api/driver/dashboard/stats` returns 200 with correct shape
- `GET /api/driver/profile` returns 200 with correct shape
- `PUT /api/driver/profile` updates and returns 200
- Unauthenticated requests return 401

### Flutter
- `flutter analyze` passes
- Driver dashboard loads
- Driver profile loads
- Change password works

---

## 9. Acceptance Criteria

1. **Login**: Driver logs in with email/password → redirected to dashboard
2. **Dashboard**: Driver sees vehicle, route, student count, trip status
3. **Profile**: Driver views and edits profile (phone, emergency contact)
4. **Change Password**: Driver changes password successfully
5. **Logout**: Driver logs out → redirected to login

---

## 10. Dependencies

- Auth system (already built)
- School Admin creates Driver records (future — for Phase 1, seed demo driver)
- Vehicle and Route created by School Admin (future — for Phase 1, seed demo data)

---

## 11. Phase 2 (Future)

- QR login with vehicle auto-assign
- RFID scan for pickup/drop
- GPS tracking (start/end trip)
- Route stops list
- Student list on route

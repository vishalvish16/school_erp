# Driver Module — Database Prompt

**Purpose**: Add Prisma models for Driver, Vehicle, TransportRoute, RouteStop and update User/School relations. This prompt is copy-paste ready for the erp-db-architect agent or a database developer.

**Project Root**: `e:/School_ERP_AI/erp-new-logic/`  
**Schema File**: `backend/prisma/schema.prisma`  
**Reference**: `docs/modules/driver/SPEC.md`

---

## 1. New Models to Add

Add the following models to `backend/prisma/schema.prisma`. Place them after the Teacher Module section (after `ClassDiary` model) and before any existing transport-related models, if any.

### 1.1 Driver Model

```prisma
// ─── Driver Portal (Transport Module) ────────────────────────────────────────

model Driver {
  id                     String    @id @default(uuid()) @db.Uuid
  schoolId               String    @map("school_id") @db.Uuid
  userId                 String?   @unique @map("user_id") @db.Uuid
  employeeNo             String    @map("employee_no") @db.VarChar(50)
  firstName              String    @map("first_name") @db.VarChar(100)
  lastName               String    @map("last_name") @db.VarChar(100)
  gender                 String    @db.VarChar(10)
  dateOfBirth            DateTime? @map("date_of_birth") @db.Date
  phone                  String?   @db.VarChar(20)
  email                  String    @db.VarChar(255)
  licenseNumber          String?   @map("license_number") @db.VarChar(50)
  licenseExpiry          DateTime? @map("license_expiry") @db.Date
  photoUrl               String?   @map("photo_url") @db.Text
  address                String?   @db.Text
  emergencyContactName   String?   @map("emergency_contact_name") @db.VarChar(100)
  emergencyContactPhone  String?   @map("emergency_contact_phone") @db.VarChar(20)
  isActive               Boolean   @default(true) @map("is_active")
  deletedAt              DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt              DateTime  @default(now()) @map("created_at")
  updatedAt              DateTime  @default(now()) @updatedAt @map("updated_at")

  school   School    @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  user     User?     @relation("DriverUser", fields: [userId], references: [id], onDelete: SetNull)
  vehicle  Vehicle?  @relation("DriverVehicle")

  @@unique([schoolId, employeeNo])
  @@index([schoolId])
  @@index([userId])
  @@map("drivers")
}
```

### 1.2 Vehicle Model

```prisma
model Vehicle {
  id          String    @id @default(uuid()) @db.Uuid
  schoolId    String    @map("school_id") @db.Uuid
  driverId    String?   @unique @map("driver_id") @db.Uuid
  vehicleNo   String    @map("vehicle_no") @db.VarChar(50)
  capacity    Int       @default(30)
  gpsDeviceId String?   @map("gps_device_id") @db.VarChar(100)
  isActive    Boolean   @default(true) @map("is_active")
  deletedAt   DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt   DateTime  @default(now()) @map("created_at")
  updatedAt   DateTime  @default(now()) @updatedAt @map("updated_at")

  school  School           @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  driver  Driver?          @relation("DriverVehicle", fields: [driverId], references: [id], onDelete: SetNull)
  route   TransportRoute?  @relation("VehicleRoute")

  @@unique([schoolId, vehicleNo])
  @@index([schoolId])
  @@index([driverId])
  @@map("vehicles")
}
```

### 1.3 TransportRoute Model

```prisma
model TransportRoute {
  id          String    @id @default(uuid()) @db.Uuid
  schoolId    String    @map("school_id") @db.Uuid
  vehicleId   String?   @unique @map("vehicle_id") @db.Uuid
  name        String    @db.VarChar(100)
  description String?   @db.Text
  isActive    Boolean   @default(true) @map("is_active")
  deletedAt   DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt   DateTime  @default(now()) @map("created_at")
  updatedAt   DateTime  @default(now()) @updatedAt @map("updated_at")

  school School       @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  vehicle Vehicle?    @relation("VehicleRoute", fields: [vehicleId], references: [id], onDelete: SetNull)
  stops  RouteStop[]

  @@index([schoolId])
  @@index([vehicleId])
  @@map("transport_routes")
}
```

### 1.4 RouteStop Model

```prisma
model RouteStop {
  id               String   @id @default(uuid()) @db.Uuid
  routeId          String   @map("route_id") @db.Uuid
  sequence         Int      @db.SmallInt
  name             String   @db.VarChar(100)
  address          String?  @db.Text
  lat              Decimal? @db.Decimal(10, 7)
  lng              Decimal? @db.Decimal(10, 7)
  estimatedArrival String?  @map("estimated_arrival") @db.VarChar(8)
  createdAt        DateTime @default(now()) @map("created_at")
  updatedAt        DateTime @default(now()) @updatedAt @map("updated_at")

  route TransportRoute @relation(fields: [routeId], references: [id], onDelete: Cascade)

  @@unique([routeId, sequence])
  @@index([routeId])
  @@map("route_stops")
}
```

---

## 2. Updates to Existing Models

### 2.1 User Model

Add the following relation to the `User` model (inside `backend/prisma/schema.prisma`):

```prisma
// Add to User model relations:
driverProfile Driver? @relation("DriverUser")
```

Insert this line alongside existing relations like `staffProfile`, `ntStaffProfile`, etc.

### 2.2 School Model

Add the following relations to the `School` model:

```prisma
// Add to School model relations:
drivers         Driver[]
vehicles        Vehicle[]
transportRoutes TransportRoute[]
```

Insert these lines alongside existing relations like `staff`, `students`, etc.

---

## 3. Migration

- **Migration file name**: `YYYYMMDDHHMMSS_add_driver_transport_models`
- **Example**: `20260316120000_add_driver_transport_models`

Run after schema update:
```bash
cd backend && npx prisma migrate dev --name add_driver_transport_models
```

---

## 4. Seed Data (Optional for Phase 1)

For demo/testing, add a seed script or manual seed that creates:
1. One `Driver` record linked to an existing `User` (with `school_id` set)
2. One `Vehicle` record linked to that driver
3. One `TransportRoute` linked to that vehicle
4. A few `RouteStop` records for the route

This enables the driver portal to show dashboard data immediately.

---

## 5. Validation Checklist

- [ ] All four new tables created: `drivers`, `vehicles`, `transport_routes`, `route_stops`
- [ ] `User.driverProfile` relation added
- [ ] `School.drivers`, `School.vehicles`, `School.transportRoutes` relations added
- [ ] Unique constraints: `(school_id, employee_no)` on drivers, `(school_id, vehicle_no)` on vehicles, `(route_id, sequence)` on route_stops
- [ ] Indexes on `school_id`, `user_id`, `driver_id`, `vehicle_id`, `route_id` for query performance
- [ ] Soft delete via `deletedAt` on Driver, Vehicle, TransportRoute
- [ ] `npx prisma generate` succeeds after migration

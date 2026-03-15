# DATABASE PROMPT — School Admin Module

## Agent Role
You are the Database Architect for the Vidyron School ERP platform. Your task is to extend the existing Prisma schema with all models required by the School Admin portal and produce the corresponding migration SQL file.

---

## Project Context

- **Root**: `e:/School_ERP_AI/erp-new-logic/`
- **Schema file**: `e:/School_ERP_AI/erp-new-logic/backend/prisma/schema.prisma`
- **ORM**: Prisma with PostgreSQL
- **Database conventions**:
  - All primary keys: `String @id @default(uuid()) @db.Uuid`
  - All FK columns: `@map("snake_case") @db.Uuid`
  - Table names: `@@map("snake_case_plural")`
  - Soft delete: `deletedAt DateTime? @map("deleted_at") @db.Timestamptz(6)`
  - Timestamps: `createdAt DateTime @default(now()) @map("created_at")` and `updatedAt DateTime @default(now()) @updatedAt @map("updated_at")`
  - Tenant isolation: every school-scoped model has `schoolId String @map("school_id") @db.Uuid` referencing `School.id` with `onDelete: Cascade`

---

## Existing Schema to Understand

The schema already contains:

```
model School {
  id        String  @id @default(uuid()) @db.Uuid
  name      String
  code      String  @unique
  subdomain String? @unique
  ...
  users     User[]
  @@map("schools")
}

model User {
  id           String  @id @default(uuid()) @db.Uuid
  schoolId     String? @map("school_id") @db.Uuid
  email        String  @unique
  passwordHash String  @map("password_hash")
  firstName    String? @map("first_name")
  lastName     String? @map("last_name")
  phone        String?
  avatarUrl    String? @map("avatar_url")
  ...
  role         Role    @relation(fields: [roleId], references: [id])
  school       School? @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  managedGroup SchoolGroup? @relation("GroupAdmin")
  @@map("users")
}
```

---

## Task 1: Add Nine New Models to schema.prisma

Add all nine models below to the schema file **after** the existing `User` model block. Do not remove or alter any existing model.

### Model 1 — Student

```prisma
model Student {
  id             String    @id @default(uuid()) @db.Uuid
  schoolId       String    @map("school_id") @db.Uuid
  admissionNo    String    @map("admission_no") @db.VarChar(50)
  firstName      String    @map("first_name") @db.VarChar(100)
  lastName       String    @map("last_name") @db.VarChar(100)
  gender         String    @db.VarChar(10)
  dateOfBirth    DateTime  @map("date_of_birth") @db.Date
  bloodGroup     String?   @map("blood_group") @db.VarChar(5)
  phone          String?   @db.VarChar(20)
  email          String?   @db.VarChar(255)
  address        String?   @db.Text
  photoUrl       String?   @map("photo_url") @db.Text
  classId        String?   @map("class_id") @db.Uuid
  sectionId      String?   @map("section_id") @db.Uuid
  rollNo         Int?      @map("roll_no")
  status         String    @default("ACTIVE") @db.VarChar(20)
  admissionDate  DateTime  @map("admission_date") @db.Date
  parentName     String?   @map("parent_name") @db.VarChar(200)
  parentPhone    String?   @map("parent_phone") @db.VarChar(20)
  parentEmail    String?   @map("parent_email") @db.VarChar(255)
  parentRelation String?   @map("parent_relation") @db.VarChar(50)
  deletedAt      DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt      DateTime  @default(now()) @map("created_at")
  updatedAt      DateTime  @default(now()) @updatedAt @map("updated_at")

  school      School       @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  class_      SchoolClass? @relation(fields: [classId], references: [id], onDelete: SetNull)
  section     Section?     @relation(fields: [sectionId], references: [id], onDelete: SetNull)
  attendances Attendance[]

  @@unique([schoolId, admissionNo])
  @@index([schoolId])
  @@index([classId])
  @@map("students")
}
```

**Allowed values for `status`**: `ACTIVE`, `INACTIVE`, `TRANSFERRED`
**Allowed values for `gender`**: `MALE`, `FEMALE`, `OTHER`

### Model 2 — Staff

```prisma
model Staff {
  id            String    @id @default(uuid()) @db.Uuid
  schoolId      String    @map("school_id") @db.Uuid
  userId        String?   @unique @map("user_id") @db.Uuid
  employeeNo    String    @map("employee_no") @db.VarChar(50)
  firstName     String    @map("first_name") @db.VarChar(100)
  lastName      String    @map("last_name") @db.VarChar(100)
  gender        String    @db.VarChar(10)
  dateOfBirth   DateTime? @map("date_of_birth") @db.Date
  phone         String?   @db.VarChar(20)
  email         String    @db.VarChar(255)
  designation   String    @db.VarChar(100)
  subjects      String[]  @default([])
  qualification String?   @db.VarChar(255)
  joinDate      DateTime  @map("join_date") @db.Date
  photoUrl      String?   @map("photo_url") @db.Text
  isActive      Boolean   @default(true) @map("is_active")
  deletedAt     DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt     DateTime  @default(now()) @map("created_at")
  updatedAt     DateTime  @default(now()) @updatedAt @map("updated_at")

  school          School    @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  user            User?     @relation("StaffUser", fields: [userId], references: [id], onDelete: SetNull)
  taughtSections  Section[] @relation("ClassTeacher")

  @@unique([schoolId, employeeNo])
  @@index([schoolId])
  @@map("staff")
}
```

**Note on `designation`**: Free-text field; typical values include `TEACHER`, `CLERK`, `LIBRARIAN`, `ACCOUNTANT`, `PRINCIPAL`.

### Model 3 — SchoolClass

```prisma
model SchoolClass {
  id        String    @id @default(uuid()) @db.Uuid
  schoolId  String    @map("school_id") @db.Uuid
  name      String    @db.VarChar(50)
  numeric   Int?
  isActive  Boolean   @default(true) @map("is_active")
  createdAt DateTime  @default(now()) @map("created_at")
  updatedAt DateTime  @default(now()) @updatedAt @map("updated_at")

  school        School         @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  sections      Section[]
  students      Student[]
  timetables    Timetable[]
  feeStructures FeeStructure[]

  @@unique([schoolId, name])
  @@index([schoolId])
  @@map("school_classes")
}
```

### Model 4 — Section

```prisma
model Section {
  id             String    @id @default(uuid()) @db.Uuid
  schoolId       String    @map("school_id") @db.Uuid
  classId        String    @map("class_id") @db.Uuid
  name           String    @db.VarChar(10)
  classTeacherId String?   @map("class_teacher_id") @db.Uuid
  capacity       Int       @default(40)
  isActive       Boolean   @default(true) @map("is_active")
  createdAt      DateTime  @default(now()) @map("created_at")
  updatedAt      DateTime  @default(now()) @updatedAt @map("updated_at")

  school       School      @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  class_       SchoolClass @relation(fields: [classId], references: [id], onDelete: Cascade)
  classTeacher Staff?      @relation("ClassTeacher", fields: [classTeacherId], references: [id], onDelete: SetNull)
  students     Student[]
  attendances  Attendance[]
  timetables   Timetable[]

  @@unique([classId, name])
  @@index([schoolId])
  @@map("sections")
}
```

### Model 5 — Attendance

```prisma
model Attendance {
  id        String   @id @default(uuid()) @db.Uuid
  schoolId  String   @map("school_id") @db.Uuid
  studentId String   @map("student_id") @db.Uuid
  sectionId String   @map("section_id") @db.Uuid
  date      DateTime @db.Date
  status    String   @db.VarChar(10)
  markedBy  String   @map("marked_by") @db.Uuid
  remarks   String?  @db.VarChar(255)
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @default(now()) @updatedAt @map("updated_at")

  school  School  @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  student Student @relation(fields: [studentId], references: [id], onDelete: Cascade)
  section Section @relation(fields: [sectionId], references: [id], onDelete: Cascade)

  @@unique([studentId, date])
  @@index([schoolId, date])
  @@index([sectionId, date])
  @@map("attendances")
}
```

**Allowed values for `status`**: `PRESENT`, `ABSENT`, `LATE`, `HOLIDAY`

### Model 6 — FeeStructure

```prisma
model FeeStructure {
  id           String    @id @default(uuid()) @db.Uuid
  schoolId     String    @map("school_id") @db.Uuid
  classId      String?   @map("class_id") @db.Uuid
  academicYear String    @map("academic_year") @db.VarChar(10)
  feeHead      String    @map("fee_head") @db.VarChar(100)
  amount       Decimal   @db.Decimal(10, 2)
  frequency    String    @db.VarChar(20)
  dueDay       Int?      @map("due_day")
  isActive     Boolean   @default(true) @map("is_active")
  createdAt    DateTime  @default(now()) @map("created_at")
  updatedAt    DateTime  @default(now()) @updatedAt @map("updated_at")

  school  School       @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  class_  SchoolClass? @relation(fields: [classId], references: [id], onDelete: SetNull)

  @@index([schoolId, academicYear])
  @@map("fee_structures")
}
```

**Allowed values for `frequency`**: `MONTHLY`, `QUARTERLY`, `ANNUALLY`, `ONE_TIME`
**`classId` null** means the fee head applies to all classes.

### Model 7 — FeePayment

```prisma
model FeePayment {
  id           String   @id @default(uuid()) @db.Uuid
  schoolId     String   @map("school_id") @db.Uuid
  studentId    String   @map("student_id") @db.Uuid
  feeHead      String   @map("fee_head") @db.VarChar(100)
  academicYear String   @map("academic_year") @db.VarChar(10)
  amount       Decimal  @db.Decimal(10, 2)
  paymentDate  DateTime @map("payment_date") @db.Date
  paymentMode  String   @map("payment_mode") @db.VarChar(30)
  receiptNo    String   @map("receipt_no") @db.VarChar(50)
  collectedBy  String   @map("collected_by") @db.Uuid
  remarks      String?  @db.VarChar(255)
  createdAt    DateTime @default(now()) @map("created_at")
  updatedAt    DateTime @default(now()) @updatedAt @map("updated_at")

  school School @relation(fields: [schoolId], references: [id], onDelete: Cascade)

  @@unique([schoolId, receiptNo])
  @@index([schoolId, studentId])
  @@map("fee_payments")
}
```

**Allowed values for `paymentMode`**: `CASH`, `UPI`, `BANK_TRANSFER`, `CHEQUE`

### Model 8 — SchoolNotice

```prisma
model SchoolNotice {
  id          String    @id @default(uuid()) @db.Uuid
  schoolId    String    @map("school_id") @db.Uuid
  title       String    @db.VarChar(255)
  body        String    @db.Text
  targetRole  String?   @map("target_role") @db.VarChar(50)
  isPinned    Boolean   @default(false) @map("is_pinned")
  publishedAt DateTime? @map("published_at") @db.Timestamptz(6)
  expiresAt   DateTime? @map("expires_at") @db.Timestamptz(6)
  createdBy   String    @map("created_by") @db.Uuid
  deletedAt   DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt   DateTime  @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt   DateTime  @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

  school School @relation(fields: [schoolId], references: [id], onDelete: Cascade)

  @@index([schoolId])
  @@map("school_notices")
}
```

**Allowed values for `targetRole`**: `all`, `teacher`, `student`, `parent`

### Model 9 — Timetable

```prisma
model Timetable {
  id        String    @id @default(uuid()) @db.Uuid
  schoolId  String    @map("school_id") @db.Uuid
  classId   String    @map("class_id") @db.Uuid
  sectionId String?   @map("section_id") @db.Uuid
  dayOfWeek Int       @map("day_of_week")
  periodNo  Int       @map("period_no")
  subject   String    @db.VarChar(100)
  staffId   String?   @map("staff_id") @db.Uuid
  startTime String    @map("start_time") @db.VarChar(8)
  endTime   String    @map("end_time") @db.VarChar(8)
  room      String?   @db.VarChar(50)
  createdAt DateTime  @default(now()) @map("created_at")
  updatedAt DateTime  @default(now()) @updatedAt @map("updated_at")

  school  School      @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  class_  SchoolClass @relation(fields: [classId], references: [id], onDelete: Cascade)
  section Section?    @relation(fields: [sectionId], references: [id], onDelete: SetNull)

  @@unique([classId, sectionId, dayOfWeek, periodNo])
  @@index([schoolId])
  @@map("timetables")
}
```

**`dayOfWeek`**: 1 = Monday, 2 = Tuesday, …, 6 = Saturday
**`startTime` / `endTime`**: stored as `"HH:MM"` strings (e.g. `"08:00"`)

---

## Task 2: Modify Existing Models in schema.prisma

### Add to `User` model (inside the model block, before the `@@map` line):

```prisma
  staffProfile Staff? @relation("StaffUser")
```

### Add to `School` model (inside the model block, before the `@@map` line):

```prisma
  students      Student[]
  staff         Staff[]
  classes       SchoolClass[]
  sections      Section[]
  attendances   Attendance[]
  feeStructures FeeStructure[]
  feePayments   FeePayment[]
  notices       SchoolNotice[]
  timetables    Timetable[]
```

---

## Task 3: Create Migration SQL File

**File path**: `e:/School_ERP_AI/erp-new-logic/backend/prisma/migrations/20260315130000_add_school_admin_models/migration.sql`

Create the directory and write the migration SQL. The SQL must:

1. Create all nine tables in dependency order: `school_classes` and `staff` before `sections` (which FK-references both), `students` before `attendances`, etc.
2. Use PostgreSQL syntax.
3. Include all `CREATE TABLE IF NOT EXISTS` statements.
4. Include all `CREATE UNIQUE INDEX` statements for `@@unique` constraints.
5. Include all `CREATE INDEX` statements for `@@index` constraints.
6. Include all `ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY` statements.

### Correct table creation order (respects FK dependencies):

1. `school_classes` (depends on `schools`)
2. `staff` (depends on `schools`, `users`)
3. `sections` (depends on `schools`, `school_classes`, `staff`)
4. `students` (depends on `schools`, `school_classes`, `sections`)
5. `attendances` (depends on `schools`, `students`, `sections`)
6. `fee_structures` (depends on `schools`, `school_classes`)
7. `fee_payments` (depends on `schools`)
8. `school_notices` (depends on `schools`)
9. `timetables` (depends on `schools`, `school_classes`, `sections`)

### SQL template for each table (fill in columns from models above):

```sql
-- CreateTable
CREATE TABLE IF NOT EXISTS "school_classes" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "name" VARCHAR(50) NOT NULL,
    "numeric" INTEGER,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "school_classes_pkey" PRIMARY KEY ("id")
);

-- ... (repeat for each table)

-- CreateIndex
CREATE UNIQUE INDEX "school_classes_school_id_name_key" ON "school_classes"("school_id", "name");
CREATE INDEX "school_classes_school_id_idx" ON "school_classes"("school_id");

-- AddForeignKey
ALTER TABLE "school_classes" ADD CONSTRAINT "school_classes_school_id_fkey"
    FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE CASCADE ON UPDATE CASCADE;
```

Full column lists per table are exactly as defined in the Prisma models above. Use `DECIMAL(10,2)` for Decimal fields, `TEXT` for `@db.Text` fields, `DATE` for `@db.Date` fields, `TIMESTAMPTZ(6)` for `@db.Timestamptz(6)` fields, `VARCHAR(n)` for `@db.VarChar(n)` fields.

---

## Task 4: Run Prisma Format and Generate

After writing the schema changes, confirm that the developer should run these commands in `e:/School_ERP_AI/erp-new-logic/backend/`:

```bash
npx prisma format
npx prisma generate
npx prisma migrate deploy   # or: npx prisma db push for dev
```

---

## Constraints and Rules

- Do NOT remove any existing model or field.
- Do NOT change any existing `@@map` table name.
- `subjects` on `Staff` is a PostgreSQL text array: `String[] @default([])` — this translates to `TEXT[] DEFAULT '{}'` in SQL.
- The `Staff.taughtSections` relation (back-reference to Section via `"ClassTeacher"`) must be declared as shown; the `Staff` model does NOT have a direct FK to `Section` — it is the other way: `Section.classTeacherId` is the FK.
- The `Timetable.@@unique([classId, sectionId, dayOfWeek, periodNo])` applies even when `sectionId` is null; this means a class-level slot (null section) is also uniquely constrained per day and period.
- `FeePayment` has no direct Prisma relation to `Student` — the `studentId` field is a UUID column but the FK constraint at the DB level exists. Add it as a raw FK in the SQL migration; the backend service will join via raw query or separate lookup.

---

## Output Checklist

- [ ] `backend/prisma/schema.prisma` — 9 new models added, User and School models extended
- [ ] `backend/prisma/migrations/20260315130000_add_school_admin_models/migration.sql` — complete SQL migration

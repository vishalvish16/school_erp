# Parent Portal — Database Prompt

**Purpose:** Add Parent and StudentParent models, update School and Student relations.  
**Target:** `backend/prisma/schema.prisma`  
**Date:** 2026-03-16

---

## 1. New Prisma Models (Copy-Paste Ready)

Add the following models to `backend/prisma/schema.prisma`. Place them after the Student model and before the Attendance model.

### 1.1 Parent Model

```prisma
model Parent {
  id        String    @id @default(uuid()) @db.Uuid
  schoolId  String    @map("school_id") @db.Uuid
  firstName String    @map("first_name") @db.VarChar(100)
  lastName  String    @map("last_name") @db.VarChar(100)
  phone     String    @db.VarChar(20)
  email     String?   @db.VarChar(255)
  relation  String?   @db.VarChar(50)
  isActive  Boolean   @default(true) @map("is_active")
  deletedAt DateTime? @map("deleted_at") @db.Timestamptz(6)
  createdAt DateTime  @default(now()) @map("created_at")
  updatedAt DateTime  @updatedAt @map("updated_at")

  school School           @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  links  StudentParent[]

  @@unique([schoolId, phone])
  @@index([schoolId])
  @@index([phone])
  @@map("parents")
}
```

### 1.2 StudentParent Model (Parent–Student Link)

```prisma
model StudentParent {
  id        String   @id @default(uuid()) @db.Uuid
  studentId String   @map("student_id") @db.Uuid
  parentId  String   @map("parent_id") @db.Uuid
  relation  String   @db.VarChar(50)
  isPrimary Boolean  @default(false) @map("is_primary")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  student Student @relation(fields: [studentId], references: [id], onDelete: Cascade)
  parent  Parent  @relation(fields: [parentId], references: [id], onDelete: Cascade)

  @@unique([studentId, parentId])
  @@index([parentId])
  @@index([studentId])
  @@map("student_parents")
}
```

---

## 2. Updates to Existing Models

### 2.1 School Model

Add the `parents` relation to the School model. Insert inside the model block (e.g., after `classDiary ClassDiary[]`):

```prisma
  parents Parent[]
```

### 2.2 Student Model

Add the `parentLinks` relation to the Student model. Insert inside the model block (e.g., after `feePayments FeePayment[]`):

```prisma
  parentLinks StudentParent[]
```

**Note:** Keep existing denormalized fields `parentName`, `parentPhone`, `parentEmail`, `parentRelation` for backward compatibility. These are synced from the primary parent when Parent/StudentParent records exist.

### 2.3 Optional: Index on Student.parentPhone

For faster lookup when resolving parent by phone (finding Student by `parentPhone` before Parent exists), add:

```prisma
  @@index([parentPhone])
```

inside the Student model, if not already present. Check existing indexes first.

---

## 3. Field Reference

| Model         | Field     | Type      | Notes                                      |
|---------------|-----------|-----------|--------------------------------------------|
| Parent        | id        | UUID      | Primary key                                |
| Parent        | schoolId  | UUID      | FK to School                               |
| Parent        | firstName | VarChar(100) | Required                               |
| Parent        | lastName  | VarChar(100) | Required                               |
| Parent        | phone     | VarChar(20) | Primary login identifier, E.164 format  |
| Parent        | email     | VarChar(255)? | Optional                             |
| Parent        | relation  | VarChar(50)? | Father, Mother, Guardian               |
| Parent        | isActive  | Boolean   | Default true                               |
| Parent        | deletedAt | Timestamptz? | Soft delete                            |
| StudentParent| studentId | UUID      | FK to Student                              |
| StudentParent| parentId  | UUID      | FK to Parent                               |
| StudentParent| relation  | VarChar(50) | Father, Mother, Guardian                |
| StudentParent| isPrimary | Boolean   | Default false                              |

---

## 4. Migration

### 4.1 Migration File Name

Use format: `YYYYMMDDHHMMSS_add_parent_module`

Example: `20260316120000_add_parent_module`

### 4.2 Commands

```bash
cd backend
npx prisma migrate dev --name add_parent_module
```

### 4.3 Post-Migration Verification

1. Run `npx prisma generate` to regenerate the client.
2. Verify relations: `Parent.school`, `Parent.links`, `StudentParent.student`, `StudentParent.parent`, `School.parents`, `Student.parentLinks`.

---

## 5. Seed Data (Optional)

Add one Parent and one StudentParent for testing:

```javascript
// In prisma/seed.js or similar
const parent = await prisma.parent.create({
  data: {
    schoolId: '<existing_school_id>',
    firstName: 'Demo',
    lastName: 'Parent',
    phone: '+919876543210',
    email: 'parent@example.com',
    relation: 'Father',
    isActive: true,
  },
});

await prisma.studentParent.create({
  data: {
    studentId: '<existing_student_id>',
    parentId: parent.id,
    relation: 'Father',
    isPrimary: true,
  },
});
```

---

## 6. Constraints and Indexes Summary

| Constraint/Index | Location        | Purpose                                  |
|------------------|-----------------|------------------------------------------|
| @@unique([schoolId, phone]) | Parent       | One parent per phone per school          |
| @@index([schoolId])        | Parent       | Tenant-scoped queries                    |
| @@index([phone])           | Parent       | Phone lookup for auth                    |
| @@unique([studentId, parentId]) | StudentParent | No duplicate links              |
| @@index([parentId])       | StudentParent | List children for a parent              |
| @@index([studentId])      | StudentParent | List parents for a student              |

---

## 7. Error Handling

- If migration fails due to existing data, ensure no orphaned `parentPhone` values conflict with the new unique constraint. The `@@unique([schoolId, phone])` on Parent means two parents in the same school cannot share the same phone.
- If Student has multiple parents (e.g., father and mother), create multiple StudentParent records with different `parentId` values.

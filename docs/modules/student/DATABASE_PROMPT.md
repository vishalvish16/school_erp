# Student Module — Database Prompt

**Purpose**: Implement all database schema changes required for the Student Portal. The receiving agent (erp-db-architect) must apply these changes to `backend/prisma/schema.prisma` and create migrations.

**Reference**: Existing schema at `e:/School_ERP_AI/erp-new-logic/backend/prisma/schema.prisma`

---

## 1. Changes to Existing Models

### 1.1 Student Model — Add `userId` and User Relation

Add the following to the `Student` model (after `deletedAt`, before `createdAt`):

```prisma
  userId    String?   @unique @map("user_id") @db.Uuid  // Portal login link
```

Add the relation (after `feePayments`):

```prisma
  user      User?     @relation("StudentUser", fields: [userId], references: [id], onDelete: SetNull)
```

Add index for efficient lookups by userId:

```prisma
  @@index([userId])
```

**Full Student model after changes** (for reference — do not replace entire model, only add the fields/relations above):

```prisma
model Student {
  id             String         @id @default(uuid()) @db.Uuid
  schoolId       String         @map("school_id") @db.Uuid
  admissionNo    String         @map("admission_no") @db.VarChar(100)
  firstName      String         @map("first_name") @db.VarChar(100)
  lastName       String         @map("last_name") @db.VarChar(100)
  gender         StudentsGender
  dateOfBirth    DateTime       @map("date_of_birth") @db.Date
  bloodGroup     String?        @map("blood_group") @db.VarChar(5)
  phone          String?        @db.VarChar(20)
  email          String?        @db.VarChar(255)
  address        String?        @db.Text
  photoUrl       String?        @map("photo_url") @db.Text
  classId        String?        @map("class_id") @db.Uuid
  sectionId      String?        @map("section_id") @db.Uuid
  rollNo         Int?           @map("roll_no")
  status         StudentsStatus @default(ACTIVE)
  admissionDate  DateTime       @map("admission_date") @db.Date
  parentName     String?        @map("parent_name") @db.VarChar(200)
  parentPhone    String?        @map("parent_phone") @db.VarChar(20)
  parentEmail    String?        @map("parent_email") @db.VarChar(255)
  parentRelation String?        @map("parent_relation") @db.VarChar(50)
  deletedAt      DateTime?     @map("deleted_at") @db.Timestamptz(6)
  userId         String?       @unique @map("user_id") @db.Uuid
  createdAt      DateTime     @default(now()) @map("created_at")
  updatedAt      DateTime     @default(now()) @updatedAt @map("updated_at")

  school      School       @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  class_      SchoolClass? @relation(fields: [classId], references: [id], onDelete: SetNull)
  section     Section?     @relation(fields: [sectionId], references: [id], onDelete: SetNull)
  attendances Attendance[]
  feePayments FeePayment[]
  user        User?        @relation("StudentUser", fields: [userId], references: [id], onDelete: SetNull)
  documents   StudentDocument[]

  @@unique([schoolId, admissionNo])
  @@index([schoolId])
  @@index([classId])
  @@index([userId])
  @@map("students")
}
```

### 1.2 User Model — Add Student Relation

Add to the `User` model (after existing relations like `verifiedNTDocuments`):

```prisma
  studentProfile Student? @relation("StudentUser")
```

---

## 2. New Model: StudentDocument

Create the `student_documents` table. Place it after the `Student` model and before `Attendance`.

**Allowed `documentType` values** (enforce in backend validation): `AADHAAR`, `TRANSFER_CERT`, `BIRTH_CERT`, `OTHER`

```prisma
model StudentDocument {
  id           String    @id @default(uuid()) @db.Uuid
  schoolId     String    @map("school_id") @db.Uuid
  studentId    String    @map("student_id") @db.Uuid
  documentType String    @map("document_type") @db.VarChar(50)
  documentName String             @map("document_name") @db.VarChar(255)
  fileUrl      String             @map("file_url") @db.Text
  fileSizeKb   Int?               @map("file_size_kb")
  mimeType     String?             @map("mime_type") @db.VarChar(100)
  uploadedBy   String             @map("uploaded_by") @db.Uuid
  verified     Boolean            @default(false)
  verifiedAt   DateTime?          @map("verified_at") @db.Timestamptz(6)
  verifiedBy   String?             @map("verified_by") @db.Uuid
  deletedAt    DateTime?          @map("deleted_at") @db.Timestamptz(6)
  createdAt    DateTime           @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt    DateTime           @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)

  school   School  @relation(fields: [schoolId], references: [id], onDelete: Cascade)
  student  Student @relation(fields: [studentId], references: [id], onDelete: Cascade)
  uploader User    @relation("StudentDocUploader", fields: [uploadedBy], references: [id], onDelete: Restrict)
  verifier User?   @relation("StudentDocVerifier", fields: [verifiedBy], references: [id], onDelete: SetNull)

  @@index([schoolId])
  @@index([studentId])
  @@index([studentId, deletedAt])
  @@map("student_documents")
}
```

---

## 3. User Model — Add StudentDocument Relations

Add to the `User` model (for uploader and verifier of student documents):

```prisma
  uploadedStudentDocs StudentDocument[] @relation("StudentDocUploader")
  verifiedStudentDocs StudentDocument[] @relation("StudentDocVerifier")
```

---

## 4. School Model — Add StudentDocument Relation

Add to the `School` model:

```prisma
  studentDocuments StudentDocument[]
```

---

## 5. Migration File

**Suggested migration name**: `YYYYMMDDHHMMSS_add_student_portal`

Example: `20260316120000_add_student_portal`

**Migration steps**:
1. Add `user_id` column to `students` (nullable UUID, unique)
2. Create `student_document_type_enum` if using enum
3. Create `student_documents` table with all columns
4. Add foreign key `students.user_id` → `users.id` (ON DELETE SET NULL)
5. Add foreign keys for `student_documents` (school_id, student_id, uploaded_by, verified_by)
6. Create indexes: `students(user_id)`, `student_documents(school_id)`, `student_documents(student_id)`, `student_documents(student_id, deleted_at)`

---

## 6. Seed / Role Requirement

Ensure a Role with `name = 'STUDENT'` and `scope = 'SCHOOL'` exists. Add to seed if missing:

```javascript
// In seed or migration — ensure STUDENT role exists
await prisma.role.upsert({
  where: { /* unique constraint if any */ },
  create: { name: 'STUDENT', description: 'Student portal user', scope: 'SCHOOL' },
  update: {}
});
```

If roles are identified by `(name, scope)` or similar, add the STUDENT role for SCHOOL scope.

---

## 7. Summary Checklist

- [ ] Add `userId` (optional, unique) to Student
- [ ] Add `user` relation to Student
- [ ] Add `studentProfile` relation to User
- [ ] Add `StudentDocumentType` enum (or use String)
- [ ] Create `StudentDocument` model with all fields
- [ ] Add `documents` relation to Student
- [ ] Add `studentDocuments` relation to School
- [ ] Add `uploadedStudentDocs` and `verifiedStudentDocs` to User
- [ ] Add `@@index([userId])` to Student
- [ ] Create migration file
- [ ] Ensure STUDENT role exists in seed

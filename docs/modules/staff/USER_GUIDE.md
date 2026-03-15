# Non-Teaching Staff — User Guide for School Administrators

Version: 1.0
Date: 2026-03-15

---

## 1. What Is Non-Teaching Staff?

Every school has two kinds of employees: teachers who deliver lessons, and everyone else who keeps the school running. That "everyone else" is what Vidyron calls **Non-Teaching Staff**.

This includes:

- Office staff — clerks, receptionists, the principal's secretary
- Finance staff — fee collectors, cashiers, accountants
- Library staff — librarians, library assistants
- Laboratory staff — lab assistants, science technicians
- General operations staff — security guards, peons, sweepers, gardeners

Unlike teachers who have class assignments, period timetables, and subject-specific attendance, non-teaching staff have a simpler daily workflow: they arrive, they work, they leave. Their HR needs — daily attendance, leave requests, documents, and pay — are managed entirely through this module.

---

## 2. Managing Staff Roles

Before you can add any staff member, you need to make sure the right **role** exists.

### What is a role?

A role describes what kind of work a staff member does. Vidyron comes with a set of **system roles** built into the platform. You can see them in the Roles section but you cannot change or delete them. These include roles like Librarian, Office Clerk, Lab Assistant, and Security Guard.

If your school uses a different title for the same function — for example, you call the fee clerk a "Finance Officer" — you can create a **custom role** with your preferred name.

### Viewing roles

Go to **Non-Teaching Staff** in the left navigation, then click the **Roles** tab. You will see a list of all roles available to your school — both the system-provided ones and any custom ones you have created.

Each role shows:
- The role name and category
- Whether it is a system role or a custom role
- How many staff members are currently assigned to it
- Whether it is active

### Creating a custom role

1. Click **Add Role**.
2. Enter a **Role Code** — this is a short identifier in capitals, such as `SENIOR_CLERK` or `HEAD_ACCOUNTANT`. Only uppercase letters and underscores are allowed.
3. Enter a **Display Name** — this is what appears in dropdowns and staff records, such as "Senior Clerk" or "Head Accountant".
4. Choose a **Category** from the five options (see Section 8 for what each category means).
5. Optionally add a description.
6. Click **Save**.

Once created, you can change the display name and description but not the code or category.

### Deactivating a custom role

If you no longer use a role, click the toggle button next to it. Inactive roles disappear from staff assignment dropdowns but existing staff who already have that role are not affected. You can re-activate a role at any time.

### Deleting a custom role

You can only delete a custom role if no staff members are currently assigned to it. If the role has staff, you must reassign those staff to a different role first.

System roles provided by the platform cannot be deactivated or deleted.

---

## 3. Adding Non-Teaching Staff

### Step-by-step

1. Go to **Non-Teaching Staff** and click **Add Staff Member**.

2. **Select a role** from the dropdown. All active roles for your school appear here, including system roles and your custom roles.

3. **Fill in the basic details:**
   - First name and last name (required)
   - Gender (required)
   - Email address (required — must be unique within your school)
   - Join date (required)
   - Employee type: Permanent, Contract, Part-Time, or Daily Wage

4. **Employee number** — you can let the system suggest one (click "Suggest"), or type your own. The system-generated format is `NTS-2026-001` (year and sequence). It must be unique within your school.

5. **Optional details:**
   - Date of birth, phone number
   - Department and designation (free text — e.g., "Administration", "Senior Clerk")
   - Brief qualification summary
   - Salary grade
   - Address, city, state
   - Blood group
   - Emergency contact name and phone

6. Click **Save**. The staff member's HR profile is created.

After creating the profile, you can optionally:
- Add detailed **qualification records** (degrees, institutions, year of passing)
- Upload **documents** (Aadhaar, PAN card, appointment letter, etc.)
- Create a **portal login** so they can log into the staff self-service portal

---

## 4. Staff Portal Login

Adding a staff member creates their HR profile, but it does not automatically give them a login to the Vidyron portal. Portal access is optional and must be explicitly set up.

### Why create a login?

Once a staff member has a login, they can:
- View their own attendance records
- Apply for leave themselves
- View leave history and summaries
- View their payslip (once the Payroll module is live)

If you do not create a login, the staff member is still tracked in attendance and leaves, but only the school admin can do those actions on their behalf.

### How to create a login

1. Open the staff member's profile.
2. Click **Create Portal Login**.
3. Enter a password for them (minimum 8 characters).
4. Click **Confirm**.

The login email is automatically the same as the staff member's email on file. They can then log in at `{yourschoolname}.vidyron.in` with their email and the password you set.

### Resetting a password

If a staff member forgets their password:
1. Open their profile.
2. Click **Reset Password**.
3. Enter a new password (minimum 8 characters).
4. Click **Confirm**.

There is a rate limit of 10 password operations per 15 minutes to prevent abuse.

---

## 5. Daily Attendance

Non-teaching staff attendance is marked once per day for each staff member. It is separate from the teacher period-wise attendance.

### Marking attendance

1. Go to **Non-Teaching Staff**, then click the **Attendance** tab.
2. Select the **date** for which you want to mark attendance.
3. Optionally filter by **Department** or **Category** to see a subset of staff.
4. For each staff member in the list, choose a status:
   - **Present** — staff was present for the full day
   - **Absent** — staff did not come in
   - **Half Day** — staff was present for roughly half the day
   - **On Leave** — staff is on approved leave
   - **Late** — staff arrived late
   - **Holiday** — the school was closed (public holiday, etc.)
5. You can optionally fill in check-in and check-out times (format HH:MM, 24-hour clock) and any remarks.
6. Click **Save All** to submit the entire list in one action.

If attendance has already been marked for some staff on that date, re-submitting will update their existing records — it will not create duplicates.

### Correcting attendance

Mistakes happen. To correct an individual attendance record:
1. Find the staff member's record in the attendance list for that date.
2. Click **Edit** on their row.
3. Change the status, times, or remarks.
4. Click **Save**.

Each correction is logged in the audit trail.

### Viewing attendance reports

Click **Attendance Report**, choose a month (YYYY-MM format), and optionally filter by staff member or department. The report shows:
- A school-wide summary count for each status type
- A per-staff breakdown with their individual counts for the month

---

## 6. Leave Management

### Viewing leave applications

Go to **Non-Teaching Staff**, then click the **Leaves** tab. You will see all leave applications across your non-teaching staff, with filters for status, staff member, leave type, and date range.

Leave statuses:
- **Pending** — submitted, waiting for review
- **Approved** — admin has approved
- **Rejected** — admin has rejected with a reason
- **Cancelled** — the leave was cancelled before it was reviewed

### Applying leave on behalf of a staff member

When a staff member cannot apply themselves (they do not have a portal login, or they are unwell and cannot log in):
1. Go to the staff member's profile.
2. Click the **Leaves** tab.
3. Click **Apply Leave**.
4. Choose the leave type, dates, and enter a reason (minimum 5 characters).
5. Click **Submit**.

Leave types available: Casual, Sick, Earned, Maternity, Paternity, Unpaid, Compensatory, Other.

Note: Backdating is allowed up to 7 calendar days. You cannot apply leave with a start date earlier than 7 days ago.

If the staff member already has a pending or approved leave that overlaps the dates you choose, the system will block the submission with an error.

### Approving a leave

1. Find the leave in the Leaves list (filter by `status = Pending` to see only pending ones).
2. Click **Review**.
3. Select **Approve**.
4. Click **Confirm**.

### Rejecting a leave

1. Click **Review** on the leave application.
2. Select **Reject**.
3. You must fill in the **Admin Remark** field explaining the reason for rejection. This is required when rejecting — you cannot reject without a note.
4. Click **Confirm**.

The staff member will see the rejection remark in their own portal.

### Cancelling a leave

Only **pending** leaves can be cancelled. Approved or rejected leaves cannot be undone through cancellation. To cancel a pending leave, open the leave application and click **Cancel**.

### Leave summary

To see how many days of each leave type a staff member has used, go to their profile, open the **Leaves** tab, and click **View Summary**. You can also filter by academic year (format `2025-2026`). Academic years run from April 1 to March 31.

---

## 7. Staff Self-Service

Once a staff member has a portal login, they can log in at `{yourschoolname}.vidyron.in` with their email and password.

What they can do after logging in:

- **View own attendance** — monthly attendance records showing their status for each day, check-in and check-out times.
- **Apply for leave** — fill in the leave form with type, dates, and reason. The same 7-day backdating limit applies.
- **Cancel own pending leaves** — if they applied by mistake, they can cancel before the admin reviews.
- **View leave history** — all their past and current leave applications with their statuses and admin remarks.
- **View leave summary** — how many days of each type they have taken.
- **View payslip** — placeholder screen; full payslip functionality will be available once the Payroll module is completed.

What they cannot do:
- View other staff members' records
- Mark their own attendance
- Approve or reject leaves

---

## 8. Role Categories and Portal Access

Every role belongs to one of five categories. The category determines which sections of the staff portal the staff member can access after logging in.

| Category | Examples | What They See in the Portal |
|----------|----------|----------------------------|
| ADMIN_SUPPORT | Office Clerk, Receptionist, Peon | Own profile, attendance, leaves, payslip (placeholder) |
| FINANCE | Fee Clerk, Cashier, Accountant | Own profile, attendance, leaves, payslip. Finance-related screens when the Fees module is integrated. |
| LIBRARY | Librarian, Library Assistant | Own profile, attendance, leaves, payslip. Library module screens when the Library module is integrated. |
| LABORATORY | Lab Assistant, Science Technician | Own profile, attendance, leaves, payslip. Lab module screens when available. |
| GENERAL | Security Guard, Sweeper, Gardener | Own profile, attendance, leaves, payslip. |

All categories currently see the same self-service features (profile, attendance, leaves). Category-specific access to module screens (Library, Finance, etc.) will activate as those modules are built.

---

## 9. Common Questions

**Can I delete a system role?**

No. System roles are provided by the platform and are shared across all schools. They cannot be deleted, deactivated, or renamed. If you need a different name for the same function, create a custom role in the same category.

**Can I change a role's category after creating it?**

No. The category is set at creation and cannot be changed. If you chose the wrong category, deactivate the incorrect role and create a new one with the right category.

**Can I reassign a staff member to a different role?**

Yes. Open the staff member's profile, click **Edit**, change the Role field, and save.

**What happens if I deactivate a staff member?**

Deactivating sets `is_active` to false. The staff member no longer appears in the active staff list and is hidden from the attendance marking screen. Their historical records (attendance, leaves, documents) are preserved. You can reactivate them at any time.

**What happens if I delete a staff member?**

Deleting performs a soft delete — the record is marked as deleted but not removed from the database. Deleted staff cannot be recovered through the UI. If you might need the staff member back later, consider deactivating instead of deleting.

**Can two staff members share the same email address?**

No. Each email address must be unique within your school. This is required because the email is also used as the login username if you create a portal login for the staff member.

**What does the employee number look like, and can I change it?**

The auto-generated format is `NTS-2026-001` — prefix NTS, the current year, and a three-digit sequence number counting staff added in that year. You can type your own employee number when creating a staff member, but it must be unique within your school and cannot be changed after creation.

**How do I handle a staff member who works in multiple departments?**

The `department` field is a free-text field — you can enter both departments, for example "Library / Administration". The system does not enforce a single department. For attendance and leave purposes, the staff member is tracked as a single individual regardless of department.

**Can a staff member see other people's attendance?**

No. The staff portal is strictly self-service. A logged-in staff member can only view their own records.

**The attendance report shows a staff member with zero records. Is something wrong?**

If a staff member has no attendance records for a month, it means attendance was never submitted for them during that period — they are neither marked present nor absent. This is not an error; it means that day's submission was not done. Use the daily attendance screen to backfill any missing days.

**What is the payslip screen?**

The payslip screen in the staff portal is currently a placeholder. It will show actual payslip data once the HR/Payroll module is built and integrated. Until then, it displays a "coming soon" message.

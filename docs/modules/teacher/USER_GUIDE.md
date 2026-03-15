# Teacher/Staff Module — User Guide

This guide is for School Administrators using the Vidyron School ERP portal at `{yourschool}.vidyron.in`.

---

## Table of Contents

1. Managing Staff
2. Staff Profiles
3. Qualifications
4. Documents
5. Subject Assignments
6. Viewing a Teacher's Timetable
7. Leave Management
8. Applying Leave on Behalf of a Staff Member
9. Reading the Leave Summary

---

## 1. Managing Staff

### Accessing the Staff Directory

From the School Admin sidebar, click "Teachers & Staff." The Staff Directory screen shows a table listing all active staff members with their employee number, name, designation, email address, and current status.

The table displays 20 records per page. Use the pagination arrows at the bottom to move between pages.

### Searching for a Staff Member

Type any part of the staff member's name, email address, or employee number into the search box at the top left. The list updates automatically as you type.

### Filtering the Staff List

Two dropdowns sit beside the search box:

- The "Role" dropdown filters by designation (Teacher, Clerk, Librarian, Principal, and so on). Select a role to show only staff members with that designation. Select "All Roles" to clear the filter.
- The "Status" dropdown filters by active or inactive status. Select "Active" to show only staff currently at work, "Inactive" to see deactivated records, or "All" to see everyone.

Both filters can be applied at the same time alongside a search term.

### Adding a New Staff Member

Click the green "Add Staff" button in the top right corner of the Staff Directory screen. A dialog opens with the following fields:

- First Name and Last Name (required)
- Employee Number (auto-suggested from the name; you can edit it; availability is checked in real time with a green tick or red cross)
- Email address (required)
- Phone number (required; must be at least 10 digits)
- Qualification (optional; a brief summary such as "B.Ed, M.Sc")
- Gender (dropdown)
- Designation (dropdown — select the staff member's role)
- Active status (toggle)
- Create login account (toggle) — when switched on, an additional password field appears; fill this in to give the staff member portal access from day one

Click "Add" to save. A success message confirms the record was created.

### Editing a Staff Member

In the staff table, click the three-dot menu at the end of any row and select "Edit." The same dialog opens, pre-filled with the staff member's current details. Make your changes and click "Update."

For more complete editing (including address, emergency contact, department, salary grade, and other extended fields), use the full edit form by navigating to the staff member's detail page and clicking "Edit" from there.

### Viewing a Staff Member's Full Profile

Click the staff member's name in the table (it appears as a green link) or select "View" from the three-dot menu. This opens the Staff Detail screen, described in the next section.

### Deactivating (Removing) a Staff Member

Select "Delete" from the three-dot menu. A confirmation dialog asks you to confirm. Once confirmed, the staff member is marked as inactive. Their record is preserved in the system — historical attendance, leave records, and subject assignments remain intact.

If the staff member is currently assigned as a class teacher for any section, the system will block the deletion and ask you to reassign the class teacher first.

---

## 2. Staff Profiles

Clicking on a staff member's name opens the Staff Detail screen. This screen has six tabs: Overview, Qualifications, Documents, Subjects, Timetable, and Leaves.

### Overview Tab

The Overview tab shows:

- The staff member's photo (if uploaded), full name, employee number, and status badge (Active / Inactive)
- Employment details: designation, department, employee type (Permanent, Contractual, Part-Time, or Probation), join date, and years of service
- A leave summary card showing total approved leave days taken in the current academic year and any currently pending requests
- A subjects count showing how many subject assignments the teacher has

An "Edit" button at the top right opens the full edit form.

### Full Edit Form (4 tabs)

The full Staff Edit Form is organized into four tabs so you can navigate to the section you need without scrolling through a long page.

**Personal Tab**
- First name, last name, gender
- Date of birth (date picker)
- Blood group (dropdown: A+, A-, B+, B-, O+, O-, AB+, AB-)

**Employment Tab**
- Employee number
- Designation
- Department (e.g., Science, Languages, Administration)
- Employee type (Permanent, Contract, Part-Time, Visiting)
- Join date (date picker)
- Salary grade (a reference code used by the future Payroll module)
- Years of prior experience before joining

**Contact Tab**
- Phone number (required)
- Email address
- Residential address, city, state
- Emergency contact name and phone number

**Login Tab**
- Username (leave blank to keep existing credentials)
- Password (leave blank to keep existing password; minimum 8 characters if entered)
- Role (Teacher or Staff)

Use the "Next" and "Back" buttons to move between tabs. Click "Save Staff" (or "Update") on the final tab to save all changes at once. If any required field is missing on any tab, an error message will tell you which tab needs attention.

---

## 3. Qualifications

The Qualifications tab on the Staff Detail screen shows a list of all academic and professional credentials on record for the staff member.

### Reading the Qualifications List

Each qualification shows:

- The degree name (e.g., "M.Sc Physics", "B.Ed")
- The institution where it was obtained
- The year of passing
- The grade or percentage achieved
- A "Highest" badge if this qualification is marked as the staff member's highest academic achievement

### Adding a Qualification

Click the "Add Qualification" button on the Qualifications tab. A panel slides up from the bottom of the screen with the following fields:

- Degree (required — e.g., "B.Ed", "M.Sc Mathematics")
- Institution (required — university or college name)
- Board or University (optional — used for school-level certificates)
- Year of Passing (number)
- Grade or Percentage (e.g., "First Class", "78.5%")
- Mark as Highest Qualification (toggle)

Turning on "Mark as Highest" will automatically remove the "Highest" badge from whichever qualification was previously marked as highest. Only one qualification can hold this designation at a time.

Click "Save" to add the qualification.

### Editing a Qualification

Click the edit icon next to any qualification in the list. The same panel opens pre-filled with the existing data. Make your changes and save.

### Deleting a Qualification

Click the delete icon next to a qualification and confirm. The deletion is permanent — the record cannot be recovered.

---

## 4. Documents

The Documents tab provides a digital document store for the staff member's HR documents.

### Reading the Documents List

Each document card shows:

- An icon indicating the file type (PDF icon for PDFs, image icon for photos)
- The document type label (Aadhaar, PAN, Degree Certificate, Experience Letter, Address Proof, Photo, or Other)
- The document name
- File size in kilobytes
- A green "Verified" badge if a school admin has confirmed the document's authenticity

### Adding a Document

Click "Add Document" on the Documents tab. Fill in:

- Document Type (dropdown — select the appropriate category)
- Document Name (a descriptive label, e.g., "Aadhaar Card", "PAN Card")
- File URL (the HTTPS link to the file stored in cloud storage; use your school's file upload workflow to get this URL)
- File Size (optional)
- MIME Type (optional — e.g., `application/pdf`)

If a document of the same type already exists (for example, if a new Aadhaar is being uploaded to replace an old one), the existing document is automatically archived when the new one is saved. Only the latest document of each type is shown.

### Verifying a Document

Once you have reviewed a physical or digital copy of a document, click "Verify" on the document card. A green "Verified" badge appears on the card, and the verification timestamp is recorded along with your user ID. Only school admins can verify documents.

### Deleting a Document

Click the delete icon on a document card and confirm. The record is soft-deleted — the file in cloud storage is not removed, but the document no longer appears in the list.

---

## 5. Subject Assignments

The Subjects tab shows which subjects a teacher is assigned to teach, and in which class-section and academic year.

### Reading the Assignments Table

The table shows: Class, Section, Subject, Academic Year, and a Remove action. A section value of "All Sections" means the assignment applies to every section of that class.

### Assigning a Subject

Click "Assign Subject" on the Subjects tab. Fill in:

- Class (dropdown — the class this applies to)
- Section (optional — leave blank to apply to all sections)
- Subject (text — type the subject name)
- Academic Year (e.g., `2025-26`)

The system checks that no other active teacher is already assigned to teach the same subject in the same class and section for the same academic year. If a conflict is found, an error message identifies the clash and the assignment is not saved.

### Removing an Assignment

Click the remove icon in the Subject Assignments table and confirm. The assignment is deleted immediately. It will also no longer appear in the teacher's timetable view.

---

## 6. Viewing a Teacher's Timetable

The Timetable tab on the Staff Detail screen shows a read-only weekly schedule for the teacher.

The grid is organized with days of the week (Monday through Saturday) across the top and period slots down the rows. Each cell in the grid shows:

- The subject being taught
- The class and section (e.g., Class 9-A)
- The room or lab (if specified)
- The start and end time of the period

Empty cells (periods when the teacher has no class) show a dash.

The timetable is populated by the Timetable module. To change a teacher's schedule, go to the Timetable section of the School Admin portal.

---

## 7. Leave Management

The Leave Management screen is separate from the Staff Detail screen. Access it from the sidebar by clicking "Leave Management."

The screen has three tabs.

### Pending Tab

The Pending tab shows all leave requests that are waiting for your decision. Each request card displays:

- The staff member's name
- The leave type (Casual, Sick, Earned, Maternity, Paternity, Unpaid, or Other)
- The date range and total number of days
- The staff member's stated reason

Two buttons sit at the bottom of each card: "Approve" and "Reject."

**Approving a Request**

Click "Approve." The leave status changes to Approved immediately. You can optionally add a remark (for example, "Approved. Please arrange a substitute.") before confirming.

**Rejecting a Request**

Click "Reject." A panel slides up asking for a reason. The rejection reason is required when declining a request — it is recorded in the system and visible to the staff member when they view their leave history. Type the reason and click "Confirm Rejection."

After approval or rejection, the card disappears from the Pending tab and moves to the All Requests tab.

### All Requests Tab

The All Requests tab shows every leave request in the system for your school, across all staff and all statuses.

Two filter bars appear at the top:

- Status filter: All, Pending, Approved, Rejected, Cancelled (tap to select; only one status at a time)
- Leave Type filter: All, Casual, Sick, Earned, Maternity, Paternity, Unpaid, Other

The list updates immediately when you tap a filter. Pull down to refresh the list manually.

Each request in this tab is shown as a compact card with the staff name, leave type, date range, number of days, and status badge.

### Summary Tab

The Summary tab gives you a high-level overview of leave statistics for the school.

The top section shows five stat cards:

- Total: total number of leave applications submitted
- Pending: requests not yet reviewed
- Approved: approved requests
- Rejected: rejected requests
- Cancelled: cancelled requests

Below the stat cards, a breakdown by leave type lists each category (Casual, Sick, Earned, and so on) with the number of applications in that category.

Pull down to refresh the summary.

---

## 8. Applying Leave on Behalf of a Staff Member

School admins can submit a leave request on behalf of any staff member — for example, if a staff member is unable to access the portal due to absence or a technical issue.

### How to Apply

1. Navigate to the Staff Detail screen for the relevant staff member.
2. Click the "Leaves" tab.
3. Click "Apply Leave."

You can also navigate directly from the sidebar by going to Leave Management, clicking the Pending tab, and selecting a staff member from the list.

The Apply Leave screen shows:

- An info notice confirming you are submitting on behalf of the staff member
- Leave Type dropdown
- From Date date picker (the calendar opens to today; any date can be selected when applying as admin)
- To Date date picker (must be on or after the From Date; the calendar minimum is set to the From Date automatically)
- A "Total days" indicator that updates automatically as you pick dates
- Reason text box (required; minimum 10 characters)

Click "Submit Leave Request" when done. A success message confirms submission and you are returned to the staff member's leave history.

If the selected date range overlaps with a leave request that is already pending or approved for this staff member, the system will reject the submission and display an error message. Review the existing requests before retrying.

---

## 9. Reading the Leave Summary

The Summary tab on the Leave Management screen (described in section 7 above) gives school-wide statistics. To view the leave summary for a specific staff member, go to that staff member's detail page and open the Leaves tab. The top of the Leaves tab shows a summary card for that individual, including:

- Total approved leave days in the current academic year
- Number of currently pending requests

The academic year for summary calculations runs from April 1 of the current calendar year to March 31 of the next calendar year, following the Indian school year convention.

Cancelled and rejected leave requests do not count toward the approved leave days total.

---

## Common Questions

**Can I recover a deleted staff member?**

Staff records are soft-deleted, meaning they are deactivated rather than permanently removed. Contact your platform administrator if you need to reactivate a staff member who was accidentally deactivated.

**Why can't I delete a staff member?**

If you see an error when trying to delete, the staff member is currently assigned as the class teacher for one or more sections. Go to the Classes section, reassign or remove the class teacher for those sections, then try deleting again.

**Why can't I approve a leave that was already approved?**

Only leaves in Pending status can be approved or rejected. If a mistake was made on an already-approved leave, reject it using the standard workflow is not possible — you will need to add a new leave record if a correction is required.

**Can a staff member apply for leave with dates in the past?**

Staff members applying leave themselves must select today's date or a future date. School admins applying leave on behalf of a staff member have no date restriction and can select past dates.

**Why is the Verify button missing on a document?**

The Verify button is only shown to school admin users. If you are logged in as a different role, you will see the document but not the verification option.

**What happens when I upload a second Aadhaar card?**

The system automatically archives the previous Aadhaar document when a new one is uploaded. Only the most recent document of each type appears in the list.

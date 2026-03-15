# Super Admin Gap Analysis Report

**Reference:** `E:\School_ERP_Documents\clude\vidyron-super-admin-complete.html`  
**Current:** `erp-new-logic` Flutter + backend codebase  
**Date:** March 8, 2026

---

## Executive Summary

This document compares the complete HTML reference (Vidyron Super Admin) with the current development to identify missing features, columns, models, and screens. **Theme is not changed** — only functional and structural gaps are listed.

---

## 1. Navigation & Top Bar

| HTML Reference | Current Dev | Status |
|----------------|-------------|--------|
| Top bar tabs: Dashboard, Schools, Groups, Plans, Billing, Audit Logs | Implemented in Super Admin top bar | ✅ |
| Live indicator badge | Not present | ❌ Missing |
| Notification bell with unread dot | Present | ✅ |
| Avatar badge | Present | ✅ |

---

## 2. Schools Table — Columns & Filters

### HTML Reference Columns

| Column | HTML | Current Dev | Status |
|--------|------|-------------|--------|
| School | Name + Board · Type (e.g. CBSE · Private) | Name only | ⚠️ Missing Board + Type |
| Code | Code (e.g. DPS-SRT-001) | ✅ Code | ✅ |
| City | City, State (e.g. Surat, GJ) | Not in table | ❌ Missing |
| Students | Student count | Not in table | ❌ Missing |
| Plan | Plan badge | ✅ Plan | ✅ |
| Status | Status badge | ✅ Status | ✅ |
| Expiry | Expiry date (e.g. 31 Dec 2026) | Not in table | ❌ Missing |
| Subdomain | Subdomain (e.g. dpssurat.vidyron.in) | Not in table | ❌ Missing |
| Actions | ⚙️ Manage, 📦 Plan, 🔗 Copy | ✅ Manage, Plan, Copy URL | ✅ |

### Schools Filters

| Filter | HTML | Current Dev | Status |
|--------|------|-------------|--------|
| Search | Search school, code, city | Search schools | ⚠️ Partial (city not searchable) |
| Plan filter | All Plans dropdown | ✅ Plan dropdown | ✅ |
| Status filter | All Status dropdown | ✅ Status chips | ✅ |
| Page tabs | All (127), Active (118), Trial (9), Suspended (1), Expiring (3) | Filter chips | ✅ |

---

## 3. Groups Screen

| Feature | HTML | Current Dev | Status |
|---------|------|-------------|--------|
| Group cards | Expandable cards with schools, stats | Present | ✅ |
| Group stats | Schools count, Students, MRR | Present | ✅ |
| Add School to Group | Modal | Present | ✅ |
| Create Group | Modal | Present | ✅ |
| Standalone School | Button | Present | ✅ |
| Group Report | Button | Present | ⚠️ Verify |
| Group Settings | Modal | Present | ⚠️ Verify |
| Group type | Private Chain, Educational Trust, etc. | Present | ✅ |
| Group subdomain | Present | Present | ✅ |

---

## 4. Plans & Pricing Screen

### Plan Cards

| Field | HTML | Current Dev | Status |
|-------|------|-------------|--------|
| Plan name | ✅ | ✅ | ✅ |
| Price per student | ₹25/35/45 per student/mo | ✅ | ✅ |
| Description | ✅ | Present | ✅ |
| Features list | ✅ | Present | ✅ |
| Schools count | ✅ | ✅ | ✅ |
| MRR | ✅ | ✅ | ✅ |
| Edit | ✏️ | Present | ✅ |
| Deactivate | ⏸ | Present | ✅ |
| Status badge | Active/Inactive | Present | ✅ |

### Plan Change Log Table

| Column | HTML | Current Dev | Status |
|--------|------|-------------|--------|
| Date | ✅ | ✅ | ✅ |
| School | ✅ | ✅ | ✅ |
| From | Plan badge | ✅ | ✅ |
| To | Plan badge | ✅ | ✅ |
| Changed By | ✅ | actorName | ✅ |
| Reason | ✅ | description | ✅ |

---

## 5. Billing Screen

### HTML Reference Columns

| Column | HTML | Current Dev | Status |
|--------|------|-------------|--------|
| School | ✅ | ✅ | ✅ |
| Plan | ✅ | ✅ | ✅ |
| Students | ✅ | ✅ | ✅ |
| Monthly | ✅ | ✅ | ✅ |
| Next Renewal | ✅ | ✅ | ✅ |
| Status | ✅ | ✅ | ✅ |
| Actions | Edit Plan, Renew, Resolve | ✅ | ✅ |

### Billing Stats

| Stat | HTML | Current Dev | Status |
|------|------|-------------|--------|
| This Month MRR | ₹38.2L | Dashboard only | ⚠️ Billing screen stats |
| ARR | ₹4.58Cr | Not present | ❌ Missing |
| Expiring in 30 days | 9 | Filter only | ⚠️ Missing stat card |
| Overdue / Suspended | 1 | Filter only | ⚠️ Missing stat card |

### Billing Table

| Feature | HTML | Current Dev | Status |
|---------|------|-------------|--------|
| Table layout | Full table | Card list | ⚠️ Different layout |
| Search | ✅ | ✅ | ✅ |
| Export CSV | ✅ | ✅ | ✅ |

---

## 6. Feature Flags Screen

### Platform-Wide Features (HTML)

| Feature | HTML | Current Dev | Status |
|---------|------|-------------|--------|
| RFID Attendance Engine | ✅ | ✅ | ✅ |
| GPS Transport Engine | ✅ | ✅ | ✅ |
| AI Intelligence Engine | ✅ | ✅ | ✅ |
| Parent Mobile App | ✅ | ✅ | ✅ |
| Chat System | ✅ | ✅ | ✅ |
| Online Payments | ✅ | ✅ | ✅ |
| Biometric Module | ✅ | ✅ | ✅ |
| Certificate Generator | ✅ | ✅ | ✅ |

### System & Maintenance (HTML)

| Feature | HTML | Current Dev | Status |
|---------|------|-------------|--------|
| Maintenance Mode | ✅ | Verify | ⚠️ |
| New Registrations | ✅ | Verify | ⚠️ |
| Email Notifications | ✅ | Verify | ⚠️ |
| SMS Gateway | ✅ | Verify | ⚠️ |
| Push Notifications | ✅ | Verify | ⚠️ |
| AI Auto-Alerts | ✅ | Verify | ⚠️ |

### Export State

| Feature | HTML | Current Dev | Status |
|---------|------|-------------|--------|
| Export State button | ✅ | Verify | ⚠️ |

---

## 7. Hardware Screen

### HTML Reference Columns

| Column | HTML | Current Dev | Status |
|--------|------|-------------|--------|
| Device ID | ✅ | deviceId | ✅ |
| Type | RFID Reader, GPS Unit, Biometric | deviceType | ✅ |
| School | ✅ | schoolName | ✅ |
| Location | ✅ | locationLabel | ✅ |
| Status | Online/Offline | status | ✅ |
| Last Ping | Time ago | lastPingAt | ✅ |
| Actions | Config, Ping, Track, Alert School | Verify | ⚠️ |

### Hardware Stats

| Stat | HTML | Current Dev | Status |
|------|------|-------------|--------|
| RFID Readers | 847 | Verify | ⚠️ |
| GPS Units | 234 | Verify | ⚠️ |
| Biometric Units | 56 | Verify | ⚠️ |
| Offline / Issues | 35 | Verify | ⚠️ |

### Add Hardware Modal

| Field | HTML | Current Dev | Status |
|-------|------|-------------|--------|
| Device Type | RFID/GPS/Biometric | Verify | ⚠️ |
| Device ID / Serial | ✅ | Verify | ⚠️ |
| Assign to School | ✅ | Verify | ⚠️ |
| Location / Description | ✅ | Verify | ⚠️ |
| Firmware Version | ✅ | Verify | ⚠️ |

---

## 8. Admin Users Screen

### HTML Reference

| Feature | HTML | Current Dev | Status |
|---------|------|-------------|--------|
| Active Super Admins list | ✅ | Present | ✅ |
| Avatar, Name, Email | ✅ | Present | ✅ |
| Role badge | Owner, Tech Admin, Ops Admin | Present | ✅ |
| Last login | ✅ | Verify | ⚠️ |
| Edit / Remove | ✅ | Present | ✅ |
| Access Permissions | Owner, Tech Admin, Ops Admin, Support Admin | Verify | ⚠️ |
| Add Admin | Modal | Present | ✅ |
| Add Admin fields | Name, Email, Mobile, Role, Temp Password | Verify | ⚠️ |

---

## 9. Audit Logs Screen

### HTML Reference Columns

| Column | HTML | Current Dev | Status |
|--------|------|-------------|--------|
| Time | ✅ | createdAt | ✅ |
| Actor | Avatar + Name | actorName | ⚠️ Avatar missing |
| Action | Tag (e.g. 🏫 School Created) | action | ✅ |
| Entity | Entity name | entityName | ✅ |
| Details | Description | description | ✅ |
| IP | IP address | actorIp | ✅ |
| Status | Success, Warning, Blocked | status | ✅ |

### Filters

| Filter | HTML | Current Dev | Status |
|--------|------|-------------|--------|
| Search | Search actions | Present | ✅ |
| Action type | All Actions, School Created, Plan Changed, etc. | Present | ✅ |
| Export | ✅ | Present | ✅ |

---

## 10. Security Screen

### HTML Reference

| Feature | HTML | Current Dev | Status |
|---------|------|-------------|--------|
| Active Threats | 0 | Verify | ⚠️ |
| Failed Logins (24h) | 2 | Verify | ⚠️ |
| Trusted Devices | 3 | Verify | ⚠️ |
| 2FA Status | ON | Verify | ⚠️ |
| Recent Security Events | List with Block IP | Verify | ⚠️ |
| Trusted Devices list | Revoke | Verify | ⚠️ |
| 2FA Settings | Change | Verify | ⚠️ |
| Export Report | ✅ | Verify | ⚠️ |

---

## 11. Infra Status Screen

### HTML Reference

| Feature | HTML | Current Dev | Status |
|---------|------|-------------|--------|
| Uptime (30 days) | 99.97% | Present | ✅ |
| Avg Response Time | 42ms | Present | ✅ |
| Active Connections | 1,847 | Present | ✅ |
| Storage Used | 67% | Present | ✅ |
| Service Health | API, DB, GPS, SMS, S3, FCM | Present | ✅ |
| 30-Day Uptime bars | Per service | Verify | ⚠️ |
| All Systems Operational badge | ✅ | Present | ✅ |

---

## 12. Dashboard

### Stats Cards

| Stat | HTML | Current Dev | Status |
|------|------|-------------|--------|
| Total Schools | 127 | ✅ | ✅ |
| Students on Platform | 1.84L | ✅ | ✅ |
| Monthly Revenue | ₹38.2L | ✅ | ✅ |
| School Groups | 14 | ✅ | ✅ |

### Dashboard Sections

| Section | HTML | Current Dev | Status |
|---------|------|-------------|--------|
| Recently Added | Schools list | ✅ | ✅ |
| Plan Distribution | Bar chart | ✅ | ✅ |
| Active / Expiring Soon | Counts | ✅ | ✅ |
| Needs Attention | Alerts | ✅ | ✅ |
| Export Report | ✅ | ✅ | ✅ |

---

## 13. Add School Modal (Multi-Step)

### HTML Steps

| Step | HTML | Current Dev | Status |
|------|------|-------------|--------|
| 1. Group? | Standalone or Group | Verify | ⚠️ |
| 2. School Info | Name, Code, Subdomain, Board, Type, City, State, Phone | Present | ✅ |
| 3. Plan | Basic, Standard, Premium | Present | ✅ |
| 4. Admin Login | Name, Email, Mobile, Temp Password | Present | ✅ |
| 5. Features | Toggles | Present | ✅ |
| Est. Students | ✅ | Verify | ⚠️ |
| Student Limit | ✅ | Verify | ⚠️ |
| Duration | 1 Year, 6 Months, 3 Months (Trial) | Verify | ⚠️ |

---

## 14. School Detail Modal

### Tabs

| Tab | HTML | Current Dev | Status |
|-----|------|-------------|--------|
| Info | School info | ✅ | ✅ |
| Plan & Billing | Plan, Student Limit, Renewal, Monthly Bill | ✅ | ✅ |
| Features | Toggles | ✅ | ✅ |
| Admin Login | Admins, Reset Password, Add Admin | ✅ | ✅ |
| Subdomain | Subdomain, Staff Login Link | ✅ | ✅ |
| Suspend School | ✅ | ✅ | ✅ |

---

## 15. Model & Column Gaps

### SuperAdminSchoolModel

| Field | HTML | Present in Model | Status |
|-------|------|------------------|--------|
| board | Board (CBSE, ICSE, etc.) | ✅ | ✅ |
| schoolType | Type (Private, Trust, etc.) | ✅ | ✅ |
| city | City | ✅ | ✅ |
| state | State | ✅ | ✅ |
| subdomain | Subdomain | ✅ | ✅ |
| studentCount | Students | ✅ | ✅ |
| subscriptionEnd | Expiry | ✅ | ✅ |

---

## 16. Priority Summary

### High Priority (Missing Columns)

1. ~~**Schools table:** Add City, Students, Expiry, Subdomain columns~~ ✅ Done
2. ~~**Schools table:** Show Board · Type in School cell~~ ✅ Done
3. ~~**Billing:** Add MRR, ARR, Expiring, Overdue stat cards~~ ✅ Done
4. ~~**Billing:** Consider table layout for consistency~~ ✅ Done

### Medium Priority

5. ~~**Feature Flags:** Verify all platform-wide and system toggles~~ ✅ Done
6. ~~**Hardware:** Verify stats, actions (Config, Ping, Track, Alert School)~~ ✅ Done
7. ~~**Admin Users:** Access Permissions section~~ ✅ Done
8. ~~**Audit Logs:** Actor avatar display~~ ✅ Done

### Lower Priority

9. ~~Top bar tabs (optional, sidebar may suffice)~~ ✅ Done
10. Live indicator badge
11. Notifications modal (vs dedicated screen)

---

## 17. Files to Update

| File | Changes |
|------|---------|
| `super_admin_schools_screen.dart` | Add City, Students, Expiry, Subdomain columns; Board + Type in School cell |
| `super_admin_billing_screen.dart` | Add stat cards; optional table layout |
| `super_admin_features_screen.dart` | Verify all toggles |
| `super_admin_hardware_screen.dart` | Verify columns, stats, actions |
| `super_admin_admins_screen.dart` | Verify Access Permissions |
| `super_admin_audit_logs_screen.dart` | Add actor avatar |
| Backend models | Ensure all fields returned by API |

---

*End of Gap Analysis*

# Super Admin Migration

## File: `super_admin_complete_20260307.sql`

### Purpose
Adds Super Admin schema: school groups, platform features, super_admins, school_admins, plan features, billing, audit tables, hardware devices.

### Rules Applied
- **Only ADD** — no DROP or TRUNCATE
- Uses `IF NOT EXISTS` / `IF EXISTS` guards
- Compatible with existing `platform` schema (BIGINT PKs)

### Schema Assumptions
- `platform.schools` (school_id BIGINT)
- `platform.users` (user_id BIGINT)
- `platform.platform_plans` (plan_id BIGINT)

### Tables Created/Updated

| Table | Action |
|-------|--------|
| platform.schools | ADD COLUMN: group_id, student_limit, overdue_days, pin_code, school_type, established_year, deleted_at, created_by, status |
| platform.school_features | CREATE (or add feature_key, updated_by, updated_at if exists) |
| platform.billing | CREATE |
| platform.audit_logs | CREATE |
| platform.plan_features | CREATE |
| platform.school_groups | CREATE |
| platform.platform_features | CREATE |
| platform.super_admins | CREATE |
| platform.school_admins | CREATE |
| platform.plan_change_log | CREATE |
| platform.hardware_devices | CREATE |
| platform.audit_school_logs | CREATE |
| platform.audit_plan_logs | CREATE |
| platform.audit_billing_logs | CREATE |
| platform.audit_feature_logs | CREATE |
| platform.audit_security_logs | CREATE |
| platform.audit_hardware_logs | CREATE |
| platform.audit_group_logs | CREATE |
| platform.audit_super_admin_logs | CREATE |

### Run Command
```bash
psql -U school_erp_owner -d school_erp_saas -f database/migrations/super_admin_complete_20260307.sql
```

### If Using `public` Schema
Replace `platform.` with `public.` or adjust `search_path` in the script.

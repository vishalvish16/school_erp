# Smart Login Migration — How to Run

## Why you see no changes

1. **Database**: The migration SQL file must be **run manually** against your PostgreSQL database.
2. **UI**: The device verification screen only appears when the API returns `requires_otp: true`, which requires the new tables to exist.

## Step 1: Run the migration

Use the migration that matches your database schema:

### Option A: Public schema (Prisma default)

If your database was created by Prisma migrations:

```bash
# Replace with your actual DB name (school_erp or school_erp_saas) and credentials
psql -U postgres -d school_erp -f database/migrations/add_smart_login_public.sql
```

Or from the project root:

```powershell
cd e:\School_ERP_AI\erp-new-logic
$env:PGPASSWORD="your_password"; psql -U postgres -h localhost -d school_erp -f database/migrations/add_smart_login_public.sql
```

### Option B: Platform schema (raw SQL setup)

If you used the database/*.sql files (00_bootstrap, 03_platform_schools, etc.):

```bash
psql -U school_erp_owner -d school_erp_saas -f database/migrations/add_smart_login_20260307.sql
```

## Step 2: Restart the backend

After the migration succeeds, restart your Node.js backend so it picks up the new tables.

## Step 3: Test the flow

1. Open the app and go to the login screen.
2. Enter your email and password.
3. On first login from a new device, you should see the **Device Verification** screen with OTP input.
4. Enter the 6-digit OTP (check backend console for `[DEV] OTP for...` during development).
5. Toggle "Remember this device" and verify — next login from the same device should skip OTP.

## Verify migration

After running, check that these tables exist:

```sql
\dt registered_devices
\dt auth_sessions
\dt otp_verifications
\dt rate_limit_tracking
\dt login_attempts
```

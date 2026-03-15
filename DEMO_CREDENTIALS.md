# Demo Login Credentials

All demo accounts use the same password: **School@12345**

## Staff Portal Login

Use these credentials with the Staff portal. You may need to provide **school_id** or **subdomain** depending on your app configuration.

| Role | Email | Password |
|------|-------|----------|
| School Admin | admin@gmail.com | School@12345 |
| Teacher | teacher@gmail.com | School@12345 |
| Clerk | clerk@gmail.com | School@12345 |
| Accountant | accountant@gmail.com | School@12345 |
| Librarian | librarian@gmail.com | School@12345 |
| Lab Assistant | labassistant@gmail.com | School@12345 |
| Security Guard | security@gmail.com | School@12345 |
| Receptionist | receptionist@gmail.com | School@12345 |
| Cashier | cashier@gmail.com | School@12345 |

**School code:** 101  
**Subdomain:** (none)

---

To re-seed or add more demo staff, run:
```bash
cd backend && node prisma/seed-staff-credentials.js
```

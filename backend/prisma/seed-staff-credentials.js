/**
 * Seed teacher and staff login credentials for demo/testing.
 * Run: node prisma/seed-staff-credentials.js
 *
 * Creates demo users with password: School@12345
 * - School Admin
 * - Teacher (Teaching Staff)
 * - Non-Teaching Staff: Clerk, Accountant, Librarian, Lab Assistant,
 *   Security, Receptionist, Cashier
 */
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

const DEMO_PASSWORD = 'School@12345';

// Non-teaching roles to seed (code, displayName, employeeNoPrefix)
const NON_TEACHING_ROLES = [
    { code: 'CLERK', displayName: 'Clerk', prefix: 'CLK' },
    { code: 'ACCOUNTANT', displayName: 'Accountant', prefix: 'ACC' },
    { code: 'LIBRARIAN', displayName: 'Librarian', prefix: 'LIB' },
    { code: 'LAB_ASSISTANT', displayName: 'Lab Assistant', prefix: 'LAB' },
    { code: 'SECURITY', displayName: 'Security Guard', prefix: 'SEC' },
    { code: 'RECEPTIONIST', displayName: 'Receptionist', prefix: 'REC' },
    { code: 'CASHIER', displayName: 'Cashier', prefix: 'CSH' },
];

async function ensureRole(name, scope = 'SCHOOL') {
    let role = await prisma.role.findFirst({ where: { name } });
    if (!role) {
        role = await prisma.role.create({
            data: { name, scope, description: `${name} role for school portal` },
        });
        console.log(`  Created role: ${name}`);
    }
    return role;
}

async function getOrCreateNTRole(code, schoolId) {
    // Prefer system role (schoolId=null) or school-specific
    let ntRole = await prisma.nonTeachingStaffRole.findFirst({
        where: { code },
    });
    if (!ntRole) {
        const categoryMap = {
            CLERK: 'FINANCE', ACCOUNTANT: 'FINANCE', CASHIER: 'FINANCE',
            LIBRARIAN: 'LIBRARY', LAB_ASSISTANT: 'LABORATORY',
            SECURITY: 'ADMIN_SUPPORT', RECEPTIONIST: 'ADMIN_SUPPORT',
        };
        ntRole = await prisma.nonTeachingStaffRole.create({
            data: {
                schoolId,
                code,
                displayName: code.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, c => c.toUpperCase()),
                category: categoryMap[code] || 'GENERAL',
                isSystem: true,
                description: `${code} role`,
            },
        });
        console.log(`  Created non-teaching role: ${code}`);
    }
    return ntRole;
}

async function ensureNonTeachingStaff(school, staffRole, { code, displayName, prefix }) {
    const domain = school.email?.split('@')[1] || 'demoschool.in';
    const email = `${code.toLowerCase().replace(/_/g, '')}@${domain}`;
    const ntRole = await getOrCreateNTRole(code, school.id);
    const existing = await prisma.nonTeachingStaff.findFirst({
        where: { schoolId: school.id, email },
    });
    if (existing) {
        return { email, displayName, created: false };
    }
    const passwordHash = await bcrypt.hash(DEMO_PASSWORD, 12);
    const user = await prisma.user.create({
        data: {
            email,
            passwordHash,
            schoolId: school.id,
            firstName: 'Demo',
            lastName: displayName,
            phone: school.phone,
            roleId: staffRole.id,
            isActive: true,
        },
    });
    await prisma.nonTeachingStaff.create({
        data: {
            schoolId: school.id,
            userId: user.id,
            roleId: ntRole.id,
            employeeNo: `${school.code}-${prefix}-001`,
            firstName: 'Demo',
            lastName: displayName,
            gender: 'MALE',
            email,
            designation: displayName,
            joinDate: new Date(),
            phone: school.phone,
            isActive: true,
        },
    });
    return { email, displayName, created: true };
}

async function main() {
    console.log('Seeding teacher and staff credentials...\n');

    const passwordHash = await bcrypt.hash(DEMO_PASSWORD, 12);

    // 1. Ensure school-level roles exist
    const schoolAdminRole = await ensureRole('school_admin');
    const teacherRole = await ensureRole('teacher');
    const staffRole = await ensureRole('staff');
    await ensureRole('STUDENT', 'SCHOOL'); // Student portal user

    // 2. Get first school
    const school = await prisma.school.findFirst({
        where: { status: 'ACTIVE' },
        orderBy: { createdAt: 'asc' },
    });

    if (!school) {
        console.log('  No school found. Run seed-schools.js or create a school first.');
        return;
    }

    const schoolId = school.id;
    const schoolCode = school.code;
    const domain = school.email?.split('@')[1] || 'demoschool.in';
    const credentials = [];

    // 3. School Admin user
    const adminEmail = `admin@${domain}`;
    let adminUser = await prisma.user.findFirst({
        where: { email: adminEmail, schoolId },
    });
    if (!adminUser) {
        adminUser = await prisma.user.create({
            data: {
                email: adminEmail,
                passwordHash,
                schoolId,
                firstName: 'School',
                lastName: 'Administrator',
                phone: school.phone,
                roleId: schoolAdminRole.id,
                isActive: true,
            },
        });
        console.log(`  Created school admin: ${adminEmail}`);
    } else {
        console.log(`  School admin exists: ${adminEmail}`);
    }
    credentials.push({ role: 'School Admin', email: adminEmail, password: DEMO_PASSWORD });

    // 4. Teacher (Teaching Staff) with User
    const teacherEmail = `teacher@${domain}`;
    let teacherStaff = await prisma.staff.findFirst({
        where: { schoolId, email: teacherEmail },
        include: { user: true },
    });
    if (!teacherStaff) {
        const teacherUser = await prisma.user.create({
            data: {
                email: teacherEmail,
                passwordHash,
                schoolId,
                firstName: 'Demo',
                lastName: 'Teacher',
                phone: school.phone,
                roleId: teacherRole.id,
                isActive: true,
            },
        });
        teacherStaff = await prisma.staff.create({
            data: {
                schoolId,
                userId: teacherUser.id,
                employeeNo: `${schoolCode}-TCH-001`,
                firstName: 'Demo',
                lastName: 'Teacher',
                gender: 'MALE',
                email: teacherEmail,
                designation: 'TEACHER',
                joinDate: new Date(),
                phone: school.phone,
                isActive: true,
            },
        });
        console.log(`  Created teacher: ${teacherEmail}`);
    } else {
        console.log(`  Teacher exists: ${teacherEmail}`);
    }
    credentials.push({ role: 'Teacher', email: teacherEmail, password: DEMO_PASSWORD });

    // 5. Non-Teaching Staff (all roles)
    try {
        for (const nt of NON_TEACHING_ROLES) {
            const result = await ensureNonTeachingStaff(school, staffRole, nt);
            if (result.created) {
                console.log(`  Created ${nt.displayName}: ${result.email}`);
            } else {
                console.log(`  ${nt.displayName} exists: ${result.email}`);
            }
            credentials.push({
                role: nt.displayName,
                email: result.email,
                password: DEMO_PASSWORD,
            });
        }
    } catch (err) {
        console.warn('  Non-teaching staff seed skipped:', err.message);
        credentials.push({
            role: 'Clerk (if NT module ready)',
            email: `clerk@${domain}`,
            password: DEMO_PASSWORD,
        });
    }

    // 6. Print credentials summary
    console.log('');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('✅ Staff credentials seeded successfully!');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('');
    console.log('Password for ALL accounts: ' + DEMO_PASSWORD);
    console.log('');
    console.log('School code:  ', schoolCode);
    console.log('Subdomain:    ', school.subdomain || '(none)');
    console.log('');
    console.log('LOGIN CREDENTIALS (Email | Password):');
    console.log('───────────────────────────────────────────────────────────────');
    for (const c of credentials) {
        console.log(`  ${c.role.padEnd(18)} | ${c.email.padEnd(35)} | ${c.password}`);
    }
    console.log('───────────────────────────────────────────────────────────────');
    console.log('');
    console.log('Use Staff portal with school_id or subdomain to login.');
}

main()
    .catch((e) => {
        console.error('Seed failed:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });

/**
 * Check if staff has login and create one if missing.
 * Usage: node check-staff-login.mjs <email> <password> [school_id]
 */
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    const email = process.argv[2] || 'milind.patel1404@gmail.com';
    const password = process.argv[3] || 'Admin@123';
    const schoolId = process.argv[4] || null;

    console.log('Checking staff:', email);

    // Find Staff by email (teaching staff)
    const staff = await prisma.staff.findFirst({
        where: {
            email: { equals: email, mode: 'insensitive' },
            deletedAt: null,
            ...(schoolId ? { schoolId } : {}),
        },
        include: { school: true, user: true },
    });

    if (!staff) {
        console.log('❌ No Staff found with email:', email);
        if (schoolId) {
            const anyStaff = await prisma.staff.findFirst({
                where: { email: { equals: email, mode: 'insensitive' }, deletedAt: null },
                include: { school: true },
            });
            if (anyStaff) {
                console.log('   Found in school:', anyStaff.school?.name, '(' + anyStaff.schoolId + ')');
            }
        }
        process.exit(1);
    }

    console.log('✅ Staff found:', staff.firstName, staff.lastName);
    console.log('   School:', staff.school?.name, '(' + staff.schoolId + ')');
    console.log('   Has User (login):', staff.userId ? 'Yes' : 'No');
    console.log('');

    if (staff.userId) {
        // User exists - reset password
        const hash = await bcrypt.hash(password, 12);
        await prisma.user.update({
            where: { id: staff.userId },
            data: { passwordHash: hash, passwordChangedAt: new Date(), failedLoginAttempts: 0, lockedUntil: null },
        });
        console.log('✅ Password reset to:', password);
    } else {
        // No User linked to Staff - create or link existing
        const hash = await bcrypt.hash(password, 12);
        let user = await prisma.user.findFirst({
            where: { email: { equals: staff.email, mode: 'insensitive' }, deletedAt: null },
        });
        if (user) {
            // User exists (e.g. from another portal) - link to Staff and fix schoolId/role
            const staffRole = await prisma.role.findFirst({ where: { name: { in: ['staff', 'teacher', 'school_admin'] } } });
            await prisma.user.update({
                where: { id: user.id },
                data: {
                    passwordHash: hash,
                    schoolId: staff.schoolId,
                    roleId: staffRole?.id ?? user.roleId,
                    isActive: true,
                    failedLoginAttempts: 0,
                    lockedUntil: null,
                },
            });
            await prisma.staff.update({
                where: { id: staff.id },
                data: { userId: user.id },
            });
            console.log('✅ Linked existing User to Staff, password set to:', password);
        } else {
            // Create new User
            const staffRole = await prisma.role.findFirst({ where: { name: { in: ['staff', 'teacher', 'school_admin'] } } });
            if (!staffRole) {
                console.log('❌ No staff/teacher role found in roles table');
                process.exit(1);
            }
            user = await prisma.user.create({
                data: {
                    email: staff.email,
                    passwordHash: hash,
                    schoolId: staff.schoolId,
                    firstName: staff.firstName,
                    lastName: staff.lastName,
                    phone: staff.phone,
                    roleId: staffRole.id,
                    isActive: true,
                },
            });
            await prisma.staff.update({
                where: { id: staff.id },
                data: { userId: user.id },
            });
            console.log('✅ Login account created for', staff.firstName, staff.lastName);
            console.log('   Password set to:', password);
        }
    }

    console.log('');
    console.log('Login with:');
    console.log('  Email:', staff.email);
    console.log('  Password:', password);
    console.log('  portal_type: staff');
    console.log('  school_id:', staff.schoolId);
}

main()
    .catch((e) => {
        console.error('Error:', e.message);
        process.exit(1);
    })
    .finally(() => prisma.$disconnect());

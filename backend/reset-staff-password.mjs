/**
 * Reset staff/teacher password for login debugging.
 * Usage: node reset-staff-password.mjs <email> <new_password> [school_id]
 *
 * Example: node reset-staff-password.mjs milind.patel1404@gmail.com Admin@123 edd1a7c2-4ef8-4235-a970-94907740da8f
 */
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    const email = process.argv[2] || 'milind.patel1404@gmail.com';
    const newPassword = process.argv[3] || 'Admin@123';
    const schoolId = process.argv[4] || null;

    console.log('Checking user:', email, 'school_id:', schoolId || '(any)');
    console.log('');

    const where = {
        email: { equals: email, mode: 'insensitive' },
        deletedAt: null,
        ...(schoolId ? { schoolId } : {}),
    };

    const user = await prisma.user.findFirst({
        where,
        include: {
            role: true,
            school: true,
            staffProfile: true,
            ntStaffProfile: true,
        },
    });

    if (!user) {
        console.log('❌ User NOT FOUND with email:', email);
        if (schoolId) {
            console.log('   Try without school_id to see if user exists in another school.');
            const anyUser = await prisma.user.findFirst({
                where: { email: { equals: email, mode: 'insensitive' }, deletedAt: null },
                include: { school: true },
            });
            if (anyUser) {
                console.log('   Found in school:', anyUser.school?.name, '(' + anyUser.schoolId + ')');
            }
        }
        process.exit(1);
    }

    console.log('✅ User found:');
    console.log('   ID:', user.id);
    console.log('   Email:', user.email);
    console.log('   School:', user.school?.name, '(' + user.schoolId + ')');
    console.log('   Role:', user.role?.name);
    console.log('   Active:', user.isActive);
    console.log('   Teaching Staff:', user.staffProfile ? 'Yes' : 'No');
    console.log('   Non-Teaching Staff:', user.ntStaffProfile ? 'Yes' : 'No');
    console.log('');

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await prisma.user.update({
        where: { id: user.id },
        data: {
            passwordHash,
            passwordChangedAt: new Date(),
            failedLoginAttempts: 0,
            lockedUntil: null,
        },
    });

    console.log('✅ Password reset to:', newPassword);
    console.log('');
    console.log('Login with:');
    console.log('  Email:', user.email);
    console.log('  Password:', newPassword);
    console.log('  portal_type: staff');
    console.log('  school_id:', user.schoolId);
}

main()
    .catch((e) => {
        console.error('Error:', e.message);
        process.exit(1);
    })
    .finally(() => prisma.$disconnect());

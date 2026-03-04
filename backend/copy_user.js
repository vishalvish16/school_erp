import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function run() {
    try {
        const publicUser = await prisma.$queryRawUnsafe(`SELECT * FROM public.users WHERE email = 'vishal.vish16@gmail.com' LIMIT 1`);
        if (publicUser.length > 0) {
            const role = await prisma.$queryRawUnsafe(`SELECT role_id FROM platform.roles WHERE role_type = 'PLATFORM' LIMIT 1`);

            await prisma.$queryRawUnsafe(`
                INSERT INTO platform.users (
                    email, password_hash, role_id, first_name, last_name, is_active, email_verified
                ) VALUES (
                    $1, $2, $3, $4, $5, $6, $7
                )
            `,
                publicUser[0].email, publicUser[0].password_hash, role[0].role_id,
                publicUser[0].first_name || 'Vishal', publicUser[0].last_name || 'Admin',
                publicUser[0].is_active, publicUser[0].email_verified);
            console.log('User copied successfully!');
        } else {
            console.log('No public user found!');
        }
    } catch (e) {
        console.error("Error:", e);
    }
}
run().finally(() => prisma.$disconnect());

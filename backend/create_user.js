import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
const prisma = new PrismaClient();

async function run() {
    try {
        const hashedPassword = await bcrypt.hash('admin123', 12);
        const role = await prisma.$queryRawUnsafe(`SELECT role_id FROM platform.roles WHERE role_type = 'PLATFORM' LIMIT 1`);

        await prisma.$queryRawUnsafe(`
            INSERT INTO platform.users (
                email, password_hash, role_id, first_name, last_name, is_active, email_verified, email_verified_at
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, NOW()
            )
        `,
            'vishal.vish16@gmail.com', hashedPassword, role[0].role_id,
            'Vishal', 'Admin', true, true);
        console.log('User created successfully!');
    } catch (e) {
        console.error("Error:", e.message);
    }
}
run().finally(() => prisma.$disconnect());

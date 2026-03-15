import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    try {
        const newHash = await bcrypt.hash('Vishal@123', 10);
        console.log('New hash:', newHash);

        await prisma.$executeRawUnsafe(
            `UPDATE users SET password_hash = $1 WHERE email = $2`,
            newHash,
            'vishal.vish16@gmail.com'
        );
        console.log('Password updated for vishal.vish16@gmail.com');

        // Verify
        const match = await bcrypt.compare('Vishal@123', newHash);
        console.log('Verify match:', match);
    } catch (e) {
        console.error('Error:', e.message);
    } finally {
        await prisma.$disconnect();
    }
}
main();

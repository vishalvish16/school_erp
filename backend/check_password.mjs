import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import { writeFileSync } from 'fs';

const prisma = new PrismaClient();

async function main() {
    try {
        const user = await prisma.$queryRawUnsafe(
            `SELECT id, email, password_hash, is_active FROM users WHERE email = $1`,
            'vishal.vish16@gmail.com'
        );
        let output = '';
        if (user.length > 0) {
            const u = user[0];
            output += `User found: ${u.email}\n`;
            output += `Password hash: ${u.password_hash}\n`;
            output += `Hash length: ${u.password_hash.length}\n`;
            output += `Active: ${u.is_active}\n`;

            // Test password
            const testPassword = 'Vishal@123';
            try {
                const match = await bcrypt.compare(testPassword, u.password_hash);
                output += `\nPassword '${testPassword}' matches: ${match}\n`;
            } catch (e) {
                output += `\nbcrypt compare error: ${e.message}\n`;
            }
        } else {
            output += 'User not found!\n';
        }

        writeFileSync('password_check.txt', output, 'utf8');
        console.log('Check password_check.txt');
    } catch (e) {
        console.error('Error:', e.message);
    } finally {
        await prisma.$disconnect();
    }
}
main();

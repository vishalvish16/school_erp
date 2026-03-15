import 'dotenv/config';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
    datasources: { db: { url: process.env.DATABASE_URL } }
});

async function main() {
    try {
        // Add missing columns
        const statements = [
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name VARCHAR(100)`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name VARCHAR(100)`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20)`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS failed_login_attempts SMALLINT DEFAULT 0`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMPTZ`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN DEFAULT false`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS mfa_enabled BOOLEAN DEFAULT false`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS mfa_secret VARCHAR(255)`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMPTZ`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_ip INET`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_password_token TEXT`,
            `ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_password_expires TIMESTAMPTZ`,
        ];

        for (const stmt of statements) {
            await prisma.$executeRawUnsafe(stmt);
            console.log('OK:', stmt.substring(0, 60) + '...');
        }

        // Set default names
        await prisma.$executeRawUnsafe(`UPDATE users SET first_name = 'Vishal', last_name = 'Admin' WHERE email = 'vishal.vish16@gmail.com' AND first_name IS NULL`);
        await prisma.$executeRawUnsafe(`UPDATE users SET first_name = 'Super', last_name = 'Admin' WHERE email = 'superadmin@schoolerp.com' AND first_name IS NULL`);

        console.log('\nMigration complete!');

        // Verify
        const cols = await prisma.$queryRawUnsafe(`
            SELECT column_name, data_type
            FROM information_schema.columns 
            WHERE table_name = 'users' 
            ORDER BY ordinal_position
        `);
        console.log('\nUpdated users table:');
        for (const col of cols) {
            console.log(`  ${col.column_name} (${col.data_type})`);
        }
    } catch (e) {
        console.error('Error:', e.message);
    } finally {
        await prisma.$disconnect();
    }
}
main();

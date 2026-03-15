import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { writeFileSync } from 'fs';

const prisma = new PrismaClient({
    datasources: { db: { url: process.env.DATABASE_URL } }
});

async function main() {
    try {
        // Get all tables
        const tables = await prisma.$queryRawUnsafe(`
            SELECT table_name FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name
        `);
        let output = '=== All tables ===\n';
        for (const t of tables) {
            output += `  ${t.table_name}\n`;
        }

        // Get all columns for key tables
        const checkTables = ['users', 'roles', 'schools', 'branches', 'platform_plans', 'school_subscriptions',
            'registered_devices', 'otp_verifications', 'auth_sessions', 'login_attempts', 'modules', 'role_permissions'];
        for (const tbl of checkTables) {
            const cols = await prisma.$queryRawUnsafe(`
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns 
                WHERE table_name = $1 
                ORDER BY ordinal_position
            `, tbl);
            if (cols.length > 0) {
                output += `\n=== ${tbl} ===\n`;
                for (const col of cols) {
                    output += `  ${col.column_name} (${col.data_type}) nullable=${col.is_nullable}\n`;
                }
            }
        }

        // Check roles data
        const roles = await prisma.$queryRawUnsafe(`SELECT * FROM roles`);
        output += '\n=== Roles data ===\n';
        for (const r of roles) {
            output += `  ${JSON.stringify(r, (k, v) => typeof v === 'bigint' ? v.toString() : v)}\n`;
        }

        // Check user + their role
        const users = await prisma.$queryRawUnsafe(`
            SELECT u.id, u.email, u.school_id, u.role_id, u.is_active, r.name as role_name, r.scope as role_scope
            FROM users u 
            LEFT JOIN roles r ON r.id = u.role_id 
            LIMIT 5
        `);
        output += '\n=== Users with roles ===\n';
        for (const u of users) {
            output += `  id=${u.id} email=${u.email} school_id=${u.school_id} role=${u.role_name} scope=${u.role_scope} active=${u.is_active}\n`;
        }

        // Check enums
        const enums = await prisma.$queryRawUnsafe(`
            SELECT t.typname, e.enumlabel
            FROM pg_type t 
            JOIN pg_enum e ON t.oid = e.enumtypid
            ORDER BY t.typname, e.enumsortorder
        `);
        output += '\n=== Enums ===\n';
        for (const e of enums) {
            output += `  ${e.typname}: ${e.enumlabel}\n`;
        }

        writeFileSync('full_schema_output.txt', output, 'utf8');
        console.log('Written to full_schema_output.txt');
    } catch (e) {
        console.error('Error:', e.message);
    } finally {
        await prisma.$disconnect();
    }
}
main();

import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    console.log('Seeding root Super Admin account...');

    // 1. Create the PLATFORM role (No schoolId needed)
    let platformRole = await prisma.role.findFirst({
        where: {
            schoolId: null,
            name: 'Super Admin',
            roleType: 'PLATFORM'
        }
    });

    if (!platformRole) {
        platformRole = await prisma.role.create({
            data: {
                name: 'Super Admin',
                roleType: 'PLATFORM',
                description: 'Root access to the entire SaaS platform'
            }
        });
    }

    // 2. Hash default password
    const passwordHash = await bcrypt.hash('password123', 10);

    // 3. Create the demo admin user
    let adminUser = await prisma.user.findUnique({
        where: { email: 'vishal.vish16@gmail.com' }
    });

    if (!adminUser) {
        adminUser = await prisma.user.create({
            data: {
                email: 'vishal.vish16@gmail.com',
                passwordHash,
                firstName: 'System',
                lastName: 'Administrator',
                isActive: true,
                roleId: platformRole.id
            }
        });
    }

    console.log('✅ Default Platform Admin seeded:', adminUser.email);
}

main()
    .catch((e) => {
        console.error('Seeding process failed:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });

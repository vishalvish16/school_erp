import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

const ADMIN_EMAIL = 'vishal.vish16@gmail.com';
const ADMIN_PASSWORD = 'password123';

async function main() {
    console.log('Seeding Super Admin + demo data...');

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
        console.log('  Created PLATFORM role');
    }

    // 2. Hash default password
    const passwordHash = await bcrypt.hash(ADMIN_PASSWORD, 10);

    // 3. Create the demo admin user (schoolId must be null for super admin)
    let adminUser = await prisma.user.findUnique({
        where: { email: ADMIN_EMAIL }
    });

    if (!adminUser) {
        adminUser = await prisma.user.create({
            data: {
                email: ADMIN_EMAIL,
                passwordHash,
                firstName: 'System',
                lastName: 'Administrator',
                isActive: true,
                roleId: platformRole.id
            }
        });
        console.log('  Created Super Admin user:', adminUser.email);
    } else {
        // Ensure existing user has schoolId=null for super admin access
        await prisma.user.update({
            where: { id: adminUser.id },
            data: { schoolId: null, branchId: null, roleId: platformRole.id }
        });
        console.log('  Updated existing user for Super Admin:', adminUser.email);
    }

    // 4. Create demo Platform Plans (required for schools)
    const planDefs = [
        { name: 'Starter', maxStudents: 100, priceMonthly: 99, icon: '📦' },
        { name: 'Pro', maxStudents: 500, priceMonthly: 299, icon: '🚀' },
        { name: 'Enterprise', maxStudents: 5000, priceMonthly: 999, icon: '🏆' }
    ];

    for (const p of planDefs) {
        const existing = await prisma.platformPlan.findFirst({
            where: { name: p.name }
        });
        if (!existing) {
            await prisma.platformPlan.create({
                data: {
                    name: p.name,
                    maxStudents: p.maxStudents,
                    maxTeachers: 20,
                    maxBranches: 1,
                    priceMonthly: p.priceMonthly,
                    isActive: true
                }
            });
            console.log('  Created plan:', p.name);
        }
    }

    // 5. Create demo school (if none exist)
    const schoolCount = await prisma.school.count();
    if (schoolCount === 0) {
        const starterPlan = await prisma.platformPlan.findFirst({
            where: { name: 'Starter' }
        });
        if (starterPlan) {
            const now = new Date();
            const endDate = new Date(now);
            endDate.setFullYear(endDate.getFullYear() + 1);

            const demoSchool = await prisma.school.create({
                data: {
                    name: 'Demo School',
                    schoolCode: 'DEMO001',
                    subdomain: 'demo-school',
                    planId: starterPlan.id,
                    contactEmail: 'admin@demoschool.in',
                    contactPhone: '+919876543210',
                    city: 'Mumbai',
                    state: 'Maharashtra',
                    isActive: true,
                    subscriptionStart: now,
                    subscriptionEnd: endDate
                }
            });

            await prisma.schoolSubscription.create({
                data: {
                    schoolId: demoSchool.id,
                    planId: starterPlan.id,
                    startDate: now,
                    endDate,
                    billingCycle: 'YEARLY',
                    priceAmount: starterPlan.priceMonthly,
                    currency: 'INR',
                    status: 'ACTIVE'
                }
            });
            console.log('  Created demo school + subscription: Demo School');
        }
    }

    console.log('');
    console.log('✅ Seed complete. Super Admin login:');
    console.log('   Email:', ADMIN_EMAIL);
    console.log('   Password:', ADMIN_PASSWORD);
    console.log('   (Use portal_type: super_admin or login from admin subdomain)');
}

main()
    .catch((e) => {
        console.error('Seeding process failed:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });

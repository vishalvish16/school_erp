import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
async function run() {
    const prisma = new PrismaClient();
    try {
        const role = await prisma.role.findFirst({ where: { roleType: 'PLATFORM' } });
        console.log('Got role:', role);
        let oldHash = await bcrypt.hash('admin123', 10);
        const existing = await prisma.user.findFirst({ where: { email: 'vishal.vish16@gmail.com' } });
        if (existing) {
            console.log('Update existing user');
            await prisma.user.update({
                where: { id: existing.id },
                data: { isActive: true, emailVerified: true }
            });
        } else {
            console.log('Create new user');
            await prisma.user.create({
                data: {
                    email: 'vishal.vish16@gmail.com',
                    passwordHash: oldHash,
                    roleId: role.id,
                    firstName: 'Vishal',
                    lastName: 'Admin',
                    isActive: true,
                    emailVerified: true
                }
            });
        }
        console.log('Success!');
    } catch (err) {
        console.log('ERROR:', err.message);
    }
}
run().finally(() => process.exit(0));

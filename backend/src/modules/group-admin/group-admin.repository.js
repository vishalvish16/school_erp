import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

class GroupAdminRepository {
  async getGroupWithSchools(groupId) {
    return prisma.schoolGroup.findFirst({
      where: { id: groupId, deletedAt: null },
      include: {
        schools: {
          where: { status: { not: 'INACTIVE' } },
          include: {
            _count: { select: { users: true } }
          }
        },
        groupAdmin: {
          select: { id: true, firstName: true, lastName: true, email: true, phone: true }
        }
      }
    });
  }

  async getGroupSchoolIds(groupId) {
    const schools = await prisma.school.findMany({
      where: { groupId, status: { not: 'INACTIVE' } },
      select: { id: true }
    });
    return schools.map(s => s.id);
  }

  async getGroupStats(groupId) {
    const schoolIds = await this.getGroupSchoolIds(groupId);
    const [schoolCount, userCounts] = await Promise.all([
      prisma.school.count({ where: { groupId, status: 'ACTIVE' } }),
      prisma.user.groupBy({
        by: ['roleId'],
        where: { schoolId: { in: schoolIds }, isActive: true, deletedAt: null },
        _count: true
      })
    ]);
    return { schoolCount, userCounts };
  }

  async getSchoolDetail(schoolId) {
    return prisma.school.findFirst({
      where: { id: schoolId },
      include: {
        _count: { select: { users: true } },
        users: {
          where: { role: { name: 'school_admin' } },
          select: { id: true, firstName: true, lastName: true, email: true },
          take: 1
        }
      }
    });
  }

  async getNotifications(groupId, { page = 1, limit = 20 }) {
    // Placeholder — returns empty until notification module is built
    return { data: [], pagination: { page, limit, total: 0, total_pages: 0 } };
  }
}

export const groupAdminRepository = new GroupAdminRepository();

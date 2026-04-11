import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { groupAdminRepository } from './group-admin.repository.js';
import { AppError } from '../../utils/response.js';
import bcrypt from 'bcrypt';
import * as smartRepo from '../auth/smart-login.repository.js';
import { sendEmail } from '../../config/mailer.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
import prisma from '../../config/prisma.js';

async function sendOtpDelivery(otpCode, phone, email) {
  if (phone) console.log(`[DEV] OTP to ${phone}: ${otpCode}`);
  if (email && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    try {
      await sendEmail({
        to: email,
        subject: 'Verify your profile change — School AI ERP',
        text: `Your verification code is: ${otpCode}. It expires in 2 minutes.`,
        html: `<p>Your verification code is: <strong>${otpCode}</strong></p><p>It expires in 2 minutes.</p>`,
      });
    } catch (e) {
      console.error('[Profile OTP] Email failed:', e.message);
    }
  }
}

class GroupAdminService {
  async getDashboardStats(groupId) {
    const group = await groupAdminRepository.getGroupWithSchools(groupId);
    if (!group) throw new AppError('Group not found', 404);

    const schools = group.schools || [];
    const activeSchools = schools.filter(s => s.status === 'ACTIVE');

    // Aggregate user counts
    const schoolIds = schools.map(s => s.id);

    // Count students and teachers
    const [totalUserCount, teacherCount] = await Promise.all([
      prisma.user.count({ where: { schoolId: { in: schoolIds }, isActive: true, deletedAt: null } }),
      prisma.user.count({ where: { schoolId: { in: schoolIds }, isActive: true, deletedAt: null, role: { name: 'teacher' } } })
    ]);

    // Subscription breakdown
    const subBreakdown = schools.reduce((acc, s) => {
      const plan = s.subscriptionPlan || 'NONE';
      acc[plan] = (acc[plan] || 0) + 1;
      return acc;
    }, {});

    // Expiring soon (within 30 days)
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
    const expiringSoon = schools.filter(s =>
      s.subscriptionEnd && new Date(s.subscriptionEnd) <= thirtyDaysFromNow && new Date(s.subscriptionEnd) >= new Date()
    );

    return {
      group: {
        id: group.id,
        name: group.name,
        slug: group.slug,
        logoUrl: group.logoUrl,
        status: group.status
      },
      totalSchools: schools.length,
      activeSchools: activeSchools.length,
      totalStudents: totalUserCount,
      totalTeachers: teacherCount,
      subscriptionBreakdown: subBreakdown,
      expiringSoon: expiringSoon.length,
      recentActivity: [] // Populated when audit module is connected
    };
  }

  async getSchools(groupId, { search, sortBy = 'name', sortOrder = 'asc' }) {
    const allowedSortFields = ['name', 'code', 'city', 'status', 'createdAt'];
    const safeSortBy = allowedSortFields.includes(sortBy) ? sortBy : 'name';
    const safeSortOrder = sortOrder === 'desc' ? 'desc' : 'asc';

    const where = {
      groupId,
      status: { not: 'INACTIVE' },
      ...(search && {
        OR: [
          { name: { contains: search, mode: 'insensitive' } },
          { code: { contains: search, mode: 'insensitive' } },
          { city: { contains: search, mode: 'insensitive' } }
        ]
      })
    };

    const schools = await prisma.school.findMany({
      where,
      orderBy: { [safeSortBy]: safeSortOrder },
      include: {
        _count: { select: { users: true } }
      }
    });

    return schools.map(s => ({
      id: s.id,
      name: s.name,
      code: s.code,
      city: s.city,
      state: s.state,
      board: s.board,
      status: s.status,
      subscription_plan: s.subscriptionPlan,
      subscription_end: s.subscriptionEnd,
      user_count: s._count.users
    }));
  }

  async getSchoolDetail(groupId, schoolId) {
    // Verify school belongs to this group
    const school = await prisma.school.findFirst({
      where: { id: schoolId, groupId }
    });
    if (!school) throw new AppError('School not found in your group', 404);

    const raw = await groupAdminRepository.getSchoolDetail(schoolId);
    if (!raw) throw new AppError('School not found', 404);

    // Fetch user count (active, non-deleted) and school admin separately for reliability
    const [userCount, admin] = await Promise.all([
      prisma.user.count({
        where: {
          schoolId: String(schoolId),
          isActive: true,
          deletedAt: null,
        },
      }),
      (async () => {
        const role = await prisma.role.findFirst({ where: { name: 'school_admin' } });
        if (!role) return null;
        const user = await prisma.user.findFirst({
          where: {
            schoolId: String(schoolId),
            roleId: role.id,
            isActive: true,
            deletedAt: null,
          },
          select: { id: true, email: true, firstName: true, lastName: true },
        });
        if (!user) return null;
        const name = [user.firstName, user.lastName].filter(Boolean).join(' ').trim() || user.email;
        return { name, email: user.email };
      })(),
    ]);

    return {
      id: raw.id,
      name: raw.name,
      code: raw.code,
      email: raw.email,
      phone: raw.phone,
      city: raw.city,
      state: raw.state,
      country: raw.country,
      pin_code: raw.pinCode,
      board: raw.board,
      timezone: raw.timezone,
      status: raw.status,
      subscription_plan: raw.subscriptionPlan,
      subscription_start: raw.subscriptionStart,
      subscription_end: raw.subscriptionEnd,
      user_count: userCount,
      school_admin_name: admin?.name ?? null,
      school_admin_email: admin?.email ?? null,
    };
  }

  async getProfile(userId, groupId) {
    const [user, group] = await Promise.all([
      prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, email: true, firstName: true, lastName: true, phone: true, lastLogin: true, avatarUrl: true }
      }),
      prisma.schoolGroup.findUnique({
        where: { id: groupId },
        select: { id: true, name: true, slug: true, logoUrl: true, country: true }
      })
    ]);
    return { user, group };
  }

  async sendProfileOtp(userId, { email, phone }) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new AppError('User not found', 404);

    const targetEmail = email || null;
    const targetPhone = phone || null;
    if (!targetEmail && !targetPhone) {
      throw new AppError('Provide email or phone to verify', 400);
    }

    const otpCode = String(Math.floor(100000 + Math.random() * 900000));
    const otpRecord = await smartRepo.createOtpVerification({
      userId,
      phone: targetPhone,
      email: targetEmail,
      otpCode,
      otpType: 'profile_update',
    });

    await sendOtpDelivery(otpCode, targetPhone, targetEmail);

    return {
      otp_session_id: otpRecord.id,
      expires_at: otpRecord.expires_at,
      masked_email: targetEmail ? targetEmail.replace(/(.{2})(.*)(@.*)/, '$1***$3') : null,
      masked_phone: targetPhone ? targetPhone.slice(-4).padStart(targetPhone.length, '*') : null,
    };
  }

  async updateProfile(userId, body, { otpSessionId, otpCode } = {}) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new AppError('User not found', 404);

    const updates = {};
    const newEmail = body.email?.trim();
    const newPhone = body.phone?.trim();

    const emailChanged = newEmail && newEmail !== user.email;
    const phoneChanged = newPhone !== undefined && newPhone !== (user.phone || '');

    if (emailChanged || phoneChanged) {
      if (!otpSessionId || !otpCode) {
        throw new AppError('OTP verification required for email or phone change. Request OTP first.', 400);
      }
      const otpRecord = await smartRepo.findOtpById(otpSessionId);
      if (!otpRecord) {
        throw new AppError('Invalid or expired OTP. Please request a new one.', 400);
      }
      if (otpRecord.user_id !== userId) {
        throw new AppError('OTP does not match this account', 403);
      }
      const codeMatch = String(otpRecord.otp_code) === String(otpCode);
      if (!codeMatch) {
        await smartRepo.incrementOtpAttempts(otpSessionId);
        throw new AppError('Invalid OTP code', 400);
      }
      await smartRepo.markOtpUsed(otpSessionId);
    }

    if (body.firstName !== undefined) updates.firstName = body.firstName?.trim() || null;
    if (body.lastName !== undefined) updates.lastName = body.lastName?.trim() || null;
    if (body.phone !== undefined) updates.phone = body.phone?.trim() || null;
    if (emailChanged) {
      const existing = await prisma.user.findUnique({ where: { email: newEmail } });
      if (existing && existing.id !== userId) {
        throw new AppError('Email already in use', 400);
      }
      updates.email = newEmail;
    }
    if (body.avatarUrl !== undefined) updates.avatarUrl = body.avatarUrl?.trim() || null;
    if (body.avatar_base64) {
      const avatarsDir = path.join(__dirname, '..', '..', '..', 'uploads', 'avatars');
      if (!fs.existsSync(avatarsDir)) fs.mkdirSync(avatarsDir, { recursive: true });
      const base64 = body.avatar_base64.replace(/^data:image\/\w+;base64,/, '');
      const buf = Buffer.from(base64, 'base64');
      const ext = (body.avatar_base64.match(/^data:image\/(\w+);/) || [null, 'jpeg'])[1] || 'jpeg';
      const filename = `${userId}.${ext}`;
      fs.writeFileSync(path.join(avatarsDir, filename), buf);
      updates.avatarUrl = `/uploads/avatars/${filename}`;
    }

    if (Object.keys(updates).length === 0) {
      const group = await prisma.schoolGroup.findFirst({ where: { groupAdminUserId: userId } });
      return this.getProfile(userId, group?.id);
    }

    await prisma.user.update({
      where: { id: userId },
      data: updates,
    });

    const group = await prisma.schoolGroup.findFirst({ where: { groupAdminUserId: userId } });
    return this.getProfile(userId, group?.id);
  }

  async changePassword(userId, currentPassword, newPassword) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new AppError('User not found', 404);

    const isValid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isValid) throw new AppError('Current password is incorrect', 400);

    const hash = await bcrypt.hash(newPassword, 12);
    await prisma.user.update({
      where: { id: userId },
      data: { passwordHash: hash, passwordChangedAt: new Date(), mustChangePassword: false }
    });
  }

  async getNotifications(groupId, { page = 1, limit = 20 }) {
    const p = Number(page) || 1;
    const l = Number(limit) || 20;
    const skip = (p - 1) * l;
    try {
      const rows = await prisma.$queryRawUnsafe(`
        SELECT id, type, title, body, is_read, link, created_at
        FROM platform_notifications
        WHERE target_role = 'group_admin' OR target_role IS NULL
        ORDER BY created_at DESC
        LIMIT $1 OFFSET $2
      `, l, skip);
      const total = await prisma.$queryRawUnsafe(`
        SELECT COUNT(*)::int AS count FROM platform_notifications
        WHERE target_role = 'group_admin' OR target_role IS NULL
      `);
      return {
        data: (rows || []).map((n) => ({
          id: n.id,
          type: n.type || 'info',
          title: n.title,
          body: n.body,
          is_read: n.is_read,
          link: n.link || null,
          created_at: n.created_at,
        })),
        pagination: { page: p, limit: l, total: total?.[0]?.count ?? 0, total_pages: Math.ceil((total?.[0]?.count ?? 0) / l) || 1 },
      };
    } catch (_) {
      return { data: [], pagination: { page: p, limit: l, total: 0, total_pages: 1 } };
    }
  }

  async getUnreadNotificationCount(groupId) {
    try {
      const result = await prisma.$queryRawUnsafe(`
        SELECT COUNT(*)::int AS count FROM platform_notifications
        WHERE (target_role = 'group_admin' OR target_role IS NULL)
          AND is_read = FALSE
      `);
      return { unread_count: result?.[0]?.count ?? 0 };
    } catch (_) {
      return { unread_count: 0 };
    }
  }

  async markNotificationRead(notificationId, groupId) {
    try {
      await prisma.$executeRawUnsafe('UPDATE platform_notifications SET is_read = TRUE WHERE id = $1::uuid', String(notificationId));
    } catch (_) { }
    return { success: true };
  }

  async getSchoolComparison(groupId) {
    const schools = await prisma.school.findMany({
      where: { groupId, status: { not: 'INACTIVE' } },
      orderBy: { name: 'asc' },
      include: { _count: { select: { users: true } } }
    });

    const now = new Date();
    const thirtyDays = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const mapped = schools.map(s => {
      let expiryStatus = 'ok';
      if (s.subscriptionEnd) {
        const end = new Date(s.subscriptionEnd);
        if (end < now) expiryStatus = 'expired';
        else if (end <= thirtyDays) expiryStatus = 'expiring_soon';
      }
      return {
        id: s.id,
        name: s.name,
        code: s.code,
        city: s.city || null,
        state: s.state || null,
        board: s.board || null,
        status: s.status,
        subscription_plan: s.subscriptionPlan || 'BASIC',
        subscription_end: s.subscriptionEnd,
        user_count: s._count.users,
        expiry_status: expiryStatus,
      };
    });

    const statusBreakdown = {};
    const planBreakdown = {};
    for (const s of mapped) {
      statusBreakdown[s.status] = (statusBreakdown[s.status] || 0) + 1;
      planBreakdown[s.subscription_plan] = (planBreakdown[s.subscription_plan] || 0) + 1;
    }

    return {
      schools: mapped,
      total_schools: mapped.length,
      total_users: mapped.reduce((acc, s) => acc + s.user_count, 0),
      status_breakdown: statusBreakdown,
      plan_breakdown: planBreakdown,
    };
  }

  // ── Student Stats ──────────────────────────────────────────────────────────

  async getStudentStats(groupId) {
    const schools = await prisma.school.findMany({
      where: { groupId, status: { not: 'INACTIVE' } },
      select: { id: true, name: true, code: true, city: true, status: true },
      orderBy: { name: 'asc' },
    });
    const schoolIds = schools.map(s => s.id);

    // Count per school per role
    const usersBySchool = await prisma.user.groupBy({
      by: ['schoolId'],
      where: { schoolId: { in: schoolIds }, isActive: true, deletedAt: null },
      _count: { id: true },
    });

    const teachersBySchool = await prisma.user.groupBy({
      by: ['schoolId'],
      where: { schoolId: { in: schoolIds }, isActive: true, deletedAt: null, role: { name: 'teacher' } },
      _count: { id: true },
    });

    const userMap = Object.fromEntries(usersBySchool.map(r => [r.schoolId, r._count.id]));
    const teacherMap = Object.fromEntries(teachersBySchool.map(r => [r.schoolId, r._count.id]));

    const rows = schools.map(s => ({
      id: s.id,
      name: s.name,
      code: s.code,
      city: s.city || null,
      status: s.status,
      totalUsers: userMap[s.id] || 0,
      totalTeachers: teacherMap[s.id] || 0,
      totalStudents: Math.max(0, (userMap[s.id] || 0) - (teacherMap[s.id] || 0)),
    }));

    return {
      schools: rows,
      totals: {
        schools: rows.length,
        users: rows.reduce((a, r) => a + r.totalUsers, 0),
        teachers: rows.reduce((a, r) => a + r.totalTeachers, 0),
        students: rows.reduce((a, r) => a + r.totalStudents, 0),
      },
    };
  }

  // ── Notices ────────────────────────────────────────────────────────────────

  async getNotices(groupId, { page = 1, limit = 20, search } = {}) {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    const skip = (p - 1) * l;

    const where = {
      groupId,
      deletedAt: null,
      ...(search && {
        OR: [
          { title: { contains: search, mode: 'insensitive' } },
          { body: { contains: search, mode: 'insensitive' } },
        ],
      }),
    };

    const [rows, total] = await Promise.all([
      prisma.groupNotice.findMany({
        where,
        orderBy: [{ isPinned: 'desc' }, { createdAt: 'desc' }],
        skip,
        take: l,
      }),
      prisma.groupNotice.count({ where }),
    ]);

    return {
      data: rows,
      pagination: { page: p, limit: l, total, total_pages: Math.ceil(total / l) || 1 },
    };
  }

  async createNotice(groupId, userId, { title, body, targetRole, isPinned, publishedAt, expiresAt }) {
    if (!title?.trim()) throw new AppError('Title is required', 400);
    if (!body?.trim()) throw new AppError('Body is required', 400);

    return prisma.groupNotice.create({
      data: {
        groupId,
        title: title.trim(),
        body: body.trim(),
        targetRole: targetRole || null,
        isPinned: Boolean(isPinned),
        publishedAt: publishedAt ? new Date(publishedAt) : new Date(),
        expiresAt: expiresAt ? new Date(expiresAt) : null,
        createdBy: userId,
      },
    });
  }

  async updateNotice(groupId, noticeId, updates) {
    const notice = await prisma.groupNotice.findFirst({
      where: { id: noticeId, groupId, deletedAt: null },
    });
    if (!notice) throw new AppError('Notice not found', 404);

    return prisma.groupNotice.update({
      where: { id: noticeId },
      data: {
        ...(updates.title !== undefined && { title: updates.title.trim() }),
        ...(updates.body !== undefined && { body: updates.body.trim() }),
        ...(updates.targetRole !== undefined && { targetRole: updates.targetRole || null }),
        ...(updates.isPinned !== undefined && { isPinned: Boolean(updates.isPinned) }),
        ...(updates.publishedAt !== undefined && { publishedAt: updates.publishedAt ? new Date(updates.publishedAt) : null }),
        ...(updates.expiresAt !== undefined && { expiresAt: updates.expiresAt ? new Date(updates.expiresAt) : null }),
      },
    });
  }

  async deleteNotice(groupId, noticeId) {
    const notice = await prisma.groupNotice.findFirst({
      where: { id: noticeId, groupId, deletedAt: null },
    });
    if (!notice) throw new AppError('Notice not found', 404);

    await prisma.groupNotice.update({
      where: { id: noticeId },
      data: { deletedAt: new Date() },
    });
  }

  // ── Alert Rules ────────────────────────────────────────────────────────────

  async getAlertRules(groupId) {
    return prisma.groupAlertRule.findMany({
      where: { groupId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createAlertRule(groupId, userId, { name, metric, condition, threshold, notifyEmail, notifySms }) {
    const VALID_METRICS = ['attendance_percentage', 'fee_collection_rate', 'active_schools_ratio'];
    const VALID_CONDITIONS = ['less_than', 'greater_than', 'equals'];
    if (!name?.trim()) throw new AppError('Name is required', 400);
    if (!VALID_METRICS.includes(metric)) throw new AppError('Invalid metric', 400);
    if (!VALID_CONDITIONS.includes(condition)) throw new AppError('Invalid condition', 400);
    if (threshold == null || isNaN(Number(threshold))) throw new AppError('Threshold must be a number', 400);

    return prisma.groupAlertRule.create({
      data: {
        groupId,
        name: name.trim(),
        metric,
        condition,
        threshold: Number(threshold),
        notifyEmail: notifyEmail !== false,
        notifySms: Boolean(notifySms),
        createdBy: userId,
      },
    });
  }

  async updateAlertRule(groupId, ruleId, updates) {
    const rule = await prisma.groupAlertRule.findFirst({ where: { id: ruleId, groupId } });
    if (!rule) throw new AppError('Alert rule not found', 404);

    return prisma.groupAlertRule.update({
      where: { id: ruleId },
      data: {
        ...(updates.name !== undefined && { name: updates.name.trim() }),
        ...(updates.isActive !== undefined && { isActive: Boolean(updates.isActive) }),
        ...(updates.threshold !== undefined && { threshold: Number(updates.threshold) }),
        ...(updates.notifyEmail !== undefined && { notifyEmail: Boolean(updates.notifyEmail) }),
        ...(updates.notifySms !== undefined && { notifySms: Boolean(updates.notifySms) }),
      },
    });
  }

  async deleteAlertRule(groupId, ruleId) {
    const rule = await prisma.groupAlertRule.findFirst({ where: { id: ruleId, groupId } });
    if (!rule) throw new AppError('Alert rule not found', 404);
    await prisma.groupAlertRule.delete({ where: { id: ruleId } });
  }
}

export const groupAdminService = new GroupAdminService();

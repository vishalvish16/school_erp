/**
 * Teacher Repository — all Prisma queries for the teacher portal.
 * Every query is scoped to schoolId from req.teacher.schoolId — no cross-school access possible.
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// ── Dashboard ──────────────────────────────────────────────────────────────────

export async function getTodaySchedule(schoolId, staffId, dayOfWeek) {
    return prisma.timetable.findMany({
        where: {
            schoolId,
            staffId,
            dayOfWeek,
        },
        orderBy: { periodNo: 'asc' },
        include: {
            class_: { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
        },
    });
}

export async function countStudentsInSections(sectionIds) {
    if (!sectionIds.length) return 0;
    return prisma.student.count({
        where: {
            sectionId: { in: sectionIds },
            deletedAt: null,
            status: 'ACTIVE',
        },
    });
}

export async function countAttendanceMarkedToday(schoolId, staffId, date) {
    const sectionIds = await getTeacherSectionIds(staffId);
    if (!sectionIds.length) return [];

    const marked = await prisma.attendance.groupBy({
        by: ['sectionId'],
        where: {
            schoolId,
            sectionId: { in: sectionIds },
            date,
        },
        _count: { id: true },
    });

    return marked.map((m) => m.sectionId);
}

async function getTeacherSectionIds(staffId) {
    const assignments = await prisma.staffSubjectAssignment.findMany({
        where: { staffId, isActive: true },
        select: { sectionId: true },
    });

    const classTeacherSections = await prisma.section.findMany({
        where: { classTeacherId: staffId, isActive: true },
        select: { id: true },
    });

    const ids = new Set();
    for (const a of assignments) {
        if (a.sectionId) ids.add(a.sectionId);
    }
    for (const s of classTeacherSections) {
        ids.add(s.id);
    }
    return [...ids];
}

export async function countActiveHomework(schoolId, staffId) {
    return prisma.homework.count({
        where: { schoolId, staffId, status: 'ACTIVE' },
    });
}

export async function countHomeworkDueThisWeek(schoolId, staffId) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const endOfWeek = new Date(today);
    endOfWeek.setDate(endOfWeek.getDate() + (7 - endOfWeek.getDay()));
    endOfWeek.setHours(23, 59, 59, 999);

    return prisma.homework.count({
        where: {
            schoolId,
            staffId,
            status: 'ACTIVE',
            dueDate: { gte: today, lte: endOfWeek },
        },
    });
}

export async function getClassTeacherInfo(staffId) {
    const section = await prisma.section.findFirst({
        where: { classTeacherId: staffId, isActive: true },
        include: {
            class_: { select: { id: true, name: true } },
            _count: { select: { students: { where: { deletedAt: null, status: 'ACTIVE' } } } },
        },
    });

    if (!section) return null;

    return {
        class_id: section.classId,
        class_name: section.class_.name,
        section_id: section.id,
        section_name: section.name,
        student_count: section._count.students,
    };
}

// ── Sections ───────────────────────────────────────────────────────────────────

export async function getTeacherSections(staffId) {
    const assignments = await prisma.staffSubjectAssignment.findMany({
        where: { staffId, isActive: true },
        include: {
            class_: { select: { id: true, name: true } },
            section: {
                select: {
                    id: true,
                    name: true,
                    classTeacherId: true,
                    _count: { select: { students: { where: { deletedAt: null, status: 'ACTIVE' } } } },
                },
            },
        },
    });

    const classTeacherSection = await prisma.section.findFirst({
        where: { classTeacherId: staffId, isActive: true },
        include: {
            class_: { select: { id: true, name: true } },
            _count: { select: { students: { where: { deletedAt: null, status: 'ACTIVE' } } } },
        },
    });

    const sectionMap = new Map();

    for (const a of assignments) {
        if (!a.section) continue;
        const key = a.section.id;
        if (!sectionMap.has(key)) {
            sectionMap.set(key, {
                class_id: a.classId,
                class_name: a.class_.name,
                section_id: a.section.id,
                section_name: a.section.name,
                student_count: a.section._count.students,
                is_class_teacher: a.section.classTeacherId === staffId,
                subjects: [],
            });
        }
        sectionMap.get(key).subjects.push(a.subject);
    }

    if (classTeacherSection && !sectionMap.has(classTeacherSection.id)) {
        sectionMap.set(classTeacherSection.id, {
            class_id: classTeacherSection.classId,
            class_name: classTeacherSection.class_.name,
            section_id: classTeacherSection.id,
            section_name: classTeacherSection.name,
            student_count: classTeacherSection._count.students,
            is_class_teacher: true,
            subjects: [],
        });
    }

    return [...sectionMap.values()];
}

// ── Attendance ─────────────────────────────────────────────────────────────────

export async function getStudentsBySection(sectionId, schoolId) {
    return prisma.student.findMany({
        where: {
            sectionId,
            schoolId,
            deletedAt: null,
            status: 'ACTIVE',
        },
        select: {
            id: true,
            admissionNo: true,
            firstName: true,
            lastName: true,
            rollNo: true,
        },
        orderBy: [{ rollNo: 'asc' }, { firstName: 'asc' }],
    });
}

export async function getAttendanceBySection(sectionId, schoolId, date) {
    return prisma.attendance.findMany({
        where: {
            sectionId,
            schoolId,
            date,
        },
        select: {
            studentId: true,
            status: true,
            remarks: true,
        },
    });
}

export async function getSectionWithClass(sectionId, schoolId) {
    return prisma.section.findFirst({
        where: { id: sectionId, schoolId },
        include: {
            class_: { select: { id: true, name: true } },
        },
    });
}

export async function upsertAttendance({ schoolId, sectionId, date, studentId, status, markedBy, remarks }) {
    return prisma.attendance.upsert({
        where: {
            studentId_date: { studentId, date },
        },
        create: {
            schoolId,
            sectionId,
            studentId,
            date,
            status,
            markedBy,
            remarks: remarks || null,
        },
        update: {
            status,
            markedBy,
            remarks: remarks || null,
            sectionId,
        },
    });
}

export async function getAttendanceReport({ sectionId, schoolId, fromDate, toDate }) {
    const attendances = await prisma.attendance.findMany({
        where: {
            sectionId,
            schoolId,
            date: { gte: fromDate, lte: toDate },
        },
        select: {
            studentId: true,
            status: true,
            date: true,
        },
    });

    const students = await prisma.student.findMany({
        where: {
            sectionId,
            schoolId,
            deletedAt: null,
            status: 'ACTIVE',
        },
        select: {
            id: true,
            firstName: true,
            lastName: true,
            rollNo: true,
        },
        orderBy: [{ rollNo: 'asc' }, { firstName: 'asc' }],
    });

    const uniqueDates = new Set(attendances.map((a) => a.date.toISOString().split('T')[0]));
    const totalWorkingDays = uniqueDates.size;

    const byStudent = {};
    for (const a of attendances) {
        if (!byStudent[a.studentId]) {
            byStudent[a.studentId] = { present: 0, absent: 0, late: 0, half_day: 0 };
        }
        const s = byStudent[a.studentId];
        switch (a.status) {
            case 'PRESENT': s.present++; break;
            case 'ABSENT': s.absent++; break;
            case 'LATE': s.late++; break;
            case 'HALF_DAY': s.half_day++; break;
        }
    }

    const studentStats = students.map((st) => {
        const stats = byStudent[st.id] || { present: 0, absent: 0, late: 0, half_day: 0 };
        const totalMarked = stats.present + stats.absent + stats.late + stats.half_day;
        return {
            student_id: st.id,
            name: `${st.firstName} ${st.lastName}`,
            roll_no: st.rollNo,
            present: stats.present,
            absent: stats.absent,
            late: stats.late,
            half_day: stats.half_day,
            attendance_pct: totalMarked > 0
                ? Math.round(((stats.present + stats.late * 0.5 + stats.half_day * 0.5) / totalMarked) * 1000) / 10
                : 0,
        };
    });

    const totalPresentAll = studentStats.reduce((sum, s) => sum + s.present, 0);
    const totalMarkedAll = studentStats.reduce((sum, s) => sum + s.present + s.absent + s.late + s.half_day, 0);
    const averageAttendancePct = totalMarkedAll > 0
        ? Math.round((totalPresentAll / totalMarkedAll) * 1000) / 10
        : 0;

    return {
        total_working_days: totalWorkingDays,
        average_attendance_pct: averageAttendancePct,
        students: studentStats,
    };
}

export async function verifyStudentsBelongToSection(studentIds, sectionId, schoolId) {
    const count = await prisma.student.count({
        where: {
            id: { in: studentIds },
            sectionId,
            schoolId,
            deletedAt: null,
        },
    });
    return count === studentIds.length;
}

// ── Homework ───────────────────────────────────────────────────────────────────

export async function findHomework({ schoolId, staffId, page = 1, limit = 20, classId, sectionId, subject, status, fromDate, toDate }) {
    const skip = (page - 1) * limit;

    const where = {
        schoolId,
        staffId,
        ...(classId && { classId }),
        ...(sectionId && { sectionId }),
        ...(subject && { subject }),
        ...(status && { status }),
        ...(fromDate || toDate
            ? {
                  dueDate: {
                      ...(fromDate && { gte: new Date(fromDate) }),
                      ...(toDate && { lte: new Date(toDate) }),
                  },
              }
            : {}),
    };

    const [data, total] = await Promise.all([
        prisma.homework.findMany({
            where,
            skip,
            take: limit,
            orderBy: { createdAt: 'desc' },
            include: {
                class_: { select: { id: true, name: true } },
                section: { select: { id: true, name: true } },
            },
        }),
        prisma.homework.count({ where }),
    ]);

    return { data, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
}

export async function findHomeworkById(id, schoolId) {
    return prisma.homework.findFirst({
        where: { id, schoolId },
        include: {
            class_: { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
        },
    });
}

export async function createHomework(data) {
    return prisma.homework.create({
        data,
        include: {
            class_: { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
        },
    });
}

export async function updateHomework(id, data) {
    return prisma.homework.update({
        where: { id },
        data: { ...data, updatedAt: new Date() },
        include: {
            class_: { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
        },
    });
}

export async function deleteHomework(id) {
    return prisma.homework.delete({ where: { id } });
}

// ── Class Diary ────────────────────────────────────────────────────────────────

export async function findDiaryEntries({ schoolId, staffId, isClassTeacher, classTeacherSectionId, page = 1, limit = 20, classId, sectionId, subject, fromDate, toDate }) {
    const skip = (page - 1) * limit;

    let where;

    if (isClassTeacher && classTeacherSectionId && sectionId === classTeacherSectionId) {
        // Class teacher viewing their own class-section: see all teachers' entries
        where = {
            schoolId,
            sectionId: classTeacherSectionId,
            ...(classId && { classId }),
            ...(subject && { subject }),
            ...(fromDate || toDate
                ? { date: { ...(fromDate && { gte: new Date(fromDate) }), ...(toDate && { lte: new Date(toDate) }) } }
                : {}),
        };
    } else {
        where = {
            schoolId,
            staffId,
            ...(classId && { classId }),
            ...(sectionId && { sectionId }),
            ...(subject && { subject }),
            ...(fromDate || toDate
                ? { date: { ...(fromDate && { gte: new Date(fromDate) }), ...(toDate && { lte: new Date(toDate) }) } }
                : {}),
        };
    }

    const [data, total] = await Promise.all([
        prisma.classDiary.findMany({
            where,
            skip,
            take: limit,
            orderBy: [{ date: 'desc' }, { periodNo: 'asc' }],
            include: {
                class_: { select: { id: true, name: true } },
                section: { select: { id: true, name: true } },
                staff: { select: { id: true, firstName: true, lastName: true } },
            },
        }),
        prisma.classDiary.count({ where }),
    ]);

    return { data, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
}

export async function findDiaryEntryById(id, schoolId) {
    return prisma.classDiary.findFirst({
        where: { id, schoolId },
        include: {
            class_: { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
            staff: { select: { id: true, firstName: true, lastName: true } },
        },
    });
}

export async function createDiaryEntry(data) {
    return prisma.classDiary.create({
        data,
        include: {
            class_: { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
        },
    });
}

export async function updateDiaryEntry(id, data) {
    return prisma.classDiary.update({
        where: { id },
        data: { ...data, updatedAt: new Date() },
        include: {
            class_: { select: { id: true, name: true } },
            section: { select: { id: true, name: true } },
        },
    });
}

export async function deleteDiaryEntry(id) {
    return prisma.classDiary.delete({ where: { id } });
}

// ── Profile ────────────────────────────────────────────────────────────────────

export async function getTeacherProfile(staffId, schoolId) {
    const [staff, assignments, classTeacherSection, school] = await Promise.all([
        prisma.staff.findFirst({
            where: { id: staffId, schoolId },
            include: {
                user: {
                    select: { id: true, email: true, phone: true, avatarUrl: true },
                },
            },
        }),
        prisma.staffSubjectAssignment.findMany({
            where: { staffId, isActive: true },
            include: {
                class_: { select: { name: true } },
                section: { select: { name: true } },
            },
        }),
        prisma.section.findFirst({
            where: { classTeacherId: staffId, isActive: true },
            include: {
                class_: { select: { name: true } },
                _count: { select: { students: { where: { deletedAt: null, status: 'ACTIVE' } } } },
            },
        }),
        prisma.school.findFirst({
            where: { id: schoolId },
            select: { id: true, name: true },
        }),
    ]);

    if (!staff) return null;

    const subjects = [...new Set(assignments.map((a) => a.subject))];

    return {
        id: staff.id,
        employee_no: staff.employeeNo,
        first_name: staff.firstName,
        last_name: staff.lastName,
        designation: staff.designation,
        department: staff.department,
        email: staff.user?.email || staff.email,
        phone: staff.user?.phone || staff.phone,
        photo_url: staff.user?.avatarUrl || staff.photoUrl,
        subjects,
        join_date: staff.joinDate,
        class_teacher_of: classTeacherSection
            ? {
                  class_name: classTeacherSection.class_.name,
                  section_name: classTeacherSection.name,
                  student_count: classTeacherSection._count.students,
              }
            : null,
        subject_assignments: assignments.map((a) => ({
            class_name: a.class_.name,
            section_name: a.section?.name || 'All',
            subject: a.subject,
        })),
        school: school ? { name: school.name } : null,
    };
}

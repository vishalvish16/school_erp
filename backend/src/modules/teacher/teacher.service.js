/**
 * Teacher Service — business logic for all teacher portal routes.
 * All methods receive schoolId from req.teacher.schoolId (never from user input).
 */
import { AppError } from '../../utils/response.js';
import * as repo from './teacher.repository.js';
import * as auditService from '../audit/audit.service.js';
import { canAccessSection } from '../../middleware/teacher-guard.middleware.js';

const ATTENDANCE_EDIT_DAYS = 3;
const DIARY_EDIT_DAYS = 7;

function startOfDay(d) {
    const dt = new Date(d);
    dt.setHours(0, 0, 0, 0);
    return dt;
}

function daysBetween(d1, d2) {
    const ms = Math.abs(startOfDay(d1) - startOfDay(d2));
    return Math.floor(ms / (1000 * 60 * 60 * 24));
}

// ── Dashboard ──────────────────────────────────────────────────────────────────

export async function getDashboard({ schoolId, teacher, teacherSections, classTeacherSection }) {
    if (!schoolId) throw new AppError('School context required', 400);

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const dayOfWeek = today.getDay();

    const sectionIds = [
        ...new Set([
            ...teacherSections.map((s) => s.sectionId).filter(Boolean),
            ...(classTeacherSection ? [classTeacherSection.sectionId] : []),
        ]),
    ];

    const [schedule, totalStudents, markedSectionIds, activeHomework, homeworkDueThisWeek, classTeacherInfo] =
        await Promise.all([
            repo.getTodaySchedule(schoolId, teacher.id, dayOfWeek),
            repo.countStudentsInSections(sectionIds),
            repo.countAttendanceMarkedToday(schoolId, teacher.id, today),
            repo.countActiveHomework(schoolId, teacher.id),
            repo.countHomeworkDueThisWeek(schoolId, teacher.id),
            repo.getClassTeacherInfo(teacher.id),
        ]);

    const todaySchedule = schedule.map((t) => ({
        period_no: t.periodNo,
        subject: t.subject,
        class_name: t.class_?.name,
        section_name: t.section?.name,
        start_time: t.startTime,
        end_time: t.endTime,
        room: t.room,
    }));

    const pendingSectionIds = sectionIds.filter((id) => !markedSectionIds.includes(id));
    const attendancePendingToday = pendingSectionIds.length;

    const pendingActions = [];
    for (const sid of pendingSectionIds) {
        const sectionInfo = teacherSections.find((s) => s.sectionId === sid);
        if (sectionInfo) {
            const sectionDetail = await repo.getSectionWithClass(sid, schoolId);
            if (sectionDetail) {
                pendingActions.push({
                    type: 'ATTENDANCE_PENDING',
                    label: `Mark attendance for ${sectionDetail.class_?.name}-${sectionDetail.name}`,
                    class_id: sectionDetail.classId,
                    section_id: sid,
                });
            }
        }
    }

    if (classTeacherSection && !markedSectionIds.includes(classTeacherSection.sectionId)) {
        const existing = pendingActions.find((a) => a.section_id === classTeacherSection.sectionId);
        if (!existing) {
            const sectionDetail = await repo.getSectionWithClass(classTeacherSection.sectionId, schoolId);
            if (sectionDetail) {
                pendingActions.push({
                    type: 'ATTENDANCE_PENDING',
                    label: `Mark attendance for ${sectionDetail.class_?.name}-${sectionDetail.name}`,
                    class_id: sectionDetail.classId,
                    section_id: classTeacherSection.sectionId,
                });
            }
        }
    }

    return {
        teacher: {
            id: teacher.id,
            name: `${teacher.firstName} ${teacher.lastName}`,
            designation: teacher.designation,
            employee_no: teacher.employeeNo,
            photo_url: teacher.photoUrl,
        },
        today_schedule: todaySchedule,
        stats: {
            total_sections: sectionIds.length,
            total_students: totalStudents,
            attendance_pending_today: attendancePendingToday,
            homework_active: activeHomework,
            homework_due_this_week: homeworkDueThisWeek,
        },
        pending_actions: pendingActions,
        class_teacher_of: classTeacherInfo,
    };
}

// ── Sections ───────────────────────────────────────────────────────────────────

export async function getSections({ staffId }) {
    return repo.getTeacherSections(staffId);
}

// ── Attendance ─────────────────────────────────────────────────────────────────

export async function getAttendance({ schoolId, req, sectionId, date }) {
    if (!sectionId) throw new AppError('sectionId query parameter is required', 400);

    if (!canAccessSection(req, sectionId)) {
        throw new AppError('You are not assigned to this section', 403);
    }

    const targetDate = date ? startOfDay(new Date(date)) : startOfDay(new Date());
    const isLocked = daysBetween(new Date(), targetDate) > ATTENDANCE_EDIT_DAYS;

    const sectionDetail = await repo.getSectionWithClass(sectionId, schoolId);
    if (!sectionDetail) throw new AppError('Section not found', 404);

    const [students, records] = await Promise.all([
        repo.getStudentsBySection(sectionId, schoolId),
        repo.getAttendanceBySection(sectionId, schoolId, targetDate),
    ]);

    const attendanceMap = {};
    for (const r of records) {
        attendanceMap[r.studentId] = { status: r.status, remarks: r.remarks };
    }

    let present = 0, absent = 0, late = 0, halfDay = 0, notMarked = 0;
    const studentList = students.map((st) => {
        const att = attendanceMap[st.id];
        if (!att) { notMarked++; }
        else {
            switch (att.status) {
                case 'PRESENT': present++; break;
                case 'ABSENT': absent++; break;
                case 'LATE': late++; break;
                case 'HALF_DAY': halfDay++; break;
            }
        }
        return {
            student_id: st.id,
            admission_no: st.admissionNo,
            name: `${st.firstName} ${st.lastName}`,
            roll_no: st.rollNo,
            status: att?.status || null,
            remarks: att?.remarks || null,
        };
    });

    return {
        section_id: sectionId,
        class_name: sectionDetail.class_?.name,
        section_name: sectionDetail.name,
        date: targetDate.toISOString().split('T')[0],
        is_locked: isLocked,
        summary: {
            total: students.length,
            present,
            absent,
            late,
            half_day: halfDay,
            not_marked: notMarked,
        },
        students: studentList,
    };
}

export async function markAttendance({ schoolId, req, userId, staffId, sectionId, date, records }) {
    if (!canAccessSection(req, sectionId)) {
        throw new AppError('You are not assigned to this section', 403);
    }

    const targetDate = startOfDay(new Date(date));
    if (daysBetween(new Date(), targetDate) > ATTENDANCE_EDIT_DAYS) {
        throw new AppError(`Attendance can only be marked for today and the previous ${ATTENDANCE_EDIT_DAYS} days`, 400);
    }

    if (targetDate > startOfDay(new Date())) {
        throw new AppError('Cannot mark attendance for a future date', 400);
    }

    const studentIds = records.map((r) => r.student_id);
    const validStudents = await repo.verifyStudentsBelongToSection(studentIds, sectionId, schoolId);
    if (!validStudents) {
        throw new AppError('One or more students do not belong to this section', 400);
    }

    let marked = 0;
    let updated = 0;

    for (const record of records) {
        const existing = await repo.getAttendanceBySection(sectionId, schoolId, targetDate);
        const hadExisting = existing.some((e) => e.studentId === record.student_id);

        await repo.upsertAttendance({
            schoolId,
            sectionId,
            date: targetDate,
            studentId: record.student_id,
            status: record.status,
            markedBy: userId,
            remarks: record.remarks,
        });

        if (hadExisting) updated++;
        else marked++;
    }

    auditService.logAudit({
        actorId: userId,
        actorRole: 'teacher',
        action: 'ATTENDANCE_MARK',
        entityType: 'attendances',
        entityId: sectionId,
        entityName: `Attendance for section ${sectionId}`,
        extra: { schoolId, sectionId, date, count: records.length },
    }).catch(() => {});

    return { marked, updated, date: targetDate.toISOString().split('T')[0], section_id: sectionId };
}

export async function getAttendanceReport({ schoolId, req, sectionId, fromDate, toDate }) {
    if (!sectionId) throw new AppError('sectionId query parameter is required', 400);

    if (!canAccessSection(req, sectionId)) {
        throw new AppError('You are not assigned to this section', 403);
    }

    const sectionDetail = await repo.getSectionWithClass(sectionId, schoolId);
    if (!sectionDetail) throw new AppError('Section not found', 404);

    const today = new Date();
    const defaultFrom = new Date(today.getFullYear(), today.getMonth(), 1);
    const from = fromDate ? startOfDay(new Date(fromDate)) : startOfDay(defaultFrom);
    const to = toDate ? startOfDay(new Date(toDate)) : startOfDay(today);

    const report = await repo.getAttendanceReport({
        sectionId,
        schoolId,
        fromDate: from,
        toDate: to,
    });

    return {
        section_id: sectionId,
        class_name: sectionDetail.class_?.name,
        section_name: sectionDetail.name,
        from_date: from.toISOString().split('T')[0],
        to_date: to.toISOString().split('T')[0],
        summary: {
            total_working_days: report.total_working_days,
            average_attendance_pct: report.average_attendance_pct,
        },
        students: report.students,
    };
}

// ── Homework ───────────────────────────────────────────────────────────────────

export async function getHomework({ schoolId, staffId, page, limit, classId, sectionId, subject, status, fromDate, toDate }) {
    return repo.findHomework({ schoolId, staffId, page, limit, classId, sectionId, subject, status, fromDate, toDate });
}

export async function getHomeworkById({ id, schoolId, staffId }) {
    const hw = await repo.findHomeworkById(id, schoolId);
    if (!hw) throw new AppError('Homework not found', 404);
    if (hw.staffId !== staffId) throw new AppError('You can only view your own homework', 403);
    return formatHomework(hw);
}

export async function createHomework({ schoolId, staffId, userId, req, data }) {
    if (!canAccessSection(req, data.section_id)) {
        throw new AppError('You are not assigned to this section for this subject', 403);
    }

    const hasSubject = req.teacherSections.some(
        (s) => s.sectionId === data.section_id && s.subject === data.subject
    );
    if (!hasSubject && req.classTeacherSection?.sectionId !== data.section_id) {
        throw new AppError('You are not assigned to teach this subject in this section', 403);
    }

    const today = startOfDay(new Date());
    const dueDate = startOfDay(new Date(data.due_date));
    if (dueDate < today) {
        throw new AppError('Due date must be today or in the future', 400);
    }

    const hw = await repo.createHomework({
        schoolId,
        staffId,
        classId: data.class_id,
        sectionId: data.section_id || null,
        subject: data.subject,
        title: data.title,
        description: data.description || null,
        assignedDate: today,
        dueDate,
        attachmentUrls: data.attachment_urls || [],
        status: 'ACTIVE',
    });

    auditService.logAudit({
        actorId: userId,
        actorRole: 'teacher',
        action: 'HOMEWORK_CREATE',
        entityType: 'homework',
        entityId: hw.id,
        entityName: data.title,
        extra: { schoolId, classId: data.class_id, sectionId: data.section_id },
    }).catch(() => {});

    return formatHomework(hw);
}

export async function updateHomework({ id, schoolId, staffId, userId, data }) {
    const hw = await repo.findHomeworkById(id, schoolId);
    if (!hw) throw new AppError('Homework not found', 404);
    if (hw.staffId !== staffId) throw new AppError('You can only edit your own homework', 403);
    if (hw.status === 'CANCELLED') throw new AppError('Cannot edit cancelled homework', 400);

    const updateData = {};
    if (data.title !== undefined) updateData.title = data.title;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.due_date !== undefined) updateData.dueDate = new Date(data.due_date);
    if (data.attachment_urls !== undefined) updateData.attachmentUrls = data.attachment_urls;

    const updated = await repo.updateHomework(id, updateData);

    auditService.logAudit({
        actorId: userId,
        actorRole: 'teacher',
        action: 'HOMEWORK_UPDATE',
        entityType: 'homework',
        entityId: id,
        entityName: updated.title,
        extra: { schoolId },
    }).catch(() => {});

    return formatHomework(updated);
}

export async function updateHomeworkStatus({ id, schoolId, staffId, userId, status }) {
    const hw = await repo.findHomeworkById(id, schoolId);
    if (!hw) throw new AppError('Homework not found', 404);
    if (hw.staffId !== staffId) throw new AppError('You can only modify your own homework', 403);

    const updated = await repo.updateHomework(id, { status });

    auditService.logAudit({
        actorId: userId,
        actorRole: 'teacher',
        action: 'HOMEWORK_STATUS_CHANGE',
        entityType: 'homework',
        entityId: id,
        entityName: hw.title,
        extra: { schoolId, oldStatus: hw.status, newStatus: status },
    }).catch(() => {});

    return formatHomework(updated);
}

export async function deleteHomework({ id, schoolId, staffId, userId }) {
    const hw = await repo.findHomeworkById(id, schoolId);
    if (!hw) throw new AppError('Homework not found', 404);
    if (hw.staffId !== staffId) throw new AppError('You can only delete your own homework', 403);

    const today = startOfDay(new Date());
    if (startOfDay(hw.dueDate) < today) {
        throw new AppError('Cannot delete homework after the due date has passed. Use status change to CANCELLED instead.', 400);
    }

    await repo.deleteHomework(id);

    auditService.logAudit({
        actorId: userId,
        actorRole: 'teacher',
        action: 'HOMEWORK_DELETE',
        entityType: 'homework',
        entityId: id,
        entityName: hw.title,
        extra: { schoolId },
    }).catch(() => {});
}

function formatHomework(hw) {
    return {
        id: hw.id,
        subject: hw.subject,
        class_name: hw.class_?.name,
        section_name: hw.section?.name || null,
        title: hw.title,
        description: hw.description,
        assigned_date: hw.assignedDate,
        due_date: hw.dueDate,
        attachment_urls: hw.attachmentUrls,
        status: hw.status,
        created_at: hw.createdAt,
    };
}

// ── Class Diary ────────────────────────────────────────────────────────────────

export async function getDiaryEntries({ schoolId, staffId, classTeacherSection, page, limit, classId, sectionId, subject, fromDate, toDate }) {
    const isClassTeacher = !!classTeacherSection;
    const classTeacherSectionId = classTeacherSection?.sectionId || null;

    return repo.findDiaryEntries({
        schoolId,
        staffId,
        isClassTeacher,
        classTeacherSectionId,
        page,
        limit,
        classId,
        sectionId,
        subject,
        fromDate,
        toDate,
    });
}

export async function createDiaryEntry({ schoolId, staffId, userId, req, data }) {
    if (!canAccessSection(req, data.section_id)) {
        throw new AppError('You are not assigned to this section', 403);
    }

    const hasSubject = req.teacherSections.some(
        (s) => s.sectionId === data.section_id && s.subject === data.subject
    );
    if (!hasSubject && req.classTeacherSection?.sectionId !== data.section_id) {
        throw new AppError('You are not assigned to teach this subject in this section', 403);
    }

    const entryDate = startOfDay(new Date(data.date));
    const today = startOfDay(new Date());
    if (daysBetween(today, entryDate) > DIARY_EDIT_DAYS) {
        throw new AppError(`Diary entries can only be created for dates within the last ${DIARY_EDIT_DAYS} days`, 400);
    }
    if (entryDate > today) {
        throw new AppError('Cannot create a diary entry for a future date', 400);
    }

    const entry = await repo.createDiaryEntry({
        schoolId,
        staffId,
        classId: data.class_id,
        sectionId: data.section_id || null,
        subject: data.subject,
        date: entryDate,
        periodNo: data.period_no || null,
        topicCovered: data.topic_covered,
        description: data.description || null,
        pageFrom: data.page_from || null,
        pageTo: data.page_to || null,
        homeworkGiven: data.homework_given || null,
        remarks: data.remarks || null,
    });

    auditService.logAudit({
        actorId: userId,
        actorRole: 'teacher',
        action: 'DIARY_CREATE',
        entityType: 'class_diary',
        entityId: entry.id,
        entityName: data.topic_covered,
        extra: { schoolId, classId: data.class_id, sectionId: data.section_id },
    }).catch(() => {});

    return formatDiaryEntry(entry);
}

export async function updateDiaryEntry({ id, schoolId, staffId, userId, data }) {
    const entry = await repo.findDiaryEntryById(id, schoolId);
    if (!entry) throw new AppError('Diary entry not found', 404);
    if (entry.staffId !== staffId) throw new AppError('You can only edit your own diary entries', 403);

    const today = startOfDay(new Date());
    if (daysBetween(today, startOfDay(entry.date)) > DIARY_EDIT_DAYS) {
        throw new AppError(`Diary entries can only be edited within ${DIARY_EDIT_DAYS} days of the entry date`, 400);
    }

    const updateData = {};
    if (data.topic_covered !== undefined) updateData.topicCovered = data.topic_covered;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.page_from !== undefined) updateData.pageFrom = data.page_from;
    if (data.page_to !== undefined) updateData.pageTo = data.page_to;
    if (data.homework_given !== undefined) updateData.homeworkGiven = data.homework_given;
    if (data.remarks !== undefined) updateData.remarks = data.remarks;
    if (data.period_no !== undefined) updateData.periodNo = data.period_no;

    const updated = await repo.updateDiaryEntry(id, updateData);

    auditService.logAudit({
        actorId: userId,
        actorRole: 'teacher',
        action: 'DIARY_UPDATE',
        entityType: 'class_diary',
        entityId: id,
        entityName: updated.topicCovered,
        extra: { schoolId },
    }).catch(() => {});

    return formatDiaryEntry(updated);
}

export async function deleteDiaryEntry({ id, schoolId, staffId, userId }) {
    const entry = await repo.findDiaryEntryById(id, schoolId);
    if (!entry) throw new AppError('Diary entry not found', 404);
    if (entry.staffId !== staffId) throw new AppError('You can only delete your own diary entries', 403);

    const today = startOfDay(new Date());
    if (daysBetween(today, startOfDay(entry.date)) > DIARY_EDIT_DAYS) {
        throw new AppError(`Diary entries can only be deleted within ${DIARY_EDIT_DAYS} days of the entry date`, 400);
    }

    await repo.deleteDiaryEntry(id);

    auditService.logAudit({
        actorId: userId,
        actorRole: 'teacher',
        action: 'DIARY_DELETE',
        entityType: 'class_diary',
        entityId: id,
        entityName: entry.topicCovered,
        extra: { schoolId },
    }).catch(() => {});
}

function formatDiaryEntry(entry) {
    return {
        id: entry.id,
        subject: entry.subject,
        class_name: entry.class_?.name,
        section_name: entry.section?.name || null,
        date: entry.date,
        period_no: entry.periodNo,
        topic_covered: entry.topicCovered,
        description: entry.description,
        page_from: entry.pageFrom,
        page_to: entry.pageTo,
        homework_given: entry.homeworkGiven,
        remarks: entry.remarks,
        created_at: entry.createdAt,
        staff_name: entry.staff ? `${entry.staff.firstName} ${entry.staff.lastName}` : undefined,
    };
}

// ── Profile ────────────────────────────────────────────────────────────────────

export async function getProfile({ staffId, schoolId }) {
    const profile = await repo.getTeacherProfile(staffId, schoolId);
    if (!profile) throw new AppError('Teacher profile not found', 404);
    return profile;
}

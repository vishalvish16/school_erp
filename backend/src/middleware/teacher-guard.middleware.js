/**
 * Middleware: Restrict access to Teacher portal only.
 * Performs a live DB lookup to ensure the Staff record is active, not deleted,
 * and has a teaching designation (TEACHER, PRINCIPAL, VICE_PRINCIPAL, HOD).
 *
 * Attaches:
 *   req.teacher          — Staff record
 *   req.teacherSections  — [{classId, sectionId, subject}] from active subject assignments
 *   req.classTeacherSection — {classId, sectionId} | null
 *
 * All downstream queries MUST use req.teacher.schoolId for tenant isolation.
 */
import { PrismaClient } from '@prisma/client';
import { AppError } from '../utils/response.js';

const prisma = new PrismaClient();

const TEACHING_DESIGNATIONS = ['TEACHER', 'PRINCIPAL', 'VICE_PRINCIPAL', 'HOD'];

export const requireTeacher = async (req, res, next) => {
    try {
        if (!req.user) {
            return next(new AppError('Authentication required', 401));
        }

        const userId = req.user.userId || req.user.id;
        if (!userId) {
            return next(new AppError('Invalid token payload. Please log in again.', 403));
        }

        const staffRecord = await prisma.staff.findFirst({
            where: {
                userId,
                deletedAt: null,
                isActive: true,
            },
        });

        if (!staffRecord) {
            return next(new AppError('Teacher access required', 403));
        }

        if (!TEACHING_DESIGNATIONS.includes(staffRecord.designation)) {
            return next(new AppError('Teacher access required', 403));
        }

        req.teacher = staffRecord;
        req.user.school_id = staffRecord.schoolId;

        const [assignments, classTeacherSection] = await Promise.all([
            prisma.staffSubjectAssignment.findMany({
                where: {
                    staffId: staffRecord.id,
                    isActive: true,
                },
                select: {
                    classId: true,
                    sectionId: true,
                    subject: true,
                },
            }),
            prisma.section.findFirst({
                where: {
                    classTeacherId: staffRecord.id,
                    isActive: true,
                },
                select: {
                    id: true,
                    classId: true,
                },
            }),
        ]);

        req.teacherSections = assignments.map((a) => ({
            classId: a.classId,
            sectionId: a.sectionId,
            subject: a.subject,
        }));

        req.classTeacherSection = classTeacherSection
            ? { classId: classTeacherSection.classId, sectionId: classTeacherSection.id }
            : null;

        next();
    } catch (error) {
        next(error);
    }
};

/**
 * Check whether the current teacher can access a specific section.
 * A teacher can access a section if they have an active subject assignment for it,
 * or if they are the class teacher of that section.
 */
export const canAccessSection = (req, sectionId) => {
    return (
        req.teacherSections.some((s) => s.sectionId === sectionId) ||
        req.classTeacherSection?.sectionId === sectionId
    );
};

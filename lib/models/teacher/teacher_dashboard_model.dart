class TeacherDashboardModel {
  final TeacherInfo teacher;
  final List<SchedulePeriod> todaySchedule;
  final TeacherStats stats;
  final List<PendingAction> pendingActions;
  final ClassTeacherInfo? classTeacherOf;

  const TeacherDashboardModel({
    required this.teacher,
    this.todaySchedule = const [],
    required this.stats,
    this.pendingActions = const [],
    this.classTeacherOf,
  });

  factory TeacherDashboardModel.fromJson(Map<String, dynamic> json) {
    final scheduleRaw = json['today_schedule'];
    final schedule = scheduleRaw is List
        ? scheduleRaw
            .map((e) =>
                SchedulePeriod.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList()
        : <SchedulePeriod>[];

    final actionsRaw = json['pending_actions'];
    final actions = actionsRaw is List
        ? actionsRaw
            .map((e) =>
                PendingAction.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList()
        : <PendingAction>[];

    return TeacherDashboardModel(
      teacher: TeacherInfo.fromJson(
        json['teacher'] is Map<String, dynamic>
            ? json['teacher'] as Map<String, dynamic>
            : {},
      ),
      todaySchedule: schedule,
      stats: TeacherStats.fromJson(
        json['stats'] is Map<String, dynamic>
            ? json['stats'] as Map<String, dynamic>
            : {},
      ),
      pendingActions: actions,
      classTeacherOf: json['class_teacher_of'] is Map<String, dynamic>
          ? ClassTeacherInfo.fromJson(
              json['class_teacher_of'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TeacherInfo {
  final String id;
  final String name;
  final String designation;
  final String employeeNo;
  final String? photoUrl;

  const TeacherInfo({
    required this.id,
    required this.name,
    required this.designation,
    required this.employeeNo,
    this.photoUrl,
  });

  factory TeacherInfo.fromJson(Map<String, dynamic> json) {
    return TeacherInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      employeeNo: json['employee_no'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class SchedulePeriod {
  final int periodNo;
  final String subject;
  final String className;
  final String sectionName;
  final String startTime;
  final String endTime;
  final String? room;

  const SchedulePeriod({
    required this.periodNo,
    required this.subject,
    required this.className,
    required this.sectionName,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  factory SchedulePeriod.fromJson(Map<String, dynamic> json) {
    return SchedulePeriod(
      periodNo: (json['period_no'] as num?)?.toInt() ?? 0,
      subject: json['subject'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      room: json['room'] as String?,
    );
  }
}

class TeacherStats {
  final int totalSections;
  final int totalStudents;
  final int attendancePendingToday;
  final int homeworkActive;
  final int homeworkDueThisWeek;

  const TeacherStats({
    this.totalSections = 0,
    this.totalStudents = 0,
    this.attendancePendingToday = 0,
    this.homeworkActive = 0,
    this.homeworkDueThisWeek = 0,
  });

  factory TeacherStats.fromJson(Map<String, dynamic> json) {
    return TeacherStats(
      totalSections: (json['total_sections'] as num?)?.toInt() ?? 0,
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      attendancePendingToday:
          (json['attendance_pending_today'] as num?)?.toInt() ?? 0,
      homeworkActive: (json['homework_active'] as num?)?.toInt() ?? 0,
      homeworkDueThisWeek:
          (json['homework_due_this_week'] as num?)?.toInt() ?? 0,
    );
  }
}

class PendingAction {
  final String type;
  final String label;
  final String? classId;
  final String? sectionId;

  const PendingAction({
    required this.type,
    required this.label,
    this.classId,
    this.sectionId,
  });

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      classId: json['class_id'] as String?,
      sectionId: json['section_id'] as String?,
    );
  }
}

class ClassTeacherInfo {
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final int studentCount;

  const ClassTeacherInfo({
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    this.studentCount = 0,
  });

  factory ClassTeacherInfo.fromJson(Map<String, dynamic> json) {
    return ClassTeacherInfo(
      classId: json['class_id'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      sectionId: json['section_id'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
    );
  }
}

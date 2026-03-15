import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/teacher_service.dart';
import '../../../../models/teacher/teacher_dashboard_model.dart';

final teacherDashboardProvider =
    FutureProvider.autoDispose<TeacherDashboardModel>((ref) {
  return ref.read(teacherServiceProvider).getDashboard();
});

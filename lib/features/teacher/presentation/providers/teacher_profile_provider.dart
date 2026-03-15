import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/teacher_service.dart';
import '../../../../models/teacher/teacher_profile_model.dart';

final teacherProfileProvider =
    FutureProvider.autoDispose<TeacherProfileModel>((ref) {
  return ref.read(teacherServiceProvider).getProfile();
});

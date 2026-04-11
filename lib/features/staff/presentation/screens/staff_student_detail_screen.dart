// =============================================================================
// FILE: lib/features/staff/presentation/screens/staff_student_detail_screen.dart
// PURPOSE: Staff portal student detail — reuses SchoolAdminStudentDetailScreen
//          with a different API base path for staff-scoped endpoints.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../school_admin/presentation/screens/school_admin_student_detail_screen.dart';

class StaffStudentDetailScreen extends StatelessWidget {
  const StaffStudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    return SchoolAdminStudentDetailScreen(
      studentId: studentId,
      basePath: '/api/staff/students',
      backPath: '/staff/students',
    );
  }
}

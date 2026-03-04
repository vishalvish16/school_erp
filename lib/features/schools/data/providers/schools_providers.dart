import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../repositories/schools_repository.dart';

// Exposes testable independent API Layer implementation injected with mockable authenticated Dio
final schoolsRepositoryProvider = Provider<ISchoolsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SchoolsRepository(dio);
});

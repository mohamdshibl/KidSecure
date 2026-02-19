import 'package:kidsecure/features/admin/domain/models/admin_stats.dart';

abstract class StatsRepository {
  Stream<AdminStats> getStats();
}

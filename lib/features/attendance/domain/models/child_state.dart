import 'attendance_record.dart';

enum ChildState { inSchool, leftSchool, onBus, absent, unknown }

extension ChildStateResolver on Iterable<AttendanceRecord> {
  ChildState resolveChildState() {
    if (isEmpty) {
      return ChildState.unknown;
    }

    // Force a local sort by timestamp descending to guarantee we get the absolute latest record
    final sortedRecords = toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final latest = sortedRecords.first;
    final latestStatus = latest.status;

    switch (latestStatus) {
      case AttendanceStatus.checkIn:
        return latest.busId != null ? ChildState.onBus : ChildState.inSchool;
      case AttendanceStatus.checkOut:
        return ChildState.leftSchool;
      case AttendanceStatus.absent:
        return ChildState.absent;
    }
  }
}

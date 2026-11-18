import 'package:flutter/material.dart';

class ScheduleItem {
  final String id;
  final String subject;
  final String subjectCode;
  final String instructor;
  final String room;
  final int dayOfWeek; // 1 = Monday … 7 = Sunday (DateTime.weekday)
  final String startTime; // 24-hour "HH:mm"
  final String endTime; // 24-hour "HH:mm"
  final int reminderMinutesBefore;

  const ScheduleItem({
    required this.id,
    required this.subject,
    required this.subjectCode,
    required this.instructor,
    required this.room,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.reminderMinutesBefore = 10,
  });

  static int _parse(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  /// Minutes since midnight.
  int get startMinutes => _parse(startTime);
  int get endMinutes => _parse(endTime);

  /// Notification ids must be ints; ids in the seed data are numeric strings.
  int get notificationId => int.parse(id);

  static String format(int minutes) {
    var h = minutes ~/ 60;
    final m = (minutes % 60).toString().padLeft(2, '0');
    final ap = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:$m $ap';
  }

  String get timeRange => '${format(startMinutes)} – ${format(endMinutes)}';

  static const palette = [
    Color(0xFF2F4BD8),
    Color(0xFF0E8F6E),
    Color(0xFFC2410C),
    Color(0xFF8B3FC4),
    Color(0xFFB4236B),
    Color(0xFF0F7C96),
  ];

  /// Same subject code always gets the same color.
  Color get color =>
      palette[subjectCode.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length];
}

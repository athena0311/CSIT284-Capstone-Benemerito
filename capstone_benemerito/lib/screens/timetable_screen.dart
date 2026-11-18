import 'package:flutter/material.dart';

import 'package:capstone_benemerito/data/dummy_items.dart';
import 'package:capstone_benemerito/models/schedule_item.dart';

/// Weekly Monday–Friday grid, 7 AM to 6 PM.
class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  static const int startHour = 7;
  static const int endHour = 18;
  static const double hourHeight = 56;
  static const double axisWidth = 48;
  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final todayWeekday = DateTime.now().weekday;
    final totalHeight = (endHour - startHour) * hourHeight;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly timetable')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: axisWidth),
                for (var d = 1; d <= 6; d++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _labels[d - 1],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: d == todayWeekday ? scheme.primary : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: axisWidth,
                  height: totalHeight,
                  child: Stack(
                    children: [
                      for (var h = startHour; h <= endHour; h++)
                        Positioned(
                          top: (h - startHour) * hourHeight - 7,
                          right: 6,
                          child: Text(
                            ScheduleItem.format(h * 60).replaceAll(':00', ''),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                ),
                for (var d = 1; d <= 6; d++)
                  Expanded(
                      child: _DayColumn(
                          weekday: d,
                          isToday: d == todayWeekday,
                          height: totalHeight)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn(
      {required this.weekday, required this.isToday, required this.height});

  final int weekday;
  final bool isToday;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = dummySchedules.where((x) => x.dayOfWeek == weekday);
    const hh = TimetableScreen.hourHeight;
    const sh = TimetableScreen.startHour;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isToday ? scheme.primaryContainer.withOpacity(.35) : null,
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Stack(
        children: [
          for (var h = 0; h < TimetableScreen.endHour - sh; h++)
            Positioned(
              top: h * hh,
              left: 0,
              right: 0,
              child: Divider(height: 1, color: Theme.of(context).dividerColor),
            ),
          for (final i in items)
            Positioned(
              top: (i.startMinutes - sh * 60) / 60 * hh,
              left: 2,
              right: 2,
              height: (i.endMinutes - i.startMinutes) / 60 * hh - 2,
              child: Tooltip(
                message: '${i.subject}\n${i.timeRange}\n${i.room}',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: i.color, borderRadius: BorderRadius.circular(6)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i.subjectCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      Text(i.room,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

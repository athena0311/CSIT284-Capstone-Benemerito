import 'dart:async';

import 'package:flutter/material.dart';

import 'package:capstone_benemerito/data/dummy_items.dart';
import 'package:capstone_benemerito/models/schedule_item.dart';
import 'package:capstone_benemerito/screens/timetable_screen.dart';

const _dayNames = [
  '',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _monthNames = [
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _nextClassText(int weekday) {
    for (var i = 1; i <= 7; i++) {
      final d = (weekday - 1 + i) % 7 + 1;
      final list = dummySchedules.where((x) => x.dayOfWeek == d).toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      if (list.isNotEmpty) {
        final when = i == 1 ? 'tomorrow' : _dayNames[d];
        return 'Next class: $when at ${ScheduleItem.format(list.first.startMinutes)} (${list.first.subjectCode})';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final today =
        dummySchedules.where((x) => x.dayOfWeek == now.weekday).toList()
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    ScheduleItem? current;
    ScheduleItem? next;
    for (final i in today) {
      if (minutes >= i.startMinutes && minutes < i.endMinutes) {
        current = i;
      } else if (minutes < i.startMinutes && next == null) {
        next = i;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BSIT - 3'),
        actions: [
          IconButton(
            tooltip: 'Weekly timetable',
            icon: const Icon(Icons.calendar_view_week),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TimetableScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${_dayNames[now.weekday]}, ${_monthNames[now.month]} ${now.day}',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _StatusCard(
            current: current,
            next: next,
            minutes: minutes,
            emptyText: today.isEmpty
                ? 'No classes today'
                : 'No more classes today',
            nextDayText: _nextClassText(now.weekday),
          ),
          const SizedBox(height: 14),
          if (today.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nothing scheduled. Open the weekly view to plan ahead.',
                ),
              ),
            )
          else
            for (final item in today)
              _ClassTile(
                item: item,
                isPast: minutes >= item.endMinutes,
                isNow: item == current,
              ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.current,
    required this.next,
    required this.minutes,
    required this.emptyText,
    required this.nextDayText,
  });

  final ScheduleItem? current;
  final ScheduleItem? next;
  final int minutes;
  final String emptyText;
  final String nextDayText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String label, title, sub;
    double? progress;

    if (current != null) {
      final c = current!;
      label = 'In class now';
      title = c.subject;
      sub = '${c.room} · ends in ${c.endMinutes - minutes} min';
      progress = (minutes - c.startMinutes) / (c.endMinutes - c.startMinutes);
    } else if (next != null) {
      final n = next!;
      label = 'Up next';
      title = n.subject;
      sub =
          '${ScheduleItem.format(n.startMinutes)} · ${n.room} · in ${n.startMinutes - minutes} min';
    } else {
      label = 'Free';
      title = emptyText;
      sub = nextDayText;
    }

    return Card(
      color: scheme.inverseSurface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: scheme.onInverseSurface.withOpacity(.75)),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: scheme.onInverseSurface,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(color: scheme.onInverseSurface.withOpacity(.85)),
            ),
            if (progress != null) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: progress.clamp(0, 1),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({
    required this.item,
    required this.isPast,
    required this.isNow,
  });

  final ScheduleItem item;
  final bool isPast;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isPast ? .5 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isNow ? item.color : Theme.of(context).dividerColor,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: item.color),
              Expanded(
                child: ListTile(
                  title: Text(
                    item.subject,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${item.timeRange}\n${item.subjectCode} · ${item.room} · ${item.instructor}',
                  ),
                  isThreeLine: true,
                  trailing: isNow
                      ? Chip(
                          label: const Text('Now'),
                          backgroundColor: item.color,
                          labelStyle: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

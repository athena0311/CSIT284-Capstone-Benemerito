import 'dart:async';

import 'package:flutter/material.dart';

import 'package:capstone_benemerito/data/schedule_repository.dart';
import 'package:capstone_benemerito/screens/class_form_screen.dart';
import 'package:capstone_benemerito/models/schedule_item.dart';
import 'package:capstone_benemerito/services/notification_service.dart';
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

/// Spacing scale used across this screen (8 / 16 / 24).
const double _s1 = 8;
const double _s2 = 16;
const double _s3 = 24;

/// Screens at least this wide (maximized browser, tablet landscape) switch to
/// a two-column layout: status card on the left, schedule list on the right.
const double _wideBreakpoint = 900;

/// 158 -> "2 h 38 min", 45 -> "45 min", 120 -> "2 h".
String _formatDuration(int minutes) {
  final total = minutes < 0 ? 0 : minutes;
  final h = total ~/ 60;
  final m = total % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h $m min';
}

int _shiftDay(int weekday, int delta) => (weekday - 1 + delta + 7) % 7 + 1;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  StreamSubscription<List<ScheduleItem>>? _sub;
  bool _remind = false;

  /// Classes loaded live from Firestore.
  List<ScheduleItem> _items = [];
  bool _loading = true;
  Object? _error;

  /// Weekday the user navigated to (1 = Mon … 7 = Sun). Null = follow today.
  int? _pickedDay;

  @override
  void initState() {
    super.initState();
    // Refresh every 30 s so "ends in X" and the progress bar stay live.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });

    // Listen to Firestore: emits again whenever the data changes.
    _sub = ScheduleRepository.instance.watchAll().listen(
      (items) {
        if (!mounted) return;
        setState(() {
          _items = items;
          _loading = false;
          _error = null;
        });
        // Keep reminders in sync with the latest data.
        if (_remind) NotificationService.instance.scheduleWeekly(items);
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _error = e;
          _loading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _toggleReminders(bool on) async {
    final svc = NotificationService.instance;
    if (!on) {
      await svc.cancelAll();
      setState(() => _remind = false);
      return;
    }
    final ok = await svc.requestPermission();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Allow notifications in Settings to get reminders.'),
        ),
      );
      return;
    }
    await svc.scheduleWeekly(_items);
    if (mounted) setState(() => _remind = true);
  }

  void _goToDay(int delta, int shown, int todayWeekday) {
    final next = _shiftDay(shown, delta);
    setState(() => _pickedDay = next == todayWeekday ? null : next);
  }

  String _nextClassText(int weekday) {
    for (var i = 1; i <= 7; i++) {
      final d = (weekday - 1 + i) % 7 + 1;
      final list = schedulesForDay(_items, d);
      if (list.isNotEmpty) {
        final when = i == 1 ? 'tomorrow' : _dayNames[d];
        return 'Next class: $when at ${ScheduleItem.format(list.first.startMinutes)} (${list.first.subjectCode})';
      }
    }
    return '';
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Opens the add / edit form. The form pops with a status message.
  Future<void> _openForm({ScheduleItem? item}) async {
    final day = _pickedDay ?? DateTime.now().weekday;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ClassFormScreen(item: item, initialDay: day),
      ),
    );
    if (!mounted || result == null) return;
    _snack(result);
  }

  Future<void> _confirmDelete(ScheduleItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete class?'),
        content: Text(
          '"${item.subject}" on ${_dayNames[item.dayOfWeek]} will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ScheduleRepository.instance.delete(item.id);
      if (mounted) _snack('Class deleted');
    } catch (e) {
      if (mounted) _snack("Couldn't delete the class: $e");
    }
  }

  void _showDetails(ScheduleItem item) {
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_s3, 0, _s3, _s3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.subjectCode,
                style: TextStyle(
                  color: item.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.subject,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: _s2),
              _InfoRow(
                icon: Icons.event_outlined,
                text: _dayNames[item.dayOfWeek],
              ),
              _InfoRow(
                icon: Icons.schedule,
                text:
                    '${item.timeRange} (${_formatDuration(item.endMinutes - item.startMinutes)})',
              ),
              _InfoRow(icon: Icons.place_outlined, text: item.room),
              _InfoRow(icon: Icons.person_outline, text: item.instructor),
              _InfoRow(
                icon: Icons.notifications_none,
                text: 'Reminder ${item.reminderMinutesBefore} min before class',
              ),
              const SizedBox(height: _s2),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _confirmDelete(item);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: _s1),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _openForm(item: item);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('BSIT - 3')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(_s3),
            child: Text(
              "Couldn't load the schedule.\n$_error",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final shown = _pickedDay ?? now.weekday;
    final isToday = shown == now.weekday;
    final dayItems = schedulesForDay(_items, shown);

    ScheduleItem? current;
    ScheduleItem? next;
    if (isToday) {
      for (final i in dayItems) {
        if (minutes >= i.startMinutes && minutes < i.endMinutes) {
          current = i;
        } else if (minutes < i.startMinutes && next == null) {
          next = i;
        }
      }
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BSIT - 3'),
        actions: [
          IconButton(
            tooltip: 'Weekly timetable',
            icon: const Icon(Icons.calendar_view_week),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TimetableScreen(items: _items)),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideBreakpoint;

          final header = Row(
            children: [
              Expanded(
                child: Text(
                  isToday
                      ? '${_dayNames[now.weekday]}, ${_monthNames[now.month]} ${now.day}'
                      : _dayNames[shown],
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isToday)
                TextButton(
                  onPressed: () => setState(() => _pickedDay = null),
                  child: const Text('Today'),
                ),
              IconButton(
                tooltip: 'Previous day',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _goToDay(-1, shown, now.weekday),
              ),
              IconButton(
                tooltip: 'Next day',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _goToDay(1, shown, now.weekday),
              ),
            ],
          );

          final hero = isToday
              ? _todayHero(
                  current: current,
                  next: next,
                  minutes: minutes,
                  todayCount: dayItems.length,
                  weekday: now.weekday,
                )
              : _otherDayHero(shown, dayItems);

          final scheduleWidgets = <Widget>[
            Text(
              isToday ? "Today's schedule" : "${_dayNames[shown]}'s schedule",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: _s1),
            if (dayItems.isEmpty)
              _EmptyDay(
                text: isToday
                    ? 'No classes today'
                    : 'No classes on ${_dayNames[shown]}',
                onAdd: () => _openForm(),
              )
            else
              for (final item in dayItems)
                _ClassTile(
                  item: item,
                  isPast: isToday && minutes >= item.endMinutes,
                  isNow: item == current,
                  onTap: () => _showDetails(item),
                ),
          ];

          final Widget content = wide
              // Two columns that stretch with the window.
              ? Padding(
                  padding: const EdgeInsets.all(_s3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              header,
                              const SizedBox(height: _s1),
                              hero,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: _s3),
                      Expanded(
                        flex: 6,
                        child: ListView(
                          padding: const EdgeInsets.only(top: _s1, bottom: 88),
                          children: scheduleWidgets,
                        ),
                      ),
                    ],
                  ),
                )
              // Single column for phones / narrow windows.
              : ListView(
                  padding: const EdgeInsets.fromLTRB(_s2, _s2, _s2, 88),
                  children: [
                    header,
                    const SizedBox(height: _s1),
                    hero,
                    const SizedBox(height: _s3),
                    ...scheduleWidgets,
                  ],
                );

          // Swipe left / right to change day.
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v < -300) _goToDay(1, shown, now.weekday);
              if (v > 300) _goToDay(-1, shown, now.weekday);
            },
            child: content,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add class'),
      ),
      bottomNavigationBar: SafeArea(
        child: SwitchListTile(
          title: const Text('Class reminders'),
          subtitle: const Text('Notify me 10 minutes before each class'),
          value: _remind,
          onChanged: _toggleReminders,
        ),
      ),
    );
  }

  Widget _todayHero({
    required ScheduleItem? current,
    required ScheduleItem? next,
    required int minutes,
    required int todayCount,
    required int weekday,
  }) {
    if (current != null) {
      final c = current;
      final total = c.endMinutes - c.startMinutes;
      final elapsed = (minutes - c.startMinutes).clamp(0, total);
      return _HeroCard(
        label: 'In class now',
        accent: c.color,
        title: c.subject,
        lines: [
          '${c.timeRange} · ${c.room}',
          '${c.instructor} · ends in ${_formatDuration(c.endMinutes - minutes)}',
        ],
        progress: elapsed / total,
        progressLeft:
            '${_formatDuration(elapsed)} of ${_formatDuration(total)}',
        progressRight: '${(elapsed / total * 100).round()}%',
      );
    }
    if (next != null) {
      final n = next;
      return _HeroCard(
        label: 'Up next · in ${_formatDuration(n.startMinutes - minutes)}',
        accent: n.color,
        title: n.subject,
        lines: ['${n.timeRange} · ${n.room}', n.instructor],
      );
    }
    return _HeroCard(
      label: 'Free',
      title: todayCount == 0 ? 'No classes today' : 'No more classes today',
      lines: [_nextClassText(weekday)],
    );
  }

  Widget _otherDayHero(int day, List<ScheduleItem> items) {
    if (items.isEmpty) {
      return _HeroCard(
        label: _dayNames[day],
        title: 'No classes',
        lines: [_nextClassText(day)],
      );
    }
    final first = items.first;
    final last = items.last;
    return _HeroCard(
      label: _dayNames[day],
      title: items.length == 1 ? '1 class' : '${items.length} classes',
      lines: [
        '${ScheduleItem.format(first.startMinutes)} – ${ScheduleItem.format(last.endMinutes)}',
        'First: ${first.subjectCode} · ${first.room}',
      ],
    );
  }
}

/// Dark summary card at the top of the screen.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.label,
    required this.title,
    required this.lines,
    this.accent,
    this.progress,
    this.progressLeft,
    this.progressRight,
  });

  final String label;
  final String title;
  final List<String> lines;
  final Color? accent;
  final double? progress;
  final String? progressLeft;
  final String? progressRight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = scheme.onInverseSurface;
    // Lighten the subject color a little so it stays visible on the dark card.
    final barColor = accent == null
        ? null
        : Color.lerp(accent, Colors.white, .25);

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.inverseSurface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (accent != null) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: barColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: _s1),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(color: on.withOpacity(.75)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: on,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            for (final l in lines.where((l) => l.isNotEmpty)) ...[
              const SizedBox(height: 4),
              Text(l, style: TextStyle(color: on.withOpacity(.85))),
            ],
            if (progress != null) ...[
              const SizedBox(height: _s2),
              LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                color: barColor,
                backgroundColor: on.withOpacity(.2),
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    progressLeft ?? '',
                    style: TextStyle(color: on.withOpacity(.75), fontSize: 12),
                  ),
                  Text(
                    progressRight ?? '',
                    style: TextStyle(color: on.withOpacity(.75), fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: _s1),
          Expanded(
            child: Text(text, style: TextStyle(color: muted)),
          ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.text, required this.onAdd});

  final String text;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _s3),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined, size: 48, color: muted),
          const SizedBox(height: _s1),
          Text(text, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Enjoy the free time, or open the weekly view to plan ahead.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: _s2),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add a class'),
          ),
        ],
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({
    required this.item,
    required this.isPast,
    required this.isNow,
    required this.onTap,
  });

  final ScheduleItem item;
  final bool isPast;
  final bool isNow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: _s1),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isNow ? item.color : Theme.of(context).dividerColor,
          width: isNow ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: item.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Opacity(
                          opacity: isPast ? .6 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.subjectCode,
                                style: TextStyle(
                                  color: item.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subject,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              _InfoRow(
                                icon: Icons.schedule,
                                text: item.timeRange,
                              ),
                              _InfoRow(
                                icon: Icons.place_outlined,
                                text: item.room,
                              ),
                              _InfoRow(
                                icon: Icons.person_outline,
                                text: item.instructor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isPast)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: scheme.primary),
                            const SizedBox(height: 2),
                            Text(
                              'Done',
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

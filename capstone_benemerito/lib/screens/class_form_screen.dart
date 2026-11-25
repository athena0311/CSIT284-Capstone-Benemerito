import 'package:flutter/material.dart';

import 'package:capstone_benemerito/data/schedule_repository.dart';
import 'package:capstone_benemerito/models/schedule_item.dart';

const _days = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Add a new class, or edit / delete an existing one.
/// Pops with a short message ("Class added", ...) so the caller can show it.
class ClassFormScreen extends StatefulWidget {
  const ClassFormScreen({super.key, this.item, this.initialDay});

  /// Null = add mode, otherwise edit mode.
  final ScheduleItem? item;

  /// Day pre-selected in add mode (1 = Monday … 7 = Sunday).
  final int? initialDay;

  @override
  State<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends State<ClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subject;
  late final TextEditingController _code;
  late final TextEditingController _instructor;
  late final TextEditingController _room;
  late int _day;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late int _reminder;
  bool _saving = false;

  bool get _isEdit => widget.item != null;

  static TimeOfDay _parse(String hhmm) {
    final p = hhmm.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  static String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _subject = TextEditingController(text: i?.subject ?? '');
    _code = TextEditingController(text: i?.subjectCode ?? '');
    _instructor = TextEditingController(text: i?.instructor ?? '');
    _room = TextEditingController(text: i?.room ?? '');
    _day = i?.dayOfWeek ?? widget.initialDay ?? 1;
    _start = i != null ? _parse(i.startTime) : const TimeOfDay(hour: 8, minute: 0);
    _end = i != null ? _parse(i.endTime) : const TimeOfDay(hour: 10, minute: 0);
    _reminder = i?.reminderMinutesBefore ?? 10;
  }

  @override
  void dispose() {
    _subject.dispose();
    _code.dispose();
    _instructor.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final startMin = _start.hour * 60 + _start.minute;
    final endMin = _end.hour * 60 + _end.minute;
    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after the start time.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final item = ScheduleItem(
        id: widget.item?.id ?? ScheduleRepository.instance.newId(),
        subject: _subject.text.trim(),
        subjectCode: _code.text.trim().toUpperCase(),
        instructor: _instructor.text.trim(),
        room: _room.text.trim(),
        dayOfWeek: _day,
        startTime: _hhmm(_start),
        endTime: _hhmm(_end),
        reminderMinutesBefore: _reminder,
      );
      await ScheduleRepository.instance.save(item);
      if (!mounted) return;
      Navigator.of(context).pop(_isEdit ? 'Class updated' : 'Class added');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save the class: $e")),
      );
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete class?'),
        content: Text('"${widget.item!.subject}" will be removed.'),
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
    setState(() => _saving = true);
    try {
      await ScheduleRepository.instance.delete(widget.item!.id);
      if (!mounted) return;
      Navigator.of(context).pop('Class deleted');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't delete the class: $e")),
      );
    }
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? 'Enter the $label' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit class' : 'Add class'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete class',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          // Forms read better at a limited width, even on a wide window.
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _subject,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _required(v, 'subject'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Subject code (e.g. CSIT224)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _required(v, 'subject code'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _instructor,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Instructor',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _required(v, 'instructor'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _room,
                  decoration: const InputDecoration(
                    labelText: 'Room',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _required(v, 'room'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _day,
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (var d = 1; d <= 7; d++)
                      DropdownMenuItem(value: d, child: Text(_days[d - 1])),
                  ],
                  onChanged: (v) => setState(() => _day = v ?? _day),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(isStart: true),
                        icon: const Icon(Icons.schedule),
                        label: Text('Start: ${_start.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(isStart: false),
                        icon: const Icon(Icons.schedule),
                        label: Text('End: ${_end.format(context)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _reminder,
                  decoration: const InputDecoration(
                    labelText: 'Reminder',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final m in const [5, 10, 15, 30])
                      DropdownMenuItem(
                        value: m,
                        child: Text('$m minutes before'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _reminder = v ?? _reminder),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isEdit ? 'Save changes' : 'Add class'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:capstone_benemerito/models/schedule_item.dart';

/// All Firestore access for classes lives here.
class ScheduleRepository {
  ScheduleRepository._();
  static final ScheduleRepository instance = ScheduleRepository._();

  final CollectionReference<Map<String, dynamic>> _col = FirebaseFirestore
      .instance
      .collection('schedules');

  /// Live list: emits again whenever the data changes in Firestore.
  Stream<List<ScheduleItem>> watchAll() => _col.snapshots().map(
    (snap) =>
        snap.docs.map((d) => ScheduleItem.fromMap(d.id, d.data())).toList(),
  );

  Future<void> save(ScheduleItem item) => _col.doc(item.id).set(item.toMap());

  Future<void> delete(String id) => _col.doc(id).delete();

  /// Uploads the dummy data once, only if the collection is empty.
  Future<void> seedIfEmpty(List<ScheduleItem> items) async {
    final existing = await _col.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final i in items) {
      batch.set(_col.doc(i.id), i.toMap());
    }
    await batch.commit();
  }
}

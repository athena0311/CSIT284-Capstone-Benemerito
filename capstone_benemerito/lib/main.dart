import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:capstone_benemerito/data/dummy_items.dart';
import 'package:capstone_benemerito/data/schedule_repository.dart';
import 'package:capstone_benemerito/screens/home_screen.dart';
import 'package:capstone_benemerito/services/notification_service.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Run ONCE to upload the dummy classes, then delete or comment this line.
  await ScheduleRepository.instance.seedIfEmpty(dummySchedules);

  // Needed for reminders. Requires the updated notification_service.dart,
  // which safely does nothing when running in Chrome.
  await NotificationService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Class Schedule',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

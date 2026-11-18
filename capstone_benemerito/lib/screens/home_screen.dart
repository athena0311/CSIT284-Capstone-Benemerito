
import 'package:flutter/material.dart';
import 'package:capstone_benemerito/data/dummy_items.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final todaySchedules = getTodaysSchedules();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Class Schedule'),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Classes",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            if (todaySchedules.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('No classes scheduled today!'),
                  ),
                ),
              )
            else
              ...todaySchedules.map((schedule) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.book,
                      color: Colors.blue,
                    ),
                    title: Text(schedule.subject),
                    subtitle: Text(
                      '${schedule.subjectCode}\n'
                      '${schedule.startTime} - ${schedule.endTime}\n'
                      '${schedule.room}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              }),

            const SizedBox(height: 25),

            const Text(
              'Weekly Timetable',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            ...List.generate(6, (index) {
              final day = index + 1;
              final schedules = getSchedulesForDay(day);

              const days = [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
              ];

              return ExpansionTile(
                title: Text(
                  days[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                initiallyExpanded: day == today,
                children: schedules.isEmpty
                    ? [
                        const ListTile(
                          title: Text('No classes'),
                        )
                      ]
                    : schedules.map((schedule) {
                        return ListTile(
                          title: Text(schedule.subject),
                          subtitle: Text(
                            '${schedule.startTime} - '
                            '${schedule.endTime} | ${schedule.room}',
                          ),
                          leading: const Icon(Icons.access_time),
                        );
                      }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}


class ScheduleItem {
  final String id;
  final String subject;
  final String subjectCode;
  final String instructor;
  final String room;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
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
}

final List<ScheduleItem> dummySchedules = [
  // MONDAY
  ScheduleItem(
    id: '1',
    subject: 'Human Computer Interaction',
    subjectCode: 'CSIT238',
    instructor: 'Mr. Santos',
    room: 'GLE 201',
    dayOfWeek: 1,
    startTime: '08:00',
    endTime: '10:00',
  ),
  ScheduleItem(
    id: '2',
    subject: 'Systems Administration and Maintenance',
    subjectCode: 'IT344',
    instructor: 'Ms. Reyes',
    room: 'RTL 300',
    dayOfWeek: 1,
    startTime: '10:30',
    endTime: '12:30',
  ),

  // TUESDAY
  ScheduleItem(
    id: '3',
    subject: 'Information Assurance and Security',
    subjectCode: 'CSIT385',
    instructor: 'Mr. Cruz',
    room: 'NGE 104',
    dayOfWeek: 2,
    startTime: '08:00',
    endTime: '10:00',
  ),
  ScheduleItem(
    id: '4',
    subject: 'Object-Oriented Programming 2',
    subjectCode: 'CSIT228',
    instructor: 'Ms. Garcia',
    room: 'RTL 301',
    dayOfWeek: 2,
    startTime: '13:00',
    endTime: '15:00',
  ),

  // WEDNESDAY
  ScheduleItem(
    id: '5',
    subject: 'Information Management 1',
    subjectCode: 'CSIT226',
    instructor: 'Mr. Santos',
    room: 'NGE 101',
    dayOfWeek: 3,
    startTime: '08:00',
    endTime: '10:00',
  ),
  ScheduleItem(
    id: '6',
    subject: 'Platform-Based Development(Mobile)',
    subjectCode: 'CSIT224',
    instructor: 'Ms. Reyes',
    room: 'NGE 102',
    dayOfWeek: 3,
    startTime: '3:00',
    endTime: '6:00',
  ),

  // THURSDAY
  ScheduleItem(
    id: '7',
    subject: 'Data Structures and Algorithms',
    subjectCode: 'CSIT226',
    instructor: 'Mr. Cruz',
    room: 'Computer Lab 1',
    dayOfWeek: 4,
    startTime: '08:00',
    endTime: '10:00',
  ),
  ScheduleItem(
    id: '8',
    subject: 'Object-Oriented Programming 2',
    subjectCode: 'CSIT228',
    instructor: 'Ms. Garcia',
    room: 'NGE 102',
    dayOfWeek: 4,
    startTime: '13:00',
    endTime: '15:00',
  ),

  // FRIDAY
  ScheduleItem(
    id: '9',
    subject: 'Information Assurance and Security',
    subjectCode: 'CSIT385',
    instructor: 'Mr. Dela Cruz',
    room: 'Computer Lab 2',
    dayOfWeek: 5,
    startTime: '08:00',
    endTime: '11:00',
  ),

  // SATURDAY
  ScheduleItem(
    id: '10',
    subject: 'Physical Education',
    subjectCode: 'PATHFIT2',
    instructor: 'Ms. Mendoza',
    room: 'University Gym',
    dayOfWeek: 6,
    startTime: '08:00',
    endTime: '10:00',
  ),
];

// Get schedules for a specific day
List<ScheduleItem> getSchedulesForDay(int day) {
  final schedules = dummySchedules
      .where((item) => item.dayOfWeek == day)
      .toList();

  schedules.sort((a, b) =>
      a.startTime.compareTo(b.startTime));

  return schedules;
}

// Get today's classes
List<ScheduleItem> getTodaysSchedules() {
  return getSchedulesForDay(DateTime.now().weekday);
}

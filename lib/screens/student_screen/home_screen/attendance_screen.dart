import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum AttendanceStatus { present, absent, cancelled, makeup }

class AttendanceScreenS extends StatefulWidget {
  const AttendanceScreenS({super.key});

  @override
  _StudentAttendanceCalendarState createState() =>
      _StudentAttendanceCalendarState();
}

class _StudentAttendanceCalendarState
    extends State<AttendanceScreenS> {
  late SharedPreferences prefs;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, AttendanceStatus> _attendanceMap = {};

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  void _loadAttendanceData() async {
    prefs = await SharedPreferences.getInstance();
    String? attendanceJson =
        prefs.getString('attendance_data');
    if (attendanceJson != null) {
      Map<String, dynamic> decodedMap =
          json.decode(attendanceJson);
      setState(() {
        _attendanceMap = decodedMap.map((key, value) =>
            MapEntry(DateTime.parse(key),
                AttendanceStatus.values[value]));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학생 출석 현황')),
      body: Column(
        children: [
          _buildMonthlyAttendanceSummary(),
          Expanded(
            child: TableCalendar(
              firstDay: DateTime.utc(2021, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) =>
                  isSameDay(_selectedDay, day),
              onDaySelected: (
                selectedDay,
                focusedDay,
              ) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _showAttendanceInfo(selectedDay);
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                weekendTextStyle:
                    const TextStyle(color: Colors.red),
                holidayTextStyle:
                    TextStyle(color: Colors.blue[800]),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (_attendanceMap.containsKey(date)) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getColorForStatus(
                            _attendanceMap[date]!),
                      ),
                      width: 40,
                      height: 40,
                      child: Text(
                        date.day.toString(),
                        style: const TextStyle(
                            color: Colors.white),
                      ),
                    );
                  }
                  return null;
                },
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) =>
                    DateFormat.yMMMM('ko_KR').format(date),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyAttendanceSummary() {
    Map<AttendanceStatus, int> monthlySummary =
        _getMonthlyAttendanceSummary(_focusedDay);
    String monthName = DateFormat('yyyy년 MM월', 'ko_KR')
        .format(_focusedDay);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$monthName 출석 요약',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildSummaryRow(
              '출석',
              monthlySummary[AttendanceStatus.present] ?? 0,
              Icons.check_circle,
              Colors.blue),
          _buildSummaryRow(
              '결석',
              monthlySummary[AttendanceStatus.absent] ?? 0,
              Icons.cancel,
              Colors.red),
          _buildSummaryRow(
              '휴강',
              monthlySummary[AttendanceStatus.cancelled] ??
                  0,
              Icons.event_busy,
              Colors.grey),
          _buildSummaryRow(
              '보강',
              monthlySummary[AttendanceStatus.makeup] ?? 0,
              Icons.update,
              Colors.green),
        ],
      ),
    );
  }

  Map<AttendanceStatus, int> _getMonthlyAttendanceSummary(
      DateTime month) {
    Map<AttendanceStatus, int> summary = {};
    _attendanceMap.forEach((date, status) {
      if (date.year == month.year &&
          date.month == month.month) {
        summary[status] = (summary[status] ?? 0) + 1;
      }
    });
    return summary;
  }

  Widget _buildSummaryRow(
      String label, int count, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label: $count'),
          Icon(icon, color: color),
        ],
      ),
    );
  }

  void _showAttendanceInfo(DateTime day) {
    if (_attendanceMap.containsKey(day)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
                style: const TextStyle(fontSize: 20),
                "${DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(day)} 출석 정보"),
            content:
                Text(_getStatusName(_attendanceMap[day]!)),
            actions: [
              TextButton(
                child: const Text(" 확인 "),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Color _getColorForStatus(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.blue;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.cancelled:
        return Colors.grey;
      case AttendanceStatus.makeup:
        return Colors.green;
    }
  }

  String _getStatusName(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return "출석";
      case AttendanceStatus.absent:
        return "결석";
      case AttendanceStatus.cancelled:
        return "휴강";
      case AttendanceStatus.makeup:
        return "보강";
    }
  }
}

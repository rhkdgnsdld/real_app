import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, cancelled, makeup }

class AttendanceScreenT extends StatefulWidget {
  const AttendanceScreenT({super.key});

  @override
  _AttendanceCalendarState createState() =>
      _AttendanceCalendarState();
}

class _AttendanceCalendarState
    extends State<AttendanceScreenT> {
  late String currentUserId;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, AttendanceStatus> _attendanceMap = {};

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _loadAttendanceData();
  }

  void _loadAttendanceData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('attendance')
        .get();

    setState(() {
      _attendanceMap = {};
      for (var doc in snapshot.docs) {
        _attendanceMap[DateTime.parse(doc.id)] =
            AttendanceStatus.values[doc.data()['status']];
      }
    });
  }

  void _saveAttendanceData(
      DateTime date, AttendanceStatus status) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('attendance')
        .doc(date.toIso8601String())
        .set({
      'status': status.index,
      'date': date,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _deleteAttendanceData(DateTime date) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('attendance')
        .doc(date.toIso8601String())
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('출석 확인 ')),
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
                _showAttendanceDialog(selectedDay);
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

  void _showAttendanceDialog(DateTime day) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("출석 상태 선택"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...AttendanceStatus.values.map((status) {
                return ListTile(
                  title: Text(_getStatusName(status)),
                  trailing: Icon(_getIconForStatus(status),
                      color: _getColorForStatus(status)),
                  onTap: () {
                    setState(() {
                      _attendanceMap[day] = status;
                      _saveAttendanceData(
                          day, status); // Firebase에 저장
                    });
                    Navigator.of(context).pop();
                  },
                );
              }),
              const Divider(),
              ListTile(
                title: const Text("삭제"),
                trailing: const Icon(Icons.delete,
                    color: Colors.red),
                onTap: () {
                  setState(() {
                    _attendanceMap.remove(day);
                    _deleteAttendanceData(
                        day); // Firebase에서 삭제
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
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

  IconData _getIconForStatus(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.cancelled:
        return Icons.event_busy;
      case AttendanceStatus.makeup:
        return Icons.update;
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

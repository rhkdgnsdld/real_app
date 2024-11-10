import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, cancelled, makeup }

class AttendanceScreenS extends StatefulWidget {
  const AttendanceScreenS({super.key});

  @override
  _StudentAttendanceCalendarState createState() =>
      _StudentAttendanceCalendarState();
}

class _StudentAttendanceCalendarState
    extends State<AttendanceScreenS> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, AttendanceStatus> _attendanceMap = {};
  String? _connectedTeacherId;

  @override
  void initState() {
    super.initState();
    _loadConnectedTeacher();
    initializeDateFormatting(
        'ko_KR', null); // 한국어 날짜 형식을 위해 추가
  }

  Future<void> _loadConnectedTeacher() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // 먼저 현재 사용자의 userId를 가져옴
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        final userId = userDoc.data()?['userId'];

        // userId로 연결을 검색
        final connection = await FirebaseFirestore.instance
            .collection('connections')
            .where('studentId', isEqualTo: userId)
            .where('status', isEqualTo: 'accepted')
            .get();

        print(
            'Found Connections: ${connection.docs.length}');

        if (connection.docs.isNotEmpty) {
          final teacherId =
              connection.docs.first.data()['teacherId'];

          // teacherId로 교사의 uid 찾기
          final teacherDocs = await FirebaseFirestore
              .instance
              .collection('users')
              .where('userId', isEqualTo: teacherId)
              .get();

          if (teacherDocs.docs.isNotEmpty) {
            final teacherUid = teacherDocs.docs.first.id;

            setState(() {
              _connectedTeacherId = teacherUid;
            });

            await _loadAttendanceData();
          }
        } else {
          print('No connected teacher found');
        }
      }
    } catch (e) {
      print('Error in _loadConnectedTeacher: $e');
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      print(
          'Loading attendance for teacher: $_connectedTeacherId');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_connectedTeacherId)
          .collection('attendance')
          .get();

      print(
          'Found ${snapshot.docs.length} attendance records');

      final newAttendanceMap =
          <DateTime, AttendanceStatus>{};

      for (var doc in snapshot.docs) {
        try {
          final date = DateTime.parse(doc.id);
          final statusIndex = doc.data()['status'] as int;
          newAttendanceMap[date] =
              AttendanceStatus.values[statusIndex];
          print(
              'Added attendance for ${doc.id}: ${AttendanceStatus.values[statusIndex]}');
        } catch (e) {
          print('Error parsing attendance record: $e');
        }
      }

      setState(() {
        _attendanceMap = newAttendanceMap;
      });
    } catch (e) {
      print('Error in _loadAttendanceData: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학생 출석 현황')),
      body: SingleChildScrollView(
        // 이 부분 추가
        child: Column(
          children: [
            _buildMonthlyAttendanceSummary(),
            SizedBox(
              // TableCalendar를 Container로 감싸기
              height: MediaQuery.of(context).size.height *
                  0.6, // 화면 높이의 60%
              child: _connectedTeacherId == null
                  ? const Center(
                      child: Text('연동된 선생님이 없습니다.'))
                  : TableCalendar(
                      firstDay: DateTime.utc(2021, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected:
                          (selectedDay, focusedDay) {
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
                        weekendTextStyle: const TextStyle(
                            color: Colors.red),
                        holidayTextStyle: TextStyle(
                            color: Colors.blue[800]),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder:
                            (context, date, events) {
                          if (_attendanceMap
                              .containsKey(date)) {
                            return Container(
                              margin:
                                  const EdgeInsets.all(4.0),
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
                        titleTextFormatter:
                            (date, locale) =>
                                DateFormat.yMMMM('ko_KR')
                                    .format(date),
                      ),
                    ),
            ),
          ],
        ),
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

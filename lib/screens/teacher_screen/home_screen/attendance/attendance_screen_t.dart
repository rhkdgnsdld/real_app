import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  String? _studentName;
  String? _connectedStudentId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _loadConnectedStudent();
    initializeDateFormatting('ko_KR', null);
  }

  Future<void> _loadConnectedStudent() async {
    try {
      // 현재 선생님의 userId 가져오기
      final teacherDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      final teacherUserId = teacherDoc.data()?['userId'];

      // 연결된 학생 찾기
      final connection = await FirebaseFirestore.instance
          .collection('connections')
          .where('teacherId', isEqualTo: teacherUserId)
          .where('status', isEqualTo: 'accepted')
          .get();

      if (connection.docs.isNotEmpty) {
        final studentId =
            connection.docs.first.data()['studentId'];

        // 학생 정보 가져오기
        final studentDocs = await FirebaseFirestore.instance
            .collection('users')
            .where('userId', isEqualTo: studentId)
            .get();

        if (studentDocs.docs.isNotEmpty) {
          setState(() {
            _studentName =
                studentDocs.docs.first.data()['name'];
            _connectedStudentId = studentId;
          });
          _loadAttendanceData();
        }
      }
    } catch (e) {
      print('Error loading student: $e');
    }
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2021, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) => false,
        onDaySelected: (selectedDay, focusedDay) {
          _showAttendanceDialog(
              selectedDay); // 여기서는 다이얼로그로 상태 변경 가능
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
          todayDecoration: BoxDecoration(
            color: mainBlue.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
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
                width: 36,
                height: 36,
                child: Text(
                  date.day.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              );
            }
            return null;
          },
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          headerPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
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

  final Color mainBlue = const Color(0xFF5BABEF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '출석부',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _connectedStudentId == null
          ? Center(
              child: Text(
                '연동된 학생이 없습니다.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildStudentInfo(),
                  _buildMonthlyAttendanceSummary(),
                  _buildCalendar(),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: mainBlue.withOpacity(0.1),
            child: Text(
              _studentName?.substring(0, 1) ?? '',
              style: TextStyle(color: mainBlue),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _studentName ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '학생 ID: $_connectedStudentId',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$monthName 출결 현황',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryCard(
                '출석',
                monthlySummary[AttendanceStatus.present] ??
                    0,
                Icons.check_circle_outlined,
                mainBlue,
              ),
              _buildSummaryCard(
                '결석',
                monthlySummary[AttendanceStatus.absent] ??
                    0,
                Icons.cancel_outlined,
                Colors.red[400]!,
              ),
              _buildSummaryCard(
                '휴강',
                monthlySummary[
                        AttendanceStatus.cancelled] ??
                    0,
                Icons.event_busy_outlined,
                Colors.grey[600]!,
              ),
              _buildSummaryCard(
                '보강',
                monthlySummary[AttendanceStatus.makeup] ??
                    0,
                Icons.update,
                Colors.green[600]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttendanceInfo(DateTime day) {
    if (_attendanceMap.containsKey(day)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              DateFormat('yyyy년 MM월 dd일', 'ko_KR')
                  .format(day),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconForStatus(_attendanceMap[day]!),
                    color: _getColorForStatus(
                        _attendanceMap[day]!),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusName(_attendanceMap[day]!),
                    style: TextStyle(
                      fontSize: 16,
                      color: _getColorForStatus(
                          _attendanceMap[day]!),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  "확인",
                  style: TextStyle(color: mainBlue),
                ),
                onPressed: () =>
                    Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            DateFormat('yyyy년 MM월 dd일', 'ko_KR')
                .format(day),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...AttendanceStatus.values.map((status) {
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: Icon(_getIconForStatus(status),
                      color: _getColorForStatus(status)),
                  title: Text(_getStatusName(status)),
                  onTap: () {
                    setState(() {
                      _attendanceMap[day] = status;
                      _saveAttendanceData(day, status);
                    });
                    Navigator.of(context).pop();
                  },
                );
              }),
              const Divider(height: 32),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                leading: const Icon(Icons.delete,
                    color: Colors.red),
                title: const Text("출석 정보 삭제"),
                onTap: () {
                  setState(() {
                    _attendanceMap.remove(day);
                    _deleteAttendanceData(day);
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

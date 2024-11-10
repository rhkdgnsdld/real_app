import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentWeeklyAssignmentScreen extends StatefulWidget {
  const StudentWeeklyAssignmentScreen({super.key});

  @override
  _StudentWeeklyAssignmentScreenState createState() =>
      _StudentWeeklyAssignmentScreenState();
}

class _StudentWeeklyAssignmentScreenState
    extends State<StudentWeeklyAssignmentScreen> {
  late DateTime _currentWeek;
  List<Map<String, dynamic>> _assignments = [];
  String? _connectedTeacherId;
  String? _connectedTeacherUid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCurrentWeek();
    _loadConnectedTeacher();
  }

  // 파스텔 색상 정의
  final Color pastelBlue = Colors.white;
  final Color pastelGreen = Colors.white;
  final Color pastelPink = Colors.blue;
  final Color pastelYellow = const Color(0xFFAED6F1);

  void _initializeCurrentWeek() {
    _currentWeek = _getWeekStartDate(DateTime.now());
    _loadAssignments();
  }

  Future<void> _loadConnectedTeacher() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // 현재 학생의 userId 가져오기
      final studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final studentUserId = studentDoc.data()?['userId'];

      // studentUserId로 연결된 선생님 찾기
      final connection = await FirebaseFirestore.instance
          .collection('connections')
          .where('studentId', isEqualTo: studentUserId)
          .where('status', isEqualTo: 'accepted')
          .get();

      if (connection.docs.isNotEmpty) {
        final teacherId =
            connection.docs.first.data()['teacherId'];

        // teacherId로 선생님의 uid 찾기
        final teacherDocs = await FirebaseFirestore.instance
            .collection('users')
            .where('userId', isEqualTo: teacherId)
            .get();

        if (teacherDocs.docs.isNotEmpty) {
          setState(() {
            _connectedTeacherId = teacherId;
            _connectedTeacherUid =
                teacherDocs.docs.first.id;
            _isLoading = false;
          });
          await _loadAssignments();
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadAssignments() async {
    if (_connectedTeacherUid == null) return;

    final weekKey =
        DateFormat('yyyy-MM-dd').format(_currentWeek);

    try {
      // 선생님의 과제 컬렉션에서 데이터 로드
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_connectedTeacherUid)
          .collection('teacher_assignments')
          .doc(FirebaseAuth
              .instance.currentUser?.uid) // 현재 학생의 uid
          .collection('weekly')
          .doc(weekKey)
          .get();

      if (snapshot.exists) {
        final assignmentList = List<String>.from(
            snapshot.data()?['assignments'] ?? []);

        // 학생의 완료 상태 가져오기
        final studentSnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('assignments')
            .doc(weekKey)
            .get();

        List<bool> completionStatus = [];
        if (studentSnapshot.exists) {
          completionStatus = List<bool>.from(studentSnapshot
                  .data()?['completionStatus'] ??
              List.filled(assignmentList.length, false));
        } else {
          completionStatus =
              List.filled(assignmentList.length, false);
        }

        setState(() {
          _assignments = List.generate(
            assignmentList.length,
            (index) => {
              'content': assignmentList[index],
              'completed': completionStatus[index],
            },
          );
        });
      } else {
        setState(() {
          _assignments = [];
        });
      }
    } catch (e) {
      print('Error loading assignments: $e');
    }
  }

  Future<void> _toggleAssignment(int index) async {
    if (_connectedTeacherUid == null) return;

    setState(() {
      _assignments[index]['completed'] =
          !_assignments[index]['completed'];
    });

    final weekKey =
        DateFormat('yyyy-MM-dd').format(_currentWeek);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // 학생의 과제 완료 상태 업데이트
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('assignments')
          .doc(weekKey)
          .set({
        'assignments':
            _assignments.map((a) => a['content']).toList(),
        'completionStatus': _assignments
            .map((a) => a['completed'])
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating assignment status: $e');
    }
  }

  void _changeWeek(int weeks) {
    setState(() {
      _currentWeek =
          _currentWeek.add(Duration(days: 7 * weeks));
      _loadAssignments(); // 주간 변경 시 과제 다시 로드
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelYellow,
      appBar: AppBar(
        title: const Text('학생 주간 과제',
            style: TextStyle(color: Colors.black87)),
        backgroundColor: pastelBlue,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildWeekNavigator(),
          Expanded(
            child: _buildAssignmentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: pastelBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Text(
            '주간과제',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.black54),
                onPressed: () => _changeWeek(-1),
              ),
              Text(
                _getWeekRangeText(_currentWeek),
                style: const TextStyle(
                    fontSize: 16, color: Colors.black87),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    color: Colors.black54),
                onPressed: () => _changeWeek(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentList() {
    if (_assignments.isEmpty) {
      return const Center(
        child: Text(
          '과제가 없습니다',
          style: TextStyle(
              fontSize: 18, color: Colors.black54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: pastelGreen,
          child: ListTile(
            title: Text(_assignments[index]['content'],
                style:
                    const TextStyle(color: Colors.black87)),
            trailing: IconButton(
              icon: Icon(
                _assignments[index]['completed']
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: _assignments[index]['completed']
                    ? Colors.green
                    : Colors.grey,
              ),
              onPressed: () => _toggleAssignment(index),
            ),
          ),
        );
      },
    );
  }

  DateTime _getWeekStartDate(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  String _getWeekRangeText(DateTime weekStart) {
    DateTime weekEnd =
        weekStart.add(const Duration(days: 6));
    return '${DateFormat('MM월 dd일').format(weekStart)} - ${DateFormat('MM월 dd일').format(weekEnd)}';
  }

  void _saveAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    String weekKey =
        DateFormat('yyyy-MM-dd').format(_currentWeek);
    List<String> assignmentsToSave = _assignments
        .map(
            (assignment) => assignment['content'] as String)
        .toList();
    await prefs.setStringList(weekKey, assignmentsToSave);
  }
}

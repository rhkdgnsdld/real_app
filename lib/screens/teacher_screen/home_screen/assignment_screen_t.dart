import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyAssignmentScreen extends StatefulWidget {
  const WeeklyAssignmentScreen({super.key});

  @override
  _WeeklyAssignmentScreenState createState() =>
      _WeeklyAssignmentScreenState();
}

class _WeeklyAssignmentScreenState
    extends State<WeeklyAssignmentScreen> {
  late DateTime _currentWeek;
  final TextEditingController _assignmentController =
      TextEditingController();
  List<String> _assignments = [];
  String? _connectedStudentId;
  String? _connectedStudentUid;

  // 파스텔 색상 정의
  final Color pastelBlue = Colors.white;
  final Color pastelGreen = Colors.white;
  final Color pastelPink = Colors.blue;
  final Color pastelYellow = const Color(0xFFAED6F1);

  @override
  void initState() {
    super.initState();
    _initializeCurrentWeek();
    _loadConnectedStudent();
  }

  Future<void> _loadConnectedStudent() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final teacherDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final teacherUserId = teacherDoc.data()?['userId'];

      final connection = await FirebaseFirestore.instance
          .collection('connections')
          .where('teacherId', isEqualTo: teacherUserId)
          .where('status', isEqualTo: 'accepted')
          .get();

      if (connection.docs.isNotEmpty) {
        final studentId =
            connection.docs.first.data()['studentId'];

        final studentDocs = await FirebaseFirestore.instance
            .collection('users')
            .where('userId', isEqualTo: studentId)
            .get();

        if (studentDocs.docs.isNotEmpty) {
          _connectedStudentId = studentId;
          _connectedStudentUid = studentDocs.docs.first.id;
          await _loadAssignments();
        }
      }
    }
  }

  Future<void> _loadAssignments() async {
    if (_connectedStudentUid == null) return;

    final weekKey =
        DateFormat('yyyy-MM-dd').format(_currentWeek);

    try {
      // 선생님의 과제 데이터 로드
      final currentUser = FirebaseAuth.instance.currentUser;
      final teacherSnapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(currentUser?.uid)
          .collection('teacher_assignments')
          .doc(_connectedStudentUid)
          .collection('weekly')
          .doc(weekKey)
          .get();

      if (teacherSnapshot.exists) {
        setState(() {
          _assignments = List<String>.from(
              teacherSnapshot.data()?['assignments'] ?? []);
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

  Future<void> _saveAssignments() async {
    if (_connectedStudentUid == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final weekKey =
        DateFormat('yyyy-MM-dd').format(_currentWeek);

    try {
      // 배치 작업을 위한 WriteBatch 생성
      final batch = FirebaseFirestore.instance.batch();

      // 1. 선생님의 과제 데이터 저장
      final teacherAssignmentRef = FirebaseFirestore
          .instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('teacher_assignments')
          .doc(_connectedStudentUid)
          .collection('weekly')
          .doc(weekKey);

      batch.set(teacherAssignmentRef, {
        'assignments': _assignments,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. 학생의 과제 데이터 저장
      final studentAssignmentRef = FirebaseFirestore
          .instance
          .collection('users')
          .doc(_connectedStudentUid)
          .collection('assignments')
          .doc(weekKey);

      batch.set(studentAssignmentRef, {
        'assignments': _assignments,
        'completionStatus':
            List.filled(_assignments.length, false),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 배치 작업 실행
      await batch.commit();

      print('Assignments saved successfully');
      print('Week: $weekKey');
      print('Assignments: $_assignments');
    } catch (e) {
      print('Error saving assignments: $e');
    }
  }

  void _addAssignment() {
    if (_assignmentController.text.isNotEmpty) {
      setState(() {
        _assignments.add(_assignmentController.text);
        _assignmentController.clear();
      });
      _saveAssignments();
    }
  }

  void _deleteAssignment(int index) {
    setState(() {
      _assignments.removeAt(index);
    });
    _saveAssignments();
  }

  // 과제 완료 상태 확인을 위한 새로운 메서드
  Future<void> _checkAssignmentStatus() async {
    if (_connectedStudentUid == null) return;

    final weekKey =
        DateFormat('yyyy-MM-dd').format(_currentWeek);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_connectedStudentUid)
          .collection('assignments')
          .doc(weekKey)
          .get();

      if (snapshot.exists) {
        final completionStatus = List<bool>.from(
            snapshot.data()?['completionStatus'] ?? []);
        // 여기서 완료 상태를 UI에 반영할 수 있습니다
        // 예: 각 과제 옆에 완료 여부 표시
      }
    } catch (e) {
      print('Error checking assignment status: $e');
    }
  }

  void _initializeCurrentWeek() {
    _currentWeek = _getWeekStartDate(DateTime.now());
    _loadAssignments();
  }

  @override
  void dispose() {
    _assignmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelYellow,
      appBar: AppBar(
        title: const Text('주간 과제',
            style: TextStyle(color: Colors.black87)),
        backgroundColor: pastelBlue,
        elevation: 0,
      ),
      // 여기서 Column을 ResizeToAvoidBottomInset와 SafeArea로 감싸줍니다
      body: SafeArea(
        child: Column(
          children: [
            _buildWeekNavigator(),
            Expanded(
              child: _buildAssignmentList(),
            ),
            Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context)
                      .viewInsets
                      .bottom),
              child: _buildAddAssignmentField(),
            ),
          ],
        ),
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
            title: Text(_assignments[index],
                style:
                    const TextStyle(color: Colors.black87)),
            trailing: IconButton(
              icon: const Icon(Icons.delete,
                  color: Colors.red),
              onPressed: () => _deleteAssignment(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddAssignmentField() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16.0, vertical: 8.0), // 패딩 수정
      decoration: BoxDecoration(
        color: pastelPink,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 추가
        children: [
          Expanded(
            child: Container(
              // TextField를 Container로 감싸서 높이 제한
              constraints: const BoxConstraints(
                  maxHeight: 50), // 높이 제한 추가
              child: TextField(
                controller: _assignmentController,
                decoration: InputDecoration(
                  hintText: '새로운 과제 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _addAssignment,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(14),
              backgroundColor: pastelBlue,
            ),
            child:
                const Icon(Icons.add, color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _changeWeek(int weeks) {
    setState(() {
      _currentWeek =
          _currentWeek.add(Duration(days: 7 * weeks));
      _loadAssignments();
    });
  }

  DateTime _getWeekStartDate(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  String _getWeekRangeText(DateTime weekStart) {
    DateTime weekEnd =
        weekStart.add(const Duration(days: 6));
    return '${DateFormat('MM월 dd일').format(weekStart)} - ${DateFormat('MM월 dd일').format(weekEnd)}';
  }
}

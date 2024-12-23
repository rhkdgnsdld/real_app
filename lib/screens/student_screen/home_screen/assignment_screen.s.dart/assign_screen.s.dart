import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentWeeklyAssignmentScreen extends StatefulWidget {
  const StudentWeeklyAssignmentScreen({super.key});

  @override
  State<StudentWeeklyAssignmentScreen> createState() =>
      _StudentWeeklyAssignmentScreenState();
}

class _StudentWeeklyAssignmentScreenState
    extends State<StudentWeeklyAssignmentScreen> {
  late DateTime _currentWeek;
  List<Map<String, dynamic>> _assignments = [];
  String? _connectedTeacherId;
  String? _connectedTeacherUid;
  String? _teacherName;
  bool _isLoading = true;

  final Color mainGreen = const Color(0xFF36D19D);

  @override
  void initState() {
    super.initState();
    _initializeCurrentWeek();
    _loadConnectedTeacher();
  }

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

  DateTime _getWeekStartDate(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Icon(Icons.calendar_today,
              color: mainGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            _getWeekRangeText(_currentWeek),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: mainGreen),
          onPressed: () => _changeWeek(-1),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: mainGreen),
          onPressed: () => _changeWeek(1),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildTeacherInfo(),
        _buildSummaryCards(),
        Expanded(
          child: _buildAssignmentList(),
        ),
      ],
    );
  }

  Widget _buildTeacherInfo() {
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
            backgroundColor: mainGreen.withOpacity(0.1),
            child: Text(
              _teacherName?.substring(0, 1) ?? '',
              style: TextStyle(color: mainGreen),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _teacherName ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '선생님 ID: $_connectedTeacherId',
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

  Widget _buildSummaryCards() {
    final completedCount =
        _assignments.where((a) => a['completed']).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              '총 과제',
              _assignments.length.toString(),
              mainGreen.withOpacity(0.1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              '완료된 과제',
              completedCount.toString(),
              mainGreen.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: mainGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentList() {
    if (_assignments.isEmpty) {
      return Center(
        child: Text(
          '등록된 과제가 없습니다',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              title: Text(
                assignment['content'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: assignment['completed']
                      ? TextDecoration.lineThrough
                      : null,
                  color: assignment['completed']
                      ? Colors.grey
                      : Colors.black87,
                ),
              ),
              trailing: IconButton(
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
                icon: Icon(
                  assignment['completed']
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: assignment['completed']
                      ? mainGreen
                      : Colors.grey[400],
                  size: 20,
                ),
                onPressed: () => _toggleAssignment(index),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getWeekRangeText(DateTime weekStart) {
    DateTime weekEnd =
        weekStart.add(const Duration(days: 6));
    return '${DateFormat('MM월 dd일').format(weekStart)} - ${DateFormat('MM월 dd일').format(weekEnd)}';
  }
}

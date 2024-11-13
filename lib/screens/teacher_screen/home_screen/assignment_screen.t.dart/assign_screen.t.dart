import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherWeeklyAssignmentScreen extends StatefulWidget {
  const TeacherWeeklyAssignmentScreen({super.key});

  @override
  State<TeacherWeeklyAssignmentScreen> createState() =>
      _TeacherWeeklyAssignmentScreenState();
}

class _TeacherWeeklyAssignmentScreenState
    extends State<TeacherWeeklyAssignmentScreen> {
  late DateTime _currentWeek;
  final TextEditingController _assignmentController =
      TextEditingController();
  final TextEditingController _searchController =
      TextEditingController();
  List<String> _assignments = [];
  String? _connectedStudentId;
  String? _connectedStudentUid;
  String? _studentName;
  bool _isLoading = true;

  // 테마 컬러 정의
  final Color mainBlue = const Color(0xFF5BABEF);

  @override
  void initState() {
    super.initState();
    _initializeCurrentWeek();
    _loadConnectedStudent();
  }

  void _initializeCurrentWeek() {
    _currentWeek = _getWeekStartDate(DateTime.now());
  }

  Future<void> _loadConnectedStudent() async {
    setState(() => _isLoading = true);
    try {
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

          final studentDocs = await FirebaseFirestore
              .instance
              .collection('users')
              .where('userId', isEqualTo: studentId)
              .get();

          if (studentDocs.docs.isNotEmpty) {
            setState(() {
              _connectedStudentId = studentId;
              _connectedStudentUid =
                  studentDocs.docs.first.id;
              _studentName =
                  studentDocs.docs.first.data()['name'];
              _isLoading = false;
            });
            await _loadAssignments();
          }
        }
      }
    } catch (e) {
      print('Error loading student: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssignments() async {
    if (_connectedStudentUid == null) return;

    try {
      final weekKey =
          DateFormat('yyyy-MM-dd').format(_currentWeek);
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
      final batch = FirebaseFirestore.instance.batch();

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

      await batch.commit();
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
              color: mainBlue, size: 20),
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
          icon: Icon(Icons.chevron_left, color: mainBlue),
          onPressed: () => _changeWeek(-1),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: mainBlue),
          onPressed: () => _changeWeek(1),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildStudentInfo(),
        _buildSummaryCards(),
        Expanded(
          child: _buildAssignmentList(),
        ),
        _buildAddAssignmentField(),
      ],
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

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              '총 과제',
              _assignments.length.toString(),
              mainBlue.withOpacity(0.1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              '완료된 과제',
              '0', // 이 부분은 실제 완료된 과제 수를 계산하여 표시
              mainBlue.withOpacity(0.1),
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
              color: mainBlue,
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
                _assignments[index],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: IconButton(
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
                icon: Icon(Icons.delete_outline,
                    color: Colors.red[400], size: 20),
                onPressed: () => _deleteAssignment(index),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddAssignmentField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _assignmentController,
              decoration: InputDecoration(
                hintText: '새로운 과제 입력',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _addAssignment,
            style: ElevatedButton.styleFrom(
              backgroundColor: mainBlue,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(8),
            ),
            child:
                const Icon(Icons.add, color: Colors.white),
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

  @override
  void dispose() {
    _assignmentController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

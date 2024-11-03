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
      final connection = await FirebaseFirestore.instance
          .collection('connections')
          .where('studentId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      if (connection.docs.isNotEmpty) {
        _connectedTeacherId =
            connection.docs.first.data()['teacherId'];
        _loadAssignments();
      }
    }
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

  void _loadAssignments() async {
    final weekKey =
        DateFormat('yyyy-MM-dd').format(_currentWeek);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('assignments')
        .doc(weekKey)
        .get();

    if (snapshot.exists) {
      final assignmentList = List<String>.from(
          snapshot.data()?['assignments'] ?? []);
      setState(() {
        _assignments = assignmentList
            .map((assignment) => {
                  'content': assignment,
                  'completed': false,
                })
            .toList();
      });
    } else {
      setState(() {
        _assignments = [];
      });
    }
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

  void _toggleAssignment(int index) async {
    setState(() {
      _assignments[index]['completed'] =
          !_assignments[index]['completed'];
    });

    // 완료 상태를 Firebase에 저장
    final weekKey =
        DateFormat('yyyy-MM-dd').format(_currentWeek);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('assignments')
        .doc(weekKey)
        .update({
      'completionStatus':
          _assignments.map((a) => a['completed']).toList(),
    });
  }
}

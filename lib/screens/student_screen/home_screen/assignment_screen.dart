import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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

  // 파스텔 색상 정의
  final Color pastelBlue = Colors.white;
  final Color pastelGreen = Colors.white;
  final Color pastelPink = Colors.blue;
  final Color pastelYellow = const Color(0xFFAED6F1);

  @override
  void initState() {
    super.initState();
    _initializeCurrentWeek();
  }

  void _initializeCurrentWeek() {
    _currentWeek = _getWeekStartDate(DateTime.now());
    _loadAssignments();
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
    final prefs = await SharedPreferences.getInstance();
    String weekKey =
        DateFormat('yyyy-MM-dd').format(_currentWeek);
    List<String>? savedAssignments =
        prefs.getStringList(weekKey);
    setState(() {
      if (savedAssignments != null) {
        _assignments = savedAssignments
            .map((assignment) => {
                  'content': assignment,
                  'completed': false,
                })
            .toList();
      } else {
        _assignments = [];
      }
    });
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

  void _toggleAssignment(int index) {
    setState(() {
      _assignments[index]['completed'] =
          !_assignments[index]['completed'];
    });
  }
}

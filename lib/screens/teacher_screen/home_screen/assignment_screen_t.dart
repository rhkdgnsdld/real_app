import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
      body: Column(
        children: [
          _buildWeekNavigator(),
          Expanded(
            child: _buildAssignmentList(),
          ),
          _buildAddAssignmentField(),
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
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: pastelPink,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Expanded(
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
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

  void _loadAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    String weekKey =
        DateFormat('yyyy-MM-dd').format(_currentWeek);
    setState(() {
      _assignments = prefs.getStringList(weekKey) ?? [];
    });
  }

  void _saveAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    String weekKey =
        DateFormat('yyyy-MM-dd').format(_currentWeek);
    await prefs.setStringList(weekKey, _assignments);
  }

  void _addAssignment() {
    if (_assignmentController.text.isNotEmpty) {
      setState(() {
        _assignments.add(_assignmentController.text);
        _saveAssignments();

        // 디버그 콘솔 출력
        print('과제 추가 시간: ${DateTime.now()}');
        print('추가된 과제: ${_assignmentController.text}');
        print(
            '현재 선택된 주: ${_getWeekRangeText(_currentWeek)}');

        _assignmentController.clear();
      });
    }
  }

  void _deleteAssignment(int index) {
    setState(() {
      _assignments.removeAt(index);
      _saveAssignments();
    });
  }
}

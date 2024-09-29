import 'package:flutter/material.dart';
import 'package:new_new_app/screens/student_screen/calendar_screen/schedule_utils.dart';
import 'assignment_screen.dart';
import 'attendance_screen.dart';
import 'material_screen.dart';
import 'chat_screen.dart';
import 'grades_screen.dart';
import '../profile_screen/studentprofile_screen.dart';
import 'package:new_new_app/widgets/button.dart'; // 달력 화면을 위한 import (아직 생성하지 않았다면 만들어야 합니다)
import 'package:shared_preferences/shared_preferences.dart';

class MainStudentScreen extends StatefulWidget {
  const MainStudentScreen({super.key});

  @override
  _MainStudentScreenState createState() =>
      _MainStudentScreenState();
}

class _MainStudentScreenState
    extends State<MainStudentScreen> {
  int _currentIndex = 0;

  final List<Widget> _children = [
    const HomeScreen(),
    const TimetablePage(),
    const StudentprofileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '일정',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _StudentName = '';

  @override
  void initState() {
    super.initState();
    _loadStudentName();
  }

  Future<void> _loadStudentName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _StudentName = prefs.getString('studentName') ?? '학생';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.blue,
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '안녕하세요! $_StudentName 학생',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                          child: CustomButton(
                              text: '이번주의 과제',
                              icon: Icons.assignment,
                              screen: AssignmentScreen())),
                      SizedBox(width: 16),
                      Expanded(
                          child: CustomButton(
                              text: '출결 확인하기',
                              icon: Icons.check_circle,
                              screen: AttendanceScreen())),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                          child: CustomButton(
                              text: '수업 자료 확인하기',
                              icon: Icons.book,
                              screen: MaterialsScreen())),
                      SizedBox(width: 16),
                      Expanded(
                          child: CustomButton(
                              text: '선생님과의 대화',
                              icon: Icons.chat,
                              screen: ChatScreen())),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: WideButton(
                      text: '성적 누적 추이 확인',
                      icon: Icons.trending_up,
                      screen: GradesScreen()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

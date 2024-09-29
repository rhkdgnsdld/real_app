import 'package:flutter/material.dart';

import 'assignment_screen_t.dart';
import 'attendance_screen_t.dart';
import 'material_screen_t.dart';
import 'chat_screen_t.dart';
import 'grades.dart';
import 'package:new_new_app/widgets/button.dart';
import '../profile_screen/teacherprofile_screen.dart';
import '../calendar_screen/calendar_screen_t.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainTeacherScreen extends StatefulWidget {
  const MainTeacherScreen({super.key});

  @override
  _MainTeacherScreenState createState() =>
      _MainTeacherScreenState();
}

class _MainTeacherScreenState
    extends State<MainTeacherScreen> {
  int _currentIndex = 0;

  final List<Widget> _children = [
    const HomeScreen(),
    const WeeklyScheduleScreen(),
    const TeacherprofileScreen(),
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
  String _TeacherName = '';

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _TeacherName =
          prefs.getString('teacherName') ?? '선생님';
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
                '안녕하세요! $_TeacherName 선생님',
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
                              text: '과제 부여하기',
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
                              text: '수업 자료 업로드하기',
                              icon: Icons.book,
                              screen: MaterialsScreen())),
                      SizedBox(width: 16),
                      Expanded(
                          child: CustomButton(
                              text: '학생과의 대화',
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
                      screen: GradeTrendScreenT()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

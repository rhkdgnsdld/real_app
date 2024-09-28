import 'package:flutter/material.dart';
import 'assignment_screen.dart';
import 'attendance_screen.dart';
import 'material_screen.dart';
import 'chat_screen.dart';
import 'grades_screen.dart';
import 'package:new_new_app/widgets/button.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue,
            child: const SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '안녕하세요! 김현민 학생',
                  style: TextStyle(
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
                                screen:
                                    AssignmentScreen())),
                        SizedBox(width: 16),
                        Expanded(
                            child: CustomButton(
                                text: '출결 확인하기',
                                icon: Icons.check_circle,
                                screen:
                                    AttendanceScreen())),
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.circle),
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
}

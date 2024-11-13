import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:new_new_app/screens/teacher_screen/chat.screen/new_chat_t.dart';
import 'package:new_new_app/screens/teacher_screen/home_screen/assignment_screen.t.dart/assign_screen.t.dart';
import 'package:new_new_app/screens/teacher_screen/home_screen/grade/grade_teacher.dart';
import 'attendance/attendance_screen_t.dart';
import 'handsout/material_screen_t.dart';
import '../calendar_screen/calendar.t.dart';
import 'package:new_new_app/widgets/button.dart';

class MainTeacherScreenR extends StatefulWidget {
  const MainTeacherScreenR({super.key});

  @override
  _MainTeacherScreenState createState() =>
      _MainTeacherScreenState();
}

class _MainTeacherScreenState
    extends State<MainTeacherScreenR> {
  int _currentIndex = 0;
  String _teacherName = '';

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        final teacherDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (teacherDoc.exists) {
          final userData =
              teacherDoc.data() as Map<String, dynamic>;
          if (userData['job'] == '선생님') {
            setState(() {
              _teacherName = userData['name'] ?? '선생님';
            });
          }
        }
      }
    } catch (e) {
      print("Error loading teacher name: $e");
      setState(() {
        _teacherName = '선생님';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'HiClass',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          const Text(
                            '!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5BABEF),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '스마트한 학생 관리의 시작',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 환영 메시지
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(
                    '환영합니다, $_teacherName 선생님!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '효율적인 학생 관리를 위한 모든 도구가 준비되어 있습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // 메뉴 리스트
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  children: [
                    MenuCard(
                      icon: Icons.assignment,
                      title: '과제 부여하기',
                      description:
                          '새로운 과제를 등록하고 제출 현황을 확인하세요',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TeacherWeeklyAssignmentScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    MenuCard(
                      icon: Icons.people,
                      title: '출결 확인하기',
                      description: '학생들의 출석 현황을 확인하고 관리하세요',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AttendanceScreenT(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    MenuCard(
                      icon: Icons.book,
                      title: '수업자료 업로드',
                      description: '수업 자료를 업로드하고 관리하세요',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TeacherFileUploadScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    MenuCard(
                      icon: Icons.trending_up,
                      title: '성적 누적추이',
                      description: '학생들의 성적 변화와 통계를 확인하세요',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TeacherGradeTrendScreenR(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const WeeklyScheduleScreenT(),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const TeacherChatScreenT(),
              ),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
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
            icon: Icon(Icons.chat_rounded),
            label: '채팅',
          ),
        ],
        selectedItemColor: const Color(0xFF5BABEF),
      ),
    );
  }
}

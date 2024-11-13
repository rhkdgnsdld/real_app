import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:new_new_app/screens/student_screen/calendar_screen/calendar_student.dart';
import 'package:new_new_app/screens/student_screen/chat_student/new_chat_s.dart';
import 'package:new_new_app/screens/student_screen/home_screen/grade_screen/grade_screen.s.dart';
import 'attendance/attendance_screen.dart';
import 'handsout/material_screen.dart';
import 'assignment_screen.s.dart/assign_screen.s.dart';
import 'timer_screen.dart';
import 'package:new_new_app/widgets/button.dart';

class MainStudentScreen extends StatefulWidget {
  const MainStudentScreen({super.key});

  @override
  _MainStudentScreenState createState() =>
      _MainStudentScreenState();
}

class _MainStudentScreenState
    extends State<MainStudentScreen> {
  int _currentIndex = 0;
  String _studentName = '';

  @override
  void initState() {
    super.initState();
    _loadStudentName();
  }

  Future<void> _loadStudentName() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        final studentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (studentDoc.exists) {
          final userData =
              studentDoc.data() as Map<String, dynamic>;
          if (userData['job'] == '학생') {
            setState(() {
              _studentName = userData['name'] ?? '학생';
            });
          }
        }
      }
    } catch (e) {
      print("Error loading student name: $e");
      setState(() {
        _studentName = '학생';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 1) {
      return const WeeklyScheduleScreenST();
    } else if (_currentIndex == 2) {
      return const StudentChatScreenS();
    }

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
                              color: Color(0xFF36D19D),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '스마트한 학습 관리의 시작',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.timer,
                      color: Color(0xFF36D19D),
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TimerScreen(),
                        ),
                      );
                    },
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
                    '환영합니다, $_studentName 학생!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '효율적인 학습 관리를 위한 모든 도구가 준비되어 있습니다',
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
                    MenuCardS(
                      icon: Icons.assignment,
                      title: '이번주의 과제',
                      description: '새로운 과제를 확인하고 제출하세요',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const StudentWeeklyAssignmentScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    MenuCardS(
                      icon: Icons.people,
                      title: '출결 확인하기',
                      description: '나의 출석 현황을 확인하세요',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AttendanceScreenS(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    MenuCardS(
                      icon: Icons.book,
                      title: '수업 자료 확인하기',
                      description: '선생님이 업로드한 수업 자료를 확인하세요',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const StudentFileListScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    MenuCardS(
                        icon: Icons.trending_up,
                        title: '성적 누적추이',
                        description: '나의 성적 변화와 통계를 확인하세요',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const GradeTrendScreenR(),
                            ),
                          );
                        }),
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
          setState(() {
            _currentIndex = index;
          });
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
        selectedItemColor: const Color(0xFF36D19D),
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF36D19D)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF36D19D),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

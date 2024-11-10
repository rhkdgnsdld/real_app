import 'package:flutter/material.dart';

import 'assignment_screen_t.dart';
import 'attendance_screen_t.dart';
import 'material_screen_t.dart';
import 'chat_screen_t.dart';
import 'grades.dart';
import 'package:new_new_app/widgets/button.dart';
import '../profile_screen/teacherprofile_screen.dart';
import '../calendar_screen/widget_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

Future<void> _showConnectionDialog(
    BuildContext context) async {
  final currentUser = FirebaseAuth.instance.currentUser;

  // 교사 정보 로드
  final teacherDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser!.uid)
      .get();

  final teacherData = teacherDoc.data();
  final teacherUserId = teacherData?['userId'] ?? '';
  final teacherName =
      teacherData?['name'] ?? ''; // 교사 이름 추가

  final studentIdController = TextEditingController();
  final studentNameController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('학생 연동'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: studentIdController,
            decoration: const InputDecoration(
              labelText: '학생 ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: studentNameController,
            decoration: const InputDecoration(
              labelText: '학생 이름',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () async {
            try {
              if (studentIdController.text.isEmpty ||
                  studentNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('모든 필드를 입력해주세요.')),
                );
                return;
              }

              // 학생 존재 여부 확인
              final studentDocs = await FirebaseFirestore
                  .instance
                  .collection('users')
                  .where('userId',
                      isEqualTo: studentIdController.text)
                  .where('job', isEqualTo: '학생')
                  .get();

              if (studentDocs.docs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('존재하지 않는 학생입니다.')),
                );
                return;
              }

              final studentUid = studentDocs.docs.first.id;
              final studentData =
                  studentDocs.docs.first.data();
              final studentName = studentData['name'] ?? '';

              // 이미 연동 요청이 있는지 확인
              final existingConnection =
                  await FirebaseFirestore.instance
                      .collection('connections')
                      .where('studentId',
                          isEqualTo:
                              studentIdController.text)
                      .where('teacherId',
                          isEqualTo: teacherUserId)
                      .get();

              if (existingConnection.docs.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('이미 연동 요청이 존재합니다.')),
                );
                return;
              }

              // Firestore에 연동 요청 저장 (이름 정보 포함)
              await FirebaseFirestore.instance
                  .collection('connections')
                  .doc()
                  .set({
                'teacherId': teacherUserId,
                'teacherName': teacherName, // 교사 이름 추가
                'studentId': studentIdController.text,
                'studentName': studentName, // 학생 이름 추가
                'status': 'pending',
                'timestamp': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('연동 요청을 보냈습니다.')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('오류가 발생했습니다: $e')),
              );
            }
          },
          child: const Text('연동 요청'),
        ),
      ],
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _teacherName = '';

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final teacherDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (teacherDoc.exists) {
        setState(() {
          _teacherName =
              teacherDoc.data()?['name'] ?? '선생님';
        });
      }
    }
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
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '안녕하세요! $_teacherName 선생님',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.connect_without_contact,
                    color: Colors.white,
                  ),
                  onPressed: () =>
                      _showConnectionDialog(context),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                const Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: '과제 부여하기',
                          icon: Icons.assignment,
                          screen: WeeklyAssignmentScreen(),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: '출결 확인하기',
                          icon: Icons.check_circle,
                          screen: AttendanceScreenT(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: '수업 자료 업로드하기',
                          icon: Icons.book,
                          screen: TeacherFileUploadScreen(),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: '학생과의 대화',
                          icon: Icons.chat,
                          screen: ChatScreen(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16.0),
                        ),
                      ),
                      onPressed: () async {
                        // 현재 선생님의 연결된 학생 정보 가져오기
                        final currentUser = FirebaseAuth
                            .instance.currentUser;
                        if (currentUser != null) {
                          // connections 컬렉션에서 현재 선생님과 연결된 학생 찾기
                          final connections =
                              await FirebaseFirestore
                                  .instance
                                  .collection('connections')
                                  .where('teacherId',
                                      isEqualTo:
                                          currentUser.uid)
                                  .where('status',
                                      isEqualTo: 'accepted')
                                  .get();

                          if (connections.docs.isNotEmpty) {
                            // 첫 번째 연결된 학생의 ID 가져오기
                            final studentId = connections
                                .docs.first
                                .data()['studentId'];

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GradeTrendScreenT(
                                        studentUid:
                                            studentId),
                              ),
                            );
                          } else {
                            // 연결된 학생이 없는 경우
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      '연결된 학생이 없습니다.')),
                            );
                          }
                        }
                      },
                      child: const Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.trending_up,
                              size: 48, color: Colors.blue),
                          SizedBox(height: 8),
                          Text(
                            '성적 누적 추이 확인',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

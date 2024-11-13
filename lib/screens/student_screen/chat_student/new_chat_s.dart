import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../home_screen/new.main.sscreen.dart';
import '../calendar_screen/calendar_student.dart';

class StudentChatScreenS extends StatefulWidget {
  const StudentChatScreenS({super.key});

  @override
  State<StudentChatScreenS> createState() =>
      _StudentChatScreenState();
}

class _StudentChatScreenState
    extends State<StudentChatScreenS> {
  final TextEditingController _messageController =
      TextEditingController();
  String? _connectedTeacherId;
  String? _connectedTeacherUid;
  String? _teacherName;
  bool _isLoading = true;
  String? _connectionRequestId;

  @override
  void initState() {
    super.initState();
    _loadConnectedTeacher();
    _watchConnectionRequests();
  }

  Future<void> _loadConnectedTeacher() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userUserId =
          userDoc.data()?['userId'] as String?;

      final connection = await FirebaseFirestore.instance
          .collection('connections')
          .where('studentId', isEqualTo: userUserId)
          .where('status', isEqualTo: 'accepted')
          .get();

      if (connection.docs.isNotEmpty) {
        final teacherId = connection.docs.first
            .data()['teacherId'] as String?;

        final teacherQuery = await FirebaseFirestore
            .instance
            .collection('users')
            .where('userId', isEqualTo: teacherId)
            .get();

        if (teacherQuery.docs.isNotEmpty) {
          final teacherDoc = teacherQuery.docs.first;
          setState(() {
            _connectedTeacherId = teacherId;
            _connectedTeacherUid = teacherDoc.id;
            _teacherName =
                teacherDoc.data()['name'] as String? ??
                    '선생님';
          });
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _watchConnectionRequests() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // 현재 학생의 userId 가져오기
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userUserId =
          userDoc.data()?['userId'] as String?;
      if (userUserId == null) return;

      // 연동 요청 실시간 감시
      FirebaseFirestore.instance
          .collection('connections')
          .where('studentId', isEqualTo: userUserId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            _connectionRequestId = snapshot.docs.first.id;
          });
        } else {
          setState(() {
            _connectionRequestId = null;
          });
        }
      });
    } catch (e) {
      print('Error watching connection requests: $e');
    }
  }

  Future<void> _acceptConnection() async {
    if (_connectionRequestId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('connections')
          .doc(_connectionRequestId)
          .update({'status': 'accepted'});

      // 연동된 선생님 정보 로드
      _loadConnectedTeacher();
    } catch (e) {
      print('Error accepting connection: $e');
    }
  }

  Future<void> _rejectConnection() async {
    if (_connectionRequestId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('connections')
          .doc(_connectionRequestId)
          .delete();
    } catch (e) {
      print('Error rejecting connection: $e');
    }
  }

  Widget _buildWaitingScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            '선생님의 연동 요청을 기다리고 있어요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '곧 맞춤형 학습이 시작됩니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.person_add_rounded,
                  size: 48,
                  color: Color(0xFF36D19D),
                ),
                const SizedBox(height: 16),
                Text(
                  '선생님의 연동 요청이 도착했어요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _acceptConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF36D19D),
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('수락하기'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _rejectConnection,
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('거절하기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                              color: Color(0xFF36D19D),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '맞춤형 학습의 시작',
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

            // 메인 컨텐츠
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator())
                  : _connectedTeacherId != null
                      ? _buildChatScreen()
                      : _connectionRequestId != null
                          ? _buildRequestScreen()
                          : _buildWaitingScreen(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // 채팅 탭
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const MainStudentScreen(),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const WeeklyScheduleScreenST(),
              ),
            );
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
            icon: Icon(Icons.chat),
            label: '채팅',
          ),
        ],
        selectedItemColor: const Color(0xFF36D19D),
      ),
    );
  }

  Widget _buildChatScreen() {
    return Column(
      children: [
        Expanded(
          child: _buildMessageList(),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF36D19D),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: Colors.white,
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// 메시지 버블의 색상도 수정
  Widget _buildMessageBubble(
      String message, bool isMe, Timestamp? timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF36D19D)
                  : Colors.white, // 색상 변경
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                if (timestamp != null)
                  Text(
                    DateFormat('HH:mm')
                        .format(timestamp.toDate()),
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe
                          ? Colors.white70
                          : Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_connectedTeacherUid == null) {
      return const Center(
          child: CircularProgressIndicator());
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('로그인이 필요합니다'));
    }

    final connectionId =
        '${currentUser.uid}_$_connectedTeacherUid';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .where('connectionId', isEqualTo: connectionId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('오류가 발생했습니다'));
        }

        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;

        if (messages.isEmpty) {
          return const Center(
            child: Text('메시지가 없습니다'),
          );
        }

        // padding을 ListView.builder에 추가
        return ListView.builder(
          reverse: true,
          padding:
              const EdgeInsets.all(16), // 여기에 padding 추가
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data()
                as Map<String, dynamic>;
            final content =
                messageData['content'] as String? ?? '';
            final isMe =
                messageData['senderId'] == currentUser.uid;
            final timestamp =
                messageData['timestamp'] as Timestamp?;

            return _buildMessageBubble(
                content, isMe, timestamp);
          },
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _connectedTeacherUid == null) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final connectionId =
          '${currentUser.uid}_$_connectedTeacherUid';

      await FirebaseFirestore.instance
          .collection('messages')
          .add({
        'connectionId': connectionId,
        'senderId': currentUser.uid,
        'senderName': '학생',
        'receiverId': _connectedTeacherUid,
        'receiverName': _teacherName ?? '선생님',
        'content': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      _messageController.clear();
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../home_screen/new.main.tscreen.dart';
import '../calendar_screen/calendar.t.dart';

class TeacherChatScreenT extends StatefulWidget {
  const TeacherChatScreenT({super.key});

  @override
  State<TeacherChatScreenT> createState() =>
      _TeacherChatScreenState();
}

class _TeacherChatScreenState
    extends State<TeacherChatScreenT> {
  final TextEditingController _messageController =
      TextEditingController();
  final TextEditingController _studentIdController =
      TextEditingController();
  final ScrollController _scrollController =
      ScrollController();
  String? _connectedStudentId;
  String? _connectedStudentUid;
  String? _studentName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConnectedStudent();
  }

  Future<void> _loadConnectedStudent() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // 현재 선생님의 user 정보 가져오기
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userUserId =
          userDoc.data()?['userId'] as String?;
      if (userUserId == null) return;

      // connections 조회
      final connection = await FirebaseFirestore.instance
          .collection('connections')
          .where('teacherId', isEqualTo: userUserId)
          .where('status', isEqualTo: 'accepted')
          .get();

      if (connection.docs.isNotEmpty) {
        final studentId = connection.docs.first
            .data()['studentId'] as String;

        // 학생 정보 조회
        final studentQuery = await FirebaseFirestore
            .instance
            .collection('users')
            .where('userId', isEqualTo: studentId)
            .get();

        if (studentQuery.docs.isNotEmpty) {
          setState(() {
            _connectedStudentId = studentId;
            _connectedStudentUid = studentQuery
                .docs.first.id; // Firebase UID 사용
            _studentName = studentQuery.docs.first
                    .data()['name'] as String? ??
                '학생';
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

  Future<void> _requestConnection() async {
    if (_studentIdController.text.trim().isEmpty) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // 입력된 studentId로 학생 찾기
      final studentQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('userId',
              isEqualTo: _studentIdController.text.trim())
          .where('job', isEqualTo: '학생')
          .get();

      if (studentQuery.docs.isEmpty) {
        // 에러 처리
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('존재하지 않는 학생 ID입니다')),
        );
        return;
      }

      final teacherDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final teacherUserId =
          teacherDoc.data()?['userId'] as String?;
      if (teacherUserId == null) return;

// 연동 요청 생성
      await FirebaseFirestore.instance
          .collection('connections')
          .add({
        'teacherId': teacherUserId, // userId 사용
        'studentId': studentQuery.docs.first
            .data()['userId'], // studentId도 userId 필드 사용
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _studentIdController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연동 요청을 보냈습니다')),
      );
    } catch (e) {
      print('Error requesting connection: $e');
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
                        '1:1 맞춤 관리',
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
                  : _connectedStudentId == null
                      ? _buildConnectionScreen()
                      : _buildChatScreen(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // 채팅 탭이 활성화
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const MainTeacherScreenR(),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const WeeklyScheduleScreenT(),
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
        selectedItemColor: const Color(0xFF5BABEF),
      ),
    );
  }

  Widget _buildConnectionScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘
          Icon(
            Icons.person_add_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),

          // 안내 텍스트
          Text(
            '학생과 연동을 시작해보세요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '1:1 채팅기능을 사용해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 입력 필드
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                hintText: '학생 ID를 입력하세요',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 연동 요청 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _requestConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BABEF),
                padding: const EdgeInsets.symmetric(
                    vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '연동 요청하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatScreen() {
    return Column(
      children: [
        // 채팅 목록
        Expanded(
          child: _buildMessageList(),
        ),
        // 메시지 입력
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
                  color: const Color(0xFF5BABEF),
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

  Widget _buildMessageList() {
    if (_connectedStudentUid == null ||
        _connectedStudentId == null) {
      return const Center(
          child: CircularProgressIndicator());
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('로그인이 필요합니다'));
    }

    final connectionId =
        '${_connectedStudentUid}_${currentUser.uid}';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .where('connectionId', isEqualTo: connectionId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('오류가 발생했습니다: ${snapshot.error}'));
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

        String? currentDate;

        return ListView.builder(
          reverse: true,
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data()
                as Map<String, dynamic>;
            final timestamp =
                messageData['timestamp'] as Timestamp?;
            final isMe =
                messageData['senderId'] == currentUser.uid;
            final content =
                messageData['content'] as String? ?? '';

            Widget? dateWidget;
            if (timestamp != null) {
              final messageDate =
                  DateFormat('yyyy년 MM월 dd일')
                      .format(timestamp.toDate());
              if (currentDate != messageDate) {
                currentDate = messageDate;
                dateWidget = _buildDateDivider(messageDate);
              }
            }

            return Column(
              children: [
                if (dateWidget != null) dateWidget,
                _buildMessageBubble(
                    content, isMe, timestamp),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateDivider(String date) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          date,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

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
              color: isMe ? Colors.blue : Colors.white,
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

  Future<void> _sendMessage() async {
    try {
      if (_messageController.text.trim().isEmpty ||
          _connectedStudentUid == null ||
          _connectedStudentId == null) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // connectionId를 항상 studentId_teacherId 형식으로 통일
      final connectionId =
          '${_connectedStudentUid}_${currentUser.uid}';

      await FirebaseFirestore.instance
          .collection('messages')
          .add({
        'connectionId': connectionId,
        'senderId': currentUser.uid,
        'senderName': '선생님',
        'receiverId': _connectedStudentUid,
        'receiverName': _studentName ?? '학생',
        'content': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _studentIdController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

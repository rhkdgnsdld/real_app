import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TeacherChatScreen extends StatefulWidget {
  const TeacherChatScreen({super.key});

  @override
  State<TeacherChatScreen> createState() =>
      _TeacherChatScreenState();
}

class _TeacherChatScreenState
    extends State<TeacherChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController =
      ScrollController();
  String? _connectedStudentId;
  String? _connectedStudentUid;
  String? _studentName;

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
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(_studentName ?? '학생'),
        elevation: 0,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildMessageList(),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom,
              ),
              child: Container(
                color: Colors.white,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            keyboardType:
                                TextInputType.text,
                            textInputAction:
                                TextInputAction.send,
                            onSubmitted: (_) =>
                                _sendMessage(),
                            decoration:
                                const InputDecoration(
                              hintText: '메시지를 입력하세요...',
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(
                                      horizontal: 16),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.arrow_upward),
                          onPressed: _sendMessage,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

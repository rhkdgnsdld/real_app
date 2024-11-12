import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StudentChatScreen extends StatefulWidget {
  const StudentChatScreen({super.key});

  @override
  State<StudentChatScreen> createState() =>
      _StudentChatScreenState();
}

class _StudentChatScreenState
    extends State<StudentChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();
  String? _connectedTeacherId;
  String? _connectedTeacherUid;
  String? _teacherName;

  @override
  void initState() {
    super.initState();
    _loadConnectedTeacher();
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
    }
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

  Widget _buildMessageBubble(
      String message, bool isMe, Timestamp? timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 4), // horizontal padding 제거
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
              color: isMe ? Colors.green : Colors.white,
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
        backgroundColor: Colors.green,
        title: Text(_teacherName ?? '선생님'),
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
                          color: Colors.green,
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
    super.dispose();
  }
}

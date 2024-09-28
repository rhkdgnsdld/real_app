import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('선생님과의 대화'),
      ),
      body: const Center(
        child: Text('채팅 인터페이스가 여기에 표시됩니다.'),
      ),
    );
  }
}

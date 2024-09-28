import 'package:flutter/material.dart';

class AssignmentScreen extends StatelessWidget {
  const AssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이번주의 과제'),
      ),
      body: const Center(
        child: Text('이번주의 과제 내용이 여기에 표시됩니다.'),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('출결 확인하기'),
      ),
      body: const Center(
        child: Text('출결 현황이 여기에 표시됩니다.'),
      ),
    );
  }
}

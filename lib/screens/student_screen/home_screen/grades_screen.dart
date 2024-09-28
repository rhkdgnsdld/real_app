import 'package:flutter/material.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('성적 누적 추이 확인'),
      ),
      body: const Center(
        child: Text('성적 추이 그래프가 여기에 표시됩니다.'),
      ),
    );
  }
}

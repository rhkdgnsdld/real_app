import 'package:flutter/material.dart';

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' 시간표 수정 '),
      ),
      body: const Center(
        child: Text(' 시간표 수정 내용 추가하기 '),
      ),
    );
  }
}

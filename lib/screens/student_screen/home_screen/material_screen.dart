import 'package:flutter/material.dart';

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수업 자료 확인하기'),
      ),
      body: const Center(
        child: Text('수업 자료 목록이 여기에 표시됩니다.'),
      ),
    );
  }
}

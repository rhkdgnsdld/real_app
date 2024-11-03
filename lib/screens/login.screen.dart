import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreenR extends StatefulWidget {
  const LoginScreenR({super.key});

  @override
  State<LoginScreenR> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreenR> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    try {
      // ID를 이메일 형식으로 변환
      String email = "${_idController.text}@example.com";

      // 로그인 시도
      final credential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      // Firestore에서 사용자 정보 확인
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        // job 필드를 확인해서 적절한 화면으로 이동
        if (userData['job'] == '선생님') {
          Navigator.pushReplacementNamed(
              context, '/teacher');
        } else if (userData['job'] == '학생') {
          Navigator.pushReplacementNamed(
              context, '/student');
        }
      }
    } catch (e) {
      // 에러 메시지 처리
      String errorMessage = '로그인 실패: ';
      if (e.toString().contains('user-not-found')) {
        errorMessage += '존재하지 않는 아이디입니다.';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage += '잘못된 비밀번호입니다.';
      } else {
        errorMessage += e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: '아이디',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, 50),
              ),
              child: const Text('로그인'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}

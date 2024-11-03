import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:new_new_app/screens/login.dart';
import 'package:new_new_app/screens/login.screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? selectedJob;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        // 키보드가 올라와도 스크롤 가능하게
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
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
              obscureText: true, // 비밀번호 숨기기
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '전화번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone, // 전화번호 키패드
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '직업을 선택해주세요',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Radio<String>(
                      value: '학생',
                      groupValue: selectedJob,
                      onChanged: (String? value) {
                        setState(() {
                          selectedJob = value;
                        });
                      },
                    ),
                    const Text('학생'),
                  ],
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: '선생님',
                      groupValue: selectedJob,
                      onChanged: (String? value) {
                        setState(() {
                          selectedJob = value;
                        });
                      },
                    ),
                    const Text('선생님'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _signUp(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(
                    double.infinity, 50), // 버튼 크기
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                '회원가입',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    try {
      // 입력값 검증 추가
      if (_idController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _nameController.text.isEmpty ||
          _phoneController.text.isEmpty) {
        throw '모든 필드를 입력해주세요';
      }

      // 비밀번호 길이 검증
      if (_passwordController.text.length < 6) {
        throw '비밀번호는 최소 6자리 이상이어야 합니다';
      }

      // Firebase Auth로 계정 생성
      print(
          '회원가입 시도: ${_idController.text}@example.com'); // 로그 추가
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: "${_idController.text}@example.com",
        password: _passwordController.text,
      );

      print('Auth 성공, Firestore 저장 시도'); // 로그 추가
      // Firestore에 사용자 정보 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'userId': _idController.text,
        'name': _nameController.text,
        'phoneNumber': _phoneController.text,
        'job': selectedJob,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Firestore 저장 성공'); // 로그 추가
      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다!')),
      );

      // 로그인 페이지나 홈 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const LoginScreenR()),
      );
    } catch (e) {
      print('회원가입 실패 에러: $e'); // 구체적인 에러 로그
      // 에러 메시지 더 자세히 표시
      String errorMessage = '회원가입 실패: ';

      if (e.toString().contains('email-already-in-use')) {
        errorMessage += '이미 사용중인 아이디입니다.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage += '비밀번호가 너무 약합니다.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage += '잘못된 이메일 형식입니다.';
      } else {
        errorMessage += e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    _idController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

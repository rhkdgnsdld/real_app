import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              const Text(
                '반갑습니다 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '필요한 정보를 입력해주세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // 입력 필드들
              _buildTextField(
                controller: _idController,
                label: '아이디',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: '비밀번호',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: '이름',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: '전화번호',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // 직업 선택 섹션
              const Text(
                '직업',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[50],
                  border:
                      Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildJobOption('학생'),
                    Divider(
                        height: 1, color: Colors.grey[200]),
                    _buildJobOption('선생님'),
                  ],
                ),
              ),
              const Spacer(),

              // 회원가입 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _signUp(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 52, // 높이 줄임
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          prefixIcon:
              Icon(icon, color: Colors.grey[400], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildJobOption(String job) {
    return RadioListTile<String>(
      title: Text(
        job,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: job,
      groupValue: selectedJob,
      onChanged: (value) =>
          setState(() => selectedJob = value),
      activeColor: Colors.blue,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12),
      visualDensity: VisualDensity.compact, // 라디오 버튼 간격 줄임
    );
  }

  Future<void> _signUp() async {
    setState(() => isLoading = true);

    try {
      if (_idController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _nameController.text.isEmpty ||
          _phoneController.text.isEmpty ||
          selectedJob == null) {
        throw '모든 필드를 입력해주세요';
      }

      if (_passwordController.text.length < 6) {
        throw '비밀번호는 최소 6자리 이상이어야 합니다';
      }

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: "${_idController.text}@example.com",
        password: _passwordController.text,
      );

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('회원가입이 완료되었습니다!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const LoginScreenR()),
      );
    } catch (e) {
      String errorMessage = '회원가입 실패: ';
      if (e.toString().contains('email-already-in-use')) {
        errorMessage += '이미 사용중인 아이디입니다.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage += '비밀번호가 너무 약합니다.';
      } else {
        errorMessage += e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

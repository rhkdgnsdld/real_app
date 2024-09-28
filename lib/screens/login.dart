import 'package:flutter/material.dart';
import 'package:new_new_app/screens/student_screen/home_screen/main.student.screen.dart';
import 'package:new_new_app/screens/teacher_screen/home_screen/main.teacher.screen.dart';
// 학생 메인 화면 import

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromRGBO(153, 134, 179, 1),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '로그인 ',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),
              _buildLoginButton(
                context,
                '선생님용',
                Icons.school,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const MainTeacherScreen())),
              ),
              const SizedBox(height: 20),
              _buildLoginButton(
                context,
                '학생용',
                Icons.person,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const MainStudentScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context,
      String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor:
              const Color.fromRGBO(153, 134, 179, 1),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color:
                    const Color.fromRGBO(153, 134, 179, 1)),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                  fontSize: 18,
                  color: Color.fromRGBO(153, 134, 179, 1)),
            ),
          ],
        ),
      ),
    );
  }
}

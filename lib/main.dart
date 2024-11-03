import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:new_new_app/screens/login.screen.dart';
import 'package:new_new_app/screens/signup.dart';
import 'package:new_new_app/screens/student_screen/home_screen/main.student.screen.dart';
import 'package:new_new_app/screens/teacher_screen/home_screen/main.teacher.screen.dart';

import 'firebase_options.dart';
import 'package:new_new_app/screens/login.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '학생 관리 서비스',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity:
            VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login', // 시작 화면
      routes: {
        '/login': (context) => const LoginScreenR(),
        '/signup': (context) => const SignUpPage(),
        '/teacher': (context) => const MainTeacherScreen(),
        '/student': (context) => const MainStudentScreen(),
      },
    );
  }
}

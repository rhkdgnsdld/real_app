import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:new_new_app/screens/login.screen.dart';
import 'package:new_new_app/screens/signup.dart';
import 'package:new_new_app/screens/student_screen/home_screen/new.main.sscreen.dart';
import 'package:new_new_app/screens/teacher_screen/home_screen/new.main.tscreen.dart';

import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase 초기화 및 정보 출력
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized');
    print('Project ID: ${app.options.projectId}');
    print('Storage Bucket: ${app.options.storageBucket}');

    // Storage 인스턴스 확인
    final storage = FirebaseStorage.instance;
    print('Storage instance created');
    print('Storage bucket: ${storage.bucket}');

    // 날짜 형식 초기화
    await initializeDateFormatting('ko_KR', null);
    print('Date formatting initialized');
  } catch (e) {
    print('Initialization error: $e');
  }

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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreenR(),
        '/signup': (context) => const SignUpPage(),
        '/teacher': (context) => const MainTeacherScreenR(),
        '/student': (context) => const MainStudentScreen(),
      },
    );
  }
}

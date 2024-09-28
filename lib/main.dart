import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:new_new_app/screens/login.dart';
import 'firebase_options.dart';
import 'package:new_new_app/screens/student_screen/home_screen/main.student.screen.dart';
import 'package:new_new_app/utils/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const LoginScreen(),
    );
  }
}

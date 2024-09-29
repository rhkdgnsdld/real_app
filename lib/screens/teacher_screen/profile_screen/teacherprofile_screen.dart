import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherprofileScreen extends StatefulWidget {
  const TeacherprofileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState
    extends State<TeacherprofileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phoneNumber = '';
  String _connectedPerson = '';

  @override
  void initState() {
    super.initState();
    _loadProfileDataT();
  }

  Future<void> _loadProfileDataT() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('teacherName') ?? '';
      _phoneNumber = prefs.getString('teacherPhone') ?? '';
      _connectedPerson =
          prefs.getString('connectedStudent') ?? '';
    });
  }

  Future<void> _saveProfileT() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('teacherName', _name);
      await prefs.setString('teacherPhone', _phoneNumber);
      await prefs.setString(
          'connectedStudent', _connectedPerson);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue,
            child: const SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '프로필수정',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: '이름',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _name,
                          onChanged: (value) {
                            setState(() {
                              _name = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: '전화번호',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _phoneNumber,
                          keyboardType: TextInputType.phone,
                          onChanged: (value) =>
                              _phoneNumber = value,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: '연동되는 학생',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _connectedPerson,
                          onChanged: (value) =>
                              _connectedPerson = value,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveProfileT,
                          child: const Text('저장'),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('이름: $_name'),
                              const SizedBox(height: 8),
                              Text('전화번호: $_phoneNumber'),
                              const SizedBox(height: 8),
                              Text(
                                  '연동되는 학생: $_connectedPerson'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userId = userDoc.data()?['userId'] ?? '';
          _name = userDoc.data()?['name'] ?? '';
          _phoneNumber =
              userDoc.data()?['phoneNumber'] ?? '';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'name': _name,
          'phoneNumber': _phoneNumber,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 저장되었습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF5BABEF),
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
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveProfile,
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
                            ],
                          ),
                        ),
                        // 연동된 학생 목록 표시
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('connections')
                              .where('teacherId',
                                  isEqualTo: FirebaseAuth
                                      .instance
                                      .currentUser
                                      ?.uid) // uid 직접 사용
                              .where('status',
                                  isEqualTo: 'accepted')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Container();
                            }

                            final connections =
                                snapshot.data!.docs;
                            if (connections.isEmpty) {
                              return Container(
                                margin:
                                    const EdgeInsets.only(
                                        top: 16),
                                padding:
                                    const EdgeInsets.all(
                                        16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius:
                                      BorderRadius.circular(
                                          8),
                                ),
                                child: const Text(
                                    '연동된 학생이 없습니다'),
                              );
                            }

                            return Column(
                              children:
                                  connections.map((doc) {
                                final data = doc.data()
                                    as Map<String, dynamic>;
                                return Container(
                                  margin:
                                      const EdgeInsets.only(
                                          top: 16),
                                  padding:
                                      const EdgeInsets.all(
                                          16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius:
                                        BorderRadius
                                            .circular(8),
                                  ),
                                  child: Text(
                                      '${data['studentName']} 학생과 연동되어 있습니다'),
                                );
                              }).toList(),
                            );
                          },
                        )
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

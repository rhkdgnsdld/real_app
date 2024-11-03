import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentprofileScreen extends StatefulWidget {
  const StudentprofileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState
    extends State<StudentprofileScreen> {
  String? _userId;
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phoneNumber = '';
  final String _connectedPerson = '';

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
                        // 연동 상태 StreamBuilder 추가
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('connections')
                              .where('studentId',
                                  isEqualTo: _userId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Container();
                            }

                            final connections =
                                snapshot.data!.docs;
                            return Column(
                              children: [
                                // 승인된 연동 표시
                                ...connections
                                    .where((doc) =>
                                        doc['status'] ==
                                        'accepted')
                                    .map((doc) {
                                  final data = doc.data()
                                      as Map<String,
                                          dynamic>;
                                  return Container(
                                    margin: const EdgeInsets
                                        .only(top: 16),
                                    padding:
                                        const EdgeInsets
                                            .all(16),
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          Colors.green[100],
                                      borderRadius:
                                          BorderRadius
                                              .circular(8),
                                    ),
                                    child: Text(
                                        '${data['teacherName']} 선생님과 연동되어 있습니다'),
                                  );
                                }),
                                // 대기중인 연동 요청 표시
                                ...connections
                                    .where((doc) =>
                                        doc['status'] ==
                                        'pending')
                                    .map((doc) {
                                  final data = doc.data()
                                      as Map<String,
                                          dynamic>;
                                  return Container(
                                    margin: const EdgeInsets
                                        .only(top: 16),
                                    padding:
                                        const EdgeInsets
                                            .all(16),
                                    decoration:
                                        BoxDecoration(
                                      color: Colors
                                          .yellow[100],
                                      borderRadius:
                                          BorderRadius
                                              .circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                            '${data['teacherName']} 선생님이 연동을 요청하였습니다'),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .end,
                                          children: [
                                            TextButton(
                                              onPressed: () => doc
                                                  .reference
                                                  .update({
                                                'status':
                                                    'rejected'
                                              }),
                                              child:
                                                  const Text(
                                                      '거절'),
                                            ),
                                            TextButton(
                                              onPressed: () => doc
                                                  .reference
                                                  .update({
                                                'status':
                                                    'accepted'
                                              }),
                                              child:
                                                  const Text(
                                                      '수락'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
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

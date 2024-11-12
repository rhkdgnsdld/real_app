import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class StudentFileListScreen extends StatefulWidget {
  const StudentFileListScreen({super.key});

  @override
  State<StudentFileListScreen> createState() =>
      _StudentFileListScreenState();
}

class _StudentFileListScreenState
    extends State<StudentFileListScreen> {
  String? _selectedCategory;
  final List<String> categories = [
    '전체',
    '수업자료',
    '과제',
    '첨삭자료',
    '기타'
  ];

  Stream<QuerySnapshot> _getFilesStream() {
    Query query =
        FirebaseFirestore.instance.collection('files');

    if (_selectedCategory != null &&
        _selectedCategory != '전체') {
      query = query.where('category',
          isEqualTo: _selectedCategory);
    }

    return query
        .orderBy('uploadDate', descending: true)
        .snapshots();
  }

  Future<void> _downloadFile(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String _formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy.MM.dd').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '자료 확인하기',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w400),
        ),
        backgroundColor: const Color(0xFF36D19D),
      ),
      body: Column(
        children: [
          // 카테고리 필터
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  bool isSelected =
                      _selectedCategory == category;
                  return Padding(
                    padding:
                        const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected ||
                          (category == '전체' &&
                              _selectedCategory == null),
                      label: Text(category),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory =
                              selected ? category : null;
                          if (category == '전체') {
                            _selectedCategory = null;
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF36D19D)
                          .withOpacity(0.2),
                      checkmarkColor:
                          const Color(0xFF36D19D),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF36D19D)
                            : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 파일 목록
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child:
                          Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('파일이 없습니다'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // 카테고리 표시
                            Container(
                              padding: const EdgeInsets
                                  .symmetric(
                                  horizontal: 8,
                                  vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF36D19D)
                                        .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(
                                        4),
                              ),
                              child: Text(
                                data['category'] ?? '기타',
                                style: const TextStyle(
                                  color: Color(0xFF36D19D),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 파일 제목
                            Text(
                              data['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            if (data['description'] !=
                                    null &&
                                data['description']
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                data['description'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // 하단 정보 및 다운로드 버튼
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                Text(
                                  _formatDate(
                                      data['uploadDate']),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.download,
                                    color:
                                        Color(0xFF36D19D),
                                  ),
                                  onPressed: () =>
                                      _downloadFile(
                                          data['url']),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

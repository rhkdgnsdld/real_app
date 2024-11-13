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
  final Color mainGreen = const Color(0xFF36D19D);
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '학습 자료',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryFilter(),
          _buildFileList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '선생님이 전달한 자료',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: mainGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '카테고리를 선택하여 자료를 확인할 수 있습니다',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            bool isSelected =
                (_selectedCategory == category) ||
                    (category == '전체' &&
                        _selectedCategory == null);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(
                  category,
                  style: TextStyle(
                    color: isSelected
                        ? mainGreen
                        : Colors.grey[700],
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (category == '전체') {
                      _selectedCategory = null;
                    } else {
                      _selectedCategory =
                          selected ? category : null;
                    }
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: mainGreen.withOpacity(0.1),
                checkmarkColor: mainGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected
                        ? mainGreen
                        : Colors.grey[300]!,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFileList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _getFilesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    mainGreen),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                '등록된 자료가 없습니다',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              Map<String, dynamic> data =
                  doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side:
                      BorderSide(color: Colors.grey[200]!),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: mainGreen
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: Text(
                              data['category'] ?? '기타',
                              style: TextStyle(
                                color: mainGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(data['uploadDate']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        data['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (data['description'] != null &&
                          data['description']
                              .toString()
                              .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          data['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(
                            Icons.download_rounded,
                            color: mainGreen,
                          ),
                          onPressed: () =>
                              _downloadFile(data['url']),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

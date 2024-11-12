import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

class TeacherFileUploadScreen extends StatefulWidget {
  const TeacherFileUploadScreen({super.key});

  @override
  _TeacherFileUploadScreenState createState() =>
      _TeacherFileUploadScreenState();
}

class _TeacherFileUploadScreenState
    extends State<TeacherFileUploadScreen> {
  File? _file;
  final bool _isUploading = false;
  String? _selectedCategory;
  final _descController = TextEditingController();
  final List<String> categories = [
    '수업자료',
    '과제',
    '첨삭자료',
    '기타'
  ];

  Future<void> _pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_file == null || _selectedCategory == null) return;

    try {
      print('Starting upload process');

      final storage = FirebaseStorage.instance;

      // 1. 가장 단순한 경로 구조로 시작
      final storageRef = storage
          .ref('test_upload.txt'); // 임시로 고정된 파일명으로 테스트

      print('Attempting upload to: ${storageRef.fullPath}');

      // 2. 기본 업로드 시도
      await storageRef.putFile(_file!);
      print('Basic upload completed');

      // 3. 성공 시 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('테스트 업로드 성공')),
      );
    } catch (e) {
      print('Upload error details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패 상세: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '자료 업로드하기',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF5BABEF),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 카테고리 선택
              const Text(
                '자료 종류',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    bool isSelected =
                        _selectedCategory == category;
                    return Padding(
                      padding:
                          const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(category),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory =
                                selected ? category : null;
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor:
                            const Color(0xFF5BABEF)
                                .withOpacity(0.2),
                        checkmarkColor:
                            const Color(0xFF5BABEF),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF5BABEF)
                              : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // 파일 선택 영역
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: _pickFile,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          _file != null
                              ? Icons.check_circle
                              : Icons.add_circle,
                          size: 40,
                          color: const Color(0xFF5BABEF),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _file != null
                              ? _file!.path.split('/').last
                              : '파일을 선택하세요',
                          style: TextStyle(
                            color: _file != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 설명 입력
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  child: TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '자료에 대한 설명을 입력하세요',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 업로드 버튼
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BABEF),
                  padding: const EdgeInsets.symmetric(
                      vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    _isUploading ? null : _uploadFile,
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                        ),
                      )
                    : const Text(
                        '자료 전달하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }
}

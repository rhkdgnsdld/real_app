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
  final Color mainBlue = const Color(0xFF5BABEF);
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '자료 업로드',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildCategorySection(),
            _buildFileUploadSection(),
            _buildDescriptionSection(),
            _buildUploadButton(),
          ],
        ),
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
            '학습 자료 전달',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: mainBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '학생에게 전달할 자료를 업로드해주세요',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자료 종류',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                bool isSelected =
                    _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? mainBlue
                            : Colors.grey[700],
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory =
                            selected ? category : null;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor:
                        mainBlue.withOpacity(0.1),
                    checkmarkColor: mainBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? mainBlue
                            : Colors.grey[300]!,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: InkWell(
          onTap: _pickFile,
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _file != null
                      ? Icons.check_circle
                      : Icons.cloud_upload,
                  size: 40,
                  color: mainBlue,
                ),
                const SizedBox(height: 12),
                Text(
                  _file != null
                      ? _file!.path.split('/').last
                      : '파일을 선택하세요',
                  style: TextStyle(
                    color: _file != null
                        ? Colors.black87
                        : Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '자료에 대한 설명을 입력하세요',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey[400]),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: mainBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: _isUploading ? null : _uploadFile,
        child: _isUploading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white),
                ),
              )
            : const Text(
                '자료 전달하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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

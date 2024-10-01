import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherFileUploadScreen extends StatefulWidget {
  const TeacherFileUploadScreen({super.key});

  @override
  _TeacherFileUploadScreenState createState() =>
      _TeacherFileUploadScreenState();
}

class _TeacherFileUploadScreenState
    extends State<TeacherFileUploadScreen> {
  File? _file;
  bool _isUploading = false;

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
    if (_file == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload file to Firebase Storage
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_file!.path.split('/').last}';
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('files/$fileName');
      UploadTask uploadTask = ref.putFile(_file!);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl =
          await taskSnapshot.ref.getDownloadURL();

      // Save file metadata to Firestore
      await FirebaseFirestore.instance
          .collection('files')
          .add({
        'name': fileName,
        'url': downloadUrl,
        'uploadDate': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('File uploaded successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload file: $e')));
    } finally {
      setState(() {
        _isUploading = false;
        _file = null;
      });
    }
    try {
      // 업로드 코드...
    } catch (e) {
      print('Error uploading file: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자료 올리기')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('파일 선택하기'),
            ),
            const SizedBox(height: 20),
            if (_file != null)
              Text(_file!.path.split('/').last),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadFile,
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text('파일 업로드하기'),
            ),
          ],
        ),
      ),
    );
  }
}

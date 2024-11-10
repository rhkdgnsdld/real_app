import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Grade {
  final String? id;
  final DateTime date;
  final String testName;
  final int score;

  Grade(
      {this.id,
      required this.date,
      required this.testName,
      required this.score});

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'testName': testName,
        'score': score,
      };

  factory Grade.fromJson(Map<String, dynamic> json) =>
      Grade(
        id: json['id'],
        date: DateTime.parse(json['date']),
        testName: json['testName'],
        score: json['score'],
      );
}

class GradeRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> saveGrade(String studentUid, bool isOfficial,
      Grade grade) async {
    try {
      await _firestore
          .collection('users')
          .doc(studentUid)
          .collection('grades')
          .add({
        'date': grade.date.toIso8601String(),
        'testName': grade.testName,
        'score': grade.score,
        'isOfficial': isOfficial,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving grade: $e');
      rethrow;
    }
  }

  Future<List<Grade>> getGrades(bool isOfficial) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        isOfficial ? 'officialGrades' : 'privateGrades';
    List<dynamic> gradesJson =
        jsonDecode(prefs.getString(key) ?? '[]');
    return gradesJson
        .map((json) => Grade.fromJson(json))
        .toList();
  }

  Future<void> updateGrade(String studentUid,
      String gradeId, Grade grade, bool isOfficial) async {
    try {
      await _firestore
          .collection('users')
          .doc(studentUid)
          .collection('grades')
          .doc(gradeId)
          .update({
        'date': grade.date.toIso8601String(),
        'testName': grade.testName,
        'score': grade.score,
        'isOfficial': isOfficial,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating grade: $e');
    }
  }

  Future<void> deleteGrade(
      String studentUid, String gradeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(studentUid)
          .collection('grades')
          .doc(gradeId)
          .delete();
    } catch (e) {
      print('Error deleting grade: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getGradesWithId(
      String studentUid, bool isOfficial) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(studentUid)
          .collection('grades')
          .where('isOfficial', isEqualTo: isOfficial)
          .orderBy('date', descending: false) // 날짜로만 정렬
          // .orderBy('__name__') 제거
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'grade': Grade(
                  id: doc.id,
                  date: DateTime.parse(doc['date']),
                  testName: doc['testName'],
                  score: doc['score'],
                ),
              })
          .toList();
    } catch (e) {
      print('Error getting grades: $e');
      return [];
    }
  }
}

class GradeValidator {
  ValidationResult validateGrade(Grade grade) {
    if (grade.testName.isEmpty) {
      return ValidationResult(false, '시험 이름을 입력해주세요.');
    }
    if (grade.score < 0 || grade.score > 100) {
      return ValidationResult(
          false, '점수는 0에서 100 사이의 숫자여야 합니다.');
    }
    return ValidationResult(true, '');
  }
}

class ValidationResult {
  final bool isValid;
  final String errorMessage;

  ValidationResult(this.isValid, this.errorMessage);
}

class GradeTrendLogic {
  final GradeRepository repository = GradeRepository();
  final GradeValidator _validator = GradeValidator(); // 추가
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> handleAddButtonPressed(
    BuildContext context,
    bool isOfficialSelected, {
    required Function(bool isValid, String errorMessage)
        onSave,
  }) async {
    final grade = await _showGradeDialog(context,
        isOfficialSelected: isOfficialSelected);
    if (grade != null) {
      final validationResult =
          _validator.validateGrade(grade);
      if (validationResult.isValid) {
        // Firebase Auth에서 현재 사용자 ID 가져오기
        String? userId =
            FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await repository.saveGrade(
              userId, isOfficialSelected, grade); // 수정
          onSave(true, '');
        } else {
          onSave(false, '사용자 정보를 찾을 수 없습니다.');
        }
      } else {
        onSave(false, validationResult.errorMessage);
      }
    }
  }

  Future<List<Grade>> getGrades(bool isOfficial) =>
      repository.getGrades(isOfficial);

  Future<void> editGrade(
      BuildContext context,
      String studentUid,
      String gradeId,
      Grade grade,
      bool isOfficial) async {
    try {
      final result = await _showGradeDialog(
        context,
        isOfficialSelected: isOfficial,
        initialGrade: grade,
      );

      print('Dialog result: $result'); // 디버깅용

      if (result == 'delete') {
        print(
            'Delete requested for grade: $gradeId'); // 디버깅용
        await repository.deleteGrade(studentUid, gradeId);
        // 삭제 성공 후 네비게이션
        Navigator.of(context).pop(true); // 삭제 성공을 알림
      } else if (result != null && result is Grade) {
        await repository.updateGrade(
            studentUid, gradeId, result, isOfficial);
        Navigator.of(context).pop(true); // 업데이트 성공을 알림
      }
    } catch (e) {
      print('Error in editGrade: $e'); // 디버깅용
      // 에러 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> deleteGrade(
      String studentUid, String gradeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(studentUid)
          .collection('grades')
          .doc(gradeId)
          .delete();
    } catch (e) {
      print('Error deleting grade: $e');
      rethrow;
    }
  }

  Future<dynamic> _showGradeDialog(
    BuildContext context, {
    bool isOfficialSelected = false,
    Grade? initialGrade,
  }) async {
    DateTime selectedDate =
        initialGrade?.date ?? DateTime.now();
    final testNameController =
        TextEditingController(text: initialGrade?.testName);
    final scoreController = TextEditingController(
        text: initialGrade?.score.toString());

    return showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(initialGrade == null
                  ? (isOfficialSelected
                      ? '교육청/평가원 성적 추가'
                      : '사설 모의고사 성적 추가')
                  : '성적 수정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final DateTime? picked =
                          await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null &&
                          picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '날짜',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(DateFormat('yyyy-MM-dd')
                              .format(selectedDate)),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: testNameController,
                    decoration: const InputDecoration(
                      labelText: "시험 이름",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: scoreController,
                    decoration: const InputDecoration(
                      labelText: "점수",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: <Widget>[
                if (initialGrade != null)
                  TextButton(
                    child: const Text('삭제',
                        style:
                            TextStyle(color: Colors.red)),
                    onPressed: () =>
                        Navigator.of(context).pop('delete'),
                  ),
                TextButton(
                  child: const Text('취소'),
                  onPressed: () =>
                      Navigator.of(context).pop(),
                ),
                TextButton(
                    child: Text(
                        initialGrade == null ? '저장' : '수정'),
                    onPressed: () {
                      final score = int.tryParse(
                          scoreController.text);
                      if (score != null) {
                        Navigator.of(context).pop(Grade(
                          date: selectedDate,
                          testName: testNameController.text,
                          score: score,
                        ));
                      }
                    }),
              ],
            );
          },
        );
      },
    );
  }

  void handleOfficialSelection(
      bool isSelected, Function(bool) updateState) {
    updateState(true);
  }

  void handlePrivateSelection(
      bool isSelected, Function(bool) updateState) {
    updateState(false);
  }
}

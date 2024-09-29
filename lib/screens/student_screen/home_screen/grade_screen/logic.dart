import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class Grade {
  final DateTime date;
  final String testName;
  final int score;

  Grade(
      {required this.date,
      required this.testName,
      required this.score});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'testName': testName,
        'score': score,
      };

  factory Grade.fromJson(Map<String, dynamic> json) =>
      Grade(
        date: DateTime.parse(json['date']),
        testName: json['testName'],
        score: json['score'],
      );
}

class GradeRepository {
  Future<void> saveGrade(
      bool isOfficial, Grade grade) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        isOfficial ? 'officialGrades' : 'privateGrades';
    List<dynamic> grades =
        jsonDecode(prefs.getString(key) ?? '[]');
    grades.add(grade.toJson());
    await prefs.setString(key, jsonEncode(grades));
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

  Future<void> updateGrade(
      bool isOfficial, int index, Grade grade) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        isOfficial ? 'officialGrades' : 'privateGrades';
    List<dynamic> grades =
        jsonDecode(prefs.getString(key) ?? '[]');
    grades[index] = grade.toJson();
    await prefs.setString(key, jsonEncode(grades));
  }

  Future<void> deleteGrade(
      bool isOfficial, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        isOfficial ? 'officialGrades' : 'privateGrades';
    List<dynamic> grades =
        jsonDecode(prefs.getString(key) ?? '[]');
    grades.removeAt(index);
    await prefs.setString(key, jsonEncode(grades));
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
  final GradeRepository _repository = GradeRepository();
  final GradeValidator _validator = GradeValidator();

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
        await _repository.saveGrade(
            isOfficialSelected, grade);
        onSave(true, '');
      } else {
        onSave(false, validationResult.errorMessage);
      }
    }
  }

  Future<List<Grade>> getGrades(bool isOfficial) =>
      _repository.getGrades(isOfficial);

  Future<void> editGrade(BuildContext context,
      bool isOfficial, int index) async {
    final grades = await getGrades(isOfficial);
    if (index < 0 || index >= grades.length) return;

    final result = await _showGradeDialog(context,
        initialGrade: grades[index]);
    if (result != null) {
      if (result is Grade) {
        await _repository.updateGrade(
            isOfficial, index, result);
      } else if (result == 'delete') {
        await _repository.deleteGrade(isOfficial, index);
      }
    }
  }

  Future<dynamic> _showGradeDialog(BuildContext context,
      {Grade? initialGrade,
      bool isOfficialSelected = false}) async {
    DateTime selectedDate =
        initialGrade?.date ?? DateTime.now();
    final testNameController = TextEditingController(
        text: initialGrade?.testName ?? '');
    final scoreController = TextEditingController(
        text: initialGrade?.score.toString() ?? '');

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
                TextButton(
                  child: const Text('취소'),
                  onPressed: () =>
                      Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('저장'),
                  onPressed: () {
                    final score =
                        int.tryParse(scoreController.text);
                    if (score != null) {
                      Navigator.of(context).pop(Grade(
                        date: selectedDate,
                        testName: testNameController.text,
                        score: score,
                      ));
                    }
                  },
                ),
                if (initialGrade != null)
                  TextButton(
                    child: const Text('삭제'),
                    onPressed: () {
                      Navigator.of(context).pop('delete');
                    },
                  ),
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

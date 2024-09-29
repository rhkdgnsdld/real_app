import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class GradeTrendLogic {
  Future<void> handleAddButtonPressed(
    BuildContext context,
    bool isOfficialSelected, {
    required Function(bool isValid, String errorMessage)
        onSave,
  }) async {
    DateTime selectedDate = DateTime.now();
    final TextEditingController testNameController =
        TextEditingController();
    final TextEditingController scoreController =
        TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isOfficialSelected
                  ? '교육청/평가원 성적 추가'
                  : '사설 모의고사 성적 추가'),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('저장'),
                  onPressed: () async {
                    if (testNameController
                            .text.isNotEmpty &&
                        scoreController.text.isNotEmpty) {
                      // 점수 유효성 검사
                      int? score = int.tryParse(
                          scoreController.text);
                      if (score == null ||
                          score < 0 ||
                          score > 100) {
                        onSave(false,
                            '점수는 0에서 100 사이의 숫자여야 합니다.');
                        return;
                      }

                      await saveGrade(
                        isOfficialSelected,
                        selectedDate,
                        testNameController.text,
                        score,
                      );
                      Navigator.of(context).pop();
                      onSave(true, '');
                    } else {
                      onSave(false, '모든 내용을 입력해주세요.');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> saveGrade(bool isOfficial, DateTime date,
      String testName, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        isOfficial ? 'officialGrades' : 'privateGrades';

    List<dynamic> grades =
        jsonDecode(prefs.getString(key) ?? '[]');

    grades.add({
      'date': date.toIso8601String(),
      'testName': testName,
      'score': score,
    });

    await prefs.setString(key, jsonEncode(grades));
  }

  Future<List<dynamic>> getGrades(bool isOfficial) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        isOfficial ? 'officialGrades' : 'privateGrades';
    return jsonDecode(prefs.getString(key) ?? '[]');
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

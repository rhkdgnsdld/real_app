import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class GradeTrendScreenR extends StatefulWidget {
  const GradeTrendScreenR({super.key});

  @override
  State<GradeTrendScreenR> createState() =>
      _GradeTrendScreenState();
}

class _GradeTrendScreenState
    extends State<GradeTrendScreenR> {
  bool _isOfficialSelected = true;
  List<Grade> _grades = [];
  bool _isLoading = true;
  String _userName = '';
  final Color mainBlue = const Color(0xFF5BABEF);
  final Color mainGreen = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadGrades();
  }

  Future<void> _loadUserInfo() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        setState(() {
          _userName = doc.data()?['name'] ?? '학생';
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('grades')
          .where('isOfficial',
              isEqualTo: _isOfficialSelected)
          .orderBy('date')
          .get();

      setState(() {
        _grades = snapshot.docs.map((doc) {
          final data = doc.data();
          // date 필드가 String인 경우와 Timestamp인 경우를 모두 처리
          DateTime date;
          if (data['date'] is Timestamp) {
            date = (data['date'] as Timestamp).toDate();
          } else if (data['date'] is String) {
            date = DateTime.parse(data['date']);
          } else {
            date = DateTime.now(); // 기본값 설정
          }

          return Grade(
            id: doc.id,
            date: date,
            testName: data['testName'] as String,
            score: (data['score'] as num).toInt(),
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading grades: $e');
      _showErrorDialog('성적 데이터를 불러오는데 실패했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message,
      {bool showRetry = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline,
                color: mainBlue, size: 24),
            const SizedBox(width: 8),
            const Text('오류',
                style: TextStyle(color: Colors.black87)),
          ],
        ),
        content: Text(message),
        actions: [
          if (showRetry)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadGrades();
              },
              child: Text('다시 시도',
                  style: TextStyle(color: mainBlue)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인',
                style: TextStyle(color: mainBlue)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddGradeDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final result = await _showGradeDialog();

      if (result != null && result is Grade) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('grades')
            .add({
          'date': Timestamp.fromDate(
              result.date), // Timestamp로 변환
          'testName': result.testName,
          'score': result.score,
          'isOfficial': _isOfficialSelected,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showSuccessMessage('성적이 추가되었습니다.');
        _loadGrades();
      }
    } catch (e) {
      print('Error adding grade: $e');
      _showErrorDialog('성적 추가 중 오류가 발생했습니다.');
    }
  }

  Future<void> _editGrade(Grade grade) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final result = await _showGradeDialog(
        initialGrade: grade,
      );

      if (result == 'delete') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('grades')
            .doc(grade.id)
            .delete();

        _showSuccessMessage('성적이 삭제되었습니다.');
        _loadGrades();
      } else if (result != null && result is Grade) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('grades')
            .doc(grade.id)
            .update({
          'date': Timestamp.fromDate(
              result.date), // Timestamp로 변환
          'testName': result.testName,
          'score': result.score,
          'isOfficial': _isOfficialSelected,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _showSuccessMessage('성적이 수정되었습니다.');
        _loadGrades();
      }
    } catch (e) {
      print('Error in editGrade: $e');
      _showErrorDialog('성적 수정/삭제 중 오류가 발생했습니다.');
    }
  }

  Future<dynamic> _showGradeDialog(
      {Grade? initialGrade}) async {
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
              title: Text(
                initialGrade == null
                    ? (_isOfficialSelected
                        ? '교육청/평가원 성적 추가'
                        : '사설 모의고사 성적 추가')
                    : '성적 수정',
                style: TextStyle(
                    color: _isOfficialSelected
                        ? mainBlue
                        : mainGreen),
              ),
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
                      decoration: InputDecoration(
                        labelText: '날짜',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(
                            color: _isOfficialSelected
                                ? mainBlue
                                : mainGreen),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(DateFormat('yyyy-MM-dd')
                              .format(selectedDate)),
                          Icon(Icons.calendar_today,
                              color: _isOfficialSelected
                                  ? mainBlue
                                  : mainGreen),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: testNameController,
                    decoration: InputDecoration(
                      labelText: "시험 이름",
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                          color: _isOfficialSelected
                              ? mainBlue
                              : mainGreen),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: scoreController,
                    decoration: InputDecoration(
                      labelText: "점수",
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                          color: _isOfficialSelected
                              ? mainBlue
                              : mainGreen),
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
                  child: Text('취소',
                      style: TextStyle(
                          color: _isOfficialSelected
                              ? mainBlue
                              : mainGreen)),
                  onPressed: () =>
                      Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(
                    initialGrade == null ? '저장' : '수정',
                    style: TextStyle(
                        color: _isOfficialSelected
                            ? mainBlue
                            : mainGreen),
                  ),
                  onPressed: () {
                    final score =
                        int.tryParse(scoreController.text);
                    if (score != null) {
                      Navigator.of(context).pop(Grade(
                        id: initialGrade?.id,
                        date: selectedDate,
                        testName: testNameController.text,
                        score: score,
                      ));
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            _isOfficialSelected ? mainBlue : mainGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: mainBlue))
          : RefreshIndicator(
              onRefresh: _loadGrades,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildToggleButtons(),
                    _buildGradeChart(),
                    if (_grades.isNotEmpty)
                      _buildSummaryCard(),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up,
              color: _isOfficialSelected
                  ? mainBlue
                  : mainGreen,
              size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_userName 학생 성적 추이',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          color: _isOfficialSelected ? mainBlue : mainGreen,
          onPressed: _showAddGradeDialog,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              '교육청/평가원',
              _isOfficialSelected,
              () => setState(() {
                _isOfficialSelected = true;
                _loadGrades();
              }),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              '사설 모의고사',
              !_isOfficialSelected,
              () => setState(() {
                _isOfficialSelected = false;
                _loadGrades();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
      String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (_isOfficialSelected ? mainBlue : mainGreen)
                  .withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? (_isOfficialSelected
                    ? mainBlue
                    : mainGreen)
                : Colors.grey,
            fontWeight: isSelected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGradeChart() {
    if (_grades.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '등록된 성적이 없습니다',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      height: 400,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double chartWidth = math.max(
              _grades.length * 100.0, constraints.maxWidth);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: 100,
                  minY: 0,
                  groupsSpace: 20,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex,
                          rod, rodIndex) {
                        return BarTooltipItem(
                          '${_grades[group.x.toInt()].score}점\n${_grades[group.x.toInt()].testName}',
                          const TextStyle(
                              color: Colors.white),
                        );
                      },
                    ),
                    touchCallback: (FlTouchEvent event,
                        barTouchResponse) {
                      if (event is FlTapUpEvent &&
                          barTouchResponse != null &&
                          barTouchResponse.spot != null) {
                        int index = barTouchResponse
                            .spot!.touchedBarGroupIndex;
                        if (index >= 0 &&
                            index < _grades.length) {
                          _editGrade(_grades[index]);
                        }
                      }
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >=
                              _grades.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('MM/dd')
                                      .format(_grades[
                                              value.toInt()]
                                          .date),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _grades[value.toInt()]
                                      .testName,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                        reservedSize: 60,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 45, // Y축 라벨 공간 늘림
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                        dashArray: value == 0 ||
                                value == 100
                            ? null
                            : [
                                5,
                                5
                              ], // 0점과 100점에는 실선, 나머지는 점선
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(
                          color: Colors.grey[300]!),
                      bottom: BorderSide(
                          color: Colors.grey[300]!),
                    ),
                  ),
                  barGroups:
                      _grades.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.score.toDouble(),
                          color: _isOfficialSelected
                              ? mainBlue
                              : mainGreen,
                          width: 20,
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    final avgScore = _grades
            .map((g) => g.score)
            .reduce((a, b) => a + b) /
        _grades.length;
    final maxScore =
        _grades.map((g) => g.score).reduce(math.max);
    final minScore =
        _grades.map((g) => g.score).reduce(math.min);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '성적 요약',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isOfficialSelected
                  ? mainBlue
                  : mainGreen,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
              '평균 점수', avgScore.toStringAsFixed(1)),
          _buildSummaryRow('최고 점수', maxScore.toString()),
          _buildSummaryRow('최저 점수', minScore.toString()),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class Grade {
  final String? id;
  final DateTime date;
  final String testName;
  final int score;

  Grade({
    this.id,
    required this.date,
    required this.testName,
    required this.score,
  });
}

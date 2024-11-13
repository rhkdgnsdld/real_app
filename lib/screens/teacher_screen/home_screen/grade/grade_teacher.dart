import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';

class TeacherGradeTrendScreenR extends StatefulWidget {
  const TeacherGradeTrendScreenR({super.key});

  @override
  State<TeacherGradeTrendScreenR> createState() =>
      _TeacherGradeTrendScreenState();
}

class _TeacherGradeTrendScreenState
    extends State<TeacherGradeTrendScreenR> {
  bool _isOfficialSelected = true;
  List<Grade> _grades = [];
  bool _isLoading = true;
  String? _connectedStudentId;
  String? _studentName;
  final Color mainBlue = const Color(0xFF5BABEF);
  final Color mainGreen = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _loadConnectedStudent();
  }

  Future<void> _loadConnectedStudent() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final teacherDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        final teacherUserId = teacherDoc.data()?['userId'];

        final connection = await FirebaseFirestore.instance
            .collection('connections')
            .where('teacherId', isEqualTo: teacherUserId)
            .where('status', isEqualTo: 'accepted')
            .get();

        if (connection.docs.isNotEmpty) {
          final studentId =
              connection.docs.first.data()['studentId'];

          final studentDocs = await FirebaseFirestore
              .instance
              .collection('users')
              .where('userId', isEqualTo: studentId)
              .get();

          if (studentDocs.docs.isNotEmpty) {
            setState(() {
              _connectedStudentId = studentId;
              _studentName =
                  studentDocs.docs.first.data()['name'];
            });
            await _loadGrades();
          }
        }
      }
    } catch (e) {
      print('Error loading student: $e');
      _showErrorDialog('학생 정보를 불러오는데 실패했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGrades() async {
    if (_connectedStudentId == null) return;

    setState(() => _isLoading = true);
    try {
      // 1. 먼저 학생의 uid를 가져옵니다
      final studentDocs = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: _connectedStudentId)
          .limit(1)
          .get();

      if (studentDocs.docs.isNotEmpty) {
        final studentUid = studentDocs.docs.first.id;

        // 2. 성적 데이터를 가져옵니다
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentUid)
            .collection('grades')
            .where('isOfficial',
                isEqualTo: _isOfficialSelected)
            .orderBy('date')
            .get();

        setState(() {
          _grades = snapshot.docs.map((doc) {
            final data = doc.data();
            // 3. date 필드가 String인 경우와 Timestamp인 경우를 모두 처리
            DateTime date;
            if (data['date'] is Timestamp) {
              date = (data['date'] as Timestamp).toDate();
            } else if (data['date'] is String) {
              date = DateTime.parse(data['date']);
            } else {
              print('Invalid date format: ${data['date']}');
              date = DateTime.now(); // 기본값 설정
            }

            return Grade(
              id: doc.id,
              date: date,
              testName: data['testName'] as String? ??
                  '무제', // null 처리 추가
              score: (data['score'] as num?)?.toInt() ??
                  0, // null 처리 추가
            );
          }).toList();

          // 4. 날짜순으로 정렬
          _grades.sort((a, b) => a.date.compareTo(b.date));
        });
      }
    } catch (e) {
      print('Error loading grades: $e');
      _showErrorDialog('성적 데이터를 불러오는데 실패했습니다.',
          showRetry: true);
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
            const Text(
              '오류',
              style: TextStyle(color: Colors.black87),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _connectedStudentId == null
              ? Center(
                  child: Text(
                    '연동된 학생이 없습니다',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadGrades();
                  },
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
          Text(
            _studentName != null
                ? '$_studentName 학생 성적 추이'
                : '성적 추이',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      centerTitle: true,
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
                        reservedSize: 45,
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
                        dashArray:
                            value == 0 || value == 100
                                ? null
                                : [5, 5], // 0점과 100점은 실선
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
              color: mainBlue,
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
  final String id;
  final DateTime date;
  final String testName;
  final int score;

  Grade({
    required this.id,
    required this.date,
    required this.testName,
    required this.score,
  });
}

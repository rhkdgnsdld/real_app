import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'logic.dart';
import 'package:intl/intl.dart';

class GradeTrendScreen extends StatefulWidget {
  const GradeTrendScreen({super.key});

  @override
  _GradeTrendScreenState createState() =>
      _GradeTrendScreenState();
}

class _GradeTrendScreenState
    extends State<GradeTrendScreen> {
  bool _isOfficialSelected = true;
  final GradeTrendLogic _logic = GradeTrendLogic();
  List<dynamic> _grades = [];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  void _loadGrades() async {
    final grades =
        await _logic.getGrades(_isOfficialSelected);
    setState(() {
      _grades = grades;
    });
  }

  void _updateSelectionState(bool isOfficial) {
    setState(() {
      _isOfficialSelected = isOfficial;
      _loadGrades();
    });
  }

  List<BarChartGroupData> _getBarGroups() {
    return _grades.asMap().entries.map((entry) {
      final index = entry.key;
      final grade = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: grade['score'].toDouble(),
            color: Colors.blue,
            width: 20, // 막대 너비 조정
          ),
        ],
      );
    }).toList();
  }

  Widget _buildBottomTitles(double value, TitleMeta meta) {
    if (value.toInt() >= 0 &&
        value.toInt() < _grades.length) {
      final grade = _grades[value.toInt()];
      final date = DateTime.parse(grade['date']);
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Column(
          children: [
            Text(DateFormat('MM/dd').format(date),
                style: const TextStyle(fontSize: 10)),
            Text(grade['testName'],
                style: const TextStyle(
                    fontSize: 8)), // 시험 이름 추가
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('성적누적추이 확인'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGradeDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () =>
                      _logic.handleOfficialSelection(
                          _isOfficialSelected,
                          _updateSelectionState),
                  child: Text(
                    '교육청,평가원',
                    style: TextStyle(
                      fontWeight: _isOfficialSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _isOfficialSelected
                          ? Colors.blue
                          : Colors.black,
                    ),
                  ),
                ),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('/',
                      style: TextStyle(fontSize: 20)),
                ),
                GestureDetector(
                  onTap: () =>
                      _logic.handlePrivateSelection(
                          _isOfficialSelected,
                          _updateSelectionState),
                  child: Text(
                    '사설',
                    style: TextStyle(
                      fontWeight: !_isOfficialSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: !_isOfficialSelected
                          ? Colors.blue
                          : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _grades.isEmpty
                  ? const Center(child: Text('데이터가 없습니다.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: _grades.length *
                            80.0, // 간격을 고려하여 너비 증가
                        child: BarChart(
                          BarChartData(
                            alignment:
                                BarChartAlignment.center,
                            maxY: 100,
                            minY: 0,
                            groupsSpace: 30, // 막대 사이의 간격 증가
                            barTouchData:
                                BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget:
                                      _buildBottomTitles,
                                  reservedSize:
                                      40, // 시험 이름을 위한 공간 확보
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 20,
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(
                                show: false),
                            borderData:
                                FlBorderData(show: false),
                            barGroups: _getBarGroups(),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGradeDialog(BuildContext context) {
    _logic.handleAddButtonPressed(
        context, _isOfficialSelected,
        onSave: (isValid, errorMessage) {
      if (isValid) {
        _loadGrades(); // 성적이 성공적으로 추가되면 그래프 업데이트
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    });
  }
}

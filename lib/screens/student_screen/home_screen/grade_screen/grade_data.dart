import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'logic.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

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
  List<Grade> _grades = [];

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
          _buildSelectionRow(),
          Expanded(
            child: _grades.isEmpty
                ? const Center(child: Text('데이터가 없습니다.'))
                : _buildGradeChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionRow() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSelectionButton(
              '교육청 , 평가원',
              _isOfficialSelected,
              () => _logic.handleOfficialSelection(
                  _isOfficialSelected,
                  _updateSelectionState)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child:
                Text('/', style: TextStyle(fontSize: 20)),
          ),
          _buildSelectionButton(
              '사설',
              !_isOfficialSelected,
              () => _logic.handlePrivateSelection(
                  _isOfficialSelected,
                  _updateSelectionState)),
        ],
      ),
    );
  }

  Widget _buildSelectionButton(
      String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: isSelected
              ? FontWeight.bold
              : FontWeight.normal,
          color: isSelected
              ? (text == '사설' ? Colors.green : Colors.blue)
              : Colors.black,
        ),
      ),
    );
  }

  Widget _buildGradeChart() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (BuildContext context,
            BoxConstraints constraints) {
          double availableWidth = constraints.maxWidth;
          double chartWidth = math.max(
              _grades.length * 60.0, availableWidth);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              height: 350,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 58, bottom: 30),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.center,
                    maxY: 110,
                    minY: 0,
                    groupsSpace: 30,
                    barTouchData: BarTouchData(
                      enabled: false,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex,
                            rod, rodIndex) {
                          return BarTooltipItem(
                            rod.toY.round().toString(),
                            const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold),
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
                          _showEditDeleteDialog(
                              context, index);
                        }
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget:
                              _buildBottomTitles,
                          reservedSize: 60,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: _getBarGroups(chartWidth),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(double chartWidth) {
    double barWidth =
        (chartWidth - 32) / (_grades.length * 2);
    barWidth = math.min(barWidth, 40.0);

    return _grades.asMap().entries.map((entry) {
      final index = entry.key;
      final grade = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: grade.score.toDouble(),
            color: _isOfficialSelected
                ? Colors.blue
                : Colors.green, // 색상 변경
            width: barWidth,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  Widget _buildBottomTitles(double value, TitleMeta meta) {
    if (value.toInt() >= 0 &&
        value.toInt() < _grades.length) {
      final grade = _grades[value.toInt()];
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 10,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('MM/dd').format(grade.date),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              grade.testName,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showAddGradeDialog(BuildContext context) {
    _logic.handleAddButtonPressed(
        context, _isOfficialSelected,
        onSave: (isValid, errorMessage) {
      if (isValid) {
        _loadGrades();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)));
      }
    });
  }

  void _showEditDeleteDialog(
      BuildContext context, int index) {
    _logic
        .editGrade(context, _isOfficialSelected, index)
        .then((_) {
      _loadGrades();
    });
  }
}

import 'package:flutter/material.dart';
import 'dart:math';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  _WeeklyScheduleScreenState createState() =>
      _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState
    extends State<WeeklyScheduleScreen> {
  List<ScheduleEvent> events = [];
  final List<Color> predefinedColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  buildWeekDays(),
                  buildTimeGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.blue,
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '주간 시간표',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add,
                  color: Colors.white),
              onPressed: () => _showAddEventDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildWeekDays() {
    final weekDays = [
      '',
      '월',
      '화',
      '수',
      '목',
      '금',
      '토',
      '일'
    ];
    return SizedBox(
      height: 50,
      child: Row(
        children: weekDays
            .map(
              (day) => Flexible(
                child: Center(
                    child: Text(day,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold))),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget buildTimeGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTimeColumn(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
                7,
                (index) => Expanded(
                      child: buildDayColumn(index),
                    )),
          ),
        ),
      ],
    );
  }

  Widget buildTimeColumn() {
    return Column(
      children: List.generate(17, (index) {
        final hour = (index + 9) % 24;
        return Container(
          height: 60,
          width: 50,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Text(
            '${hour.toString().padLeft(2, '0')}:00',
            style: TextStyle(
                fontSize: 12, color: Colors.grey[600]),
          ),
        );
      }),
    );
  }

  Widget buildDayColumn(int dayIndex) {
    return Column(
      children: List.generate(17, (timeIndex) {
        final eventsAtThisTime = events.where((event) =>
            event.day == dayIndex &&
            event.hour <= timeIndex + 9 &&
            event.hour + event.duration > timeIndex + 9);

        return Stack(
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border(
                  bottom:
                      BorderSide(color: Colors.grey[300]!),
                  right:
                      BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            ...eventsAtThisTime.map((event) =>
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => _showEditEventDialog(
                        context, event),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: event.color.withOpacity(0.7),
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                              color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        );
      }),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    String title = '';
    int day = 0;
    int hour = 9;
    int duration = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('일정 추가'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                        labelText: '일정 제목'),
                    onChanged: (value) => title = value,
                  ),
                  DropdownButton<int>(
                    value: day,
                    items: List.generate(
                        7,
                        (index) => DropdownMenuItem<int>(
                              value: index,
                              child: Text([
                                '월',
                                '화',
                                '수',
                                '목',
                                '금',
                                '토',
                                '일'
                              ][index]),
                            )),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => day = value);
                      }
                    },
                  ),
                  DropdownButton<int>(
                    value: hour,
                    items: List.generate(
                        17,
                        (index) => DropdownMenuItem<int>(
                              value: index + 9,
                              child: Text(
                                  '${(index + 9).toString().padLeft(2, '0')}:00'),
                            )),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => hour = value);
                      }
                    },
                  ),
                  DropdownButton<int>(
                    value: duration,
                    items: [1, 2, 3, 4].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value시간'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => duration = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('취소'),
                  onPressed: () =>
                      Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('추가'),
                  onPressed: () {
                    if (title.isNotEmpty) {
                      Navigator.of(context).pop();
                      // 여기서 전체 화면의 상태를 업데이트합니다.
                      setState(() {
                        events.add(ScheduleEvent(
                          title: title,
                          day: day,
                          hour: hour,
                          duration: duration,
                          color: predefinedColors[Random()
                              .nextInt(
                                  predefinedColors.length)],
                        ));
                      });
                    } else {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                            content:
                                Text('일정 제목을 입력해주세요.')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // 다이얼로그가 닫힌 후 전체 화면을 다시 빌드합니다.
      setState(() {});
    });
  }

  void _showEditEventDialog(
      BuildContext context, ScheduleEvent event) {
    String title = event.title;
    int day = event.day;
    int hour = event.hour;
    int duration = event.duration;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('일정 편집'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                        labelText: '일정 제목'),
                    controller:
                        TextEditingController(text: title),
                    onChanged: (value) => title = value,
                  ),
                  DropdownButton<int>(
                    value: day,
                    items: List.generate(
                        7,
                        (index) => DropdownMenuItem<int>(
                              value: index,
                              child: Text([
                                '월',
                                '화',
                                '수',
                                '목',
                                '금',
                                '토',
                                '일'
                              ][index]),
                            )),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => day = value);
                      }
                    },
                  ),
                  DropdownButton<int>(
                    value: hour,
                    items: List.generate(
                        17,
                        (index) => DropdownMenuItem<int>(
                              value: index + 9,
                              child: Text(
                                  '${(index + 9).toString().padLeft(2, '0')}:00'),
                            )),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => hour = value);
                      }
                    },
                  ),
                  DropdownButton<int>(
                    value: duration,
                    items: [1, 2, 3, 4].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value시간'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => duration = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('삭제'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      events.remove(event);
                    });
                  },
                ),
                TextButton(
                  child: const Text('취소'),
                  onPressed: () =>
                      Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('수정'),
                  onPressed: () {
                    if (title.isNotEmpty) {
                      Navigator.of(context).pop();
                      setState(() {
                        int index = events.indexOf(event);
                        events[index] = ScheduleEvent(
                          title: title,
                          day: day,
                          hour: hour,
                          duration: duration,
                          color: event.color,
                        );
                      });
                    } else {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                            content:
                                Text('일정 제목을 입력해주세요.')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // 다이얼로그가 닫힌 후 전체 화면을 다시 빌드합니다.
      setState(() {});
    });
  }
}

class ScheduleEvent {
  final String title;
  final int day;
  final int hour;
  final int duration;
  final Color color;

  ScheduleEvent({
    required this.title,
    required this.day,
    required this.hour,
    required this.duration,
    required this.color,
  });
}

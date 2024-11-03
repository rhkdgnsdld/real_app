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
              onPressed: () => _showEventDialog(context),
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
    return SingleChildScrollView(
      child: Row(
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTimeColumn() {
    return Column(
      children: [
        // 상단에 15픽셀(30분의 반) 높이의 빈 공간 추가
        const SizedBox(height: 15),
        ...List.generate(32, (index) {
          final hour = 9 + (index ~/ 2);
          final minute = (index % 2) * 30;
          return Container(
            height: 30,
            width: 50,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: minute == 0
                      ? Colors.grey[300]!
                      : Colors.grey[100]!,
                ),
              ),
            ),
            child: minute == 0
                ? Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600]),
                  )
                : const SizedBox(),
          );
        }),
      ],
    );
  }

  Widget buildDayColumn(int dayIndex) {
    return Stack(
      children: [
        Column(
          children: [
            // 상단에 15픽셀(30분의 반) 높이의 빈 공간 추가
            const SizedBox(height: 15),
            ...List.generate(32, (index) {
              return Container(
                height: 30,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: index % 2 == 0
                          ? Colors.grey[300]!
                          : Colors.grey[100]!,
                    ),
                    right: BorderSide(
                        color: Colors.grey[300]!),
                  ),
                ),
              );
            }),
          ],
        ),
        // 이벤트도 같은 offset 적용
        Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Stack(
            children: events
                .where((event) => event.day == dayIndex)
                .map((event) {
              // 기존 계산 방식 유지
              double startTimeInHours =
                  event.startTimeAsDouble - 9.0;
              double gridUnits = startTimeInHours * 2;
              double topPosition = gridUnits * 30;

              double durationInHours = event.duration;
              double durationGridUnits =
                  durationInHours * 2;
              double heightValue = durationGridUnits * 30;

              return Positioned(
                top: topPosition,
                left: 0,
                right: 0,
                height: heightValue,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 2),
                  decoration: BoxDecoration(
                    color: event.color.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: GestureDetector(
                    onTap: () =>
                        _showEventDialog(context, event),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

// 시간 포맷 헬퍼 함수
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showEventDialog(BuildContext context,
      [ScheduleEvent? event]) {
    String title = event?.title ?? '';
    int day = event?.day ?? 0;
    TimeOfDay startTime = event?.startTime ??
        const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = event?.endTime ??
        const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title:
                  Text(event == null ? '시간표 추가' : '시간표 수정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '과목명',
                      hintText: '과목명을 입력하세요',
                    ),
                    controller: TextEditingController(
                        text: title)
                      ..selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: title.length),
                      ),
                    onChanged: (value) => title = value,
                  ),
                  const SizedBox(height: 16),
                  const Text('요일',
                      style: TextStyle(fontSize: 16)),
                  DropdownButton<int>(
                    isExpanded: true,
                    value: day,
                    items: const [
                      DropdownMenuItem(
                          value: 0, child: Text('월요일')),
                      DropdownMenuItem(
                          value: 1, child: Text('화요일')),
                      DropdownMenuItem(
                          value: 2, child: Text('수요일')),
                      DropdownMenuItem(
                          value: 3, child: Text('목요일')),
                      DropdownMenuItem(
                          value: 4, child: Text('금요일')),
                      DropdownMenuItem(
                          value: 5, child: Text('토요일')),
                      DropdownMenuItem(
                          value: 6, child: Text('일요일')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => day = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('시작 시간'),
                            TextButton(
                              onPressed: () async {
                                final TimeOfDay? picked =
                                    await showTimePicker(
                                  context: context,
                                  initialTime: startTime,
                                  builder:
                                      (context, child) {
                                    return MediaQuery(
                                      data: MediaQuery.of(
                                              context)
                                          .copyWith(
                                        alwaysUse24HourFormat:
                                            true,
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setDialogState(() =>
                                      startTime = picked);
                                }
                              },
                              child: Text(
                                  _formatTime(startTime)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('종료 시간'),
                            TextButton(
                              onPressed: () async {
                                final TimeOfDay? picked =
                                    await showTimePicker(
                                  context: context,
                                  initialTime: endTime,
                                  builder:
                                      (context, child) {
                                    return MediaQuery(
                                      data: MediaQuery.of(
                                              context)
                                          .copyWith(
                                        alwaysUse24HourFormat:
                                            true,
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setDialogState(() =>
                                      endTime = picked);
                                }
                              },
                              child: Text(
                                  _formatTime(endTime)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                if (event != null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() => events.remove(event));
                    },
                    child: const Text('삭제'),
                  ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                            content: Text('과목명을 입력해주세요')),
                      );
                      return;
                    }

                    final startDouble = startTime.hour +
                        (startTime.minute / 60);
                    final endDouble = endTime.hour +
                        (endTime.minute / 60);

                    if (startDouble >= endDouble) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                            content: Text(
                                '종료 시간은 시작 시간보다 늦어야 합니다')),
                      );
                      return;
                    }

                    final newEvent = ScheduleEvent(
                      title: title,
                      day: day,
                      startTime: startTime,
                      endTime: endTime,
                      color: event?.color ??
                          predefinedColors[Random().nextInt(
                              predefinedColors.length)],
                    );

                    setState(() {
                      if (event == null) {
                        events.add(newEvent);
                      } else {
                        final index = events.indexOf(event);
                        events[index] = newEvent;
                      }
                    });

                    Navigator.of(context).pop();
                  },
                  child: Text(event == null ? '추가' : '수정'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ScheduleEvent {
  final String title;
  final int day;
  final TimeOfDay startTime; // 시작 시간을 TimeOfDay로 변경
  final TimeOfDay endTime; // 종료 시간을 TimeOfDay로 변경
  final Color color;

  ScheduleEvent({
    required this.title,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.color,
  });

  // 시간을 double로 변환하는 helper 메서드
  double get startTimeAsDouble =>
      startTime.hour + (startTime.minute / 60);
  double get endTimeAsDouble =>
      endTime.hour + (endTime.minute / 60);
  double get duration =>
      endTimeAsDouble - startTimeAsDouble;
}

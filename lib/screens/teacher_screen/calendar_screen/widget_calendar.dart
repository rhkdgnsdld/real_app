import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  _WeeklyScheduleScreenState createState() =>
      _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState
    extends State<WeeklyScheduleScreen> {
  List<ScheduleEvent> events = [];
  final String userId =
      FirebaseAuth.instance.currentUser?.uid ?? '';
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
  void initState() {
    super.initState();
    if (userId.isNotEmpty) {
      loadSchedule();
    }
  }

  Future<void> loadSchedule() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .doc(userId)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        setState(() {
          events = (data['events'] as List)
              .map((e) => ScheduleEvent.fromJson(
                  e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      print('스케줄 로드 에러: $e');
    }
  }

  // 스케줄 저장
  Future<void> saveSchedule() async {
    try {
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(userId)
          .set({
        'events': events.map((e) => e.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('스케줄 저장 에러: $e');
    }
  }

  void _addEvent(ScheduleEvent newEvent) {
    setState(() {
      events.add(newEvent);
    });
    saveSchedule();
  }

  void _updateEvent(
      ScheduleEvent oldEvent, ScheduleEvent newEvent) {
    setState(() {
      final index = events.indexOf(oldEvent);
      if (index != -1) {
        events[index] = newEvent;
      }
    });
    saveSchedule();
  }

  void _deleteEvent(ScheduleEvent event) {
    setState(() {
      events.remove(event);
    });
    saveSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          buildHeader(),
          buildWeekDays(),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                // 전체 너비 지정
                width: MediaQuery.of(context).size.width,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      buildTimeColumn(),
                      Expanded(
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
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
                ),
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
      color: const Color(0xFF5BABEF),
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
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTimeColumn() {
    return Column(
      children: List.generate(33, (index) {
        // 33개의 줄로 변경
        final hour = 8 + (index ~/ 2); // 8시부터 시작
        final minute = (index % 2) * 30;
        return Container(
          height: 30,
          width: 60,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                // top border로 변경
                color: Colors.grey[300]!,
                width: minute == 30
                    ? 0.5
                    : 1.0, // 정시는 굵게, 30분은 얇게
              ),
            ),
          ),
          child: Text(
            minute == 30
                ? '${(hour + 1).toString().padLeft(2, '0')}:00' // 30분 줄 위에 다음 정시 표시
                : '${hour.toString().padLeft(2, '0')}:30', // 정시 줄 위에 30분 표시
            style: TextStyle(
              fontSize: 12,
              color: minute == 30
                  ? Colors.grey[800]
                  : Colors.grey[500],
              fontWeight: minute == 30
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        );
      }),
    );
  }

  Widget buildDayColumn(int dayIndex) {
    return Stack(
      children: [
        // 격자 그리기
        Column(
          children: List.generate(33, (index) {
            return Container(
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[300]!,
                    width: index % 2 == 1 ? 0.5 : 1.0,
                  ),
                  right:
                      BorderSide(color: Colors.grey[300]!),
                ),
              ),
            );
          }),
        ),
        // 이벤트 표시 (Stack을 제거하고 직접 events를 매핑)
        ...events
            .where((event) => event.day == dayIndex)
            .map((event) {
          double startTimeInHours =
              event.startTimeAsDouble - 9.0;
          double gridUnits = startTimeInHours * 2;
          double topPosition = (gridUnits + 1) * 30;

          double durationInHours = event.duration;
          double durationGridUnits = durationInHours * 2;
          double heightValue = durationGridUnits * 30;

          return Positioned(
            top: topPosition,
            left: 0,
            right: 0,
            height: heightValue,
            child: GestureDetector(
              // 이벤트 탭 가능하도록 GestureDetector 추가
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('${event.title} 수정'),
                      content:
                          const Text('이 시간표를 수정하시겠습니까?'),
                      actions: [
                        // 삭제 버튼
                        TextButton(
                          onPressed: () {
                            setState(() {
                              events.remove(event);
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('삭제',
                              style: TextStyle(
                                  color: Colors.red)),
                        ),
                        // 취소 버튼
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context),
                          child: const Text('취소'),
                        ),
                        // 수정 버튼
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                                context); // 현재 다이얼로그 닫기
                            _showEventDialog(context,
                                event); // 수정 다이얼로그 열기
                          },
                          child: const Text('수정'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 2),
                decoration: BoxDecoration(
                  color: event.color.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                        style:
                            const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
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
    final TextEditingController titleController =
        TextEditingController(text: event?.title ?? '');
    String title = event?.title ?? '';
    List<int> selectedDays =
        event != null ? [event.day] : [];
    TimeOfDay selectedStartTime = event?.startTime ??
        const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay selectedEndTime = event?.endTime ??
        const TimeOfDay(hour: 10, minute: 0);
    // 색상을 미리 선택
    Color selectedColor = event?.color ??
        predefinedColors[
            Random().nextInt(predefinedColors.length)];

    final weekDays = [
      {'index': 0, 'name': '월'},
      {'index': 1, 'name': '화'},
      {'index': 2, 'name': '수'},
      {'index': 3, 'name': '목'},
      {'index': 4, 'name': '금'},
      {'index': 5, 'name': '토'},
      {'index': 6, 'name': '일'},
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Center(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 헤더
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              Colors.blue.withOpacity(0.1),
                          borderRadius:
                              const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                                Icons.calendar_today),
                            const SizedBox(width: 8),
                            Text(
                              event == null
                                  ? '시간표 추가'
                                  : '시간표 수정',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 내용
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // 과목명 입력
                            TextField(
                              onChanged: (value) {
                                title = value;
                              },
                              decoration:
                                  const InputDecoration(
                                labelText: '과목명',
                                hintText: '과목명을 입력하세요',
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 요일 선택
                            const Text('요일 선택',
                                style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceEvenly,
                              children: weekDays.map((day) {
                                bool isSelected =
                                    selectedDays.contains(
                                        day['index']);
                                return GestureDetector(
                                  onTap: () {
                                    dialogSetState(() {
                                      // setState를 dialogSetState로 변경
                                      if (isSelected) {
                                        selectedDays.remove(
                                            day['index']);
                                      } else {
                                        selectedDays.add(
                                            day['index']
                                                as int);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding:
                                        const EdgeInsets
                                            .all(8),
                                    decoration:
                                        BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors
                                              .grey[200],
                                      shape:
                                          BoxShape.circle,
                                    ),
                                    child: Text(
                                      day['name'] as String,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            // 시간 선택
                            Row(
                              children: [
                                Expanded(
                                  child: ListTile(
                                    title: const Text('시작'),
                                    subtitle: Text(_formatTime(
                                        selectedStartTime)),
                                    onTap: () async {
                                      final TimeOfDay?
                                          picked =
                                          await showTimePicker(
                                        context: context,
                                        initialTime:
                                            selectedStartTime,
                                        builder: (context,
                                            child) {
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
                                        setState(() =>
                                            selectedStartTime =
                                                picked);
                                      }
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: ListTile(
                                    title: const Text('종료'),
                                    subtitle: Text(
                                        _formatTime(
                                            selectedEndTime)),
                                    onTap: () async {
                                      final TimeOfDay?
                                          picked =
                                          await showTimePicker(
                                        context: context,
                                        initialTime:
                                            selectedEndTime,
                                        builder: (context,
                                            child) {
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
                                        setState(() =>
                                            selectedEndTime =
                                                picked);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 버튼
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context),
                              child: const Text('취소'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (title.isEmpty) {
                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            '과목명을 입력해주세요')),
                                  );
                                  return;
                                }

                                if (selectedDays.isEmpty) {
                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            '요일을 선택해주세요')),
                                  );
                                  return;
                                }

                                if (event != null) {
                                  // 수정 모드
                                  final newEvent =
                                      ScheduleEvent(
                                    title: title,
                                    day: selectedDays[0],
                                    startTime:
                                        selectedStartTime,
                                    endTime:
                                        selectedEndTime,
                                    color: event.color,
                                  );
                                  _updateEvent(
                                      event, newEvent);
                                } else {
                                  // 새로운 이벤트 추가 모드
                                  for (int day
                                      in selectedDays) {
                                    final newEvent =
                                        ScheduleEvent(
                                      title: title,
                                      day: day,
                                      startTime:
                                          selectedStartTime,
                                      endTime:
                                          selectedEndTime,
                                      color: selectedColor,
                                    );
                                    _addEvent(newEvent);
                                  }
                                }

                                Navigator.pop(context);
                              },
                              child: Text(event == null
                                  ? '추가'
                                  : '수정'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) => titleController.dispose());
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

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'day': day,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'color': color.value, // Color를 정수값으로 저장
    };
  }

  // JSON에서 ScheduleEvent 객체 생성
  static ScheduleEvent fromJson(Map<String, dynamic> json) {
    return ScheduleEvent(
      title: json['title'] as String,
      day: json['day'] as int,
      startTime: TimeOfDay(
          hour: json['startHour'],
          minute: json['startMinute']),
      endTime: TimeOfDay(
          hour: json['endHour'], minute: json['endMinute']),
      color: Color(json['color'] as int),
    );
  }

  double get startTimeAsDouble =>
      startTime.hour + (startTime.minute / 60);
  double get endTimeAsDouble =>
      endTime.hour + (endTime.minute / 60);
  double get duration =>
      endTimeAsDouble - startTimeAsDouble;
}

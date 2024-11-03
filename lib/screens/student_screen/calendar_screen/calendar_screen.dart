import 'package:flutter/material.dart';
import 'dart:math';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  _ScheduleViewState createState() => _ScheduleViewState();
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

class _ScheduleViewState extends State<ScheduleView> {
  List<ScheduleEvent> events = [];
  final List<Color> predefinedColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
  ];

  // 통합된 다이얼로그 함수
  void _showEventDialog(BuildContext context,
      [ScheduleEvent? event]) {
    // 수정 모드면 기존 값을, 추가 모드면 기본값을 사용
    String title = event?.title ?? '';
    int day = event?.day ?? 0;
    int hour = event?.hour ?? 9;
    int duration = event?.duration ?? 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title:
                  Text(event == null ? '일정 추가' : '일정 편집'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                        labelText: '일정 제목'),
                    controller: TextEditingController(
                        text: title)
                      ..selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: title.length),
                      ),
                    onChanged: (value) => title = value,
                  ),
                  const SizedBox(height: 8),
                  _buildDropdownButton(
                    value: day,
                    items: List.generate(
                        7,
                        (index) => {
                              'value': index,
                              'label': [
                                '월',
                                '화',
                                '수',
                                '목',
                                '금',
                                '토',
                                '일'
                              ][index]
                            }),
                    onChanged: (value) =>
                        setDialogState(() => day = value),
                  ),
                  const SizedBox(height: 8),
                  _buildDropdownButton(
                    value: hour,
                    items: List.generate(
                        17,
                        (index) => {
                              'value': index + 9,
                              'label':
                                  '${(index + 9).toString().padLeft(2, '0')}:00'
                            }),
                    onChanged: (value) =>
                        setDialogState(() => hour = value),
                  ),
                  const SizedBox(height: 8),
                  _buildDropdownButton(
                    value: duration,
                    items: [1, 2, 3, 4]
                        .map((value) => {
                              'value': value,
                              'label': '$value시간'
                            })
                        .toList(),
                    onChanged: (value) => setDialogState(
                        () => duration = value),
                  ),
                ],
              ),
              actions: [
                if (event != null)
                  TextButton(
                    child: const Text('삭제'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() => events.remove(event));
                    },
                  ),
                TextButton(
                  child: const Text('취소'),
                  onPressed: () =>
                      Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(event == null ? '추가' : '수정'),
                  onPressed: () {
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                            content:
                                Text('일정 제목을 입력해주세요.')),
                      );
                      return;
                    }

                    final newEvent = ScheduleEvent(
                      title: title,
                      day: day,
                      hour: hour,
                      duration: duration,
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
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownButton({
    required int value,
    required List<Map<String, dynamic>> items,
    required Function(int) onChanged,
  }) {
    return DropdownButton<int>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem<int>(
                value: item['value'],
                child: Text(item['label']),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1 / 2,
        ),
        itemCount: 7 * 17,
        itemBuilder: (context, index) {
          int day = index % 7;
          int hour = index ~/ 7 + 9;

          // firstWhere 대신 where를 사용하여 해당 시간의 이벤트를 찾습니다
          final currentEvents = events.where((e) =>
              e.day == day &&
              hour >= e.hour &&
              hour < (e.hour + e.duration));

          // 찾은 이벤트가 있고, 현재 시간이 이벤트의 시작 시간인 경우
          if (currentEvents.isNotEmpty &&
              hour == currentEvents.first.hour) {
            final event = currentEvents.first;
            return GestureDetector(
              onTap: () => _showEventDialog(context, event),
              child: Container(
                height: 50.0 * event.duration,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: event.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  event.title,
                  style:
                      const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // 이벤트가 있지만 시작 시간이 아닌 경우 빈 컨테이너 반환
          if (currentEvents.isNotEmpty) {
            return Container();
          }

          // 이벤트가 없는 경우 기본 그리드 셀 반환
          return Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.grey.withOpacity(0.3)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

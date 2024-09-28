import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TimetableEntry {
  String subject;
  String day;
  int startTime;
  int duration;

  TimetableEntry({
    required this.subject,
    required this.day,
    required this.startTime,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'day': day,
        'startTime': startTime,
        'duration': duration,
      };

  factory TimetableEntry.fromJson(
          Map<String, dynamic> json) =>
      TimetableEntry(
        subject: json['subject'],
        day: json['day'],
        startTime: json['startTime'],
        duration: json['duration'],
      );
}

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  _TimetablePageState createState() =>
      _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  List<TimetableEntry> entries = [];

  @override
  void initState() {
    super.initState();
    loadEntries();
  }

  void loadEntries() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? entriesJson =
        prefs.getString('timetableEntries');
    if (entriesJson != null) {
      List<dynamic> decodedEntries =
          jsonDecode(entriesJson);
      setState(() {
        entries = decodedEntries
            .map((e) => TimetableEntry.fromJson(e))
            .toList();
      });
    }
  }

  void saveEntries() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String entriesJson =
        jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString('timetableEntries', entriesJson);
  }

  void addEntry(TimetableEntry entry) {
    setState(() {
      entries.add(entry);
    });
    saveEntries();
  }

  void editEntry(int index, TimetableEntry newEntry) {
    setState(() {
      entries[index] = newEntry;
    });
    saveEntries();
  }

  void deleteEntry(int index) {
    setState(() {
      entries.removeAt(index);
    });
    saveEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.blue,
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '시간표 확인',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add,
                        color: Colors.white),
                    onPressed: () =>
                        _showAddEntryDialog(context),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: TimetableGrid(
                  entries: entries,
                  onEdit: editEntry,
                  onDelete: deleteEntry),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String subject = '';
        String day = '월';
        int startTime = 14;
        int duration = 1;

        return AlertDialog(
          title: const Text('시간표 추가'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                      labelText: '과목명'),
                  onChanged: (value) => subject = value,
                ),
                DropdownButtonFormField<String>(
                  value: day,
                  items: ['월', '화', '수', '목', '금', '토', '일']
                      .map((d) => DropdownMenuItem(
                          value: d, child: Text(d)))
                      .toList(),
                  onChanged: (value) => day = value!,
                  decoration: const InputDecoration(
                      labelText: '요일'),
                ),
                DropdownButtonFormField<int>(
                  value: startTime,
                  items: List.generate(
                          9, (index) => index + 14)
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text('$t시')))
                      .toList(),
                  onChanged: (value) => startTime = value!,
                  decoration: const InputDecoration(
                      labelText: '시작 시간'),
                ),
                DropdownButtonFormField<int>(
                  value: duration,
                  items: [1, 2, 3, 4]
                      .map((d) => DropdownMenuItem(
                          value: d, child: Text('$d시간')))
                      .toList(),
                  onChanged: (value) => duration = value!,
                  decoration: const InputDecoration(
                      labelText: '수업 시간'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('추가'),
              onPressed: () {
                if (subject.isNotEmpty) {
                  addEntry(TimetableEntry(
                    subject: subject,
                    day: day,
                    startTime: startTime,
                    duration: duration,
                  ));
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class TimetableGrid extends StatelessWidget {
  final List<TimetableEntry> entries;
  final Function(int, TimetableEntry) onEdit;
  final Function(int) onDelete;

  const TimetableGrid(
      {super.key,
      required this.entries,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      defaultColumnWidth: const FlexColumnWidth(1),
      children: _buildTableRows(context),
    );
  }

  List<TableRow> _buildTableRows(BuildContext context) {
    List<TableRow> rows = [];
    List<String> days = [
      '',
      '월',
      '화',
      '수',
      '목',
      '금',
      '토',
      '일'
    ];
    List<int> hours =
        List.generate(17, (index) => index + 9);

    // Header row
    rows.add(TableRow(
      children: days
          .map((day) => TableCell(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(day,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                ),
              ))
          .toList(),
    ));

    // Time rows
    for (int hour in hours) {
      rows.add(TableRow(
        children: [
          TableCell(
            child: Container(
              height: 60,
              alignment: Alignment.center,
              child: Text('$hour:00'),
            ),
          ),
          ...List.generate(7, (dayIndex) {
            String currentDay = days[dayIndex + 1];
            TimetableEntry? currentEntry =
                entries.firstWhere(
              (e) =>
                  e.day == currentDay &&
                  e.startTime == hour,
              orElse: () => TimetableEntry(
                  subject: '',
                  day: '',
                  startTime: -1,
                  duration: 0),
            );

            if (currentEntry.startTime != -1) {
              return TableCell(
                verticalAlignment:
                    TableCellVerticalAlignment.fill,
                child: GestureDetector(
                  onTap: () => _showEditEntryDialog(
                      context,
                      entries.indexOf(currentEntry),
                      currentEntry),
                  child: Container(
                    height: 60.0 * currentEntry.duration,
                    color: Colors.blue[100],
                    alignment: Alignment.center,
                    child: Text(currentEntry.subject),
                  ),
                ),
              );
            } else {
              TimetableEntry? ongoingEntry =
                  entries.firstWhere(
                (e) =>
                    e.day == currentDay &&
                    e.startTime < hour &&
                    (e.startTime + e.duration) > hour,
                orElse: () => TimetableEntry(
                    subject: '',
                    day: '',
                    startTime: -1,
                    duration: 0),
              );

              return TableCell(
                child: ongoingEntry.startTime != -1
                    ? Container(color: Colors.blue[100])
                    : Container(height: 60),
              );
            }
          }),
        ],
      ));
    }

    return rows;
  }

  void _showEditEntryDialog(BuildContext context, int index,
      TimetableEntry entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String subject = entry.subject;
        String day = entry.day;
        int startTime = entry.startTime;
        int duration = entry.duration;

        return AlertDialog(
          title: const Text('시간표 수정'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                      labelText: '과목명'),
                  controller:
                      TextEditingController(text: subject),
                  onChanged: (value) => subject = value,
                ),
                DropdownButtonFormField<String>(
                  value: day,
                  items: ['월', '화', '수', '목', '금', '토', '일']
                      .map((d) => DropdownMenuItem(
                          value: d, child: Text(d)))
                      .toList(),
                  onChanged: (value) => day = value!,
                  decoration: const InputDecoration(
                      labelText: '요일'),
                ),
                DropdownButtonFormField<int>(
                  value: startTime,
                  items: List.generate(
                          9, (index) => index + 14)
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text('$t시')))
                      .toList(),
                  onChanged: (value) => startTime = value!,
                  decoration: const InputDecoration(
                      labelText: '시작 시간'),
                ),
                DropdownButtonFormField<int>(
                  value: duration,
                  items: [1, 2, 3, 4]
                      .map((d) => DropdownMenuItem(
                          value: d, child: Text('$d시간')))
                      .toList(),
                  onChanged: (value) => duration = value!,
                  decoration: const InputDecoration(
                      labelText: '수업 시간'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('삭제'),
              onPressed: () {
                onDelete(index);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('수정'),
              onPressed: () {
                if (subject.isNotEmpty) {
                  onEdit(
                      index,
                      TimetableEntry(
                        subject: subject,
                        day: day,
                        startTime: startTime,
                        duration: duration,
                      ));
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

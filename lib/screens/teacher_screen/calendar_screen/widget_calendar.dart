import 'package:flutter/material.dart';

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
            icon:
                const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // TODO: Implement add functionality
            },
          ),
        ],
      ),
    ),
  );
}

Widget buildWeekDays() {
  final weekDays = ['', '월', '화', '수', '목', '금', '토', '일'];
  return SizedBox(
    height: 50,
    child: Row(
      children: weekDays
          .map((day) => Expanded(
                child: Center(
                    child: Text(day,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold))),
              ))
          .toList(),
    ),
  );
}

Widget buildTimeGrid() {
  return Row(
    children: [
      buildTimeColumn(),
      Expanded(
        child: Row(
          children: List.generate(
              7,
              (index) => Expanded(
                    child: buildDayColumn(),
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

Widget buildDayColumn() {
  return Column(
    children: List.generate(17, (index) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
            right: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      );
    }),
  );
}

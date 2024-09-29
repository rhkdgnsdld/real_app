import 'package:flutter/material.dart';
import 'widget_calendar.dart';

class WeeklyScheduleScreenS extends StatelessWidget {
  const WeeklyScheduleScreenS({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          buildHeader(),
          Flexible(
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
}

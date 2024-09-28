import 'package:flutter/material.dart';
import 'widget_calendar.dart';

class WeeklyScheduleScreen extends StatelessWidget {
  const WeeklyScheduleScreen({super.key});

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
}

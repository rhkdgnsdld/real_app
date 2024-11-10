import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  static const thirtyMinutes = 1800;
  static const eigthtyMinutes = 4800;
  static const hundredMinutes = 6000;

  late AnimationController _animationController;
  late Timer timer;
  int totalSeconds = thirtyMinutes; // 초기값 설정
  int initialSeconds = thirtyMinutes; // 초기값 설정
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
          seconds: thirtyMinutes), // 초기 duration 설정
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (isRunning) {
      timer.cancel(); // 타이머가 실행 중이면 취소
    }
    super.dispose();
  }

  void onTick(Timer timer) {
    if (totalSeconds == 0) {
      setState(() {
        isRunning = false;
        totalSeconds = initialSeconds;
      });
      timer.cancel();
      _animationController.reset();
    } else {
      setState(() {
        totalSeconds = totalSeconds - 1;
      });
    }
  }

  void onStartPressed() {
    timer = Timer.periodic(
      const Duration(seconds: 1),
      onTick,
    );
    setState(() {
      isRunning = true;
    });
    _animationController.reverse(
        from: totalSeconds / initialSeconds);
  }

  void onPausePressed() {
    timer.cancel();
    setState(() {
      isRunning = false;
    });
    _animationController.stop();
  }

  void setTimer(int seconds) {
    if (isRunning) {
      timer.cancel();
    }
    setState(() {
      totalSeconds = seconds;
      initialSeconds = seconds;
      isRunning = false;
    });
    _animationController.duration =
        Duration(seconds: seconds);
    _animationController.reset();
  }

  String format(int seconds) {
    var duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes =
        twoDigits(duration.inMinutes); // 수정: 전체 분 표시
    final secondsStr =
        twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$secondsStr";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Column(
        children: [
          const SizedBox(height: 90),
          Flexible(
            flex: 4,
            child: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: TimerPainter(
                              animation:
                                  _animationController,
                              backgroundColor: Colors.white
                                  .withOpacity(0.3),
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                    Text(
                      format(totalSeconds),
                      style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontSize: 89,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 100,
                  color: Theme.of(context).cardColor,
                  onPressed: () {
                    if (isRunning) {
                      timer.cancel();
                    }
                    setState(() {
                      totalSeconds = initialSeconds;
                      isRunning = false;
                    });
                    _animationController.reset();
                  },
                  icon: const Icon(Icons.restore_sharp),
                ),
                const SizedBox(width: 20),
                IconButton(
                  iconSize: 100,
                  color: Theme.of(context).cardColor,
                  onPressed: isRunning
                      ? onPausePressed
                      : onStartPressed,
                  icon: Icon(isRunning
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 1,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeSelectIcon(30, thirtyMinutes),
                _buildTimeSelectIcon(80, eigthtyMinutes),
                _buildTimeSelectIcon(100, hundredMinutes),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '돌아가기',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelectIcon(int minutes, int seconds) {
    bool isSelected = totalSeconds == seconds;
    return GestureDetector(
      onTap: () => setTimer(seconds),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$minutes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.green : Colors.white,
          ),
        ),
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final Animation<double> animation;
  final Color backgroundColor;
  final Color color;

  TimerPainter({
    required this.animation,
    required this.backgroundColor,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = 15.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 배경 원 그리기 (희미한 원)
    paint.color = backgroundColor;
    canvas.drawCircle(
        size.center(Offset.zero), size.width / 2.0, paint);

    // 시간을 나타내는 호 그리기
    paint.color = color;
    double progress = (1.0 - animation.value) * 2 * pi;
    canvas.drawArc(
      Offset.zero & size,
      -pi / 2, // 12시 방향에서 시작
      progress, // 시계 방향으로 진행
      false, // 중심까지 연결하지 않음
      paint,
    );
  }

  @override
  bool shouldRepaint(TimerPainter old) {
    return animation.value != old.animation.value ||
        color != old.color ||
        backgroundColor != old.backgroundColor;
  }
}

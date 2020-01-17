import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:intl/intl.dart';

enum _Element {
  background,
  digit,
}

final _lightTheme = {
  _Element.background: Colors.grey.shade300,
  _Element.digit: Colors.grey.shade800,
};

final _darkTheme = {
  _Element.background: Colors.grey.shade900,
  _Element.digit: Colors.red.shade400,
};

class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      _timer = Timer(
        Duration(minutes: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _darkTheme;
    final hour =
        DateFormat(widget.model.is24HourFormat ? 'HH' : 'hh').format(_dateTime);
    final minute = DateFormat('mm').format(_dateTime);
    final firstHourDigit = int.parse(hour) ~/ 10;
    final secondHourDigit = int.parse(hour) % 10;
    final firstMinuteDigit = int.parse(minute) ~/ 10;
    final secondMinuteDigit = int.parse(minute) % 10;
    final deviceWidth = MediaQuery.of(context).size.width;
    final radius = deviceWidth / 12;
    final paintSize = deviceWidth / 60;
    final digitColor = colors[_Element.digit];
    final animationDuration = const Duration(milliseconds: 500);

    return Container(
      color: colors[_Element.background],
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Center(
        child: Row(
          children: <Widget>[
            createDigitWidget(firstHourDigit, digitColor, radius, paintSize,
                animationDuration),
            createDigitWidget(secondHourDigit, digitColor, radius, paintSize,
                animationDuration),
            createDigitWidget(firstMinuteDigit, digitColor, radius, paintSize,
                animationDuration),
            createDigitWidget(secondMinuteDigit, digitColor, radius, paintSize,
                animationDuration),
          ],
        ),
      ),
    );
  }

  Expanded createDigitWidget(int digit, Color color, double radius,
          double paintSize, Duration animationDuration) =>
      Expanded(
        child: AnimatedSwitcher(
          child: CustomPaint(
            key: ValueKey(digit),
            painter: DigitPainter(
              digit,
              color: color,
              radius: radius,
              paintSize: paintSize,
            ),
          ),
          duration: animationDuration,
          transitionBuilder: (Widget child, Animation<double> animation) =>
              ScaleTransition(child: child, scale: animation),
        ),
      );
}

class DigitPainter extends CustomPainter {
  DigitPainter(this.digit, {this.color, this.radius, this.paintSize});

  final int digit;
  final Color color;
  final double radius;
  final double paintSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = paintSize
      ..style = PaintingStyle.fill;
    var center = Offset(size.width / 2, size.height / 2);
    drawDigit(canvas, center, paint);
  }

  void drawDigit(Canvas canvas, Offset center, Paint paint) {
    switch (digit) {
      case 1:
        drawDot(canvas, center, paint);
        break;
      case 2:
        drawVerticalRoundedLine(center, canvas, paint);
        break;
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 9:
        drawRegularPolygon(canvas, center, paint);
        break;
    }
  }

  void drawRegularPolygon(Canvas canvas, Offset center, Paint paint) {
    canvas.drawPath(regularPolygonPath(center), paint);
  }

  void drawDot(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(center, paintSize, paint);
  }

  void drawVerticalRoundedLine(Offset center, Canvas canvas, Paint paint) {
    var up = Offset(center.dx, center.dy + radius - paintSize / 2);
    var down = Offset(center.dx, center.dy - radius + paintSize / 2);
    canvas.drawLine(up, down, paint);
    canvas.drawCircle(up, paintSize / 2, paint);
    canvas.drawCircle(down, paintSize / 2, paint);
  }

  Path regularPolygonPath(Offset center) {
    final path = Path()..moveTo(center.dx, center.dy);
    final startAngle = 1.5;
    var angle = startAngle * pi;
    var angleIncrement = 2 * pi / digit;
    var x, y;
    var drawCount = digit + 1;
    for (var i = 0; i < drawCount; i++) {
      x = center.dx + radius * cos(angle);
      y = center.dy + radius * sin(angle);
      path.lineTo(x, y);
      angle += angleIncrement;
    }
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is DigitPainter) {
      return oldDelegate.digit != digit;
    } else {
      return true;
    }
  }
}

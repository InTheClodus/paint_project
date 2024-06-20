import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double MIN_ANGLE = (pi * 5) / 24;
const double POINT_ANGLE = pi / 12;

class TimerWidget extends StatefulWidget {
  final void Function(String leftTime, String rightTime)? onTimeChanged;

  const TimerWidget({super.key, this.onTimeChanged});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}


class _TimerWidgetState extends State<TimerWidget> {
  double slipAngleL = (pi * 3) / 4;
  double slipAngleR = (pi * 1) / 4;
  bool isDragging = false;
  String draggingPoint = '';
  Offset lastPosition = Offset.zero;

  void _onPanStart(DragStartDetails details) {
    final position = details.localPosition;
    if (_isOnPoint(position, slipAngleL)) {
      draggingPoint = 'l';
    } else if (_isOnPoint(position, slipAngleR)) {
      draggingPoint = 'r';
    } else {
      draggingPoint = '';
    }

    if (_isOnSlip(position)) {
      setState(() {
        isDragging = true;
      });
      lastPosition = position;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final position = details.localPosition;
    final angle = _calculateAngle(position);
    final lastAngle = _calculateAngle(lastPosition);

    if (isDragging) {
      setState(() {
        if (draggingPoint == 'l') {
          final targetL = _formatAngle(slipAngleL + angle - lastAngle);
          final delta = _calculateAngleDifference(targetL, slipAngleR);

          if (delta >= MIN_ANGLE) {
            slipAngleL = targetL;
          }
        } else if (draggingPoint == 'r') {
          final targetR = _formatAngle(slipAngleR + angle - lastAngle);
          final delta = _calculateAngleDifference(targetR, slipAngleL);

          if (delta >= MIN_ANGLE) {
            slipAngleR = targetR;
          }
        } else {
          final targetL = _formatAngle(slipAngleL + angle - lastAngle);
          final targetR = _formatAngle(slipAngleR + angle - lastAngle);
          slipAngleL = targetL;
          slipAngleR = targetR;
        }
      });
      lastPosition = position;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      isDragging = false;
    });
    if (widget.onTimeChanged != null) {
      final leftTime = _angleToTimeString(slipAngleL);
      final rightTime = _angleToTimeString(slipAngleR);
      widget.onTimeChanged!(leftTime, rightTime);
    }
  }

  String _angleToTimeString(double angle) {
    final totalMinutes = (angle / (2 * pi)) * 1440; // 总分钟数
    final hours = (totalMinutes / 60).floor();
    final minutes = (totalMinutes % 60).floor();
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }


  double _calculateAngle(Offset position) {
    const centerX = 200.0;
    const centerY = 200.0;
    var angle = atan2(position.dy - centerY, position.dx - centerX);
    if (angle < 0) angle = 2 * pi + angle;
    return angle;
  }

  double _calculateAngleDifference(double angle1, double angle2) {
    final delta = (angle1 - angle2).abs();
    return min(delta, 2 * pi - delta);
  }

  bool _isOnSlip(Offset position) {
    const centerX = 200.0;
    const centerY = 200.0;
    const clockR = 100.0;
    const sliperWidth = 24.0;
    const spaceWidth = 5.0;

    final r = (position - const Offset(centerX, centerY)).distance;
    final angle = _calculateAngle(position);

    final langle = slipAngleL;
    final rangle = slipAngleR < slipAngleL ? slipAngleR + 2 * pi : slipAngleR;
    final cangle = angle < slipAngleL ? angle + 2 * pi : angle;

    final result = r < clockR + spaceWidth + sliperWidth &&
        r > clockR + spaceWidth &&
        cangle - langle < rangle - langle;

    if (result) {
      final ldiff = _calculateAngleDifference(slipAngleL, angle);
      final rdiff = _calculateAngleDifference(slipAngleR, angle);

      if (ldiff > POINT_ANGLE && rdiff > POINT_ANGLE) draggingPoint = '';
      if (ldiff > POINT_ANGLE && rdiff < POINT_ANGLE) draggingPoint = 'r';
      if (ldiff < POINT_ANGLE && rdiff > POINT_ANGLE) draggingPoint = 'l';
    } else {
      draggingPoint = '';
    }

    return result;
  }

  bool _isOnPoint(Offset position, double angle) {
    const centerX = 200.0;
    const centerY = 200.0;
    const clockR = 100.0;
    const sliperWidth = 24.0;
    const spaceWidth = 5.0;

    final pointX =
        centerX + (clockR + spaceWidth + sliperWidth / 2) * cos(angle);
    final pointY =
        centerY + (clockR + spaceWidth + sliperWidth / 2) * sin(angle);

    final pointDistance = (position - Offset(pointX, pointY)).distance;

    return pointDistance < 10.0;
  }

  double _formatAngle(double angle) {
    if (angle > 2 * pi) return angle - 2 * pi;
    if (angle < 0) return angle + 2 * pi;
    return angle;
  }

  ui.Image? leftImage;
  ui.Image? rightImage;

  Future<ui.Image> loadImage(String asset) async {
    final ByteData data = await rootBundle.load(asset);
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final leftIcon = await loadImage('assets/left_icon.png');
    final rightIcon = await loadImage('assets/right_icon.png');
    setState(() {
      leftImage = leftIcon;
      rightImage = rightIcon;
    });
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        size: const Size(400, 400),
        painter: TimerPainter(
          slipAngleL,
          slipAngleR,
          leftImage: leftImage,
          rightImage: rightImage,
        ),
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final double slipAngleL;
  final double slipAngleR;
  static const double POINT_ANGLE = pi / 12;

  ui.Image? leftImage;
  ui.Image? rightImage;

  TimerPainter(this.slipAngleL, this.slipAngleR,
      {this.leftImage, this.rightImage});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const clockR = 100.0;
    const sliperWidth = 24.0;
    const spaceWidth = 5.0;

    // Draw the background circle
    final backgroundPaint1 = Paint()
      ..color = const Color(0xFF010101)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), 134, backgroundPaint1);
    final paint = Paint()
      ..color = const Color(0xFF2C2C2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sliperWidth
      ..strokeCap = StrokeCap.round; // Add round caps to the paint

    // Draw the background circle
    final backgroundPaint = Paint()
      ..color = const Color(0xFF2C2C2E)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), clockR, backgroundPaint);

    // Draw the arc with rounded ends
    final arcLength = slipAngleR > slipAngleL
        ? slipAngleR - slipAngleL
        : 2 * pi - slipAngleL + slipAngleR;
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: clockR + sliperWidth / 2 + spaceWidth),
      slipAngleL,
      arcLength,
      false,
      paint,
    );

    // Draw the left point arc
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: clockR + sliperWidth / 2 + spaceWidth),
      slipAngleL,
      POINT_ANGLE,
      false,
      paint..color = const Color(0xFF2C2C2E),
    );

    // Draw the right point arc
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: clockR + sliperWidth / 2 + spaceWidth),
      slipAngleR - POINT_ANGLE,
      POINT_ANGLE,
      false,
      paint..color = const Color(0xFF2C2C2E),
    );

    // Draw the ticks and numbers
    final tickPaint = Paint()
      ..color = const Color(0xFF8D8D8F)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < 12; i++) {
      final angle = (i * pi / 6) - pi / 2;
      const tickLength = 6.0;

      final tickStart = Offset(
        centerX + (clockR - tickLength - 5) * cos(angle), // 缩进5个单位
        centerY + (clockR - tickLength - 5) * sin(angle), // 缩进5个单位
      );
      final tickEnd = Offset(
        centerX + (clockR - 5) * cos(angle), // 缩进5个单位
        centerY + (clockR - 5) * sin(angle), // 缩进5个单位
      );

      canvas.drawLine(tickStart, tickEnd, tickPaint);

      // Draw the numbers
      final textAngle = angle;
      final textX =
          centerX + (clockR - tickLength * 2.5 - 10) * cos(textAngle); // 缩进5个单位
      final textY =
          centerY + (clockR - tickLength * 2.5 - 10) * sin(textAngle); // 缩进5个单位

      final textSpan = TextSpan(
        text: '${2 * i}',
        style: TextStyle(
          color:
              (i % 3 == 0) ? const Color(0xFFFBFBFD) : const Color(0xFF8D8D8F),
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
        ),
      );

      textPainter.text = textSpan;
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              textX - textPainter.width / 2, textY - textPainter.height / 2));
    }

    // Draw small ticks
    for (int i = 0; i < 12; i++) {
      final mainAngle = (i * pi / 6) - pi / 2;
      for (int j = 1; j < 8; j++) {
        final subAngle = mainAngle + (j * pi / 48); // 7个小刻度加上大刻度一共是8个刻度
        final tickLength = j == 3 ? 6.0 : 3.0;

        final tickStart = Offset(
          centerX + (clockR - tickLength - 5) * cos(subAngle), // 缩进5个单位
          centerY + (clockR - tickLength - 5) * sin(subAngle), // 缩进5个单位
        );
        final tickEnd = Offset(
          centerX + (clockR - 5) * cos(subAngle), // 缩进5个单位
          centerY + (clockR - 5) * sin(subAngle), // 缩进5个单位
        );

        canvas.drawLine(tickStart, tickEnd, tickPaint);
      }
    }

    // Draw the ruler on the progress bar
    const rulerHeight = 8.0;
    const rulerWidth = 1.3;
    final rulerPaint = Paint()
      ..color = const Color(0xFF8D8D8F)
      ..strokeWidth = rulerWidth
      ..style = PaintingStyle.stroke;

    final rulerStartAngle = slipAngleL + POINT_ANGLE;
    final rulerEndAngle = slipAngleR - POINT_ANGLE;
    final rulerArcLength = (rulerEndAngle > rulerStartAngle)
        ? rulerEndAngle - rulerStartAngle
        : (2 * pi - rulerStartAngle + rulerEndAngle);

    // Calculate the number of ticks based on the central ticks' spacing
    const tickSpacing =
        pi / 48; // same as the small tick spacing in the central circle
    final numTicks = (rulerArcLength / tickSpacing).ceil();

    for (int i = 0; i <= numTicks; i++) {
      final angle = rulerStartAngle + i * tickSpacing;

      // Adjust angle to be within 0 to 2π range
      final adjustedAngle = angle % (2 * pi);

      // Check if the current tick should be drawn
      final shouldDraw =
          (rulerStartAngle < rulerEndAngle && adjustedAngle <= rulerEndAngle) ||
              (rulerStartAngle > rulerEndAngle &&
                  (adjustedAngle >= rulerStartAngle ||
                      adjustedAngle <= rulerEndAngle));

      if (!shouldDraw) break;

      final start = Offset(
        centerX +
            (clockR + spaceWidth + sliperWidth / 2 - rulerHeight / 2) *
                cos(adjustedAngle),
        centerY +
            (clockR + spaceWidth + sliperWidth / 2 - rulerHeight / 2) *
                sin(adjustedAngle),
      );
      final end = Offset(
        centerX +
            (clockR + spaceWidth + sliperWidth / 2 + rulerHeight / 2) *
                cos(adjustedAngle),
        centerY +
            (clockR + spaceWidth + sliperWidth / 2 + rulerHeight / 2) *
                sin(adjustedAngle),
      );
      canvas.drawLine(start, end, rulerPaint);
    }

    // Draw images at points
    if (leftImage != null && rightImage != null) {
      _drawImageAtAngle(canvas, leftImage!, slipAngleL, centerX, centerY,
          clockR, spaceWidth, sliperWidth);
      _drawImageAtAngle(canvas, rightImage!, slipAngleR, centerX, centerY,
          clockR, spaceWidth, sliperWidth);
    }
  }

  void _drawImageAtAngle(
      Canvas canvas,
      ui.Image image,
      double angle,
      double centerX,
      double centerY,
      double clockR,
      double spaceWidth,
      double sliperWidth) {
    final pointX =
        centerX + (clockR + spaceWidth + sliperWidth / 2) * cos(angle);
    final pointY =
        centerY + (clockR + spaceWidth + sliperWidth / 2) * sin(angle);

    final rect = Rect.fromCenter(
        center: Offset(pointX, pointY), width: 24.0, height: 24.0);

    final paint = Paint();
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

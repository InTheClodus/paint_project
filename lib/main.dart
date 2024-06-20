import 'package:flutter/material.dart';

import 'ios_clock.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paint',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String start = "";
  String end = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: const Color(0xFF2C2C2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CustomPaint(
              painter: ChargePainter(),
              size: Size(58,58),
            ),
            TimerWidget(
              onTimeChanged: (String leftTime, String rightTime) {
                // 在这里处理左边和右边时间的变化
                print('左边时间: $leftTime');
                print('右边时间: $rightTime');
                setState(() {
                  end = leftTime;

                  start = rightTime;
                });
              },
            ),
            Text(
              '开始时间：$start \n 结束时间：$end',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ChargePainter extends CustomPainter {
  // 底层颜色
  final Color bottomColor;

  // 顶层颜色
  final Color topColor;

  ChargePainter({
    this.bottomColor = const Color(0xFF1ACC2C),
    this.topColor = const Color(0xFF1FA22C),
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    double circleSize = size.width / 2;

    // 绘制第一个圆
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF494949), Color(0xFF494949)],
    ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2));
    paint.style = PaintingStyle.fill;
    paint.color = Colors.black.withOpacity(0.6);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      circleSize,
      paint,
    );

    // 绘制第二个圆
    paint.shader = null;
    paint.color = bottomColor;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      circleSize - 1.5298,
      paint,
    );

    // 绘制第三个圆
    paint.color = topColor;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      circleSize - 7.9043,
      paint,
    );

    // 绘制椭圆形
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Colors.white.withOpacity(0)],
    ).createShader(Rect.fromLTWH(0, 8.4668, size.width, 65.7849));
    paint.blendMode = BlendMode.overlay;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2 + 2.5498),
          width: circleSize * 1.87,
          height: circleSize * 1.73),
      paint,
    );

    // 绘制闪电路径
    double lightningSize = (circleSize - 7.9043) / 1.5; // 使闪电比第二个圆小

    Path path = Path();
    path.moveTo(
      size.width / 2 + 6.5847 * lightningSize / 23.0308,
      size.height / 2 - 23.0308 * lightningSize / 23.0308,
    );
    path.lineTo(
      size.width / 2 - 11.0841 * lightningSize / 23.0308,
      size.height / 2 + 3.8118 * lightningSize / 23.0308,
    );
    path.lineTo(
      size.width / 2 - 0.7198 * lightningSize / 23.0308,
      size.height / 2 + 3.8118 * lightningSize / 23.0308,
    );
    path.lineTo(
      size.width / 2 - 5.8193 * lightningSize / 23.0308,
      size.height / 2 + 24.3206 * lightningSize / 23.0308,
    );
    path.lineTo(
      size.width / 2 + 11.6842 * lightningSize / 23.0308,
      size.height / 2 - 2.9255 * lightningSize / 23.0308,
    );
    path.lineTo(
      size.width / 2 + 1.6576 * lightningSize / 23.0308,
      size.height / 2 - 2.9255 * lightningSize / 23.0308,
    );
    path.close();

    Paint lightningPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, lightningPaint);
  }

  @override
  bool shouldRepaint(covariant ChargePainter oldDelegate) {
    // 当颜色改变时，重新绘制
    return oldDelegate.bottomColor != bottomColor ||
        oldDelegate.topColor != topColor;
  }
}

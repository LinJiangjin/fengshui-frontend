import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 设计稿图标集（24x24，线宽 1.8，圆头圆角，与 Ardot SVG 一一对应）
enum AppIconKind {
  back,
  share,
  chevronRight,
  chevronDown,
  search,
  filter,
  heart,
  warn,
  check,
  refresh,
  target,
  location,
  edit,
  bookmark,
  compass,
  taiji,
  plan,
  report,
  spark,
  home,
  user,
}

class AppIcon extends StatelessWidget {
  const AppIcon(
    this.kind, {
    super.key,
    this.size = 24,
    this.color = const Color(0xFF1E2A25),
    this.strokeWidth = 1.8,
  });

  final AppIconKind kind;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppIconPainter(kind, color, strokeWidth),
      ),
    );
  }
}

class _AppIconPainter extends CustomPainter {
  _AppIconPainter(this.kind, this.color, this.strokeWidth);

  final AppIconKind kind;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0; // 设计稿基于 24 画布
    canvas.save();
    canvas.scale(s);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (kind) {
      case AppIconKind.back:
        canvas.drawPath(
          Path()..moveTo(15, 4.5)..lineTo(8, 12)..lineTo(15, 19.5),
          stroke,
        );
        break;

      case AppIconKind.share:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..lineTo(12, 16)
            ..moveTo(8.5, 6.5)
            ..lineTo(12, 3)
            ..lineTo(15.5, 6.5)
            ..moveTo(4.5, 15)
            ..lineTo(4.5, 18.5)
            ..arcToPoint(const Offset(6.5, 20.5),
                radius: const Radius.circular(2), clockwise: false)
            ..lineTo(17.5, 20.5)
            ..arcToPoint(const Offset(19.5, 18.5),
                radius: const Radius.circular(2), clockwise: false)
            ..lineTo(19.5, 15),
          stroke,
        );
        break;

      case AppIconKind.chevronRight:
        canvas.drawPath(
          Path()..moveTo(9.5, 5)..lineTo(16, 12)..lineTo(9.5, 19),
          stroke,
        );
        break;

      case AppIconKind.chevronDown:
        canvas.drawPath(
          Path()..moveTo(5, 9.5)..lineTo(12, 16)..lineTo(19, 9.5),
          stroke,
        );
        break;

      case AppIconKind.search:
        canvas.drawCircle(const Offset(11, 11), 7, stroke);
        canvas.drawLine(const Offset(16.5, 16.5), const Offset(20.5, 20.5), stroke);
        break;

      case AppIconKind.filter:
        canvas.drawPath(
          Path()
            ..moveTo(4, 6.5)
            ..lineTo(20, 6.5)
            ..moveTo(7, 12)
            ..lineTo(17, 12)
            ..moveTo(10, 17.5)
            ..lineTo(14, 17.5),
          stroke,
        );
        break;

      case AppIconKind.heart:
        canvas.drawPath(
          Path()
            ..moveTo(12, 20.5)
            ..cubicTo(12, 20.5, 4.5, 15.9, 4.5, 11)
            ..arcToPoint(const Offset(19.5, 11),
                radius: const Radius.circular(4.5), clockwise: false)
            ..cubicTo(19.5, 15.9, 12, 20.5, 12, 20.5),
          stroke,
        );
        break;

      case AppIconKind.warn:
        canvas.drawPath(
          Path()
            ..moveTo(12, 4)
            ..lineTo(2.8, 20)
            ..lineTo(21.2, 20)
            ..close(),
          stroke,
        );
        canvas.drawLine(const Offset(12, 9.8), const Offset(12, 14.2), stroke);
        canvas.drawPoints(
          ui.PointMode.points,
          const [Offset(12, 17.4)],
          stroke..strokeWidth = strokeWidth,
        );
        break;

      case AppIconKind.check:
        canvas.drawPath(
          Path()
            ..moveTo(4.5, 12.5)
            ..lineTo(9.5, 17.5)
            ..lineTo(19.5, 6.5),
          stroke..strokeWidth = 2,
        );
        break;

      case AppIconKind.refresh:
        canvas.drawArc(
          const Rect.fromLTWH(3.5, 3.5, 17, 17),
          -2.4,
          5.2,
          false,
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(20.5, 4.6)
            ..lineTo(20.5, 10)
            ..lineTo(15, 10),
          stroke,
        );
        break;

      case AppIconKind.target:
        canvas.drawCircle(const Offset(12, 12), 7.5, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(12, 2)
            ..lineTo(12, 5)
            ..moveTo(12, 19)
            ..lineTo(12, 22)
            ..moveTo(2, 12)
            ..lineTo(5, 12)
            ..moveTo(19, 12)
            ..lineTo(22, 12),
          stroke,
        );
        canvas.drawCircle(const Offset(12, 12), 1.6, fill);
        break;

      case AppIconKind.location:
        canvas.drawPath(
          Path()
            ..moveTo(12, 21)
            ..cubicTo(12, 21, 19, 14.6, 19, 10)
            ..arcToPoint(const Offset(5, 10),
                radius: const Radius.circular(7), clockwise: false)
            ..cubicTo(5, 14.6, 12, 21, 12, 21),
          stroke,
        );
        canvas.drawCircle(const Offset(12, 10), 2.6, stroke);
        break;

      case AppIconKind.edit:
        canvas.drawPath(
          Path()
            ..moveTo(4, 20)
            ..lineTo(8, 20)
            ..lineTo(20, 8)
            ..lineTo(16, 4)
            ..close(),
          stroke,
        );
        break;

      case AppIconKind.bookmark:
        canvas.drawPath(
          Path()
            ..moveTo(6, 3.5)
            ..lineTo(18, 3.5)
            ..lineTo(18, 21)
            ..lineTo(12, 16.6)
            ..lineTo(6, 21)
            ..close(),
          stroke,
        );
        break;

      case AppIconKind.compass:
        canvas.drawCircle(const Offset(12, 12), 9, stroke..strokeWidth = 1.6);
        canvas.drawPath(
          Path()
            ..moveTo(16.2, 7.8)
            ..lineTo(13.6, 14.2)
            ..lineTo(7.2, 16.8)
            ..lineTo(9.8, 10.4)
            ..close(),
          fill,
        );
        canvas.drawPath(
          Path()
            ..moveTo(12, 2.6)
            ..lineTo(12, 4.8)
            ..moveTo(12, 19.2)
            ..lineTo(12, 21.4)
            ..moveTo(2.6, 12)
            ..lineTo(4.8, 12)
            ..moveTo(19.2, 12)
            ..lineTo(21.4, 12),
          stroke..strokeWidth = 1.4,
        );
        break;

      case AppIconKind.taiji:
        canvas.drawCircle(const Offset(12, 12), 9, stroke..strokeWidth = 1.6);
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..arcToPoint(const Offset(12, 12),
                radius: const Radius.circular(4.5), clockwise: true)
            ..arcToPoint(const Offset(12, 21),
                radius: const Radius.circular(4.5), clockwise: false),
          stroke..strokeWidth = 1.4,
        );
        canvas.drawCircle(const Offset(12, 7.5), 1.3, fill);
        canvas.drawCircle(const Offset(12, 16.5), 1.3, Paint()..color = color);
        break;

      case AppIconKind.plan:
        final rect = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7;
        for (final o in const [
          Offset(3, 3),
          Offset(13.5, 3),
          Offset(3, 13.5),
          Offset(13.5, 13.5),
        ]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(o.dx, o.dy, 7.5, 7.5), const Radius.circular(1.6)),
            rect,
          );
        }
        break;

      case AppIconKind.report:
        canvas.drawLine(const Offset(3.5, 20.5), const Offset(20.5, 20.5), stroke..strokeWidth = 1.7);
        for (final r in const [
          Rect.fromLTWH(4.5, 11, 3.8, 7),
          Rect.fromLTWH(10.1, 5, 3.8, 13),
          Rect.fromLTWH(15.7, 14, 3.8, 4),
        ]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(1.2)),
            stroke,
          );
        }
        break;

      case AppIconKind.spark:
        canvas.drawPath(
          Path()
            ..moveTo(11, 2.5)
            ..lineTo(12.8, 7.7)
            ..lineTo(18, 9.5)
            ..lineTo(12.8, 11.3)
            ..lineTo(11, 16.5)
            ..lineTo(9.2, 11.3)
            ..lineTo(4, 9.5)
            ..lineTo(9.2, 7.7)
            ..close(),
          fill,
        );
        canvas.drawPath(
          Path()
            ..moveTo(18.5, 14.5)
            ..lineTo(19.4, 16.9)
            ..lineTo(21.8, 17.8)
            ..lineTo(19.4, 18.7)
            ..lineTo(18.5, 21.1)
            ..lineTo(17.6, 18.7)
            ..lineTo(15.2, 17.8)
            ..lineTo(17.6, 16.9)
            ..close(),
          fill,
        );
        break;

      case AppIconKind.home:
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 10.6)
            ..lineTo(12, 3.6)
            ..lineTo(20.5, 10.6)
            ..lineTo(20.5, 20)
            ..lineTo(15.3, 20)
            ..lineTo(15.3, 14)
            ..lineTo(8.7, 14)
            ..lineTo(8.7, 20)
            ..lineTo(3.5, 20)
            ..close(),
          stroke,
        );
        break;

      case AppIconKind.user:
        canvas.drawCircle(const Offset(12, 8), 4, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(4.5, 20.5)
            ..cubicTo(4.5, 16.6, 7.9, 14.3, 12, 14.3)
            ..cubicTo(16.1, 14.3, 19.5, 16.6, 19.5, 20.5),
          stroke,
        );
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AppIconPainter old) =>
      old.kind != kind || old.color != color || old.strokeWidth != strokeWidth;
}

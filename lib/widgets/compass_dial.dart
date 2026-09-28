import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/compass_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// 罗盘盘面（264 x 264，严格对应设计稿 S2 的 SVG 结构）
///
/// 盘面固定（上北下南左西右东），指针组随朝向旋转 -heading，
/// 使红色指针始终指向真实北方。
class CompassDial extends StatelessWidget {
  const CompassDial({
    super.key,
    required this.heading,
    this.size = 264,
  });

  final double heading;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CompassDialPainter(heading: heading),
      ),
    );
  }
}

/// 八卦标注：文字 / 左上 x / 左上 y / 字号 / 是否四正卦 / 颜色
const List<_Gua> _guas = [
  _Gua('坎', 121, 22, 13, true, AppColors.ink),
  _Gua('艮', 194, 46, 11, false, AppColors.muted),
  _Gua('震', 228, 124, 13, true, AppColors.ink),
  _Gua('巽', 196, 202, 11, false, AppColors.muted),
  _Gua('离', 121, 226, 13, true, AppColors.danger),
  _Gua('坤', 46, 202, 11, false, AppColors.muted),
  _Gua('兑', 14, 124, 13, true, AppColors.ink),
  _Gua('乾', 44, 46, 11, false, AppColors.muted),
];

class _Gua {
  const _Gua(this.text, this.x, this.y, this.fontSize, this.bold, this.color);
  final String text;
  final double x;
  final double y;
  final double fontSize;
  final bool bold;
  final Color color;
}

class _CompassDialPainter extends CustomPainter {
  _CompassDialPainter({required this.heading});

  final double heading;

  @override
  void paint(Canvas canvas, Size size) {
    const c = Offset(132, 132);

    // 底盘
    canvas.drawCircle(
      c,
      120,
      Paint()..color = const Color(0xFFFCFAF5),
    );
    canvas.drawCircle(
      c,
      120,
      Paint()
        ..color = const Color(0xFFE4DCCB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 金色八卦刻度（8 段）
    _dashedRing(canvas, c, 112, 18, 8, 3, const Color(0xF2BE9351));
    // 墨色二十四山刻度（24 段）
    _dashedRing(canvas, c, 96, 13, 24, 1.5, const Color(0x521E2A25));

    final thin = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, 76, thin);
    canvas.drawCircle(c, 44, thin);

    // 十字虚线
    _dashLine(canvas, const Offset(132, 16), const Offset(132, 248), thin);
    _dashLine(canvas, const Offset(16, 132), const Offset(248, 132), thin);

    // 指针（随朝向旋转）
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(Angle.toRadian(-Angle.normalize(heading)));
    canvas.translate(-c.dx, -c.dy);
    canvas.drawPath(
      Path()
        ..moveTo(132, 44)
        ..lineTo(142, 132)
        ..lineTo(122, 132)
        ..close(),
      Paint()..color = AppColors.danger,
    );
    canvas.drawPath(
      Path()
        ..moveTo(132, 220)
        ..lineTo(122, 132)
        ..lineTo(142, 132)
        ..close(),
      Paint()..color = const Color(0x471E2A25),
    );
    canvas.restore();

    // 中心
    canvas.drawCircle(c, 7, Paint()..color = Colors.white);
    canvas.drawCircle(
      c,
      7,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 八卦文字（固定不旋转）
    for (final g in _guas) {
      final tp = TextPainter(
        text: TextSpan(
          text: g.text,
          style: TextStyle(
            fontFamily: AppFont.serif,
            fontSize: g.fontSize,
            fontWeight: g.bold ? FontWeight.w600 : FontWeight.w500,
            color: g.color,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(g.x, g.y));
    }
  }

  void _dashedRing(
    Canvas canvas,
    Offset c,
    double r,
    double width,
    int count,
    double dashLen,
    Color color,
  ) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final circumference = 2 * math.pi * r;
    final sweep = (dashLen / circumference) * 2 * math.pi;
    for (int i = 0; i < count; i++) {
      final start = -math.pi / 2 + i * (2 * math.pi / count);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, sweep, false, p);
    }
  }

  void _dashLine(Canvas canvas, Offset a, Offset b, Paint p) {
    const dash = 4.0;
    const gap = 6.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    double d = 0;
    while (d < total) {
      final len = (d + dash) > total ? total - d : dash;
      canvas.drawLine(a + dir * d, a + dir * (d + len), p);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter old) =>
      old.heading != heading;
}

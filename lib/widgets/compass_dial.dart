import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/orientation_calc.dart';
import '../services/compass_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// 罗盘盘面（280 x 280）
///
/// 盘面固定：上北下南，子山居中 0°，二十四山每山 15° 顺时针排布
/// （顺序与后端 `engine/compass.py` 的 MOUNTAINS 一致）。
/// 指针随实测坐向旋转 +heading：红针指坐山、白针指向山；
/// 当前坐山所在的 15° 扇区淡金高亮，与下方「二十四山」读数互为印证。
class CompassDial extends StatelessWidget {
  const CompassDial({
    super.key,
    required this.heading,
    this.size = 280,
  });

  /// 真北方位角（坐向读数）：红针指向盘面对应刻度
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

// ---- 盘面半径（画布 280，中心 140,140）----
const double _rBezel = 136; // 外框（墨绿）
const double _rRingOut = 133; // 外金环
const double _rRingIn = 126; // 山带外缘
const double _rMountTop = 120; // 二十四山字顶（字身朝内）
const double _rField = 107; // 天池（内盘）外缘
const double _rTrigram = 96; // 八卦字顶
const double _rHair1 = 70; // 天池发丝线
const double _rHair2 = 52;
const double _needleLen = 96; // 指针半长

// 盘面专用色（仿罗盘实物：墨绿底 + 鎏金刻字 + 朱砂针）
const Color _cream = Color(0xFFF1E9D8);
const Color _creamDim = Color(0xB3F1E9D8);
const Color _coral = Color(0xFFE59C86); // 离卦（南）点朱
const Color _goldChar = Color(0xFFC9AE7C); // 二十四山 · 天干地支
const Color _goldCharStrong = Color(0xFFE2CB98); // 二十四山 · 乾坤艮巽
const Color _goldLuoshu = Color(0x66D8BC85); // 洛书暗字

/// 八卦标注：卦名 / 盘面角（顺时针，北为 0）/ 字号 / 颜色 / 是否四正卦
const List<_Gua> _guas = [
  _Gua('坎', 0, 17, _cream, true),
  _Gua('艮', 45, 13.5, _creamDim, false),
  _Gua('震', 90, 17, _cream, true),
  _Gua('巽', 135, 13.5, _creamDim, false),
  _Gua('离', 180, 17, _coral, true),
  _Gua('坤', 225, 13.5, _creamDim, false),
  _Gua('兑', 270, 17, _cream, true),
  _Gua('乾', 315, 13.5, _creamDim, false),
];

class _Gua {
  const _Gua(this.text, this.angle, this.fontSize, this.color, this.bold);
  final String text;
  final double angle;
  final double fontSize;
  final Color color;
  final bool bold;
}

/// 盘面静态文字缓存：字符不随帧变化，TextPainter 只需排版一次
final Map<String, TextPainter> _glyphCache = {};

TextPainter _glyph(String key, String text, double fontSize, Color color,
    FontWeight weight) {
  return _glyphCache.putIfAbsent(
    key,
    () => TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFont.serif,
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(),
  );
}

class _CompassDialPainter extends CustomPainter {
  _CompassDialPainter({required this.heading});

  final double heading;

  @override
  void paint(Canvas canvas, Size size) {
    const c = Offset(140, 140);
    final h = Angle.normalize(heading);

    _shadow(canvas, c);
    _bezel(canvas, c);
    _mountBand(canvas, c, h);
    _field(canvas, c);
    _sheen(canvas, c);
    _needle(canvas, c, h);
  }

  /// 盘底投影（让罗盘从卡片上"浮"起来）
  void _shadow(Canvas canvas, Offset c) {
    canvas.drawCircle(
      c + const Offset(0, 8),
      126,
      Paint()
        ..color = const Color(0x2929170F)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  /// 外框：墨绿径向渐变 + 双金环
  void _bezel(Canvas canvas, Offset c) {
    canvas.drawCircle(
      c,
      _rBezel,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.32, -0.5),
          radius: 1.05,
          colors: [Color(0xFF3B6559), Color(0xFF15302A)],
        ).createShader(Rect.fromCircle(center: c, radius: _rBezel)),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(c, _rRingOut, ring..color = const Color(0xD8BE9351));
    canvas.drawCircle(c, _rRingIn, ring..color = const Color(0x66BE9351));
  }

  /// 山带：当前坐山扇区高亮 + 山界刻度 + 八卦方位金点 + 二十四山字
  void _mountBand(Canvas canvas, Offset c, double h) {
    // 当前坐山 15° 扇区高亮
    final idx =
        OrientationCalc.mountains.indexOf(OrientationCalc.mountainOf(h));
    if (idx >= 0) {
      final m = idx * 15.0;
      final band = Path()
        ..moveTo(_polar(c, _rField, m - 7.5).dx,
            _polar(c, _rField, m - 7.5).dy)
        ..arcTo(Rect.fromCircle(center: c, radius: _rRingIn),
            Angle.toRadian(m - 97.5), Angle.toRadian(15), false)
        ..lineTo(_polar(c, _rField, m + 7.5).dx,
            _polar(c, _rField, m + 7.5).dy)
        ..arcTo(Rect.fromCircle(center: c, radius: _rField),
            Angle.toRadian(m - 82.5), Angle.toRadian(-15), false)
        ..close();
      canvas.drawPath(band, Paint()..color = const Color(0x1FE8C97E));
      final edge = Paint()
        ..color = const Color(0x8CBE9351)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawLine(
          _polar(c, _rField, m - 7.5), _polar(c, _rRingIn, m - 7.5), edge);
      canvas.drawLine(
          _polar(c, _rField, m + 7.5), _polar(c, _rRingIn, m + 7.5), edge);
    }

    // 山界刻度（每 15°）
    final tick = Paint()
      ..color = const Color(0x59BE9351)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 24; i++) {
      final d = 7.5 + i * 15.0;
      canvas.drawLine(_polar(c, _rRingIn, d), _polar(c, 121, d), tick);
    }

    // 八卦方位金点（每 45°，嵌在外金环上）
    final bead = Paint()..color = const Color(0xA6BE9351);
    for (int i = 0; i < 8; i++) {
      canvas.drawCircle(_polar(c, 123.5, i * 45.0), 1.6, bead);
    }

    // 二十四山字：天干地支 / 乾坤艮巽，字顶朝外
    for (int i = 0; i < 24; i++) {
      final ch = OrientationCalc.mountains[i];
      final isGua = ch == '乾' || ch == '坤' || ch == '艮' || ch == '巽';
      final tp = _glyph(
        'm$ch',
        ch,
        10.5,
        isGua ? _goldCharStrong : _goldChar,
        isGua ? FontWeight.w600 : FontWeight.w500,
      );
      _paintRadial(canvas, _polar(c, _rMountTop, i * 15.0), i * 15.0, tp);
    }
  }

  /// 天池：内盘 + 发丝线 + 四正向金点 + 洛书暗字 + 八卦
  void _field(Canvas canvas, Offset c) {
    canvas.drawCircle(
      c,
      _rField,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.45),
          radius: 1.0,
          colors: [Color(0xFF234A40), Color(0xFF152F29)],
        ).createShader(Rect.fromCircle(center: c, radius: _rField)),
    );
    final hair = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, _rField, hair..color = const Color(0x59BE9351));
    canvas.drawCircle(c, _rHair1, hair..color = const Color(0x33BE9351));
    canvas.drawCircle(c, _rHair2, hair..color = const Color(0x26BE9351));

    // 四正向金点
    final dot = Paint()..color = const Color(0x8CBE9351);
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(_polar(c, 64, i * 90.0), 1.4, dot);
    }

    // 洛书九宫暗字（纯装饰，中心 5 被天心钮遮住）
    const luoshu = [
      [4, 9, 2],
      [3, 5, 7],
      [8, 1, 6],
    ];
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final n = luoshu[row][col];
        final tp = _glyph('ls$n', '$n', 8.5, _goldLuoshu, FontWeight.w500);
        tp.paint(
          canvas,
          c +
              Offset(-30 + col * 30.0 - tp.width / 2,
                  -30 + row * 30.0 - tp.height / 2),
        );
      }
    }

    // 八卦：四正大、四维小，字顶朝外
    for (final g in _guas) {
      final tp = _glyph(
        'g${g.text}',
        g.text,
        g.fontSize,
        g.color,
        g.bold ? FontWeight.w600 : FontWeight.w500,
      );
      _paintRadial(canvas, _polar(c, _rTrigram, g.angle), g.angle, tp);
    }
  }

  /// 玻璃反光（左上角一道浅弧）
  void _sheen(Canvas canvas, Offset c) {
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: 124),
      Angle.toRadian(195),
      Angle.toRadian(55),
      false,
      Paint()
        ..color = const Color(0x0AFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
  }

  /// 指针：红针指坐山、白针指向山，针身带坐 / 向小字，旋转 +heading
  void _needle(Canvas canvas, Offset c, double h) {
    final red = Path()
      ..moveTo(0, -_needleLen)
      ..lineTo(7.5, -14)
      ..lineTo(4.5, 8)
      ..lineTo(-4.5, 8)
      ..lineTo(-7.5, -14)
      ..close();
    final ivory = Path()
      ..moveTo(0, _needleLen)
      ..lineTo(7.5, 14)
      ..lineTo(4.5, -8)
      ..lineTo(-4.5, -8)
      ..lineTo(-7.5, 14)
      ..close();

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(Angle.toRadian(h));

    // 投影
    final shadow = Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.save();
    canvas.translate(0, 2.5);
    canvas.drawPath(red, shadow);
    canvas.drawPath(ivory, shadow);
    canvas.restore();

    // 针体（朱砂 + 象牙，描边勾形）
    canvas.drawPath(red, Paint()..color = AppColors.danger);
    canvas.drawPath(
      red,
      Paint()
        ..color = const Color(0xFF96351F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawPath(ivory, Paint()..color = const Color(0xFFF4EEE1));
    canvas.drawPath(
      ivory,
      Paint()
        ..color = const Color(0xFF9A8B6B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 坐 / 向 小字（随针旋转）
    final tpSit = _glyph('sit', '坐', 9.5, _cream, FontWeight.w600);
    final tpFace = _glyph('face', '向', 9.5, _creamDim, FontWeight.w600);
    tpSit.paint(canvas, Offset(-tpSit.width / 2, -105.75));
    tpFace.paint(canvas, Offset(-tpFace.width / 2, 96.25));

    // 天心钮（黄铜）
    canvas.drawCircle(Offset.zero, 11, Paint()..color = AppColors.gold);
    canvas.drawCircle(
      Offset.zero,
      11,
      Paint()
        ..color = AppColors.goldDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(Offset.zero, 7, Paint()..color = const Color(0xFFFCFAF5));
    canvas.drawCircle(Offset.zero, 2.5, Paint()..color = AppColors.ink);
    canvas.restore();
  }

  /// 盘面角（顺时针，北为 0）-> 画布坐标
  Offset _polar(Offset c, double r, double dialDeg) {
    final a = Angle.toRadian(dialDeg);
    return Offset(c.dx + r * math.sin(a), c.dy - r * math.cos(a));
  }

  /// 径向文字：字顶朝外、字身朝内，绕 pivot 旋转 dialDeg
  void _paintRadial(
      Canvas canvas, Offset pivot, double dialDeg, TextPainter tp) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(Angle.toRadian(dialDeg));
    tp.paint(canvas, Offset(-tp.width / 2, 0));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter old) =>
      old.heading != heading;
}

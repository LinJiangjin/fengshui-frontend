import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/house.dart';
import '../models/library.dart';
import '../models/palace_grid.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// 空间示意：把方案的分区配色铺到房屋的九宫宫位上。
///
/// 两种视角：
/// - [SpaceViewMode.plan] 平面图：3×3 宫位 + 隔墙，房间按方案配色填色
/// - [SpaceViewMode.solid] 等轴测立体图：同一批房间块拉出墙体，看空间关系
///
/// **数据边界**：方案库只给「房间 + 配色 + 一句话」，没有尺寸与门窗；
/// 因此几何一律取自房屋档案的房间宫位，不凭空造户型。房间在宫位里怎么分
/// 也是用户自己录的（`RoomProfile.cell`），这里只负责上色与排布。
enum SpaceViewMode { plan, solid }

class SchemeSpaceView extends StatelessWidget {
  const SchemeSpaceView({
    super.key,
    required this.house,
    required this.scheme,
    this.mode = SpaceViewMode.plan,
  });

  final HouseProfile house;
  final LibraryScheme scheme;
  final SpaceViewMode mode;

  @override
  Widget build(BuildContext context) {
    final cells = _buildCells(house, scheme);
    final bearing = facingBearing(house.orientation?.facingDirection);
    return AspectRatio(
      aspectRatio: mode == SpaceViewMode.plan ? 1.0 : 1.28,
      child: CustomPaint(
        painter: mode == SpaceViewMode.plan
            ? _PlanPainter(cells: cells, facingBearing: bearing)
            : _SolidPainter(cells: cells),
      ),
    );
  }
}

/// 向方方位 -> 罗盘角度（度）。平面图按「向方朝上」摆放，北向箭头据此旋转。
double facingBearing(String? direction) {
  const map = {
    '正北': 0.0,
    '东北': 45.0,
    '正东': 90.0,
    '东南': 135.0,
    '正南': 180.0,
    '西南': 225.0,
    '正西': 270.0,
    '西北': 315.0,
  };
  return map[direction] ?? 0.0;
}

/// 房间 -> 方案配色。
///
/// 顺序：同名分区 -> 房型关键词（卧 / 客 / 餐 / 厨 / 卫 / 浴 / 书 / 玄）
/// -> 房间名包含分区名 -> 方案主色。方案没单列这个房型时沿用主色，
/// 不另造一个「配色」出来。
Color schemeRoomColor(LibraryScheme scheme, String roomName) {
  final fallback =
      scheme.colors.isNotEmpty ? scheme.colors.first.color : const Color(0xFFE4DCCB);
  if (scheme.rooms.isEmpty) return fallback;

  for (final r in scheme.rooms) {
    if (r.name == roomName) return r.color;
  }
  for (final key in const ['卧', '客', '餐', '厨', '卫', '浴', '书', '玄']) {
    if (!roomName.contains(key)) continue;
    for (final r in scheme.rooms) {
      if (r.name.contains(key)) return r.color;
    }
  }
  for (final r in scheme.rooms) {
    if (roomName.contains(r.name)) return r.color;
  }
  return fallback;
}

class _Band {
  const _Band(this.name, this.color);
  final String name;
  final Color color;
}

class _DirCell {
  const _DirCell(this.direction, this.bands);
  final String direction;
  final List<_Band> bands;
}

/// 生成 9 个显示格：位置按「向方朝上」旋转，房间按固定宫位索引归位。
List<_DirCell> _buildCells(HouseProfile house, LibraryScheme scheme) {
  final facing = house.orientation?.facingDirection ?? '';
  final order = PalaceGrid.orderOf(facing.isEmpty ? null : facing);
  return List.generate(9, (pos) {
    final dir = order[pos];
    final fixedIdx = PalaceGrid.fixedOrder.indexOf(dir);
    final rooms = fixedIdx < 0
        ? const <RoomProfile>[]
        : house.rooms.where((r) => r.cell == fixedIdx).toList();
    return _DirCell(
      dir,
      rooms.map((r) => _Band(r.name, schemeRoomColor(scheme, r.name))).toList(),
    );
  });
}

// ------------------------------------------------------------------ 公共色
const Color _wallInk = Color(0xFF38453F);
const Color _cellBg = Color(0xFFF2F5F0);
const Color _paper = Color(0xFFFBFCF9);
const Color _wallFill = Color(0xFFF2F5EF);
const Color _wallSide = Color(0xFFE2E8DD);
const Color _slab = Color(0xFFC4CBBE);

/// 色块上的文字颜色：深底用白字，浅底用墨字
Color _onColor(Color c) {
  final l = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
  return l > 0.66 ? AppColors.inkSoft : Colors.white;
}

TextPainter _tp(String text, TextStyle style, {double maxWidth = 999}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  return tp;
}

// ------------------------------------------------------------------ 平面图
class _PlanPainter extends CustomPainter {
  _PlanPainter({required this.cells, required this.facingBearing});

  final List<_DirCell> cells;
  final double facingBearing;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 外墙 + 纸底
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, w - 2, h - 2),
      const Radius.circular(14),
    );
    canvas.drawRRect(outer, Paint()..color = _paper);
    canvas.drawRRect(
      outer,
      Paint()
        ..color = _wallInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final inner = Rect.fromLTWH(7, 7, w - 14, h - 14);
    final cw = inner.width / 3;
    final ch = inner.height / 3;

    for (var pos = 0; pos < 9; pos++) {
      final cell = cells[pos];
      final rect = Rect.fromLTWH(
        inner.left + (pos % 3) * cw,
        inner.top + (pos ~/ 3) * ch,
        cw,
        ch,
      );
      canvas.drawRect(rect, Paint()..color = _cellBg);

      if (cell.bands.isEmpty) {
        final tp = _tp(
          cell.direction,
          TextStyle(
            fontFamily: AppFont.sans,
            fontSize: 11,
            color: AppColors.muted.withValues(alpha: 0.75),
          ),
        );
        tp.paint(
          canvas,
          Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
        );
      } else {
        final bh = rect.height / cell.bands.length;
        for (var i = 0; i < cell.bands.length; i++) {
          final band = cell.bands[i];
          final br = Rect.fromLTWH(rect.left, rect.top + i * bh, rect.width, bh);
          canvas.drawRect(br, Paint()..color = band.color);
          final tp = _tp(
            band.name,
            TextStyle(
              fontFamily: AppFont.sans,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _onColor(band.color),
            ),
            maxWidth: rect.width - 12,
          );
          tp.paint(
            canvas,
            Offset(br.center.dx - tp.width / 2, br.center.dy - tp.height / 2),
          );
          if (i > 0) {
            canvas.drawLine(
              br.topLeft,
              br.topRight,
              Paint()
                ..color = _wallInk.withValues(alpha: 0.18)
                ..strokeWidth = 1,
            );
          }
        }
      }

      // 宫位名（左下角小字）
      final dirTp = _tp(
        cell.direction,
        TextStyle(
          fontFamily: AppFont.sans,
          fontSize: 9,
          color: _onColor(cell.bands.isEmpty ? _cellBg : cell.bands.last.color)
              .withValues(alpha: 0.42),
        ),
      );
      dirTp.paint(canvas, Offset(rect.left + 5, rect.bottom - dirTp.height - 4));
    }

    // 隔墙
    final wall = Paint()
      ..color = _wallInk.withValues(alpha: 0.55)
      ..strokeWidth = 1.6;
    canvas.drawLine(
        Offset(inner.left + cw, inner.top),
        Offset(inner.left + cw, inner.bottom),
        wall);
    canvas.drawLine(Offset(inner.left + cw * 2, inner.top),
        Offset(inner.left + cw * 2, inner.bottom), wall);
    canvas.drawLine(Offset(inner.left, inner.top + ch),
        Offset(inner.right, inner.top + ch), wall);
    canvas.drawLine(Offset(inner.left, inner.top + ch * 2),
        Offset(inner.right, inner.top + ch * 2), wall);

    // 指北针（平面按向方朝上，北向随之旋转）
    _paintCompass(canvas, const Offset(28, 28));

    // 网格外框，压住墙面线头
    canvas.drawRect(
      inner,
      Paint()
        ..color = _wallInk.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  void _paintCompass(Canvas canvas, Offset c) {
    canvas.drawCircle(c, 17, Paint()..color = Colors.white.withValues(alpha: 0.92));
    canvas.drawCircle(
      c,
      17,
      Paint()
        ..color = AppColors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-facingBearing * math.pi / 180);
    // 箭头
    canvas.drawPath(
      Path()
        ..moveTo(0, -8)
        ..lineTo(4.6, 3)
        ..lineTo(0, 0.6)
        ..lineTo(-4.6, 3)
        ..close(),
      Paint()..color = AppColors.primary,
    );
    canvas.restore();
    final tp = _tp(
      'N',
      const TextStyle(
        fontFamily: AppFont.number,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy + 3));
  }

  @override
  bool shouldRepaint(covariant _PlanPainter old) =>
      old.cells != cells || old.facingBearing != facingBearing;
}

// ------------------------------------------------------------ 等轴测立体图
class _SolidPainter extends CustomPainter {
  _SolidPainter({required this.cells});

  final List<_DirCell> cells;

  /// 墙高（以格为单位的倍数）
  static const double _wallH = 0.95;

  @override
  void paint(Canvas canvas, Size size) {
    final s = (size.width - 26) / 5.196; // 3 格 × 2 × cos30°
    final cx = size.width / 2;
    final cy = _wallH * s + 1.5 * s + 8;

    Offset pt(double x, double y, [double z = 0]) {
      final dx = (x - 1.5) - (y - 1.5);
      final dy = (x - 1.5) + (y - 1.5);
      return Offset(cx + dx * 0.866 * s, cy + dy * 0.5 * s - z * s);
    }

    final corners = [
      pt(0, 0),
      pt(3, 0),
      pt(3, 3),
      pt(0, 3),
    ];

    // 地盘投影
    canvas.drawPath(
      (Path()..addPolygon(corners, true)).shift(const Offset(0, 10)),
      Paint()
        ..color = const Color(0x22000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 近端板厚
    canvas.drawPath(
      Path()
        ..addPolygon([
          pt(3, 0, 0),
          pt(3, 3, 0),
          pt(3, 3, -0.07),
          pt(3, 0, -0.07),
        ], true),
      Paint()..color = _slab,
    );
    canvas.drawPath(
      Path()
        ..addPolygon([
          pt(0, 3, 0),
          pt(3, 3, 0),
          pt(3, 3, -0.07),
          pt(0, 3, -0.07),
        ], true),
      Paint()..color = _slab,
    );

    // 远端两面墙（x = 0 / y = 0），从前往后看是里墙
    void wall(List<Offset> quad, Color color) {
      canvas.drawPath(
        Path()..addPolygon(quad, true),
        Paint()..color = color,
      );
      canvas.drawPath(
        Path()..addPolygon(quad, true),
        Paint()
          ..color = _wallInk.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    wall([
      pt(0, 0, 0),
      pt(0, 3, 0),
      pt(0, 3, _wallH),
      pt(0, 0, _wallH),
    ], _wallSide);
    wall([
      pt(0, 0, 0),
      pt(3, 0, 0),
      pt(3, 0, _wallH),
      pt(0, 0, _wallH),
    ], _wallFill);

    // 墙顶亮边，让墙体有厚度
    final topEdge = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawLine(pt(0, 3, _wallH), pt(0, 0, _wallH), topEdge);
    canvas.drawLine(pt(0, 0, _wallH), pt(3, 0, _wallH), topEdge);

    // 地板（按远近排序：r+c 小的先画）
    final order = List.generate(9, (i) => i)
      ..sort((a, b) => (a ~/ 3 + a % 3).compareTo(b ~/ 3 + b % 3));

    for (final pos in order) {
      final cell = cells[pos];
      final r = pos ~/ 3;
      final c = pos % 3;
      final bands = cell.bands;
      if (bands.isEmpty) {
        canvas.drawPath(
          Path()..addPolygon([
            pt(c.toDouble(), r.toDouble()),
            pt(c + 1.0, r.toDouble()),
            pt(c + 1.0, r + 1.0),
            pt(c.toDouble(), r + 1.0),
          ], true),
          Paint()..color = _cellBg,
        );
        continue;
      }
      final n = bands.length;
      for (var i = 0; i < n; i++) {
        final y0 = r + i / n;
        final y1 = r + (i + 1) / n;
        final quad = [
          pt(c.toDouble(), y0),
          pt(c + 1.0, y0),
          pt(c + 1.0, y1),
          pt(c.toDouble(), y1),
        ];
        canvas.drawPath(
          Path()..addPolygon(quad, true),
          Paint()..color = bands[i].color,
        );
      }
    }

    // 隔墙线 + 房间名
    final line = Paint()
      ..color = _wallInk.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(pt(i.toDouble(), 0), pt(i.toDouble(), 3), line);
      canvas.drawLine(pt(0, i.toDouble()), pt(3, i.toDouble()), line);
    }
    // 外沿
    canvas.drawPath(
      Path()..addPolygon(corners, true),
      Paint()
        ..color = _wallInk.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    for (var pos = 0; pos < 9; pos++) {
      final cell = cells[pos];
      if (cell.bands.isEmpty) continue;
      final r = pos ~/ 3;
      final c = pos % 3;
      final n = cell.bands.length;
      for (var i = 0; i < n; i++) {
        final yc = r + (i + 0.5) / n;
        final center = pt(c + 0.5, yc);
        final tp = _tp(
          cell.bands[i].name,
          TextStyle(
            fontFamily: AppFont.sans,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: _onColor(cell.bands[i].color),
          ),
          maxWidth: 74,
        );
        tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SolidPainter old) => old.cells != cells;
}

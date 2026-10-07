import 'diagnosis.dart';

/// 九宫格排布：3×3 网格，索引 0..8 按行优先（左上 -> 右下）。
///
/// 基础方位图为传统风水画法：**上南下北、左东右西**
/// ```
/// 0 东南  1 正南  2 西南
/// 3 正东  4 中宫  5 正西
/// 6 东北  7 正北  8 西北
/// ```
///
/// 开启「按坐向」后，房屋的**向方**会转到顶部中间（索引 1），
/// 其余方位整体旋转，宫位星曜不变，只是视角换成「站在宅内向外看」。
class PalaceGrid {
  const PalaceGrid._();

  /// 方位 -> 罗盘角度档位（自正北起，顺时针每 45° 一档）
  static const Map<String, int> _dirIndex = {
    '正北': 0,
    '东北': 1,
    '正东': 2,
    '东南': 3,
    '正南': 4,
    '西南': 5,
    '正西': 6,
    '西北': 7,
  };

  /// 外圈八宫在网格中的位置：自「正南（上中）」起顺时针每 45° 一档
  static const List<int> _ringPositions = [1, 2, 5, 8, 7, 6, 3, 0];

  /// 固定方位排布（上南下北）
  static const List<String> fixedOrder = [
    '东南', '正南', '西南',
    '正东', '中宫', '正西',
    '东北', '正北', '西北',
  ];

  /// 按向方旋转后的方位排布；[facing] 为空或无法识别时退回固定排布。
  static List<String> orderOf(String? facing) {
    final f = _dirIndex[facing];
    if (f == null) return fixedOrder;
    final cells = List<String?>.filled(9, null);
    cells[4] = '中宫';
    for (final entry in _dirIndex.entries) {
      final step = (entry.value - f) % 8;
      cells[_ringPositions[step]] = entry.key;
    }
    return cells.map((e) => e ?? '').toList();
  }

  /// 生成 3×3 宫位列表（索引即网格位置）。缺失的方位补 null。
  static List<Palace?> build(
    List<Palace> palaces, {
    String? facing,
    bool rotate = true,
  }) {
    final map = {for (final p in palaces) p.direction: p};
    final order = rotate ? orderOf(facing) : fixedOrder;
    return order.map((k) => map[k]).toList();
  }

  /// 归一化坐标 (0..1) -> 网格位置 0..8，用于把户型图上的房间映射到宫位。
  static int indexAt(double u, double v) {
    final col = (u * 3).floor().clamp(0, 2);
    final row = (v * 3).floor().clamp(0, 2);
    return row * 3 + col;
  }
}

import '../services/compass_service.dart';

/// 二十四山定向：把真北度数换算成坐山 / 向山 / 宅卦。
///
/// 规则与后端 `server/app/engine/compass.py` + `constants.py` 完全一致，
/// 供罗盘页在本地实时换算（无需每次转动都请求后端）。
class OrientationCalc {
  OrientationCalc._();

  /// 以子山居中 0 度，每山 15 度，顺时针排列
  static const List<String> mountains = [
    '子', '癸', '丑', '艮', '寅', '甲', '卯', '乙',
    '辰', '巽', '巳', '丙', '午', '丁', '未', '坤',
    '申', '庚', '酉', '辛', '戌', '乾', '亥', '壬',
  ];

  /// 二十四山 -> 八卦宫
  static const Map<String, String> trigramByMountain = {
    '壬': '坎', '子': '坎', '癸': '坎',
    '丑': '艮', '艮': '艮', '寅': '艮',
    '甲': '震', '卯': '震', '乙': '震',
    '辰': '巽', '巽': '巽', '巳': '巽',
    '丙': '离', '午': '离', '丁': '离',
    '未': '坤', '坤': '坤', '申': '坤',
    '庚': '兑', '酉': '兑', '辛': '兑',
    '戌': '乾', '乾': '乾', '亥': '乾',
  };

  /// 八卦宫 -> 方位名
  static const Map<String, String> trigramDirection = {
    '坎': '正北', '坤': '西南', '震': '正东', '巽': '东南',
    '乾': '西北', '兑': '正西', '艮': '东北', '离': '正南',
  };

  static const double mountainSpan = 15.0;

  /// 度数 -> 山名。子山居中 0 度，每山 15 度。
  static String mountainOf(double trueNorth) {
    final i = (Angle.normalize(trueNorth) / mountainSpan).round() % 24;
    return mountains[i];
  }

  /// 对冲之山（相隔 12 位 = 180 度）
  static String oppositeOf(String mountain) {
    final i = mountains.indexOf(mountain);
    return mountains[(i + 12) % 24];
  }

  /// 当前度数偏离所在山中心线的角度（度）
  static double offsetOf(double trueNorth) {
    final d = Angle.normalize(trueNorth);
    final center = ((d / mountainSpan).round() % 24) * mountainSpan;
    var diff = d - center;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  /// 真北度数 -> 坐向信息
  static OrientationResult of(double trueNorth) {
    final sitting = mountainOf(trueNorth);
    final facing = oppositeOf(sitting);
    final trigram = trigramByMountain[sitting] ?? '坎';
    final direction = trigramDirection[trigram] ?? '正北';
    final facingTrigram = trigramByMountain[facing] ?? '离';
    final facingDirection = trigramDirection[facingTrigram] ?? '正南';
    return OrientationResult(
      degree: Angle.normalize(trueNorth),
      mountain: sitting,
      facing: facing,
      title: '$sitting山$facing向',
      trigram: trigram,
      direction: direction,
      facingDirection: facingDirection,
      houseType: '$trigram宅',
      // 例：坐北朝南
      readable: '坐${direction.substring(1)}朝${facingDirection.substring(1)}',
    );
  }
}

class OrientationResult {
  const OrientationResult({
    required this.degree,
    required this.mountain,
    required this.facing,
    required this.title,
    required this.trigram,
    required this.direction,
    required this.facingDirection,
    required this.houseType,
    required this.readable,
  });

  final double degree;
  final String mountain;
  final String facing;
  final String title; // 子山午向
  final String trigram; // 坎
  final String direction; // 正北
  final String facingDirection; // 正南
  final String houseType; // 坎宅
  final String readable; // 坐北朝南

  /// 例：子山午向 · 坐北朝南
  String get summary => '$title · $readable';
}

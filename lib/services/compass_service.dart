import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// 罗盘数据源抽象。
///
/// 真机走 DeviceCompassService；无磁力计 / 传感器无数据的环境
/// （桌面、模拟器、未授权的 Web）用 DemoCompassService 匀速扫描兜底，
/// 保证坐向文案随度数实时变化；用户手动输入时走 ManualCompassService。
abstract class CompassService {
  Stream<double> get heading;
  bool get available;
}

/// 真机罗盘（磁力计 + 陀螺仪融合）
class DeviceCompassService implements CompassService {
  DeviceCompassService([Stream<CompassEvent>? events])
      : _events = events ?? FlutterCompass.events;

  final Stream<CompassEvent>? _events;

  @override
  Stream<double> get heading {
    final events = _events;
    if (events == null) return const Stream<double>.empty();
    return events.map((e) => Angle.normalize(e.heading ?? 0.0));
  }

  /// 传感器流可能为 null（Web / 桌面未授权），此时不可用
  @override
  bool get available => _events != null;
}

/// 手动罗盘：持续输出用户指定的角度，界面与交互完全一致。
/// 角度必须由调用方给出，不再默认成某个写死的度数。
class ManualCompassService implements CompassService {
  ManualCompassService({required this.fixedDegree});

  final double fixedDegree;

  @override
  Stream<double> get heading =>
      Stream<double>.periodic(const Duration(milliseconds: 120), (_) => fixedDegree);

  @override
  bool get available => false;
}

/// 演示罗盘：仅用于调试阶段验证「度数 -> 二十四山 -> 坐X朝X」链路。
///
/// 它输出的是自动扫描的假读数，**不是测量结果**，
/// 正式包（release）不会使用它，避免把演示读数当成真实坐向保存。
class DemoCompassService implements CompassService {
  DemoCompassService({
    this.start = 0.0,
    this.step = 1.5,
    this.period = const Duration(milliseconds: 200),
  });

  final double start;
  final double step;
  final Duration period;

  @override
  Stream<double> get heading =>
      Stream<double>.periodic(period, (i) => Angle.normalize(start + (i + 1) * step));

  @override
  bool get available => false;
}

/// 无可用传感器：不产生任何读数，由界面引导用户手动输入坐向，
/// 而不是自动编一个数出来。
class UnavailableCompassService implements CompassService {
  @override
  Stream<double> get heading => const Stream<double>.empty();

  @override
  bool get available => false;
}

/// 自动选择数据源：拿不到传感器流时，调试包退回演示罗盘，正式包直接标记不可用
class CompassServiceFactory {
  static CompassService create() {
    try {
      final service = DeviceCompassService();
      if (service.available) return service;
    } catch (_) {
      // 插件在该平台未实现时直接忽略
    }
    if (kDebugMode) return DemoCompassService();
    return UnavailableCompassService();
  }
}

/// 角度工具
class Angle {
  Angle._();

  static double normalize(double d) => ((d % 360) + 360) % 360;

  /// 两角之间的最短差值（-180, 180]
  static double delta(double a, double b) {
    var d = normalize(a - b);
    if (d > 180) d -= 360;
    return d;
  }

  static double toRadian(double d) => d * math.pi / 180.0;
}

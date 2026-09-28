import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 设计稿尺寸常量（Ardot 画布 390 x 844）
class AppDimens {
  const AppDimens._();

  static const screenW = 390.0;
  static const screenH = 844.0;

  static const contentH = 782.0;
  static const pagePadH = 20.0;

  static const tabBarH = 88.0;
  static const tabBarTop = 756.0;
  static const bottomBarH = 88.0;

  static const rXL = 24.0; // 大卡
  static const rL = 18.0;  // 中卡 / 图标底 / 按钮
  static const rM = 16.0;  // 提示卡
  static const rS = 14.0;  // 九宫格 / 缩略图
  static const rPill = 26.0;

  static const gapXL = 16.0;
  static const gapL = 12.0;
  static const gapM = 10.0;
  static const gapS = 8.0;
  static const gapXS = 6.0;
}

/// 卡片通用装饰：白底 + 1px #E9E3D6 描边
BoxDecoration appCard({double radius = AppDimens.rXL, Color? color, Color? border}) {
  return BoxDecoration(
    color: color ?? AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border ?? AppColors.cardBorder, width: 1),
  );
}

/// 设计稿通用卡片投影
const List<BoxShadow> cardShadow = [
  BoxShadow(
    color: Color(0x0F29170F),
    offset: Offset(0, 10),
    blurRadius: 26,
    spreadRadius: -10,
  ),
];

/// 主按钮投影
const List<BoxShadow> primaryShadow = [
  BoxShadow(
    color: Color(0x4D2E5C4F),
    offset: Offset(0, 10),
    blurRadius: 22,
    spreadRadius: -6,
  ),
];

/// 严格按 390 宽设计稿渲染：整体按屏幕宽度等比缩放，保证各端比例一致
class DesignCanvas extends StatelessWidget {
  const DesignCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    // 让出系统状态栏：padding.top 可能被上层消费掉，取 viewPadding 兜底
    final top = math.max(mq.padding.top, mq.viewPadding.top);
    final scale = size.width / AppDimens.screenW;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: FittedBox(
          alignment: Alignment.topCenter,
          fit: BoxFit.fitWidth,
          child: SizedBox(
            width: AppDimens.screenW,
            height: (size.height - top) / scale,
            child: child,
          ),
        ),
      ),
    );
  }
}

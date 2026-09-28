import 'package:flutter/material.dart';

/// 设计稿色板（自 Ardot 设计稿逐点提取，勿手改色值）
class AppColors {
  const AppColors._();

  // 基础背景 / 文字
  static const bg = Color(0xFFF5F1E8); // 宣纸底
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1E2A25); // 墨
  static const inkSoft = Color(0xFF3C4A43);
  static const body = Color(0xFF6B7A73);
  static const muted = Color(0xFF96A39B);

  // 主色 松墨绿
  static const primary = Color(0xFF2F5D50);
  static const primaryDeep = Color(0xFF1C3D38);
  static const primarySoft = Color(0xFFEAF2EC);
  static const primarySoftBg = Color(0xFFF2F7F3);
  static const primarySoftBorder = Color(0xFFD9E6DC);
  static const accent = Color(0xFF8FCBAE);

  // 黄铜 / 土
  static const gold = Color(0xFFBE9351);
  static const goldDeep = Color(0xFF8A6A2E);
  static const goldSoftBg = Color(0xFFFBF6EA);

  // 朱砂 / 煞
  static const danger = Color(0xFFC1553C);
  static const dangerDeep = Color(0xFFB23F26);
  static const dangerSoftBg = Color(0xFFFBEDE8);
  static const dangerStrongBg = Color(0xFFF7E2DA);
  static const dangerBorder = Color(0xFFEBBFB0);

  // 线框 / 填充
  static const cardBorder = Color(0xFFE9E3D6);
  static const divider = Color(0xFFEDE5D4);
  static const iconBg = Color(0xFFFBF7EE);
  static const iconBorder = Color(0xFFEDE5D4);
  static const tipBg = Color(0xFFFBF5E9);
  static const tipBorder = Color(0xFFF1E7D2);
  static const btnSecondary = Color(0xFFF2EDE2);
  static const track = Color(0xFFEDE7DA);

  // 五行
  static const wood = Color(0xFF3F7A5E);
  static const fire = Color(0xFFC1553C);
  static const earth = Color(0xFFBE9351);
  static const metal = Color(0xFF8C8F94);
  static const water = Color(0xFF3D6E8C);

  // 五行浅底 / 深字（用神 chip 用，取自设计稿）
  static const woodSoftBg = AppColors.primarySoft; // #EAF2EC
  static const fireSoftBg = Color(0xFFFAEDE8);
  static const earthSoftBg = AppColors.goldSoftBg; // #FBF6EA
  static const metalSoftBg = Color(0xFFF1F1F2);
  static const waterSoftBg = Color(0xFFEBF0F4);
  static const woodDeep = AppColors.primary; // #2F5D50
  static const fireDeep = Color(0xFFA8492F);
  static const earthDeep = AppColors.goldDeep; // #8A6A2E
  static const metalDeep = Color(0xFF5D6A72);
  static const waterDeep = AppColors.water; // #3D6E8C

  /// 首页评分卡渐变
  static const heroGradient = LinearGradient(
    begin: Alignment(-0.75, -1.0),
    end: Alignment(1.0, 0.75),
    colors: [Color(0xFF2E5C4F), Color(0xFF1C3D38)],
  );

  /// 九宫格按吉凶取色（旺 / 平 / 煞 / 大凶）
  static Color palaceBg(String level) {
    switch (level) {
      case '旺':
        return primarySoftBg;
      case '平':
        return goldSoftBg;
      case '煞':
        return dangerSoftBg;
      case '大凶':
        return dangerStrongBg;
      default:
        return primarySoftBg;
    }
  }

  static Color palaceFg(String level) {
    switch (level) {
      case '旺':
        return primary;
      case '平':
        return goldDeep;
      case '煞':
        return danger;
      case '大凶':
        return dangerDeep;
      default:
        return primary;
    }
  }

  static Color? palaceBorder(String level) =>
      level == '大凶' ? dangerBorder : null;

  static Color levelDot(String level) {
    switch (level) {
      case '旺':
        return primary;
      case '平':
        return gold;
      case '煞':
      case '大凶':
        return danger;
      default:
        return muted;
    }
  }

  /// 首页三项指标的评级圆点：优 / 良 / 弱 / 大凶。
  /// 与九宫的 levelDot（旺 / 平 / 煞）是两套值域，不要混用。
  static Color gradeDot(String grade) {
    switch (grade) {
      case '优':
        return primary;
      case '良':
        return gold;
      case '弱':
        return muted;
      case '大凶':
        return danger;
      default:
        return muted;
    }
  }

  /// 五行主色：四柱天干地支、五行能量条
  static Color elementColor(String element) {
    switch (element) {
      case '木':
        return wood;
      case '火':
        return fire;
      case '土':
        return earth;
      case '金':
        return metal;
      case '水':
        return water;
      default:
        return ink;
    }
  }

  /// 五行浅底：用神 chip 背景
  static Color elementSoftBg(String element) {
    switch (element) {
      case '木':
        return woodSoftBg;
      case '火':
        return fireSoftBg;
      case '土':
        return earthSoftBg;
      case '金':
        return metalSoftBg;
      case '水':
        return waterSoftBg;
      default:
        return iconBg;
    }
  }

  /// 五行深字：用神 chip 文字
  static Color elementDeep(String element) {
    switch (element) {
      case '木':
        return woodDeep;
      case '火':
        return fireDeep;
      case '土':
        return earthDeep;
      case '金':
        return metalDeep;
      case '水':
        return waterDeep;
      default:
        return body;
    }
  }
}

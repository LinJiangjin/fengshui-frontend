import 'package:flutter/material.dart';

/// 设计色板。
///
/// 来源：Ardot 设计稿 + 2026-10-18 一次色板提质。改色时的硬约束：
/// - 正文 ≥ 5:1、次要文字 ≥ 4.5:1（相对 [bg] 与 [card] 中更低的那个）；
/// - 卡片描边 ≈ 1.3:1（相对白卡），低于 1.2 就「看不见边界」；
/// - 主色按钮上的白字 ≥ 4.5:1。
/// 改完记得同步同色硬编码：`compass_page` 的渐变零透明色、`layout_page` 的墙色/纸色、
/// `widgets/scheme_space_view` 的纸色。
class AppColors {
  const AppColors._();

  // ---- 基础背景 / 文字 ----
  // 底色从「土黄宣纸」改成中性微冷的纸色：黄底会把所有浅色卡片带旧、
  // 也会让黄铜与朱砂两暖色互相糊住。
  static const bg = Color(0xFFE9EDE6); // 纸底（微冷中性）
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF16211C); // 墨（14.8:1）
  static const inkSoft = Color(0xFF31403A);
  static const body = Color(0xFF56635D); // 正文 5.2:1
  static const muted = Color(0xFF626E67); // 次要 4.6:1（原 2.3:1，偏灰看不清）

  // ---- 主色 松墨绿 ----
  static const primary = Color(0xFF25604C);
  static const primaryDeep = Color(0xFF163E34);
  static const primarySoft = Color(0xFFE4EFE8);
  static const primarySoftBg = Color(0xFFEFF5F1);
  static const primarySoftBorder = Color(0xFFCBE0D4);
  static const accent = Color(0xFF6CBFA0);

  // ---- 黄铜 / 土 ----
  static const gold = Color(0xFFB58A45);
  static const goldDeep = Color(0xFF7C5E28);
  static const goldSoftBg = Color(0xFFFAF4E8);

  // ---- 朱砂 / 煞 ----
  static const danger = Color(0xFFB5452C);
  static const dangerDeep = Color(0xFF95321D);
  static const dangerSoftBg = Color(0xFFFAEBE5);
  static const dangerStrongBg = Color(0xFFF5DAD2);
  static const dangerBorder = Color(0xFFE6B4A5);

  // ---- 线框 / 填充 ----
  // 边框抬到 1.3:1 左右，细线不再「看不见」，卡片边界清楚
  static const cardBorder = Color(0xFFDCE2DA);
  static const divider = Color(0xFFE3E8E1);
  static const iconBg = Color(0xFFF3F6F1);
  static const iconBorder = Color(0xFFE2E8DF);
  static const tipBg = Color(0xFFFAF6EC); // 提示卡保留暖调，作为暖/冷对比
  static const tipBorder = Color(0xFFF1E9D6);
  static const btnSecondary = Color(0xFFEAEEE6);
  static const track = Color(0xFFE4E9E1);

  // ---- 五行 ----
  static const wood = Color(0xFF2F7A5E);
  static const fire = Color(0xFFB5452C);
  static const earth = Color(0xFFB58A45);
  static const metal = Color(0xFF75828A);
  static const water = Color(0xFF356E8E);

  // 五行浅底 / 深字（用神 chip 用）
  static const woodSoftBg = AppColors.primarySoft; // #E4EFE8
  static const fireSoftBg = Color(0xFFFAEDE7);
  static const earthSoftBg = AppColors.goldSoftBg; // #FAF4E8
  static const metalSoftBg = Color(0xFFEEF0F2);
  static const waterSoftBg = Color(0xFFE9EFF4);
  static const woodDeep = AppColors.primary; // #25604C
  static const fireDeep = Color(0xFF9C3A22);
  static const earthDeep = AppColors.goldDeep; // #7C5E28
  static const metalDeep = Color(0xFF5B666E);
  static const waterDeep = Color(0xFF2F6483);

  /// 首页评分卡渐变
  static const heroGradient = LinearGradient(
    begin: Alignment(-0.75, -1.0),
    end: Alignment(1.0, 0.75),
    colors: [Color(0xFF2A5B4B), Color(0xFF163A31)],
  );

  /// 九宫格按吉凶取色（旺 / 平 / 煞 / 大凶）
  static Color palaceBg(String level) {
    switch (level) {
      case '旺':
        return const Color(0xFFE7F2EA);
      case '平':
        return const Color(0xFFFAF3E3);
      case '煞':
        return const Color(0xFFFAEBE4);
      case '大凶':
        return const Color(0xFFF5DAD1);
      default:
        // 等级缺失/未知：用中性色，不要乐观地当成吉位
        return const Color(0xFFE9ECE6);
    }
  }

  static Color palaceFg(String level) {
    switch (level) {
      case '旺':
        return const Color(0xFF22604A);
      case '平':
        return const Color(0xFF836021);
      case '煞':
        return danger;
      case '大凶':
        return const Color(0xFF8F2F17);
      default:
        return muted;
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
        return const Color(0xFF8A9290);
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
        return const Color(0xFF8A9290);
      case '大凶':
        return danger;
      default:
        return const Color(0xFF8A9290);
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

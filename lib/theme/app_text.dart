import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 字体族（与 Ardot 设计稿一致）
///
/// 若要 1:1 还原，把 NotoSerifSC / NotoSansSC / Inter 字体文件放入
/// assets/fonts/ 并在 pubspec.yaml 的 fonts 节点注册（已预留注释）。
/// 未注册时 Flutter 会回退系统字体，布局与间距不受影响。
class AppFont {
  const AppFont._();
  static const serif = 'Noto Serif SC';
  static const sans = 'Noto Sans SC';
  static const number = 'Inter';
}

/// 设计稿字号 / 字重 / 行高
class AppText {
  const AppText._();

  // 标题类 · Noto Serif SC SemiBold
  static const greeting = TextStyle(
    fontFamily: AppFont.serif, fontSize: 22, fontWeight: FontWeight.w600,
    color: AppColors.ink, height: 1.2,
  );
  static const pageTitle = TextStyle(
    fontFamily: AppFont.serif, fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const section = TextStyle(
    fontFamily: AppFont.serif, fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const cardTitle = TextStyle(
    fontFamily: AppFont.serif, fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const value17 = TextStyle(
    fontFamily: AppFont.serif, fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const smallTitle = TextStyle(
    fontFamily: AppFont.serif, fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  // 正文类 · Noto Sans SC
  static const body13 = TextStyle(
    fontFamily: AppFont.sans, fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.body, height: 21 / 13,
  );
  static const body12 = TextStyle(
    fontFamily: AppFont.sans, fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.body, height: 19 / 12,
  );
  static const label11 = TextStyle(
    fontFamily: AppFont.sans, fontSize: 11, fontWeight: FontWeight.w400,
    color: AppColors.muted, height: 16 / 11,
  );
  static const label12 = TextStyle(
    fontFamily: AppFont.sans, fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );
  static const medium11 = TextStyle(
    fontFamily: AppFont.sans, fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );
  static const medium12 = TextStyle(
    fontFamily: AppFont.sans, fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.body,
  );
  static const medium13 = TextStyle(
    fontFamily: AppFont.sans, fontSize: 13, fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );
  static const medium15 = TextStyle(
    fontFamily: AppFont.sans, fontSize: 15, fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );
  static const button15 = TextStyle(
    fontFamily: AppFont.sans, fontSize: 15, fontWeight: FontWeight.w500,
    color: Colors.white,
  );
  static const button14 = TextStyle(
    fontFamily: AppFont.sans, fontSize: 14, fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // 数字类 · Inter
  static const score = TextStyle(
    fontFamily: AppFont.number, fontSize: 42, fontWeight: FontWeight.w700,
    color: Colors.white, height: 1.0,
  );
  static const scoreUnit = TextStyle(
    fontFamily: AppFont.number, fontSize: 14, fontWeight: FontWeight.w500,
    color: Color(0x99FFFFFF),
  );
  static const degree = TextStyle(
    fontFamily: AppFont.number, fontSize: 42, fontWeight: FontWeight.w700,
    color: AppColors.ink, height: 1.0,
  );
  static const degreeUnit = TextStyle(
    fontFamily: AppFont.number, fontSize: 22, fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );
  static const number12 = TextStyle(
    fontFamily: AppFont.number, fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.body,
  );
  static const clock = TextStyle(
    fontFamily: AppFont.number, fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
}

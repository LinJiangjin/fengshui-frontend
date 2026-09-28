import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// S5 · 家具布局建议
class LayoutPage extends StatelessWidget {
  const LayoutPage({super.key});

  static const _tips = [
    (true, '沙发宜背靠实墙，面向动线', '背后有靠主事业稳固；忌背门而坐，可在沙发侧加矮柜挡煞。'),
    (true, '床头宜朝东或南，避开正北', '顺命理喜用木火，助眠安神；正北五黄位不宜久卧。'),
    (false, '灶台与水池需间隔 60cm 以上', '水火相冲易生口角，可用中岛或绿植作缓冲。'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.pagePadH, 4, AppDimens.pagePadH, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    const SizedBox(height: AppDimens.gapL),
                    _planCard(),
                    const SizedBox(height: AppDimens.gapL),
                    const Text('摆放建议', style: AppText.section),
                    const SizedBox(height: AppDimens.gapL),
                    ..._tips.map((t) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppDimens.gapL),
                          child: _tipCard(t.$1, t.$2, t.$3),
                        )),
                  ],
                ),
              ),
              Positioned(left: 0, right: 0, bottom: 0, child: _bottomBar()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppIcon(AppIconKind.back, size: 22, color: AppColors.ink),
        Text('家具布局建议', style: AppText.pageTitle),
        AppIcon(AppIconKind.heart, size: 20, color: AppColors.ink),
      ],
    );
  }

  // ------------------------------------------------------- 户型平面图
  Widget _planCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('户型平面 · 布局示意', style: AppText.cardTitle),
              Text('96㎡ · 坐北朝南', style: AppText.label11),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 318,
            height: 230,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.iconBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE9E0CE), width: 1),
              ),
              child: Stack(
                children: [
                  _room(6, 6, 186, 134, '客厅'),
                  _room(192, 6, 120, 134, '主卧'),
                  _room(6, 140, 128, 84, '厨房'),
                  _room(134, 140, 178, 84, '卫生间'),
                  _furniture(16, 88, 110, 30, '沙发'),
                  _furniture(138, 16, 48, 30, '书桌'),
                  _furniture(216, 32, 76, 56, '床'),
                  _furniture(16, 174, 56, 26, '灶台'),
                  _marker(
                      166, 60, AppColors.gold, '财位', const Color(0xFF8A6A2E)),
                  _marker(296, 14, AppColors.danger, '五黄', AppColors.danger),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _room(double x, double y, double w, double h, String name) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE4DCCB), width: 1),
        ),
        padding: const EdgeInsets.only(left: 10, top: 8),
        child: Text(name,
            style:
                AppText.medium11.copyWith(color: AppColors.body, fontSize: 10)),
      ),
    );
  }

  Widget _furniture(double x, double y, double w, double h, String name) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFEFE8DA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDFD7C6), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(name,
            style: AppText.label11
                .copyWith(color: const Color(0xFF8A7F6B), fontSize: 9)),
      ),
    );
  }

  Widget _marker(
      double x, double y, Color color, String label, Color textColor) {
    return Positioned(
      left: x,
      top: y,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(5)),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: AppText.medium11.copyWith(color: textColor, fontSize: 9)),
        ],
      ),
    );
  }

  // ------------------------------------------------------- 建议卡
  Widget _tipCard(bool good, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: appCard(radius: AppDimens.rM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            good ? AppIconKind.check : AppIconKind.warn,
            size: 18,
            color: good ? AppColors.primary : AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.medium13),
                const SizedBox(height: 5),
                Text(desc, style: AppText.body12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: good ? AppColors.primarySoft : AppColors.dangerSoftBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              good ? '宜' : '忌',
              style: AppText.medium11.copyWith(
                color: good ? AppColors.primary : AppColors.danger,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      height: AppDimens.bottomBarH,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadH, 14, AppDimens.pagePadH, 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.btnSecondary,
              borderRadius: BorderRadius.circular(25),
            ),
            alignment: Alignment.center,
            child: Text('导出平面图',
                style: AppText.button14.copyWith(color: AppColors.inkSoft)),
          ),
          const SizedBox(width: AppDimens.gapM),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              alignment: Alignment.center,
              child: const Text('应用此布局方案', style: AppText.button14),
            ),
          ),
        ],
      ),
    );
  }
}

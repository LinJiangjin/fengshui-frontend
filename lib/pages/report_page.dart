import 'package:flutter/material.dart';

import '../models/diagnosis.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// S3 · 风水诊断报告
class ReportPage extends StatelessWidget {
  const ReportPage({
    super.key,
    required this.diagnosis,
    this.onRemeasure,
    this.onViewLayout,
  });

  final Diagnosis diagnosis;
  final VoidCallback? onRemeasure;
  final VoidCallback? onViewLayout;

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
                    _header(context),
                    const SizedBox(height: AppDimens.gapL),
                    _palaceCard(),
                    const SizedBox(height: AppDimens.gapL),
                    const Text('重点提示', style: AppText.section),
                    const SizedBox(height: AppDimens.gapL),
                    ...diagnosis.advice.map(_adviceCard),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _bottomBar(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: const AppIcon(AppIconKind.back, size: 22, color: AppColors.ink),
        ),
        const Text('风水诊断报告', style: AppText.pageTitle),
        const AppIcon(AppIconKind.share, size: 20, color: AppColors.ink),
      ],
    );
  }

  // ------------------------------------------------------- 九宫飞星卡
  Widget _palaceCard() {
    final d = diagnosis;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('九宫飞星 · 流年盘', style: AppText.cardTitle),
              Text('${d.year}年 · ${d.orientation.houseType}',
                  style: AppText.label11),
            ],
          ),
          const SizedBox(height: AppDimens.gapL),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: d.orderedPalaces.map(_palaceCell).toList(),
          ),
          const SizedBox(height: AppDimens.gapL),
          Row(
            children: [
              _legend('旺位', AppColors.primary),
              const SizedBox(width: 16),
              _legend('平位', AppColors.gold),
              const SizedBox(width: 16),
              _legend('煞位', AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(text, style: AppText.label11.copyWith(color: AppColors.body)),
      ],
    );
  }

  Widget _palaceCell(Palace p) {
    final fg = AppColors.palaceFg(p.level);
    final border = AppColors.palaceBorder(p.level);
    return Container(
      width: 102,
      height: 102,
      decoration: BoxDecoration(
        color: AppColors.palaceBg(p.level),
        borderRadius: BorderRadius.circular(AppDimens.rS),
        border: border != null
            ? Border.all(color: border, width: 1)
            : (p.isCenter
                ? Border.all(color: AppColors.primarySoftBorder, width: 1)
                : null),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            p.title,
            style: AppText.label11.copyWith(
              color: p.level == '大凶' ? const Color(0xFF8A5443) : AppColors.body,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            p.starTitle,
            style: AppText.value17.copyWith(
              color: fg,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            p.label,
            style: AppText.medium11.copyWith(color: fg, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- 重点提示
  Widget _adviceCard(Advice a) {
    final isWarn = a.type == 'warn';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapL),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: appCard(radius: AppDimens.rM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(
              isWarn ? AppIconKind.warn : AppIconKind.check,
              size: 18,
              color: isWarn ? AppColors.danger : AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title, style: AppText.medium13),
                  const SizedBox(height: 5),
                  Text(a.desc, style: AppText.body12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------- 底部操作栏
  Widget _bottomBar(BuildContext context) {
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
          Expanded(
            child: GestureDetector(
              onTap: onRemeasure ?? () => Navigator.maybePop(context),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.btnSecondary,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text('重新测量',
                    style: AppText.button14.copyWith(color: AppColors.inkSoft)),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.gapM),
          Expanded(
            child: GestureDetector(
              onTap: onViewLayout,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: const Text('查看布局建议', style: AppText.button14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

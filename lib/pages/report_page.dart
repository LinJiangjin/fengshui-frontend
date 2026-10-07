import 'package:flutter/material.dart';

import '../models/diagnosis.dart';
import '../models/palace_grid.dart';
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
    final cells = PalaceGrid.build(
      d.palaces,
      facing: d.orientation.facingDir,
      rotate: true,
    );
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
          const SizedBox(height: AppDimens.gapS),
          _viewInfo(),
          const SizedBox(height: AppDimens.gapM),
          // 3×3 等宽等高，间距统一
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: [
              for (var i = 0; i < cells.length; i++) _palaceCell(cells[i]),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legend('旺位', AppColors.primary),
              _legend('平位', AppColors.gold),
              _legend('煞位', AppColors.danger),
              _legend('大凶', AppColors.dangerDeep),
            ],
          ),
        ],
      ),
    );
  }

  /// 视角说明：九宫盘按坐向旋转，向方朝上
  Widget _viewInfo() {
    final facing = diagnosis.orientation.facingDir;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '按坐向',
            style: AppText.medium11.copyWith(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (facing.isNotEmpty)
          Expanded(
            child: Text('向方 $facing 朝上', style: AppText.label11),
          ),
      ],
    );
  }

  Widget _legend(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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

  Widget _palaceCell(Palace? p) {
    if (p == null) return const SizedBox.shrink();
    final o = diagnosis.orientation;
    final isFacing = !p.isCenter && p.direction == o.facingDir;
    final isSitting = !p.isCenter && p.direction == o.sitting;
    final mark = isFacing
        ? AppColors.gold
        : (isSitting ? AppColors.primary : null);
    final fg = AppColors.palaceFg(p.level);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.palaceBg(p.level),
        borderRadius: BorderRadius.circular(AppDimens.rS),
        border: Border.all(
          color: mark ??
              AppColors.palaceBorder(p.level) ??
              (p.isCenter ? AppColors.primarySoftBorder : AppColors.cardBorder),
          width: mark != null ? 1.6 : 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.title,
                  style: AppText.label11.copyWith(
                    color: p.level == '大凶'
                        ? const Color(0xFF8A5443)
                        : AppColors.body,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.starName,
                  style: AppText.value17.copyWith(color: fg, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  p.element,
                  style: AppText.label11.copyWith(
                    color: fg.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.label,
                  style: AppText.medium11.copyWith(color: fg, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (mark != null)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: mark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isFacing ? '向' : '坐',
                  style: AppText.medium11.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                  ),
                ),
              ),
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

import 'package:flutter/material.dart';

import '../models/diagnosis.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// S1 · 首页 · 今日风水
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.diagnosis,
    required this.onQuickAction,
  });

  final Diagnosis diagnosis;
  final ValueChanged<int> onQuickAction;

  @override
  Widget build(BuildContext context) {
    final d = diagnosis;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePadH, 0, AppDimens.pagePadH, 104),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(d),
                const SizedBox(height: AppDimens.gapM),
                _scoreCard(d),
                const SizedBox(height: AppDimens.gapM),
                _luckRow(d),
                const SizedBox(height: AppDimens.gapM),
                const Text('快速测算', style: AppText.section),
                const SizedBox(height: AppDimens.gapM),
                _quickActions(),
                const SizedBox(height: AppDimens.gapM),
                const Text('我的房屋', style: AppText.section),
                const SizedBox(height: AppDimens.gapM),
                _houseCard(d),
                const SizedBox(height: AppDimens.gapM),
                _adviceCard(d),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- 页头
  /// 公历日期文案：2026年9月27日 周日
  String get _dateText {
    final now = DateTime.now();
    const weeks = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${now.year}年${now.month}月${now.day}日 ${weeks[now.weekday - 1]}';
  }

  Widget _header(Diagnosis d) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('早安，明之先生', style: AppText.greeting),
            const SizedBox(height: 4),
            Text(
              '$_dateText · 今日宜：安床 纳财',
              style: AppText.label12,
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          alignment: Alignment.center,
          child: const AppIcon(AppIconKind.user,
              size: 24, color: AppColors.muted),
        ),
      ],
    );
  }

  // ------------------------------------------------------- 综合评分卡
  Widget _scoreCard(Diagnosis d) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        boxShadow: const [
          BoxShadow(
            color: Color(0x471C3D33),
            offset: Offset(0, 14),
            blurRadius: 30,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${d.houseName} 风水综合评分',
                  style: AppText.medium13.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('今日已更新',
                    style: AppText.medium11.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          // 分数行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${d.score}', style: AppText.score),
                  const SizedBox(width: 6),
                  const Text('/ 100', style: AppText.scoreUnit),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(d.orientation.readable,
                      style: AppText.value17.copyWith(color: Colors.white)),
                  const SizedBox(height: 5),
                  Text(
                    d.orientation.subtitle,
                    style: AppText.label11.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
          const SizedBox(height: AppDimens.gapM),
          // 三项指标
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: d.metrics.map(_metric).toList(),
          ),
        ],
      ),
    );
  }

  Widget _metric(Metric m) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.gradeDot(m.grade),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  m.value,
                  style: AppText.medium13.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            m.desc,
            style: AppText.label11.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- 吉凶双卡
  Widget _luckRow(Diagnosis d) {
    return Row(
      children: [
        Expanded(
          child: _luckCard(
            label: '今日吉位',
            value: d.best.title.contains('·')
                ? d.best.title
                : '${d.best.direction} · ${d.best.level}',
            desc: d.best.note,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimens.gapL),
        Expanded(
          child: _luckCard(
            label: '今日忌方',
            value: d.worst.title,
            desc: d.worst.note,
            color: AppColors.danger,
            showWarn: true,
          ),
        ),
      ],
    );
  }

  Widget _luckCard({
    required String label,
    required String value,
    required String desc,
    required Color color,
    bool showWarn = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: appCard(radius: AppDimens.rL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          showWarn
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(label, style: AppText.medium11),
                    const AppIcon(AppIconKind.warn,
                        size: 16, color: AppColors.danger),
                  ],
                )
              : Text(label, style: AppText.medium11),
          const SizedBox(height: 8),
          Text(value, style: AppText.value17.copyWith(color: color)),
          const SizedBox(height: 8),
          Text(desc, style: AppText.label11.copyWith(color: AppColors.body)),
        ],
      ),
    );
  }

  // ------------------------------------------------------- 快捷入口
  Widget _quickActions() {
    final items = [
      (AppIconKind.compass, '罗盘定向'),
      (AppIconKind.taiji, '八字排盘'),
      (AppIconKind.report, '户型诊断'),
      (AppIconKind.plan, '家具布局'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(items.length, (i) {
        final it = items[i];
        return GestureDetector(
          onTap: () => onQuickAction(i),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.iconBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.iconBorder, width: 1),
                ),
                alignment: Alignment.center,
                child: AppIcon(it.$1, size: 24, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(it.$2, style: AppText.medium11.copyWith(color: AppColors.inkSoft)),
            ],
          ),
        );
      }),
    );
  }

  // ------------------------------------------------------- 房屋卡
  Widget _houseCard(Diagnosis d) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: appCard(radius: AppDimens.rL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment(-0.7, -0.7),
                end: Alignment(0.7, 1.0),
                colors: [Color(0xFFC7AD78), Color(0xFF6B8C80)],
              ),
            ),
          ),
          const SizedBox(width: AppDimens.gapL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.houseName, style: AppText.medium15),
                const SizedBox(height: 5),
                Text(
                  '${d.orientation.readable} · ${d.orientation.title}',
                  style: AppText.label12,
                ),
              ],
            ),
          ),
          const AppIcon(AppIconKind.chevronRight,
              size: 20, color: AppColors.muted),
        ],
      ),
    );
  }

  // ------------------------------------------------------- 今日建议
  Widget _adviceCard(Diagnosis d) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tipBg,
        borderRadius: BorderRadius.circular(AppDimens.rL),
        border: Border.all(color: AppColors.tipBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(AppIconKind.spark,
                  size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Text('今日调候建议',
                  style: AppText.smallTitle.copyWith(color: AppColors.goldDeep)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            d.advice.isNotEmpty
                ? d.advice.first.desc
                : '暂无建议，请先完成坐向测量。',
            style: AppText.body13,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('查看完整调理方案',
                  style: AppText.medium12.copyWith(color: AppColors.primary)),
              const SizedBox(width: 4),
              const AppIcon(AppIconKind.chevronRight,
                  size: 14, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

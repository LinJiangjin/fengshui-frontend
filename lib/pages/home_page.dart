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
    required this.onOpenHouses,
    this.updatedAt,
    this.onRefresh,
  });

  final Diagnosis diagnosis;
  final ValueChanged<int> onQuickAction;
  final VoidCallback onOpenHouses;

  /// 下拉手动刷新（重新请求后端，拿当日最新日盘）
  final Future<void> Function()? onRefresh;

  /// 最近一次算出的时间（用于卡片右上角的更新文案）
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final d = diagnosis;
    final scroll = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
                if (d.daily != null) ...[
                  const SizedBox(height: AppDimens.gapS),
                  _dailyCaption(d.daily!),
                ],
                const SizedBox(height: AppDimens.gapM),
                const Text('快速测算', style: AppText.section),
                const SizedBox(height: AppDimens.gapM),
                _quickActions(),
                const SizedBox(height: AppDimens.gapM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('我的房屋', style: AppText.section),
                    GestureDetector(
                      onTap: onOpenHouses,
                      child: Text('切换 / 管理',
                          style: AppText.medium12.copyWith(
                              color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.gapM),
                _houseCard(d),
                const SizedBox(height: AppDimens.gapM),
                _adviceCard(d),
        ],
      ),
    );
    if (onRefresh == null) {
      return Column(children: [Expanded(child: scroll)]);
    }
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh!,
            child: scroll,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- 页头
  /// 更新文案：精确到分钟，让刷新可见（如「今日 14:32 更新」）
  String get _updateText {
    final t = updatedAt;
    if (t == null) return '今日已更新';
    final now = DateTime.now();
    final hhmm =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return '今日 $hhmm 更新';
    }
    return '${t.month}月${t.day}日 $hhmm 更新';
  }

  /// 公历日期文案：2026年9月27日 周日
  String get _dateText {
    final now = DateTime.now();
    const weeks = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${now.year}年${now.month}月${now.day}日 ${weeks[now.weekday - 1]}';
  }

  /// 问候语按时段变化，不再写死某个用户名
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 6) return '夜深了';
    if (h < 11) return '早安';
    if (h < 14) return '午安';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  Widget _header(Diagnosis d) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_greeting, style: AppText.greeting),
            const SizedBox(height: 4),
            Text(
              // 今日吉位来自后端日盘，不再写死「宜：安床 纳财」
              '$_dateText · 今日${d.todayBest.roleName}：${d.todayBest.direction}',
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
                child: Text(_updateText,
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
          // 三项指标：统一列高、标题顶部对齐、描述固定两行
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < d.metrics.length; i++) ...[
                Expanded(child: _metric(d.metrics[i])),
                if (i != d.metrics.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(Metric m) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行固定高度，三列顶部严格对齐
          SizedBox(
            height: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                Expanded(
                  child: Text(
                    m.value,
                    style: AppText.medium13.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 描述固定两行高度，行数不同时底部仍对齐
          SizedBox(
            height: 34,
            child: Text(
              m.desc,
              style: AppText.label11.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- 吉凶双卡
  /// 吉位 / 忌方取当日紫白盘（日家九宫飞星），每天都会变
  Widget _luckRow(Diagnosis d) {
    final best = d.todayBest;
    final worst = d.todayWorst;
    return Row(
      children: [
        Expanded(
          child: _luckCard(
            label: '今日吉位',
            value: best.title.contains('·')
                ? best.title
                : '${best.direction} · ${best.level}',
            desc: best.note,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimens.gapL),
        Expanded(
          child: _luckCard(
            label: '今日忌方',
            value: worst.title,
            desc: worst.note,
            color: AppColors.danger,
            showWarn: true,
          ),
        ),
      ],
    );
  }

  /// 当日星曜说明：三碧入中 · 丙午日 · 阴遁上元
  Widget _dailyCaption(DailyChart c) {
    final parts = <String>[
      c.summary,
      if (c.escape.isNotEmpty) c.escapeSummary,
      if (c.solarTermRange.isNotEmpty) c.solarTermRange,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: AppIcon(AppIconKind.spark, size: 14, color: AppColors.gold),
        ),
        const SizedBox(width: AppDimens.gapXS),
        Expanded(
          child: Text(
            '今日日星：${parts.join(' · ')}',
            style: AppText.label11,
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
    final areaText = d.area > 0
        ? '${d.area.toStringAsFixed(d.area.truncateToDouble() == d.area ? 0 : 1)}㎡'
        : '';
    return GestureDetector(
      onTap: onOpenHouses,
      child: Container(
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
              alignment: Alignment.center,
              child: Text(
                d.houseName.isNotEmpty ? d.houseName.substring(0, 1) : '宅',
                style: AppText.value17.copyWith(color: Colors.white),
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
                    [
                      d.orientation.readable,
                      d.orientation.title,
                      if (areaText.isNotEmpty) areaText,
                    ].join(' · '),
                    style: AppText.label12,
                  ),
                ],
              ),
            ),
            const AppIcon(AppIconKind.chevronRight,
                size: 20, color: AppColors.muted),
          ],
        ),
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

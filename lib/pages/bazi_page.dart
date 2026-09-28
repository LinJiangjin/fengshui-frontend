import 'package:flutter/material.dart';

import '../models/bazi.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// S4 · 命理档案
///
/// 四柱、五行占比、用神喜忌全部来自后端确定性排盘引擎（/api/v1/bazi），
/// 页面内不含任何硬编码命理数据。默认展示设计稿示例：1988-03-12 辰时 · 男。
class BaziPage extends StatefulWidget {
  const BaziPage({
    super.key,
    this.year = 1988,
    this.month = 3,
    this.day = 12,
    this.hour = 8,
    this.minute = 0,
    this.gender = '男',
    this.longitude = 120.0,
    this.name = '',
  });

  /// 出生年（公历）
  final int year;
  final int month;
  final int day;

  /// 出生时刻（北京时间 24 小时制）
  final int hour;
  final int minute;

  /// 男 / 女
  final String gender;

  /// 出生地东经度数，用于真太阳时校正
  final double longitude;

  /// 姓名（可选）
  final String name;

  @override
  State<BaziPage> createState() => _BaziPageState();
}

class _BaziPageState extends State<BaziPage> {
  final ApiClient _api = ApiClient();

  BaziProfile? _profile;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _api.fetchBazi(
        year: widget.year,
        month: widget.month,
        day: widget.day,
        hour: widget.hour,
        minute: widget.minute,
        gender: widget.gender,
        longitude: widget.longitude,
        name: widget.name,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              if (profile != null)
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.pagePadH, 4, AppDimens.pagePadH, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(),
                      const SizedBox(height: AppDimens.gapL),
                      _pillarCard(profile),
                      const SizedBox(height: AppDimens.gapL),
                      _elementCard(profile),
                      const SizedBox(height: AppDimens.gapL),
                      _fortuneCard(profile),
                    ],
                  ),
                )
              else
                Center(child: _statusView()),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _bottomBar(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 加载中 / 失败态（配色沿用设计稿，不用裸 Text）
  Widget _statusView() {
    if (_loading) {
      return const CircularProgressIndicator(color: AppColors.primary);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadH),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.all(AppDimens.gapXL),
          decoration: appCard(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 32, color: AppColors.muted),
              const SizedBox(height: AppDimens.gapL),
              const Text('排盘失败', style: AppText.cardTitle),
              const SizedBox(height: AppDimens.gapXS),
              Text(
                _error ?? '未知错误',
                textAlign: TextAlign.center,
                style: AppText.body12,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimens.gapXL),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: _load,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primarySoftBorder),
                    backgroundColor: AppColors.primarySoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.rPill),
                    ),
                  ),
                  child: Text(
                    '重新排盘',
                    style: AppText.medium13.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppIcon(AppIconKind.back, size: 22, color: AppColors.ink),
        Text('命理档案', style: AppText.pageTitle),
        AppIcon(AppIconKind.edit, size: 20, color: AppColors.ink),
      ],
    );
  }

  Widget _pillarCard(BaziProfile profile) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('生辰八字', style: AppText.cardTitle),
              Text(profile.birth.summary, style: AppText.label11),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < profile.pillars.length; i++) ...[
                if (i > 0) const SizedBox(width: AppDimens.gapS),
                Expanded(child: _pillarBox(profile.pillars[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillarBox(BaziPillar pillar) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.iconBg,
        borderRadius: BorderRadius.circular(AppDimens.rS),
      ),
      child: Column(
        children: [
          Text(pillar.name, style: AppText.label11),
          const SizedBox(height: 4),
          Text(
            pillar.gan,
            style: AppText.value17.copyWith(fontSize: 24, color: pillar.ganColor),
          ),
          Text(
            pillar.zhi,
            style: AppText.value17.copyWith(fontSize: 24, color: pillar.zhiColor),
          ),
          const SizedBox(height: 4),
          Text(pillar.hiddenText, style: AppText.label11),
        ],
      ),
    );
  }

  Widget _elementCard(BaziProfile profile) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('五行能量', style: AppText.cardTitle),
              Text(profile.elementSummary, style: AppText.label11),
            ],
          ),
          const SizedBox(height: AppDimens.gapL),
          ...profile.elements.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.gapL),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      child: Text(e.element,
                          style: AppText.medium12
                              .copyWith(color: AppColors.inkSoft)),
                    ),
                    const SizedBox(width: AppDimens.gapM),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.track,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: e.percent / 100.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: e.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.gapM),
                    SizedBox(
                      width: 34,
                      child: Text('${e.percent}%',
                          textAlign: TextAlign.right, style: AppText.number12),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _fortuneCard(BaziProfile profile) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('用神喜忌', style: AppText.cardTitle),
              Text(profile.fortuneSubtitle, style: AppText.label11),
            ],
          ),
          const SizedBox(height: AppDimens.gapL),
          _godRow('喜用神', profile.favorable),
          const SizedBox(height: AppDimens.gapL),
          _godRow('忌 神', profile.unfavorable),
        ],
      ),
    );
  }

  /// 喜忌行：数量不固定，用 Wrap 自动折行
  Widget _godRow(String title, List<BaziGod> gods) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 52, child: Text(title, style: AppText.label12)),
        const SizedBox(width: AppDimens.gapS),
        Expanded(
          child: Wrap(
            spacing: AppDimens.gapS,
            runSpacing: AppDimens.gapXS,
            children: gods.map(_chip).toList(),
          ),
        ),
      ],
    );
  }

  Widget _chip(BaziGod god) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: god.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        god.label,
        style: AppText.medium12.copyWith(color: god.foreground),
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
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: const Text('按命理生成布局建议', style: AppText.button14),
      ),
    );
  }
}

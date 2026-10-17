import 'package:flutter/material.dart';

import '../models/phone_energy.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// 号码八星（数字能量）
///
/// ⚠ 这是**近现代民间民俗说法**，没有术数典籍支撑，与玄空 / 八字 / 六爻
/// 不是同一级别的体系。所以页面做了三件事把它定位清楚：
/// 1. 顶部固定一条性质声明（后端下发，原样展示）；
/// 2. 只讲「性格与倾向」，不断具体事件；
/// 3. 号码属个人信息，全程只显示脱敏形式，原始号码不回显。
class PhoneEnergyPage extends StatefulWidget {
  const PhoneEnergyPage({super.key});

  @override
  State<PhoneEnergyPage> createState() => _PhoneEnergyPageState();
}

class _PhoneEnergyPageState extends State<PhoneEnergyPage> {
  final ApiClient _api = ApiClient();
  final TextEditingController _ctrl = TextEditingController();

  String _kind = 'mobile';
  PhoneEnergy? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = '请输入号码');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api.fetchPhoneEnergy(number: raw, kind: _kind);
      if (!mounted) return;
      setState(() {
        _result = r;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '号码分析失败，请检查网络后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.pagePadH, 4, AppDimens.pagePadH, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context),
                const SizedBox(height: AppDimens.gapL),
                _inputCard(),
                const SizedBox(height: AppDimens.gapL),
                SizedBox(
                  width: double.infinity,
                  child: _actionButton('看数组', primary: true, onTap: _submit),
                ),
                const SizedBox(height: AppDimens.gapL),
                ..._resultBody(),
              ],
            ),
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
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.maybePop(context),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: AppIcon(AppIconKind.back, size: 22, color: AppColors.ink),
          ),
        ),
        const Text('号码八星', style: AppText.pageTitle),
        const Padding(
          padding: EdgeInsets.all(6),
          child: AppIcon(AppIconKind.search, size: 20, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _inputCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('输入号码', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapS),
          const Text(
            '手机号、车牌、门牌、任意数字串都行，只取其中的数字。'
            '号码不会离开本机以外的展示环节——结果里只显示脱敏形式。',
            style: AppText.label11,
          ),
          const SizedBox(height: AppDimens.gapM),
          Wrap(
            spacing: AppDimens.gapS,
            children: const [
              _Kind('mobile', '手机号'),
              _Kind('plate', '车牌'),
              _Kind('address', '门牌'),
              _Kind('general', '其他'),
            ].map((k) => _kindChip(k.key, k.label)).toList(),
          ),
          const SizedBox(height: AppDimens.gapM),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.text,
            style: AppText.medium13,
            decoration: InputDecoration(
              hintText: _kind == 'mobile' ? '13812345678' : '输入号码',
              hintStyle: AppText.label11,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.rS),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.rS),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kindChip(String key, String label) {
    final active = _kind == key;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _kind = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.btnSecondary,
          borderRadius: BorderRadius.circular(AppDimens.rPill),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: AppText.medium12.copyWith(
            color: active ? AppColors.primaryDeep : AppColors.body,
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String label,
      {required VoidCallback? onTap, bool primary = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : AppColors.btnSecondary,
          borderRadius: BorderRadius.circular(AppDimens.rM),
        ),
        child: Text(
          label,
          style: AppText.medium13.copyWith(
            color: primary ? Colors.white : AppColors.body,
          ),
        ),
      ),
    );
  }

  List<Widget> _resultBody() {
    if (_loading) {
      return const [
        SizedBox(height: 100),
        Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ];
    }
    final err = _error;
    if (err != null) return [_errorCard(err)];
    final r = _result;
    if (r == null) return [const SizedBox.shrink()];
    return [
      _natureBanner(r),
      const SizedBox(height: AppDimens.gapL),
      _verdictCard(r),
      const SizedBox(height: AppDimens.gapL),
      _pairsCard(r),
      const SizedBox(height: AppDimens.gapL),
      _distCard(r),
      const SizedBox(height: AppDimens.gapL),
      _pointsCard(r),
    ];
  }

  /// 性质声明：后端下发，原样展示，不淡化
  Widget _natureBanner(PhoneEnergy r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.gapM),
      decoration: BoxDecoration(
        color: AppColors.goldSoftBg,
        borderRadius: BorderRadius.circular(AppDimens.rS),
        border: Border.all(color: AppColors.goldDeep),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: AppIcon(AppIconKind.warn, size: 15, color: AppColors.goldDeep),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              r.natureNote,
              style: AppText.body12.copyWith(color: AppColors.goldDeep),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verdictCard(PhoneEnergy r) {
    final fg = AppColors.palaceFg(r.levelKey);
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: BoxDecoration(
        color: AppColors.palaceBg(r.levelKey),
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('数组结果', style: AppText.cardTitle),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppDimens.rPill),
                ),
                child: Text(
                  '${r.score} 分 · ${r.level}',
                  style: AppText.medium11.copyWith(color: fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapS),
          Text(r.masked, style: AppText.medium13.copyWith(color: AppColors.ink)),
          const SizedBox(height: AppDimens.gapM),
          Text(r.plain, style: AppText.body12),
          if (r.dominantPlain.isNotEmpty) ...[
            const SizedBox(height: AppDimens.gapS),
            Text('主导「${r.dominant}」：${r.dominantPlain}',
                style: AppText.body12),
          ],
        ],
      ),
    );
  }

  Widget _pairsCard(PhoneEnergy r) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('逐组拆解', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapS),
          const Text(
            '相邻两位重叠拆分；末尾三组权重加倍（通行说法认为尾号影响最重）。'
            '含 0 或 5 的组不归入八星，按修饰规则另行计分。',
            style: AppText.label11,
          ),
          const SizedBox(height: AppDimens.gapM),
          Wrap(
            spacing: AppDimens.gapS,
            runSpacing: AppDimens.gapS,
            children: r.items.map(_pairChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _pairChip(PhoneEnergyItem i) {
    final fg = AppColors.palaceFg(i.level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: i.isClassified ? AppColors.palaceBg(i.level) : AppColors.iconBg,
        borderRadius: BorderRadius.circular(AppDimens.rS),
        border: Border.all(
          color: i.isTail ? fg : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                i.isClassified ? '${i.pair} ${i.star}' : i.pair,
                style: AppText.medium12.copyWith(
                  color: i.isClassified ? fg : AppColors.muted,
                ),
              ),
              if (i.isTail) ...[
                const SizedBox(width: 4),
                Text('尾', style: AppText.label11.copyWith(fontSize: 9)),
              ],
            ],
          ),
          Text(
            i.isClassified ? '${i.scoreText} 分' : '含 0/5',
            style: AppText.label11.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _distCard(PhoneEnergy r) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('八星分布', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapM),
          Row(
            children: [
              Expanded(
                child: _statCell('吉星', '${r.good} 组'),
              ),
              Expanded(
                child: _statCell('凶星', '${r.bad} 组'),
              ),
              Expanded(
                child: _statCell('0 / 5', '${r.zeros} / ${r.fives}'),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          ...r.distribution.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.gapXS),
              child: Row(
                children: [
                  SizedBox(width: 42, child: Text(e.key, style: AppText.label11)),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.track,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: r.items.isEmpty
                            ? 0
                            : (e.value / r.items.length).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.gapS),
                  SizedBox(
                    width: 28,
                    child: Text('${e.value}',
                        textAlign: TextAlign.right, style: AppText.number12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label11),
        const SizedBox(height: 2),
        Text(value, style: AppText.medium13.copyWith(color: AppColors.ink)),
      ],
    );
  }

  Widget _pointsCard(PhoneEnergy r) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('怎么看这组号码', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapM),
          ...r.points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.gapS),
              child: Text(p, style: AppText.body12),
            ),
          ),
          if (r.advice.isNotEmpty) ...[
            const SizedBox(height: AppDimens.gapM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.gapM),
              decoration: BoxDecoration(
                color: AppColors.primarySoftBg,
                borderRadius: BorderRadius.circular(AppDimens.rS),
              ),
              child: Text(
                r.advice,
                style: AppText.body12.copyWith(color: AppColors.primaryDeep),
              ),
            ),
          ],
          const SizedBox(height: AppDimens.gapM),
          Text('规则版本 ${r.rulesVersion}', style: AppText.label11),
        ],
      ),
    );
  }

  Widget _errorCard(String err) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AppIcon(AppIconKind.warn, size: 16, color: AppColors.danger),
              SizedBox(width: 8),
              Text('无法分析', style: AppText.cardTitle),
            ],
          ),
          const SizedBox(height: AppDimens.gapS),
          Text(err, style: AppText.body12),
        ],
      ),
    );
  }
}

class _Kind {
  const _Kind(this.key, this.label);

  final String key;
  final String label;
}

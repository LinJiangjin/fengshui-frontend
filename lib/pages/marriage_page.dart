import 'package:flutter/material.dart';

import '../models/marriage.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// 合婚配对：生肖合婚 / 八字合婚
///
/// 页面不做任何吉凶推导，只把后端下发的内容排好版。
/// 所有关系（六合 / 六冲 / 六害 / 三合 / 天干五合 / 喜用互补）
/// 都由服务端确定性算出。
class MarriagePage extends StatefulWidget {
  const MarriagePage({super.key});

  @override
  State<MarriagePage> createState() => _MarriagePageState();
}

enum _Mode { zodiac, bazi }

/// 一方的输入
class _PartyInput {
  _PartyInput(this.tag)
      : year = TextEditingController(),
        month = TextEditingController(),
        day = TextEditingController(),
        hour = TextEditingController(),
        lng = TextEditingController(text: '120.0');

  final String tag;
  final TextEditingController year;
  final TextEditingController month;
  final TextEditingController day;
  final TextEditingController hour;
  final TextEditingController lng;
  String gender = '男';

  void dispose() {
    year.dispose();
    month.dispose();
    day.dispose();
    hour.dispose();
    lng.dispose();
  }

  Map<String, dynamic> toPayload({required bool full}) {
    final y = int.tryParse(year.text.trim()) ?? 0;
    if (!full) {
      return {
        'year': y,
        'month': int.tryParse(month.text.trim()) ?? 0,
        'day': int.tryParse(day.text.trim()) ?? 0,
        'gender': gender,
      };
    }
    return {
      'year': y,
      'month': int.tryParse(month.text.trim()) ?? 0,
      'day': int.tryParse(day.text.trim()) ?? 0,
      'hour': int.tryParse(hour.text.trim()) ?? 0,
      'minute': 0,
      'gender': gender,
      'longitude': double.tryParse(lng.text.trim()) ?? 120.0,
    };
  }
}

class _MarriagePageState extends State<MarriagePage> {
  final ApiClient _api = ApiClient();

  _Mode _mode = _Mode.zodiac;
  late final _PartyInput _a = _PartyInput('甲方');
  late final _PartyInput _b = _PartyInput('乙方');

  MarriageResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _switchMode(_Mode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _result = null;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final full = _mode == _Mode.bazi;
    final a = _a.toPayload(full: full);
    final b = _b.toPayload(full: full);
    if ((a['year'] as int) <= 0 || (b['year'] as int) <= 0) {
      setState(() => _error = '请填写双方的出生年');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api.fetchMarriage(
        mode: full ? 'bazi' : 'zodiac',
        a: a,
        b: b,
      );
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
        _error = '合婚计算失败，请检查网络后重试';
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
                _modeSwitch(),
                const SizedBox(height: AppDimens.gapL),
                _partyCard(_a),
                const SizedBox(height: AppDimens.gapM),
                _partyCard(_b),
                const SizedBox(height: AppDimens.gapL),
                SizedBox(
                  width: double.infinity,
                  child: _actionButton(label: '看配对', primary: true,
                      onTap: _submit),
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
        const Text('合婚配对', style: AppText.pageTitle),
        const Padding(
          padding: EdgeInsets.all(6),
          child: AppIcon(AppIconKind.heart, size: 20, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _modeSwitch() {
    Widget item(_Mode mode, String label) {
      final active = _mode == mode;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _switchMode(mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimens.rM - 4),
            ),
            child: Text(
              label,
              style: AppText.medium13.copyWith(
                color: active ? AppColors.primaryDeep : AppColors.body,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.btnSecondary,
        borderRadius: BorderRadius.circular(AppDimens.rM),
      ),
      child: Row(
        children: [
          item(_Mode.zodiac, '生肖合婚'),
          item(_Mode.bazi, '八字合婚'),
        ],
      ),
    );
  }

  Widget _partyCard(_PartyInput p) {
    final full = _mode == _Mode.bazi;
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(p.tag, style: AppText.cardTitle),
              const Spacer(),
              _genderChip(p, '男'),
              const SizedBox(width: AppDimens.gapS),
              _genderChip(p, '女'),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          Row(
            children: [
              Expanded(flex: 2, child: _field(p.year, '出生年', hint: '1990')),
              const SizedBox(width: AppDimens.gapS),
              Expanded(child: _field(p.month, '月', hint: full ? '6' : '可空')),
              const SizedBox(width: AppDimens.gapS),
              Expanded(child: _field(p.day, '日', hint: full ? '1' : '可空')),
            ],
          ),
          if (full) ...[
            const SizedBox(height: AppDimens.gapS),
            Row(
              children: [
                Expanded(child: _field(p.hour, '时辰（0-23）', hint: '9')),
                const SizedBox(width: AppDimens.gapS),
                Expanded(child: _field(p.lng, '东经', hint: '120.0')),
              ],
            ),
            const SizedBox(height: AppDimens.gapXS),
            const Text(
              '月日不为空才能排八字；生肖模式可留空（留空则不参与立春分界）。',
              style: AppText.label11,
            ),
          ],
        ],
      ),
    );
  }

  Widget _genderChip(_PartyInput p, String g) {
    final active = p.gender == g;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => p.gender = g),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.btnSecondary,
          borderRadius: BorderRadius.circular(AppDimens.rPill),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          g,
          style: AppText.medium12.copyWith(
            color: active ? AppColors.primaryDeep : AppColors.body,
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label11),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true, signed: true),
          style: AppText.medium13,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.label11.copyWith(fontSize: 10),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onTap,
    bool primary = false,
  }) {
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
      _verdictCard(r),
      const SizedBox(height: AppDimens.gapL),
      _itemsCard(r),
      const SizedBox(height: AppDimens.gapL),
      _pointsCard(r),
      const SizedBox(height: AppDimens.gapL),
      _footNote(r),
    ];
  }

  Widget _verdictCard(MarriageResult r) {
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
              Expanded(child: Text(r.modeName, style: AppText.cardTitle)),
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
          const SizedBox(height: AppDimens.gapM),
          Row(
            children: [
              Expanded(child: Text(r.a.label, style: AppText.medium13)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child:
                    AppIcon(AppIconKind.heart, size: 16, color: AppColors.body),
              ),
              Expanded(child: Text(r.b.label, style: AppText.medium13)),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          Text(r.plain, style: AppText.body12),
        ],
      ),
    );
  }

  Widget _itemsCard(MarriageResult r) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('逐项配对', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapS),
          const Text(
            '合婚看的是摩擦点与助力点：合处能不能解冲处，比单看一项更能说明问题。',
            style: AppText.label11,
          ),
          const SizedBox(height: AppDimens.gapM),
          ...r.items.map(_itemRow),
        ],
      ),
    );
  }

  Widget _itemRow(MarriageItem i) {
    final fg = AppColors.palaceFg(i.level);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.gapS),
      padding: const EdgeInsets.all(AppDimens.gapM),
      decoration: BoxDecoration(
        color: AppColors.palaceBg(i.level),
        borderRadius: BorderRadius.circular(AppDimens.rS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  i.label,
                  style: AppText.medium12.copyWith(color: AppColors.ink),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  i.relation,
                  style: AppText.medium11.copyWith(fontSize: 10, color: fg),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                i.scoreText,
                style: AppText.number12.copyWith(color: fg),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(i.detail, style: AppText.label11),
          const SizedBox(height: 2),
          Text(i.plain, style: AppText.body12),
        ],
      ),
    );
  }

  Widget _pointsCard(MarriageResult r) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('怎么看这一对', style: AppText.cardTitle),
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
                color: AppColors.goldSoftBg,
                borderRadius: BorderRadius.circular(AppDimens.rS),
              ),
              child: Text(
                r.advice,
                style: AppText.body12.copyWith(color: AppColors.goldDeep),
              ),
            ),
          ],
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
              Text('无法计算', style: AppText.cardTitle),
            ],
          ),
          const SizedBox(height: AppDimens.gapS),
          Text(err, style: AppText.body12),
        ],
      ),
    );
  }

  Widget _footNote(MarriageResult r) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AppIcon(AppIconKind.spark, size: 15, color: AppColors.body),
              SizedBox(width: 8),
              Text('三条务必知道的口径', style: AppText.smallTitle),
            ],
          ),
          const SizedBox(height: AppDimens.gapS),
          const Text(
            '1. 生肖一律按立春分界取年支：1、2 月出生的人按元旦算会整整差一年。',
            style: AppText.label11,
          ),
          const SizedBox(height: 4),
          const Text(
            '2. 生肖合婚只看年支，是粗筛；八字合婚再看日干、日支与喜用互补，'
            '逐项叠加而非单一判据定生死。',
            style: AppText.label11,
          ),
          const SizedBox(height: 4),
          const Text(
            '3. 合婚说的是「容易在哪儿卡住、又靠什么补回来」，不是判决书；'
            '能不能在一起从来不只由命盘决定。',
            style: AppText.label11,
          ),
          const SizedBox(height: 8),
          Text('规则版本 ${r.rulesVersion}', style: AppText.label11),
        ],
      ),
    );
  }
}

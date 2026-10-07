import 'package:flutter/material.dart';

import '../models/bazi.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// S4 · 命理档案
///
/// 四柱、五行占比、用神喜忌全部来自后端确定性排盘引擎（/api/v1/bazi）。
/// 出生信息由用户录入，页面内没有任何写死的示例命盘；
/// 未录入时展示录入表单，不会拿默认值冒充用户资料去排盘。
class BaziPage extends StatefulWidget {
  const BaziPage({
    super.key,
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.gender,
    this.longitude,
    this.name,
  });

  /// 出生年（公历）；为 null 表示尚未录入
  final int? year;
  final int? month;
  final int? day;

  /// 出生时刻（北京时间 24 小时制）
  final int? hour;
  final int? minute;

  /// 男 / 女
  final String? gender;

  /// 出生地东经度数，用于真太阳时校正
  final double? longitude;

  /// 姓名（可选）
  final String? name;

  @override
  State<BaziPage> createState() => _BaziPageState();
}

/// 一次排盘所需的出生信息
class _BirthInput {
  _BirthInput({
    required this.date,
    required this.time,
    required this.gender,
    required this.longitude,
    this.name = '',
  });

  final DateTime date;
  final TimeOfDay time;
  final String gender;
  final double longitude;
  final String name;
}

class _BaziPageState extends State<BaziPage> {
  final ApiClient _api = ApiClient();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();

  BaziProfile? _profile;
  String? _error;
  bool _loading = false;

  /// 已录入的出生信息；为 null 时展示录入表单
  _BirthInput? _input;

  DateTime? _date;
  TimeOfDay? _time;
  String _gender = '男';

  @override
  void initState() {
    super.initState();
    final w = widget;
    // 只有外部传入了完整档案才直接排盘，否则等用户录入
    if (w.year != null && w.month != null && w.day != null && w.hour != null) {
      _input = _BirthInput(
        date: DateTime(w.year!, w.month!, w.day!),
        time: TimeOfDay(hour: w.hour!, minute: w.minute ?? 0),
        gender: w.gender ?? '男',
        longitude: w.longitude ?? 120.0,
        name: w.name ?? '',
      );
      _load();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final input = _input;
    if (input == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _api.fetchBazi(
        year: input.date.year,
        month: input.date.month,
        day: input.date.day,
        hour: input.time.hour,
        minute: input.time.minute,
        gender: input.gender,
        longitude: input.longitude,
        name: input.name,
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    final lng = double.tryParse(_lngCtrl.text.trim());
    if (_date == null || _time == null) {
      setState(() => _error = '请先选择出生日期与时刻');
      return;
    }
    if (lng == null || lng < 73 || lng > 135) {
      setState(() => _error = '请填写出生地东经度数（73 ~ 135）');
      return;
    }
    setState(() {
      _error = null;
      _input = _BirthInput(
        date: _date!,
        time: _time!,
        gender: _gender,
        longitude: lng,
        name: _nameCtrl.text.trim(),
      );
      _profile = null;
    });
    _load();
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
              else if (_input == null)
                // 尚未录入出生信息：展示录入表单，不展示任何示例命盘
                _inputForm()
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

  // ------------------------------------------------------- 出生信息录入
  Widget _inputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadH, 4, AppDimens.pagePadH, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: AppDimens.gapL),
          Container(
            padding: const EdgeInsets.all(AppDimens.gapXL),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppDimens.rXL),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              boxShadow: cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('录入出生信息', style: AppText.cardTitle),
                const SizedBox(height: 6),
                Text(
                  '排盘需要公历出生时刻与出生地经度（用于真太阳时校正），不会用默认值代替。',
                  style: AppText.body12.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppDimens.gapL),
                _field(
                  '出生日期',
                  _date == null
                      ? '请选择'
                      : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
                  _pickDate,
                ),
                const SizedBox(height: AppDimens.gapM),
                _field(
                  '出生时刻',
                  _time == null ? '请选择' : _time!.format(context),
                  _pickTime,
                ),
                const SizedBox(height: AppDimens.gapL),
                const Text('性别', style: AppText.medium13),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _genderChip('男'),
                    const SizedBox(width: AppDimens.gapM),
                    _genderChip('女'),
                  ],
                ),
                const SizedBox(height: AppDimens.gapL),
                _textField('出生地东经度数（如北京 116.4）', _lngCtrl,
                    TextInputType.number),
                const SizedBox(height: AppDimens.gapM),
                _textField('姓名（可选）', _nameCtrl, TextInputType.text),
                if (_error != null) ...[
                  const SizedBox(height: AppDimens.gapM),
                  Text(
                    _error!,
                    style: AppText.body12.copyWith(color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.medium13),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(AppDimens.rS),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: AppText.medium13.copyWith(color: AppColors.body)),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderChip(String g) {
    final on = _gender == g;
    return GestureDetector(
      onTap: () => setState(() => _gender = g),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: on ? AppColors.primarySoft : AppColors.iconBg,
          borderRadius: BorderRadius.circular(AppDimens.rPill),
          border: Border.all(
              color: on ? AppColors.primary : AppColors.cardBorder),
        ),
        child: Text(
          g,
          style: AppText.medium13
              .copyWith(color: on ? AppColors.primary : AppColors.body),
        ),
      ),
    );
  }

  Widget _textField(
    String hint,
    TextEditingController ctrl,
    TextInputType type,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: AppText.medium13.copyWith(color: AppColors.body),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body12.copyWith(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.iconBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.rS),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.rS),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
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
    final hasProfile = _profile != null;
    return Container(
      height: AppDimens.bottomBarH,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadH, 14, AppDimens.pagePadH, 24),
      child: GestureDetector(
        onTap: () {
          if (hasProfile) {
            setState(() {
              _profile = null;
              _input = null;
              _error = null;
              _date = null;
              _time = null;
            });
          } else {
            _submit();
          }
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            hasProfile ? '重新录入出生信息' : '开始排盘',
            style: AppText.button14,
          ),
        ),
      ),
    );
  }
}

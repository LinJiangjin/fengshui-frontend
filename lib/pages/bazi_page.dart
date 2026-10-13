import 'dart:async';

import 'package:flutter/material.dart';

import '../data/china_geo.dart';
import '../models/bazi.dart';
import '../models/bazi_record.dart';
import '../models/ziwei.dart';
import '../services/api_client.dart';
import '../services/bazi_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/city_picker_sheet.dart';

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

class _BaziPageState extends State<BaziPage> {
  final ApiClient _api = ApiClient();
  final TextEditingController _nameCtrl = TextEditingController();

  /// 命理档案仓库：本地留存 + 服务端落库，用于回填「上次录入的信息」
  final BaziStore _store = BaziStore();

  BaziProfile? _profile;
  String? _error;
  bool _loading = false;

  /// 本次排盘用的出生信息；为 null 时展示录入表单
  BaziRecord? _input;

  /// 档案未能同步到服务端时的提示（此时命盘照常展示）
  String? _syncWarning;

  /// 紫微斗数命盘与解读（排盘成功后另行请求，失败不阻断八字展示）
  ZiweiChart? _ziwei;
  String? _ziweiError;

  /// 流年是否展开全部十年（默认只展示最近三年）
  bool _yearsExpanded = false;

  DateTime? _date;
  TimeOfDay? _time;
  String _gender = '男';

  /// 出生地：省名 + 城市坐标（用于回显「广东 · 广州」）
  String? _province;
  CityCoord? _city;

  /// 东经度数：选择出生地后自动带出，可手动微调
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    final w = widget;
    // 外部传入了完整出生信息（如从别处跳转进来）：直接排盘
    if (w.year != null && w.month != null && w.day != null && w.hour != null) {
      _longitude = w.longitude;
      _input = BaziRecord(
        year: w.year!,
        month: w.month!,
        day: w.day!,
        hour: w.hour!,
        minute: w.minute ?? 0,
        gender: w.gender ?? '男',
        longitude: w.longitude ?? 120.0,
        name: w.name ?? '',
      );
      _load();
      return;
    }
    // 否则先看有没有录入过的档案：有就回填并直接出盘，没有才展示空表单
    unawaited(_restoreFromStore());
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _store.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  /// 回填上次录入的出生信息；档案存在时直接排盘
  Future<void> _restoreFromStore() async {
    await _store.init();
    if (!mounted) return;
    final record = _store.record;
    if (record == null) return;
    setState(() {
      _applyRecord(record);
      _input = record;
    });
    await _load();
  }

  /// 把档案回填到表单字段（重新录入时可在原值上微调）
  void _applyRecord(BaziRecord record) {
    _date = record.date;
    _time = record.time;
    _gender = record.gender;
    _longitude = record.longitude;
    _nameCtrl.text = record.name;
    _province = record.province.isEmpty ? null : record.province;

    final found = (_province == null || record.city.isEmpty)
        ? null
        : ChinaGeo.find(_province!, record.city);
    // 字典里查不到（或档案只存了经度）时，用档案里的经度兜底展示
    _city = found ??
        (record.city.isEmpty
            ? null
            : CityCoord(record.city, record.longitude, 0));
  }

  Future<void> _load() async {
    final input = _input;
    if (input == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _syncWarning = null;
    });
    try {
      final profile = await _api.fetchBazi(
        year: input.year,
        month: input.month,
        day: input.day,
        hour: input.hour,
        minute: input.minute,
        gender: input.gender,
        longitude: input.longitude,
        name: input.name,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
      // 排盘成功后把出生信息落库；失败只提示，不影响已展示的命盘
      unawaited(_persist(input));
      // 同一份出生信息再排一张紫微盘（独立请求，失败只在该卡片内提示）
      unawaited(_loadZiwei(input));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// 排紫微命盘（感情 / 职业 / 运势），失败只在紫微卡片内提示
  Future<void> _loadZiwei(BaziRecord input) async {
    if (mounted) setState(() => _ziweiError = null);
    try {
      final chart = await _api.fetchZiwei(
        year: input.year,
        month: input.month,
        day: input.day,
        hour: input.hour,
        minute: input.minute,
        gender: input.gender,
        longitude: input.longitude,
        name: input.name,
      );
      if (!mounted) return;
      setState(() {
        _ziwei = chart;
        _ziweiError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _ziweiError = e.toString());
    }
  }

  /// 把本次录入的出生信息写入本地与服务端
  Future<void> _persist(BaziRecord input) async {
    try {
      await _store.save(input);
      if (mounted) setState(() => _syncWarning = null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _syncWarning = '已排盘，但档案未能同步到服务器：$e');
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
    final lng = _longitude;
    if (_date == null || _time == null) {
      setState(() => _error = '请先选择出生日期与时刻');
      return;
    }
    if (lng == null || !ChinaGeo.isValidLongitude(lng)) {
      setState(() => _error = '请选择出生地，自动获取东经度数（73 ~ 135）');
      return;
    }
    setState(() {
      _error = null;
      _input = BaziRecord.fromDateTime(
        date: _date!,
        time: _time!,
        gender: _gender,
        longitude: lng,
        name: _nameCtrl.text.trim(),
        province: _province ?? '',
        city: _city?.name ?? '',
      );
      _profile = null;
    });
    _load();
  }

  /// 选择出生地：点选城市后自动带出东经度数
  Future<void> _pickBirthPlace() async {
    final picked = await showModalBottomSheet<CityPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CityPickerSheet(
        selectedProvince: _province,
        selectedCity: _city?.name,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _province = picked.province;
      _city = picked.city;
      _longitude = picked.city.longitude;
      _error = null;
    });
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          '已自动获取 ${ChinaGeo.formatLongitude(picked.city.longitude)}'
          '（${picked.province} · ${picked.city.name}）',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 手动微调经度：出生地靠近行政区边界时使用
  Future<void> _editLongitude() async {
    final ctrl =
        TextEditingController(text: _longitude?.toStringAsFixed(2) ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('手动填写东经度数', style: AppText.cardTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppText.medium13,
          decoration: const InputDecoration(hintText: '如 116.4'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: AppText.medium13),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定', style: AppText.medium13),
          ),
        ],
      ),
    );
    final value = double.tryParse(ctrl.text.trim());
    ctrl.dispose();
    if (ok != true || !mounted) return;
    if (value == null || !ChinaGeo.isValidLongitude(value)) {
      setState(() => _error = '东经度数需在 73 ~ 135 之间');
      return;
    }
    setState(() {
      _longitude = value;
      _error = null;
    });
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
                      const SizedBox(height: AppDimens.gapL),
                      _ziweiCard(),
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
                  '排盘需要公历出生时刻与出生地（自动换算东经度数做真太阳时校正），不会用默认值代替。',
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
                _field('出生地', _placeText, _pickBirthPlace),
                const SizedBox(height: AppDimens.gapM),
                _lngRow(),
                const SizedBox(height: AppDimens.gapM),
                _textField('姓名（可选）', _nameCtrl, TextInputType.text),
                if (_error != null) ...[
                  const SizedBox(height: AppDimens.gapM),
                  Text(
                    _error!,
                    style: AppText.body12.copyWith(color: AppColors.danger),
                  ),
                ],
                if (_syncWarning != null) ...[
                  const SizedBox(height: AppDimens.gapM),
                  Text(
                    _syncWarning!,
                    style: AppText.body12.copyWith(color: AppColors.goldDeep),
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

  /// 出生地回显文案
  String get _placeText {
    final city = _city;
    if (city == null) return '请选择省 / 市';
    return '$_province · ${city.name}';
  }

  /// 经度行：展示自动带出的东经度数，并保留手动微调入口
  Widget _lngRow() {
    final lng = _longitude;
    return Row(
      children: [
        Expanded(
          child: Text(
            lng == null
                ? '选择出生地后自动获取东经度数'
                : '自动获取：${ChinaGeo.formatLongitude(lng)}（真太阳时校正）',
            style: AppText.label11,
          ),
        ),
        if (lng != null)
          GestureDetector(
            onTap: _editLongitude,
            child: Text(
              '手动微调',
              style: AppText.medium12.copyWith(color: AppColors.primary),
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

  /// Tab 页内置页头：只保留标题，不再放返回 / 编辑图标
  Widget _header() {
    return const Center(
      child: Text('命理档案', style: AppText.pageTitle),
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

  // ------------------------------------------------------- 紫微斗数
  /// 紫微斗数：十二宫速览 + 感情 / 职业 / 运势三块解读
  Widget _ziweiCard() {
    final chart = _ziwei;
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('紫微斗数', style: AppText.cardTitle),
              const SizedBox(width: AppDimens.gapM),
              Expanded(
                child: Text(
                  chart?.headline ?? '按出生信息排十二宫命盘',
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          if (chart == null)
            _ziweiStatus()
          else ...[
            Text(
              chart.basic.summary,
              style: AppText.body12.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppDimens.gapL),
            _palaceGrid(chart.palaces),
            const SizedBox(height: AppDimens.gapL),
            _ziweiSection(chart.love),
            const SizedBox(height: AppDimens.gapL),
            _ziweiSection(chart.career),
            if (chart.career.wealth != null) ...[
              const SizedBox(height: AppDimens.gapM),
              _ziweiSubBlock(chart.career.wealth!),
            ],
            const SizedBox(height: AppDimens.gapL),
            _ziweiSection(chart.fortune),
            if (chart.fortune.daXian != null) ...[
              const SizedBox(height: AppDimens.gapM),
              _ziweiDaXianBlock(chart.fortune.daXian!),
            ],
            if (chart.years.isNotEmpty) ...[
              const SizedBox(height: AppDimens.gapL),
              _ziweiYears(chart.years),
            ],
          ],
        ],
      ),
    );
  }

  /// 紫微卡片内的加载中 / 失败态
  Widget _ziweiStatus() {
    final err = _ziweiError;
    if (err != null) {
      return Text(
        '紫微命盘加载失败：$err',
        style: AppText.body12.copyWith(color: AppColors.danger),
      );
    }
    return const Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: AppDimens.gapS),
        Text('正在排紫微命盘…', style: AppText.label11),
      ],
    );
  }

  /// 十二宫速览：命宫高亮，身宫标「身」，空宫显示「空宫」
  Widget _palaceGrid(List<ZiweiPalace> palaces) {
    return Wrap(
      spacing: AppDimens.gapS,
      runSpacing: AppDimens.gapS,
      children: palaces.map(_palaceBox).toList(),
    );
  }

  Widget _palaceBox(ZiweiPalace p) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: p.isMing ? AppColors.primarySoft : AppColors.iconBg,
        borderRadius: BorderRadius.circular(AppDimens.rS),
        border: Border.all(
          color: p.isMing ? AppColors.primary : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                p.name,
                style: AppText.label11.copyWith(
                  color: p.isMing ? AppColors.primary : AppColors.muted,
                ),
              ),
              if (p.isShen) ...[
                const SizedBox(width: 2),
                Text(
                  '身',
                  style: AppText.label11.copyWith(color: AppColors.goldDeep),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            p.starText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.medium12
                .copyWith(color: p.isMing ? AppColors.primary : AppColors.ink),
          ),
          if (p.siHua.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              p.siHua.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label11.copyWith(color: AppColors.goldDeep),
            ),
          ],
        ],
      ),
    );
  }

  /// 一段解读：标题 + 宫位信息 + 逐条结论
  Widget _ziweiSection(ZiweiSection s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(s.title, style: AppText.smallTitle)),
            const SizedBox(width: AppDimens.gapS),
            Text(s.caption, style: AppText.label11),
          ],
        ),
        const SizedBox(height: AppDimens.gapS),
        ...s.points.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.gapXS),
            child: Text(p, style: AppText.body12),
          ),
        ),
      ],
    );
  }

  /// 财帛宫（职业区块的补充）
  Widget _ziweiSubBlock(ZiweiSection s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.gapM),
      decoration: BoxDecoration(
        color: AppColors.primarySoftBg,
        borderRadius: BorderRadius.circular(AppDimens.rS),
      ),
      child: _ziweiSection(s),
    );
  }

  /// 当前十年大限（运势区块的补充）
  Widget _ziweiDaXianBlock(ZiweiDaXian d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.gapM),
      decoration: BoxDecoration(
        color: AppColors.goldSoftBg,
        borderRadius: BorderRadius.circular(AppDimens.rS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text('当前大限 · 十年运', style: AppText.smallTitle),
              ),
              const SizedBox(width: AppDimens.gapS),
              Expanded(
                child: Text(
                  d.caption,
                  textAlign: TextAlign.right,
                  style: AppText.label11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapS),
          ...d.points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.gapXS),
              child: Text(p, style: AppText.body12),
            ),
          ),
        ],
      ),
    );
  }

  /// 流年运势：默认展示最近三年，其余折叠
  Widget _ziweiYears(List<ZiweiYear> years) {
    final shown = _yearsExpanded ? years : years.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('流年运势 · 逐年', style: AppText.smallTitle),
        const SizedBox(height: AppDimens.gapS),
        ...shown.map(_yearBlock),
        if (years.length > 3) ...[
          const SizedBox(height: AppDimens.gapS),
          GestureDetector(
            onTap: () => setState(() => _yearsExpanded = !_yearsExpanded),
            child: Row(
              children: [
                Text(
                  _yearsExpanded ? '收起' : '展开其余 ${years.length - 3} 年',
                  style: AppText.medium12.copyWith(color: AppColors.primary),
                ),
                const SizedBox(width: 4),
                Icon(
                  _yearsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _yearBlock(ZiweiYear y) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimens.gapS),
      padding: const EdgeInsets.all(AppDimens.gapM),
      decoration: BoxDecoration(
        color: AppColors.iconBg,
        borderRadius: BorderRadius.circular(AppDimens.rS),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${y.year}', style: AppText.medium13),
              const SizedBox(width: AppDimens.gapS),
              Text('${y.ganZhi}年', style: AppText.label11),
              const Spacer(),
              _stanceChip(y.stance),
            ],
          ),
          const SizedBox(height: 4),
          Text(y.caption, style: AppText.label11),
          if (y.focus.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('重点：$y.focus', style: AppText.label11),
          ],
          const SizedBox(height: AppDimens.gapS),
          ...y.points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.gapXS),
              child: Text(p, style: AppText.body12),
            ),
          ),
        ],
      ),
    );
  }

  /// 宜主动（主色）/ 稳中求进（黄铜）/ 宜守成（朱砂）
  Widget _stanceChip(String stance) {
    final guard = stance == '宜守成';
    final act = stance == '宜主动';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: guard
            ? AppColors.dangerSoftBg
            : (act ? AppColors.primarySoft : AppColors.goldSoftBg),
        borderRadius: BorderRadius.circular(AppDimens.rPill),
      ),
      child: Text(
        stance,
        style: AppText.medium11.copyWith(
          color: guard
              ? AppColors.dangerDeep
              : (act ? AppColors.primary : AppColors.goldDeep),
        ),
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
            // 回到录入表单，并保留这次已录入的出生信息供用户微调
            setState(() {
              _profile = null;
              _input = null;
              _error = null;
              _syncWarning = null;
              _ziwei = null;
              _ziweiError = null;
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

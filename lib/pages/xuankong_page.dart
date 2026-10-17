import 'package:flutter/material.dart';

import '../models/diagnosis.dart' show Extreme;
import '../models/house.dart';
import '../models/palace_grid.dart';
import '../models/xuankong.dart';
import '../services/api_client.dart';
import '../services/auth_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// S9 · 玄空飞星
///
/// 与其它页面的分工（三套体系，回答三个不同的问题）：
/// * 八宅回答「人与宅合不合、房间该落在哪一宫」——装修落地最常用；
/// * 黄历回答「**什么时候**」——哪天宜动工、宜入宅；
/// * 玄空回答「**特定时段的方位吉凶**」——本月哪个方位旺、这套房在当运
///   是旺山旺向还是上山下水。
///
/// 页面分两个模式：
/// * **月盘**：按当前日期所在**节气月**起飞星（月白），逐宫与流年星叠看。
///   只需日期，不依赖房屋与命理档案。
/// * **宅运盘**：山星 / 运星 / 向星三盘叠加，判格局（旺山旺向 / 双星会向 /
///   双星会坐 / 上山下水 …）、给逐宫吉凶与用途。
///
/// 全部数值——入中之数、顺逆、到山到向、格局、逐宫旺衰——都由服务端确定性
/// 引擎算出（引擎已与《四十八局旺山旺向》整表对拍），客户端**不做飞星推算**，
/// 也不内置结果快照。顺逆的判据由后端一并下发，本页原样展示，便于追溯。
class XuankongPage extends StatefulWidget {
  const XuankongPage({super.key, this.house, this.onOpenCompass});

  /// 当前房屋；已实测坐向时直接作为宅运盘的坐向来源（更准，且能提示兼向）
  final HouseProfile? house;

  /// 未实测坐向时跳到罗盘页测量（由外层切换 tab）
  final VoidCallback? onOpenCompass;

  @override
  State<XuankongPage> createState() => _XuankongPageState();
}

enum _Mode { month, house }

class _XuankongPageState extends State<XuankongPage> {
  final ApiClient _api = ApiClient();

  _Mode _mode = _Mode.month;

  // ------------------------------------------------------------------ 月盘
  XuankongMonth? _month;
  late DateTime _cursor;
  bool _monthLoading = true;
  String? _monthError;

  // ---------------------------------------------------------------- 宅运盘
  XuankongHouse? _house;
  bool _houseLoading = false;
  String? _houseError;

  /// 是否用房屋的罗盘实测值起盘；为假时按 [_sitTrigram] 的天元龙起盘
  bool _useCompass = false;

  /// 坐山卦（只知卦不知度数时的退路）
  String _sitTrigram = '坎';

  /// 立宅 / 入宅年份，用于自动定元运
  int _buildYear = DateTime.now().year;

  /// 宅运盘是否已经请求过一次（切到该模式时才发首个请求）
  bool _houseTouched = false;

  /// 只知卦时可选坐山：中宫无卦，故为八卦
  static const _trigrams = ['坎', '艮', '震', '巽', '离', '坤', '兑', '乾'];

  static const _levelRank = {'旺': 0, '平': 1, '煞': 2, '大凶': 3};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _cursor = DateTime(now.year, now.month, now.day);
    _useCompass = widget.house?.measured ?? false;
    _loadMonth();
  }

  // ---------------------------------------------------------------- 数据
  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool get _isToday {
    final now = DateTime.now();
    return _cursor.year == now.year &&
        _cursor.month == now.month &&
        _cursor.day == now.day;
  }

  /// token 失效统一走全局登出，AuthGate 会自动切回登录页
  Future<bool> _handleApiError(ApiException e) async {
    if (!e.isUnauthorized) return false;
    await AuthStore.instance?.forceLogout();
    return true;
  }

  Future<void> _loadMonth() async {
    setState(() {
      _monthLoading = true;
      _monthError = null;
    });
    try {
      final m = await _api.fetchXuankongMonth(date: _ymd(_cursor));
      if (!mounted) return;
      setState(() {
        _month = m;
        _monthLoading = false;
      });
    } on ApiException catch (e) {
      if (await _handleApiError(e)) return;
      if (!mounted) return;
      setState(() {
        _monthError = e.message;
        _monthLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _monthError = e.toString();
        _monthLoading = false;
      });
    }
  }

  void _shiftDay(int delta) {
    setState(() => _cursor = _cursor.add(Duration(days: delta)));
    _loadMonth();
  }

  /// 回到今天：月盘按日期推进，走远了要能一键回来
  void _jumpToToday() {
    final now = DateTime.now();
    setState(() => _cursor = DateTime(now.year, now.month, now.day));
    _loadMonth();
  }

  /// 宅运盘入参两边各取一：坐向（罗盘度数 / 坐山卦）与元运（建宅年份）。
  /// 两边都不会替用户兜底——缺坐向、缺年份都发不出请求，后端也会返回 400。
  Future<void> _loadHouse() async {
    _houseTouched = true;
    final h = widget.house;
    final useCompass = _useCompass && (h?.measured ?? false);

    setState(() {
      _houseLoading = true;
      _houseError = null;
    });
    try {
      final chart = await _api.fetchXuankongHouse(
        degree: useCompass ? h!.degree : null,
        declination: useCompass ? h!.declination : 0.0,
        trigram: useCompass ? '' : _sitTrigram,
        buildYear: _buildYear,
        name: useCompass ? h!.displayName : '',
      );
      if (!mounted) return;
      setState(() {
        _house = chart;
        _houseLoading = false;
      });
    } on ApiException catch (e) {
      if (await _handleApiError(e)) return;
      if (!mounted) return;
      setState(() {
        _houseError = e.message;
        _houseLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _houseError = e.toString();
        _houseLoading = false;
      });
    }
  }

  void _switchMode(_Mode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    if (mode == _Mode.house && !_houseTouched) _loadHouse();
  }

  /// 当前房屋是否可用作坐向来源
  bool get _canUseCompass => widget.house?.measured ?? false;

  void _pickCompass(bool on) {
    if (!on && !_canUseCompass) return;
    if (_useCompass == on) return;
    setState(() => _useCompass = on);
    _loadHouse();
  }

  void _pickTrigram(String tri) {
    if (tri == _sitTrigram) return;
    setState(() {
      _sitTrigram = tri;
      _useCompass = false;
    });
    _loadHouse();
  }

  void _shiftBuildYear(int delta) {
    final next = (_buildYear + delta).clamp(1864, 2100);
    if (next == _buildYear) return;
    setState(() => _buildYear = next);
    _loadHouse();
  }

  // ---------------------------------------------------------------- 九宫映射
  /// 方位 -> 宫。月盘与宅运盘共用同一套方位键（含中宫），因此映射方式一致。
  List<T?> _cells<T>(List<T> palaces, String Function(T) direction) {
    final map = <String, T>{for (final p in palaces) direction(p): p};
    return [for (final d in PalaceGrid.fixedOrder) map[d]];
  }

  // ---------------------------------------------------------------- 骨架
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              color: AppColors.bg,
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.pagePadH, 4, AppDimens.pagePadH, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context),
                  const SizedBox(height: AppDimens.gapL),
                  _modeSwitch(),
                  const SizedBox(height: AppDimens.gapL),
                  if (_mode == _Mode.month) ..._monthBody() else ..._houseBody(),
                  const SizedBox(height: AppDimens.gapL),
                  _footNote(),
                ],
              ),
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
        const Text('玄空飞星', style: AppText.pageTitle),
        // 占位：与左侧返回图标等宽，保证标题居中
        const Padding(
          padding: EdgeInsets.all(6),
          child: AppIcon(AppIconKind.flyingStar,
              size: 20, color: AppColors.ink),
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
          item(_Mode.month, '月盘'),
          item(_Mode.house, '宅运盘'),
        ],
      ),
    );
  }

  // ================================================================ 月盘
  List<Widget> _monthBody() {
    if (_monthLoading) {
      return const [
        SizedBox(height: 140),
        Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ];
    }
    final err = _monthError;
    if (err != null) {
      return [
        _placeholder(
          icon: Icons.cloud_off,
          title: '无法获取月盘',
          desc: err,
          buttonText: '重试',
          onTap: _loadMonth,
        ),
      ];
    }
    final m = _month;
    if (m == null) return const [];

    return [
      _monthDateBar(m),
      const SizedBox(height: AppDimens.gapL),
      _monthOverviewCard(m),
      const SizedBox(height: AppDimens.gapL),
      _monthGridCard(m),
      const SizedBox(height: AppDimens.gapL),
      _stackCard(m),
      const SizedBox(height: AppDimens.gapL),
      _keyPointsCard(m.keyPoints),
    ];
  }

  Widget _monthDateBar(XuankongMonth m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: appCard(radius: AppDimens.rL),
      child: Row(
        children: [
          _navArrow(Icons.chevron_left_rounded, () => _shiftDay(-1)),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isToday ? null : _jumpToToday,
              child: Column(
                children: [
                  // 节气月与「节」是一体的（九月 ⟺ 寒露起），写在一起才不会被误读成公历月
                  Text(
                    '${m.year}年 ${m.monthName}（${m.jieqi}起）',
                    style: AppText.cardTitle,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '公历 ${m.date} · 节气月序 ${m.monthIndex} · 年支 ${m.branch}',
                    style: AppText.label11,
                  ),
                  if (!_isToday) ...[
                    const SizedBox(height: 4),
                    Text(
                      '点此回到今天',
                      style: AppText.label11.copyWith(color: AppColors.primary),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _navArrow(Icons.chevron_right_rounded, () => _shiftDay(1)),
        ],
      ),
    );
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.iconBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.iconBorder),
        ),
        child: Icon(icon, size: 20, color: AppColors.inkSoft),
      ),
    );
  }

  /// 月盘概览：入中之星、流年入中之星、以及本月最旺 / 最需避忌之宫
  Widget _monthOverviewCard(XuankongMonth m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _centerBox('月星入中', m.centerStar, m.centerStarName),
              const SizedBox(width: 8),
              _centerBox('流年入中', m.yearCenterStar, m.yearCenterStarName),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _spotBox('本月最旺之宫', m.best, good: true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _spotBox('本月最需避忌', m.worst, good: false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.goldSoftBg,
              borderRadius: BorderRadius.circular(AppDimens.rM),
              border: Border.all(color: AppColors.tipBorder),
            ),
            child: Text(
              '月白口诀：${m.jieqiMnemonic}',
              style: AppText.label11.copyWith(color: AppColors.goldDeep),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerBox(String label, int star, String starName) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.iconBg,
          borderRadius: BorderRadius.circular(AppDimens.rL),
          border: Border.all(color: AppColors.iconBorder),
        ),
        child: Column(
          children: [
            Text(label, style: AppText.medium11.copyWith(fontSize: 10)),
            const SizedBox(height: 4),
            Text('$star', style: AppText.degree.copyWith(fontSize: 26)),
            const SizedBox(height: 2),
            Text(starName, style: AppText.smallTitle),
          ],
        ),
      ),
    );
  }

  Widget _spotBox(String label, Extreme? spot, {required bool good}) {
    final Color fg = good ? AppColors.primary : AppColors.danger;
    final Color bg = good ? AppColors.primarySoftBg : AppColors.dangerSoftBg;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.rM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label11.copyWith(color: fg)),
          const SizedBox(height: 6),
          Text(
            spot?.title.isNotEmpty == true
                ? spot!.title
                : (spot?.direction ?? '—'),
            style: AppText.medium13.copyWith(color: fg),
          ),
          const SizedBox(height: 3),
          Text(
            spot == null ? '' : '${spot.level} · ${spot.label}',
            style: AppText.label11.copyWith(color: fg),
          ),
          const SizedBox(height: 4),
          Text(spot?.note ?? '', style: AppText.label11),
        ],
      ),
    );
  }

  /// 月盘九宫：底色看月星自身吉凶，角标给出与同宫流年星的复合结论
  Widget _monthGridCard(XuankongMonth m) {
    final cells = _cells<XuankongMonthPalace>(m.palaces, (p) => p.direction);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('月盘九宫', style: AppText.cardTitle),
              Text('上南下北 · ${m.monthName}', style: AppText.label11),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '格内大字为月星，右上角小字为该宫流年星；底色是月星自身吉凶，'
            '右侧标签是月星与流年星同宫的复合结论。',
            style: AppText.label11,
          ),
          const SizedBox(height: AppDimens.gapM),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: [
              for (final c in cells)
                c == null ? _emptyCell() : _monthCell(c),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          _levelLegend(),
        ],
      ),
    );
  }

  Widget _monthCell(XuankongMonthPalace p) {
    final fg = AppColors.palaceFg(p.level);
    final stackFg = AppColors.palaceFg(p.stack.level);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.palaceBg(p.level),
        borderRadius: BorderRadius.circular(AppDimens.rS),
        border: Border.all(
          color: AppColors.palaceBorder(p.level) ?? AppColors.cardBorder,
          width: p.level == '大凶' ? 1.6 : 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${p.direction} · ${p.trigram}',
                  style: AppText.label11
                      .copyWith(fontSize: 10, color: AppColors.body),
                ),
                const SizedBox(height: 3),
                Text(
                  '${p.star}',
                  style: AppText.value17.copyWith(color: fg, fontSize: 19),
                ),
                const SizedBox(height: 1),
                Text(
                  p.starName,
                  style: AppText.label11.copyWith(color: fg, fontSize: 10),
                ),
              ],
            ),
          ),
          // 同宫流年星
          Positioned(
            top: 4,
            right: 5,
            child: Text(
              '流年${p.yearStar}',
              style: AppText.label11
                  .copyWith(fontSize: 9, color: AppColors.muted),
            ),
          ),
          // 月星与流年星同数同宫：两盘共振
          if (p.stacked)
            Positioned(
              top: 4,
              left: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: stackFg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '同宫',
                  style: AppText.medium11
                      .copyWith(color: Colors.white, fontSize: 8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 逐宫叠断：一眼看出哪几宫月星与流年星同宫后转凶
  Widget _stackCard(XuankongMonth m) {
    final outer = m.palaces.where((p) => !p.isCenter).toList()
      ..sort((a, b) => (_levelRank[b.stack.level] ?? 9)
          .compareTo(_levelRank[a.stack.level] ?? 9));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('月星 × 流年星 同宫叠断', style: AppText.cardTitle),
              Text('${m.centerStarName} 叠 ${m.yearCenterStarName}',
                  style: AppText.label11),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '两盘皆顺飞，因此「同数同宫」只可能出现在两盘入中之数相同时。',
            style: AppText.label11,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in outer) _stackChip(c)],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          for (final c in outer.take(3)) _stackRow(c),
        ],
      ),
    );
  }

  Widget _stackChip(XuankongMonthPalace p) {
    final fg = AppColors.palaceFg(p.stack.level);
    final bg = AppColors.palaceBg(p.stack.level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        '${p.direction} ${p.stack.key}',
        style: AppText.label12.copyWith(color: fg),
      ),
    );
  }

  Widget _stackRow(XuankongMonthPalace p) {
    final fg = AppColors.palaceFg(p.stack.level);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 13,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: fg,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.direction} · ${p.starName} + ${p.yearStarName} → ${p.stack.key}',
                  style: AppText.medium12.copyWith(color: fg),
                ),
                const SizedBox(height: 2),
                Text(p.stack.note, style: AppText.label11),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================ 宅运盘
  List<Widget> _houseBody() {
    return [
      _houseInputCard(),
      const SizedBox(height: AppDimens.gapL),
      ..._houseResult(),
    ];
  }

  /// 入参卡：坐向来源（罗盘实测 / 坐山卦）+ 立宅年份（定元运）
  Widget _houseInputCard() {
    final h = widget.house;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('坐向', style: AppText.cardTitle),
              if (h != null)
                Text(h.displayName, style: AppText.label11),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _optionTile(
                  title: '罗盘实测',
                  sub: _canUseCompass
                      ? '${h!.degree!.toStringAsFixed(1)}° '
                          '（磁偏 ${h.declination.toStringAsFixed(1)}°）'
                      : '尚未测量坐向',
                  active: _useCompass && _canUseCompass,
                  enabled: _canUseCompass,
                  onTap: () => _pickCompass(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _optionTile(
                  title: '只知坐山卦',
                  sub: '按卦取天元龙起盘',
                  active: !_useCompass || !_canUseCompass,
                  enabled: true,
                  onTap: () => _pickCompass(false),
                ),
              ),
            ],
          ),
          if (!_canUseCompass) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.goldSoftBg,
                borderRadius: BorderRadius.circular(AppDimens.rM),
                border: Border.all(color: AppColors.tipBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前按「$_sitTrigram卦」的天元龙起盘，精度有限。'
                    '用罗盘实测坐向更准，还能提示是否已属兼向。',
                    style:
                        AppText.label11.copyWith(color: AppColors.goldDeep),
                  ),
                  if (widget.onOpenCompass != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onOpenCompass,
                      child: Text(
                        '去测量坐向 ›',
                        style: AppText.medium12
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tri in _trigrams)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pickTrigram(tri),
                    child: Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (!_useCompass && _sitTrigram == tri)
                            ? AppColors.primary
                            : AppColors.btnSecondary,
                        borderRadius: BorderRadius.circular(AppDimens.rS),
                      ),
                      child: Text(
                        tri,
                        style: AppText.medium12.copyWith(
                          color: (!_useCompass && _sitTrigram == tri)
                              ? Colors.white
                              : AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          const Text('立宅元运', style: AppText.cardTitle),
          const SizedBox(height: 8),
          Row(
            children: [
              _navArrow(Icons.remove_rounded, () => _shiftBuildYear(-1)),
              Expanded(
                child: Column(
                  children: [
                    Text('$_buildYear 年', style: AppText.cardTitle),
                    const SizedBox(height: 2),
                    const Text(
                      '按建宅 / 入宅年份自动定运（三元九运每运二十年）',
                      style: AppText.label11,
                    ),
                  ],
                ),
              ),
              _navArrow(Icons.add_rounded, () => _shiftBuildYear(1)),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _buildYear == DateTime.now().year
                ? null
                : () {
                    setState(() => _buildYear = DateTime.now().year);
                    _loadHouse();
                  },
            child: Text(
              '按当年元运（${DateTime.now().year} 年）',
              style: AppText.label11.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionTile({
    required String title,
    required String sub,
    required bool active,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final fg = !enabled
        ? AppColors.muted
        : (active ? AppColors.primary : AppColors.inkSoft);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active && enabled
              ? AppColors.primarySoft
              : AppColors.btnSecondary.withValues(alpha: enabled ? 1 : 0.5),
          borderRadius: BorderRadius.circular(AppDimens.rM),
          border: Border.all(
            color: active && enabled
                ? AppColors.primarySoftBorder
                : AppColors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.medium12.copyWith(color: fg)),
            const SizedBox(height: 2),
            Text(sub, style: AppText.label11),
          ],
        ),
      ),
    );
  }

  List<Widget> _houseResult() {
    if (_houseLoading) {
      return const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ];
    }
    final err = _houseError;
    if (err != null) {
      return [
        _placeholder(
          icon: Icons.cloud_off,
          title: '无法获取宅运盘',
          desc: err,
          buttonText: '重试',
          onTap: _loadHouse,
        ),
      ];
    }
    final chart = _house;
    if (chart == null) {
      return [
        _placeholder(
          icon: Icons.grid_view_rounded,
          title: '尚未取得宅运盘',
          desc: '请选择坐向与立宅年份后重试。',
          buttonText: '重试',
          onTap: _loadHouse,
        ),
      ];
    }

    return [
      _houseTitleCard(chart),
      const SizedBox(height: AppDimens.gapL),
      if (chart.jianxiang) ...[
        _warnBanner(
          '坐向偏离该山中心较多，已属兼向；本盘按正针下卦起星，'
          '替卦须另定，结论仅作参考。',
        ),
        const SizedBox(height: AppDimens.gapL),
      ],
      _yunCard(chart),
      const SizedBox(height: AppDimens.gapL),
      _centerCard(chart),
      const SizedBox(height: AppDimens.gapL),
      _houseGridCard(chart),
      const SizedBox(height: AppDimens.gapL),
      _patternCard(chart),
      const SizedBox(height: AppDimens.gapL),
      _palaceListCard(chart),
      const SizedBox(height: AppDimens.gapL),
      _rolesCard(chart),
      const SizedBox(height: AppDimens.gapL),
      _keyPointsCard(chart.keyPoints),
    ];
  }

  /// 坐向 + 综合评分
  Widget _houseTitleCard(XuankongHouse chart) {
    final fg = AppColors.palaceFg(chart.levelKey);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.palaceBg(chart.levelKey),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${chart.score}',
                    style: AppText.value17.copyWith(color: fg, fontSize: 20)),
                Text(chart.level,
                    style: AppText.label11.copyWith(color: fg, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chart.title.isNotEmpty
                        ? chart.title
                        : '${chart.sitFaceTitle} 宅运盘',
                    style: AppText.cardTitle),
                const SizedBox(height: 5),
                Text(
                  '坐 ${_sideText(chart.sit)}  ·  向 ${_sideText(chart.face)}',
                  style: AppText.label11,
                ),
                const SizedBox(height: 4),
                const Text(
                  '综合评分含格局分与逐宫旺衰分，仅供横向比较，'
                  '格局本身才是判断的主线。',
                  style: AppText.label11,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 坐 / 向的展示文案：优先后端给的「山（元龙 · 阴阳）」标签，退到山名
  String _sideText(XuankongSide? side) {
    if (side == null || side.mountain.isEmpty) return '—';
    return side.label.isNotEmpty ? side.label : side.mountain;
  }

  Widget _warnBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dangerSoftBg,
        borderRadius: BorderRadius.circular(AppDimens.rM),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(AppIconKind.warn, size: 16, color: AppColors.dangerDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style:
                    AppText.label11.copyWith(color: AppColors.dangerDeep)),
          ),
        ],
      ),
    );
  }

  Widget _yunCard(XuankongHouse chart) {
    final y = chart.yun;
    if (y == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('元运', style: AppText.cardTitle),
              Text(y.yearRange, style: AppText.label11),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCell('元运', y.name, sub: y.yuan),
              const SizedBox(width: 8),
              _statCell('当运旺星', y.starName, sub: '五行属${y.element}'),
              const SizedBox(width: 8),
              _statCell(
                '运之来源',
                y.source == 'explicit'
                    ? '手动指定'
                    : (y.source == 'build_year' ? '建宅年份' : '当年'),
                sub: y.source == 'build_year' ? '$_buildYear 年' : '',
              ),
            ],
          ),
          if (y.summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(y.summary,
                style: AppText.body12.copyWith(color: AppColors.inkSoft)),
          ],
        ],
      ),
    );
  }

  Widget _statCell(String label, String value, {String sub = ''}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.iconBg,
          borderRadius: BorderRadius.circular(AppDimens.rM),
          border: Border.all(color: AppColors.iconBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.label11.copyWith(fontSize: 10)),
            const SizedBox(height: 3),
            Text(value, style: AppText.medium13),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sub, style: AppText.label11.copyWith(fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }

  /// 中宫：山星 / 向星的入中之数与顺逆判据。
  ///
  /// 这一段是玄空里最容易记错的地方（顺逆看的是「入中之数在元旦盘对应宫里、
  /// 与本节同一元龙那一山」的阴阳，而不是本山自己的阴阳），所以把后端给出的
  /// 依据原样透出来，用户可自行复核。
  Widget _centerCard(XuankongHouse chart) {
    final c = chart.center;
    if (c == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('中宫起星', style: AppText.cardTitle),
          const SizedBox(height: 6),
          const Text(
            '运盘恒顺飞；山星入中之数取运盘在坐山宫之数，向星取运盘在向首宫之数。',
            style: AppText.label11,
          ),
          const SizedBox(height: 12),
          _centerRow('山星', c.shanStar, c.shanDirection, c.shanBasis),
          const SizedBox(height: 10),
          _centerRow('向星', c.xiangStar, c.xiangDirection, c.xiangBasis),
        ],
      ),
    );
  }

  Widget _centerRow(String tag, int star, String direction, String basis) {
    final forward = direction == '顺飞';
    final color = forward ? AppColors.primary : AppColors.goldDeep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.iconBg,
        borderRadius: BorderRadius.circular(AppDimens.rM),
        border: Border.all(color: AppColors.iconBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tag, style: AppText.medium12),
              const SizedBox(width: 8),
              Text('$star 入中', style: AppText.medium12.copyWith(color: color)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: forward
                      ? AppColors.primarySoft
                      : AppColors.goldSoftBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(direction,
                    style: AppText.medium11
                        .copyWith(color: color, fontSize: 10)),
              ),
            ],
          ),
          if (basis.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(basis, style: AppText.label11),
          ],
        ],
      ),
    );
  }

  /// 三盘九宫：山星在左上、运星居中、向星在右上（传统盘面写法）
  Widget _houseGridCard(XuankongHouse chart) {
    final cells =
        _cells<XuankongHousePalace>(chart.palaces, (p) => p.direction);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('三盘叠加 · 宅盘', style: AppText.cardTitle),
              Text('上南下北 · ${chart.yun?.name ?? ''}',
                  style: AppText.label11),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '左上 = 山星（人丁），中 = 运星（时运），右上 = 向星（财禄）；'
            '底色为本宫综合吉凶，带「坐 / 向」角标的宫是坐山宫与向首宫。',
            style: AppText.label11,
          ),
          const SizedBox(height: AppDimens.gapM),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: [
              for (final c in cells)
                c == null ? _emptyCell() : _houseCell(c),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          _levelLegend(),
        ],
      ),
    );
  }

  Widget _houseCell(XuankongHousePalace p) {
    final fg = AppColors.palaceFg(p.level);
    final mark = p.isSit
        ? AppColors.primary
        : (p.isFace ? AppColors.gold : null);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.palaceBg(p.level),
        borderRadius: BorderRadius.circular(AppDimens.rS),
        border: Border.all(
          color: mark ??
              AppColors.palaceBorder(p.level) ??
              AppColors.cardBorder,
          width: mark != null ? 1.6 : 1,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 山星（左） / 向星（右）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _smallStar('山', p.shanStar, p.shanState.level),
                    _smallStar('向', p.xiangStar, p.xiangState.level),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${p.yunStar}',
                          style:
                              AppText.value17.copyWith(color: fg, fontSize: 19),
                        ),
                        Text(
                          p.yunStarName,
                          style:
                              AppText.label11.copyWith(color: fg, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  '${p.direction} · ${p.trigram}',
                  textAlign: TextAlign.center,
                  style: AppText.label11
                      .copyWith(fontSize: 9, color: AppColors.body),
                ),
              ],
            ),
          ),
          // 坐 / 向角标放在顶边正中：左上、右上已被山星、向星占用
          if (mark != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: mark,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    p.isSit ? '坐' : '向',
                    style: AppText.medium11
                        .copyWith(color: Colors.white, fontSize: 8),
                  ),
                ),
              ),
            ),
          if (p.hasLostWuhuang)
            const Positioned(
              bottom: 3,
              right: 4,
              child: AppIcon(AppIconKind.warn,
                  size: 12, color: AppColors.dangerDeep),
            ),
        ],
      ),
    );
  }

  Widget _smallStar(String tag, int star, String level) {
    final fg = AppColors.palaceFg(level);
    return Text(
      '$tag$star',
      style: AppText.medium11.copyWith(fontSize: 10, color: fg),
    );
  }

  Widget _emptyCell() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.btnSecondary.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppDimens.rS),
      ),
    );
  }

  Widget _levelLegend() {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _legendDot('旺', AppColors.palaceBg('旺'), AppColors.palaceFg('旺')),
        _legendDot('平', AppColors.palaceBg('平'), AppColors.palaceFg('平')),
        _legendDot('煞', AppColors.palaceBg('煞'), AppColors.palaceFg('煞')),
        _legendDot('大凶', AppColors.palaceBg('大凶'), AppColors.palaceFg('大凶')),
      ],
    );
  }

  Widget _legendDot(String label, Color bg, Color fg) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.cardBorder),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppText.label11.copyWith(color: fg)),
      ],
    );
  }

  /// 格局判定：本盘的主线结论
  Widget _patternCard(XuankongHouse chart) {
    final p = chart.pattern;
    if (p == null) return const SizedBox.shrink();
    final fg = AppColors.palaceFg(p.level);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.palaceBg(p.level),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(p.name,
                    style: AppText.medium12.copyWith(color: fg)),
              ),
              const Spacer(),
              const Text('旺山旺向需合「四十八局」', style: AppText.label11),
            ],
          ),
          const SizedBox(height: 10),
          Text(p.summary,
              style: AppText.body13.copyWith(color: AppColors.inkSoft)),
          const SizedBox(height: 10),
          Text(p.advice, style: AppText.body12),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _flagChip('山盘旺星到坐山', p.shanAtSit),
              _flagChip('向盘旺星到向首', p.xiangAtFace),
              _flagChip('山盘旺星到向首', p.shanAtFace),
              _flagChip('向盘旺星到坐山', p.xiangAtSit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flagChip(String label, bool on) {
    final fg = on ? AppColors.primary : AppColors.muted;
    final bg = on ? AppColors.primarySoftBg : AppColors.btnSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(on ? AppIconKind.check : AppIconKind.warn,
              size: 12, color: fg),
          const SizedBox(width: 5),
          Text(label, style: AppText.label11.copyWith(color: fg)),
        ],
      ),
    );
  }

  /// 逐宫宜忌：按吉凶档位从旺到凶排，方便先看该用的、再看该避的
  Widget _palaceListCard(XuankongHouse chart) {
    final outer = chart.palaces.where((p) => !p.isCenter).toList()
      ..sort((a, b) => (_levelRank[a.level] ?? 9)
          .compareTo(_levelRank[b.level] ?? 9));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('逐宫宜忌', style: AppText.cardTitle),
          const SizedBox(height: 6),
          const Text(
            '按吉凶档位排序：从旺到凶，先看该用的方位，再看该避的方位。'
            '中宫另述，不参与外围吉凶排序。\n'
            '每宫分两行：先看这宫宜作何用（按山向星旺衰），'
            '再看山向两星凑在一起出什么事（双星组合）。',
            style: AppText.label11,
          ),
          const SizedBox(height: 12),
          for (final p in outer) _palaceRow(p),
          const SizedBox(height: 2),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('中宫',
                  style: AppText.medium12.copyWith(color: AppColors.ink)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chart.palaces
                      .where((p) => p.isCenter)
                      .map((p) => p.role)
                      .join(),
                  style: AppText.body12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _palaceRow(XuankongHousePalace p) {
    final fg = AppColors.palaceFg(p.level);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 13,
                decoration: BoxDecoration(
                  color: AppColors.levelDot(p.level),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('${p.direction} · ${p.trigram}宫',
                  style: AppText.medium12.copyWith(color: AppColors.ink)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.palaceBg(p.level),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(p.level,
                    style: AppText.medium11
                        .copyWith(fontSize: 10, color: fg)),
              ),
              const Spacer(),
              Text(
                '山${p.shanStar}(${p.shanState.state}) '
                '向${p.xiangStar}(${p.xiangState.state})',
                style: AppText.label11.copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(p.role, style: AppText.body12),
          ),
          if (p.pair != null) ...[
            const SizedBox(height: 6),
            _pairBlock(p.pair!),
          ],
        ],
      ),
    );
  }

  /// 双星组合：山向两星同宫的判词。
  ///
  /// 只在这一块**说明出处**——有古典赋文的（紫白诀 / 玄空秘旨）与只按五行
  /// 生克推出来的，对用户可信度不同，不能混在一处说。
  Widget _pairBlock(XuankongPair pair) {
    final fg = AppColors.palaceFg(pair.level);
    final showAdvice = pair.level == '煞' || pair.level == '大凶';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.palaceBg(pair.level),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                '「${pair.name}」',
                style: AppText.medium12.copyWith(color: fg),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pair.source} · ${pair.timing}',
                  style: AppText.label11.copyWith(fontSize: 10),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pair.level,
                  style: AppText.medium11.copyWith(fontSize: 10, color: fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            pair.nature,
            style: AppText.body12.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(pair.verdict, style: AppText.body12),
          // 建议只在需要动手的时候给，吉宫不必啰嗦
          if (showAdvice && pair.advice.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              '宜：${pair.advice}',
              style: AppText.body12.copyWith(color: fg),
            ),
          ],
        ],
      ),
    );
  }

  /// 三盘各自管什么——玄空盘最容易读混的就是这三层
  Widget _rolesCard(XuankongHouse chart) {
    if (chart.roles.isEmpty) return const SizedBox.shrink();
    const order = ['shan', 'xiang', 'yun'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('三盘分工', style: AppText.cardTitle),
          const SizedBox(height: 12),
          for (final key in order)
            if (chart.roles[key] != null) _roleRow(chart.roles[key]!),
        ],
      ),
    );
  }

  Widget _roleRow(XuankongRole r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.btnSecondary,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(r.name, style: AppText.medium12),
              ),
              const SizedBox(width: 8),
              Text(r.duty, style: AppText.label11),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.good, style: AppText.body12),
                const SizedBox(height: 2),
                Text(r.bad, style: AppText.body12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 公共块
  Widget _keyPointsCard(List<String> points) {
    if (points.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tipBg,
        borderRadius: BorderRadius.circular(AppDimens.rM),
        border: Border.all(color: AppColors.tipBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AppIcon(AppIconKind.check, size: 16, color: AppColors.goldDeep),
              SizedBox(width: 8),
              Text('行动要点', style: AppText.cardTitle),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < points.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ',
                      style: AppText.medium12
                          .copyWith(color: AppColors.goldDeep)),
                  Expanded(
                    child: Text(points[i],
                        style: AppText.body12
                            .copyWith(color: AppColors.inkSoft)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder({
    required IconData icon,
    required String title,
    required String desc,
    required String buttonText,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 12),
      decoration: appCard(),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.muted),
          const SizedBox(height: 14),
          Text(title, style: AppText.section),
          const SizedBox(height: 8),
          Text(desc, textAlign: TextAlign.center, style: AppText.body12),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primarySoftBorder),
                backgroundColor: AppColors.primarySoftBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonText,
                  style: AppText.medium15.copyWith(color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.iconBg,
        borderRadius: BorderRadius.circular(AppDimens.rM),
        border: Border.all(color: AppColors.iconBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(AppIconKind.spark, size: 15, color: AppColors.body),
              const SizedBox(width: 8),
              Text('三条务必知道的口径',
                  style: AppText.medium12.copyWith(color: AppColors.inkSoft)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '1. 月盘用节气月（立春起正月，以十二「节」为界），与公历月不同步；'
            '换月请以交节为准。',
            style: AppText.label11,
          ),
          const SizedBox(height: 5),
          const Text(
            '2. 顺逆（顺飞 / 逆飞）看的不是坐山本山的阴阳，而是「入中之数在元旦盘'
            '对应宫里、与本节同一元龙那一山」的阴阳；本页把后端给出的判据原样展示，'
            '可逐条复核。',
            style: AppText.label11,
          ),
          const SizedBox(height: 5),
          const Text(
            '3. 八运以下「旺山旺向」共四十八局，九运（2024 起）没有旺山旺向——'
            '二十四山全部是双星会向或双星会坐，这是九运的常态，不是排盘出错。',
            style: AppText.label11,
          ),
          const SizedBox(height: 8),
          const Text(
            '本页全部数值由确定性规则引擎计算，不经过大模型；'
            '结论仅供居住调理参考，不构成任何专业建议。',
            style: AppText.label11,
          ),
        ],
      ),
    );
  }
}

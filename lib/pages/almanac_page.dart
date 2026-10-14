import 'package:flutter/material.dart';

import '../models/almanac.dart';
import '../models/diagnosis.dart' show Extreme;
import '../services/api_client.dart';
import '../services/auth_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// S8 · 黄历择日
///
/// 与其它页面的分工：
/// * 玄空回答「方位此刻的吉凶」，八宅回答「人与宅合不合、房间落在哪一宫」；
/// * 黄历回答「**什么时候**」——今天宜忌如何、哪一天适合动工搬家。
///
/// 页面分两个模式：
/// * **今日黄历**：通书日课（宜忌 / 建除 / 天神 / 宿曜 / 冲煞 / 神煞 / 方位 /
///   十三时辰吉凶），并复用玄空的日家紫白给出「今日吉位 / 忌方」。
/// * **择日查询**：选事项（装修开工 / 入宅搬家 …）后在给定区间内挑吉日，
///   附月历热力便于整体扫读，每条推荐都给逐项理由。
///
/// 本页是纯计算接口，不需要登录，也不依赖房屋 / 命理档案；
/// 唯一的可选输入是「自己生肖」，用于避开冲日。
class AlmanacPage extends StatefulWidget {
  const AlmanacPage({super.key});

  @override
  State<AlmanacPage> createState() => _AlmanacPageState();
}

enum _Mode { day, select }

class _AlmanacPageState extends State<AlmanacPage> {
  final ApiClient _api = ApiClient();

  _Mode _mode = _Mode.day;

  // ---------------------------------------------------------------- 今日黄历
  AlmanacDay? _day;
  late DateTime _cursor;
  bool _dayLoading = true;
  String? _dayError;

  /// 展开的时辰下标（null 表示收起）
  int? _expandedHour;

  // ---------------------------------------------------------------- 择日查询
  List<AlmanacActivity> _activities = const [];
  AlmanacSelectResult? _picks;
  AlmanacCalendar? _calendar;
  late DateTime _monthCursor;
  String _activityKey = 'zhuangxiu';
  String _zodiac = '';
  bool _selectLoading = false;
  String? _selectError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _cursor = DateTime(now.year, now.month, now.day);
    _monthCursor = DateTime(now.year, now.month);
    _loadDay();
  }

  // ---------------------------------------------------------------- 数据
  bool get _isToday {
    final now = DateTime.now();
    return _cursor.year == now.year &&
        _cursor.month == now.month &&
        _cursor.day == now.day;
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadDay() async {
    setState(() {
      _dayLoading = true;
      _dayError = null;
      _expandedHour = null;
    });
    try {
      final day = await _api.fetchAlmanacDay(date: _ymd(_cursor));
      if (!mounted) return;
      setState(() {
        _day = day;
        _dayLoading = false;
      });
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await AuthStore.instance?.forceLogout();
        return;
      }
      if (!mounted) return;
      setState(() {
        _dayError = e.message;
        _dayLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dayError = e.toString();
        _dayLoading = false;
      });
    }
  }

  void _shiftDay(int delta) {
    setState(() => _cursor = _cursor.add(Duration(days: delta)));
    _loadDay();
  }

  void _jumpToDate(DateTime date) {
    setState(() {
      _cursor = DateTime(date.year, date.month, date.day);
      _mode = _Mode.day;
    });
    _loadDay();
  }

  /// 首次进入择日模式时拉取事项与当月热力，之后只在切换条件时重算。
  Future<void> _ensureSelectData({bool force = false}) async {
    if (_activities.isEmpty || force) {
      try {
        final list = await _api.fetchAlmanacActivities();
        if (!mounted) return;
        setState(() {
          _activities = list;
          if (list.isNotEmpty &&
              !list.any((a) => a.key == _activityKey)) {
            _activityKey = list.first.key;
          }
        });
      } on ApiException catch (e) {
        if (e.isUnauthorized) {
          await AuthStore.instance?.forceLogout();
          return;
        }
        if (!mounted) return;
        setState(() => _selectError = e.message);
        return;
      }
    }
    await Future.wait([_loadCalendar(), _runSelect()]);
  }

  Future<void> _loadCalendar() async {
    try {
      final cal = await _api.fetchAlmanacCalendar(
        year: _monthCursor.year,
        month: _monthCursor.month,
        activity: _activityKey,
        zodiac: _zodiac,
      );
      if (!mounted) return;
      setState(() => _calendar = cal);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await AuthStore.instance?.forceLogout();
        return;
      }
      if (!mounted) return;
      setState(() => _selectError = e.message);
    }
  }

  Future<void> _runSelect() async {
    setState(() {
      _selectLoading = true;
      _selectError = null;
    });
    try {
      final result = await _api.selectAlmanacDates(
        activity: _activityKey,
        startDate: _ymd(_monthCursor),
        days: _daysInMonth(_monthCursor),
        zodiac: _zodiac,
        limit: 8,
      );
      if (!mounted) return;
      setState(() {
        _picks = result;
        _selectLoading = false;
      });
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await AuthStore.instance?.forceLogout();
        return;
      }
      if (!mounted) return;
      setState(() {
        _selectError = e.message;
        _selectLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectError = e.toString();
        _selectLoading = false;
      });
    }
  }

  static int _daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  void _shiftMonth(int delta) {
    setState(() {
      _monthCursor = DateTime(_monthCursor.year, _monthCursor.month + delta);
    });
    _loadCalendar();
    _runSelect();
  }

  void _pickActivity(String key) {
    if (key == _activityKey) return;
    setState(() => _activityKey = key);
    _loadCalendar();
    _runSelect();
  }

  void _pickZodiac(String zodiac) {
    if (zodiac == _zodiac) return;
    setState(() => _zodiac = zodiac);
    _loadCalendar();
    _runSelect();
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
                  if (_mode == _Mode.day) ..._dayBody() else ..._selectBody(),
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
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.maybePop(context),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: AppIcon(AppIconKind.back, size: 22, color: AppColors.ink),
          ),
        ),
        const Text('黄历择日', style: AppText.pageTitle),
        const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.calendar_month_rounded,
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
          onTap: () {
            if (_mode == mode) return;
            setState(() => _mode = mode);
            if (mode == _Mode.select) _ensureSelectData();
          },
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
          item(_Mode.day, '今日黄历'),
          item(_Mode.select, '择日查询'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 今日黄历
  List<Widget> _dayBody() {
    if (_dayLoading) {
      return const [
        SizedBox(height: 140),
        Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ];
    }
    final err = _dayError;
    if (err != null) {
      return [
        _placeholder(
          icon: Icons.cloud_off,
          title: '无法获取黄历',
          desc: err,
          buttonText: '重试',
          onTap: _loadDay,
        ),
      ];
    }
    final day = _day;
    if (day == null) return const [];

    return [
      _dateBar(day),
      const SizedBox(height: AppDimens.gapL),
      _yiJiCard(day),
      const SizedBox(height: AppDimens.gapL),
      _infoCard(day),
      const SizedBox(height: AppDimens.gapL),
      _godsCard(day),
      const SizedBox(height: AppDimens.gapL),
      _hoursCard(day),
      const SizedBox(height: AppDimens.gapL),
      _purpleWhiteCard(day),
      const SizedBox(height: AppDimens.gapL),
      _scoreCard(day),
    ];
  }

  Widget _dateBar(AlmanacDay day) {
    final parsed = day.day;
    final label = parsed == null
        ? day.date
        : '${parsed.year}年${parsed.month}月${parsed.day}日';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: appCard(radius: AppDimens.rL),
      child: Row(
        children: [
          _navArrow(Icons.chevron_left_rounded, () => _shiftDay(-1)),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isToday ? null : _loadDay,
              child: Column(
                children: [
                  Text(label, style: AppText.cardTitle),
                  const SizedBox(height: 3),
                  Text(
                    '${day.weekday} · 农历${day.lunar.text}',
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

  /// 宜忌双栏：宜用主色（吉），忌用朱砂（煞），延用全局吉凶配色。
  Widget _yiJiCard(AlmanacDay day) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (day.allAvoid) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.dangerSoftBg,
                borderRadius: BorderRadius.circular(AppDimens.rM),
                border: Border.all(color: AppColors.dangerBorder),
              ),
              child: Row(
                children: [
                  const AppIcon(AppIconKind.warn,
                      size: 16, color: AppColors.dangerDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '当日忌「诸事不宜」，大事不宜安排',
                      style: AppText.medium12
                          .copyWith(color: AppColors.dangerDeep),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          _termColumn('宜', day.yi, good: true),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          _termColumn('忌', day.ji, good: false),
        ],
      ),
    );
  }

  Widget _termColumn(String title, List<String> terms, {required bool good}) {
    final Color fg = good ? AppColors.primary : AppColors.danger;
    final Color bg = good ? AppColors.primarySoftBg : AppColors.dangerSoftBg;
    final Color border =
        good ? AppColors.primarySoftBorder : AppColors.dangerBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: Text(
                title,
                style: AppText.medium13.copyWith(color: fg),
              ),
            ),
            const SizedBox(width: 10),
            Text('共 ${terms.length} 项', style: AppText.label11),
          ],
        ),
        const SizedBox(height: 10),
        if (terms.isEmpty)
          Text('无', style: AppText.body12.copyWith(color: AppColors.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final term in terms) _termChip(term, fg: fg, bg: bg),
            ],
          ),
      ],
    );
  }

  Widget _termChip(String text, {required Color fg, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(text, style: AppText.label12.copyWith(color: fg)),
    );
  }

  /// 建除 / 天神 / 宿曜 / 冲煞 / 纳音 / 旬空 / 五神方位
  Widget _infoCard(AlmanacDay day) {
    final jc = day.jianChu;
    final ts = day.tianShen;
    final xiu = day.xiu;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('日课', style: AppText.cardTitle),
              Text(
                '${day.ganZhi.year}年 ${day.ganZhi.month}月 ${day.ganZhi.day}日',
                style: AppText.label11,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoCell('建除', jc.label, tone: jc.tone),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoCell('日神', ts.name,
                    tone: null, sub: ts.type, good: ts.isLucky),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _infoCell('二十八宿', xiu.full.isEmpty ? xiu.name : xiu.full,
                    tone: null, sub: xiu.luck, good: xiu.isLucky),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoCell('冲煞', day.chong.display, tone: null,
                    sub: '煞${day.chong.sha}'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaChip('纳音', day.naYin),
              _metaChip('旬', day.xun.name),
              _metaChip('旬空', day.xun.kong),
              if (day.solarTerm.isNotEmpty) _metaChip('交节', day.solarTerm),
              if (day.solarTermRange.isNotEmpty)
                _metaChip('节气', day.solarTermRange),
            ],
          ),
          const SizedBox(height: 12),
          Text(jc.meaning, style: AppText.label11),
          const SizedBox(height: 4),
          Text(ts.meaning, style: AppText.label11),
          const SizedBox(height: 4),
          Text('口诀：${jc.motto}', style: AppText.label11),
        ],
      ),
    );
  }

  Widget _infoCell(String label, String value,
      {String? tone, String? sub, bool good = false}) {
    // 有 tone 的按建除档位取吉凶配色；没有 tone 的按 luck 决定
    final bool favorable = tone != null
        ? (tone == '大吉' || tone == '黄道')
        : good;
    final Color fg = favorable ? AppColors.primary : AppColors.danger;
    final Color bg = favorable ? AppColors.primarySoftBg : AppColors.dangerSoftBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.rM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label11.copyWith(color: AppColors.body)),
          const SizedBox(height: 4),
          Text(value, style: AppText.medium15.copyWith(color: fg)),
          if (sub != null && sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(sub, style: AppText.label11.copyWith(color: fg)),
          ],
          if (tone != null && tone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(tone, style: AppText.label11.copyWith(color: fg)),
          ],
        ],
      ),
    );
  }

  Widget _metaChip(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.btnSecondary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text('$label $value', style: AppText.label11),
    );
  }

  /// 吉神 / 凶煞 / 五神方位
  Widget _godsCard(AlmanacDay day) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (day.jiShen.isNotEmpty) ...[
            _subTitle('吉神宜趋'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in day.jiShen)
                  _termChip(s,
                      fg: AppColors.primary, bg: AppColors.primarySoftBg),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (day.xiongSha.isNotEmpty) ...[
            _subTitle('凶煞宜忌'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in day.xiongSha)
                  _termChip(s, fg: AppColors.danger, bg: AppColors.dangerSoftBg),
              ],
            ),
            const SizedBox(height: 14),
          ],
          _subTitle('方位'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < day.fiveGods.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _godCell(day.fiveGods[i])),
              ],
            ],
          ),
          if (day.pengZu.lines.isNotEmpty) ...[
            const SizedBox(height: 14),
            _subTitle('彭祖百忌'),
            const SizedBox(height: 6),
            for (final line in day.pengZu.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(line, style: AppText.label11),
              ),
          ],
        ],
      ),
    );
  }

  Widget _subTitle(String text) =>
      Text(text, style: AppText.medium12.copyWith(color: AppColors.inkSoft));

  Widget _godCell(AlmanacGod god) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.goldSoftBg,
        borderRadius: BorderRadius.circular(AppDimens.rS),
      ),
      child: Column(
        children: [
          Text(god.name, style: AppText.label11.copyWith(color: AppColors.body)),
          const SizedBox(height: 3),
          Text(
            god.direction.isEmpty ? '—' : god.direction,
            style: AppText.medium12.copyWith(color: AppColors.goldDeep),
          ),
        ],
      ),
    );
  }

  /// 十三时辰吉凶：点一行展开该时辰的时宜 / 时忌。
  Widget _hoursCard(AlmanacDay day) {
    final lucky = day.luckyHours.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('时辰吉凶', style: AppText.cardTitle),
              Text('吉时 $lucky / ${day.hours.length}', style: AppText.label11),
            ],
          ),
          const SizedBox(height: 6),
          const Text('子时分早（00:00）晚（23:00）两位，干支与吉凶各不相同。',
              style: AppText.label11),
          const SizedBox(height: 10),
          for (final hour in day.hours) _hourRow(hour),
        ],
      ),
    );
  }

  Widget _hourRow(AlmanacHour hour) {
    final expanded = _expandedHour == hour.index;
    final Color fg =
        hour.isLucky ? AppColors.primary : AppColors.danger;
    final Color bg =
        hour.isLucky ? AppColors.primarySoftBg : AppColors.dangerSoftBg;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(
          () => _expandedHour = expanded ? null : hour.index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDimens.rS),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Text(hour.slotLabel,
                      style: AppText.medium12.copyWith(color: fg)),
                ),
                SizedBox(
                  width: 92,
                  child: Text(hour.range, style: AppText.label11),
                ),
                Expanded(
                  child: Text(
                    '${hour.tianShen} · ${hour.ganZhi}',
                    style: AppText.label11.copyWith(color: fg),
                  ),
                ),
                Text(hour.luck, style: AppText.label11.copyWith(color: fg)),
                const SizedBox(width: 4),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: fg,
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 8),
              if (hour.naYin.isNotEmpty || hour.caiDirection.isNotEmpty)
                Text(
                  '纳音 ${hour.naYin}  ·  财神 ${hour.caiDirection}'
                  '  ·  冲${hour.chong.zodiac}',
                  style: AppText.label11,
                ),
              const SizedBox(height: 6),
              _hourTerms('宜', hour.yi, AppColors.primary),
              const SizedBox(height: 4),
              _hourTerms('忌', hour.ji, AppColors.danger),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hourTerms(String label, List<String> terms, Color color) {
    return RichText(
      text: TextSpan(
        style: AppText.label11,
        children: [
          TextSpan(
            text: '$label ',
            style: AppText.label11.copyWith(color: color),
          ),
          TextSpan(
            text: terms.isEmpty ? '无' : terms.join('、'),
            style: AppText.label11.copyWith(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  /// 当日紫白：与玄空日盘同源，直接复用「吉位 / 忌方」结论
  Widget _purpleWhiteCard(AlmanacDay day) {
    final pw = day.purpleWhite;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('当日九星', style: AppText.cardTitle),
              Text('${pw.escape} · ${pw.yuan}', style: AppText.label11),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _spotBox('今日吉位', pw.best, good: true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _spotBox('今日忌方', pw.worst, good: false),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '入中 ${pw.centerStarName}；九星为玄空日盘，与「户型诊断」同一口径。',
            style: AppText.label11,
          ),
          if (!pw.calendarExact) ...[
            const SizedBox(height: 4),
            Text('注：当年节气取自近似值，交节前后可能差一天。',
                style: AppText.label11.copyWith(color: AppColors.danger)),
          ],
        ],
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
            spot?.direction ?? '—',
            style: AppText.value17.copyWith(color: fg),
          ),
          const SizedBox(height: 2),
          Text(
            spot == null ? '' : spot.roleName,
            style: AppText.label11.copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  /// 当日总体评分与逐条依据
  Widget _scoreCard(AlmanacDay day) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.palaceBg(day.tone),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.score}',
                      style: AppText.value17.copyWith(
                        color: AppColors.palaceFg(day.tone),
                      ),
                    ),
                    Text(
                      day.level,
                      style: AppText.label11.copyWith(
                        color: AppColors.palaceFg(day.tone),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '当日总体吉凶（不含具体事项）。择日请到「择日查询」按事项评估。',
                  style: AppText.label11,
                ),
              ),
            ],
          ),
          if (day.scoreReasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final reason in day.scoreReasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(Icons.circle,
                          size: 5, color: AppColors.muted),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(reason, style: AppText.label11)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 择日查询
  List<Widget> _selectBody() {
    if (_activities.isEmpty && _selectError != null) {
      return [
        _placeholder(
          icon: Icons.cloud_off,
          title: '无法获取择日数据',
          desc: _selectError!,
          buttonText: '重试',
          onTap: () => _ensureSelectData(force: true),
        ),
      ];
    }
    if (_activities.isEmpty) {
      return const [
        SizedBox(height: 140),
        Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ];
    }

    return [
      _activityPicker(),
      const SizedBox(height: AppDimens.gapL),
      _zodiacPicker(),
      const SizedBox(height: AppDimens.gapL),
      _calendarCard(),
      const SizedBox(height: AppDimens.gapL),
      _picksCard(),
    ];
  }

  Widget _activityPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('要办什么事', style: AppText.cardTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final act in _activities)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _pickActivity(act.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: act.key == _activityKey
                          ? AppColors.primary
                          : AppColors.btnSecondary,
                      borderRadius: BorderRadius.circular(AppDimens.rPill),
                    ),
                    child: Text(
                      act.name,
                      style: AppText.medium12.copyWith(
                        color: act.key == _activityKey
                            ? Colors.white
                            : AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _activities
                .where((a) => a.key == _activityKey)
                .map((a) => '${a.note}（对应通书「${a.terms.join('、')}」）')
                .join(),
            style: AppText.label11,
          ),
        ],
      ),
    );
  }

  Widget _zodiacPicker() {
    const zodiacs = ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('避开与自己相冲的日子', style: AppText.cardTitle),
              if (_zodiac.isNotEmpty)
                GestureDetector(
                  onTap: () => _pickZodiac(''),
                  child: Text('不限',
                      style: AppText.label11
                          .copyWith(color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final z in zodiacs)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _pickZodiac(_zodiac == z ? '' : z),
                  child: Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _zodiac == z
                          ? AppColors.goldDeep
                          : AppColors.btnSecondary,
                      borderRadius: BorderRadius.circular(AppDimens.rS),
                    ),
                    child: Text(
                      z,
                      style: AppText.medium12.copyWith(
                        color:
                            _zodiac == z ? Colors.white : AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _zodiac.isEmpty
                ? '未选择生肖：不避冲，推荐结果可能包含与你相冲的日子。'
                : '已选生肖「$_zodiac」：冲该生肖的日子会被扣分并标注，仍会展示供你判断。',
            style: AppText.label11,
          ),
        ],
      ),
    );
  }

  /// 月历热力：一眼扫出本月哪几天适合该事项
  Widget _calendarCard() {
    final cal = _calendar;
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _navArrow(Icons.chevron_left_rounded, () => _shiftMonth(-1)),
              Expanded(
                child: Text(
                  '${_monthCursor.year}年${_monthCursor.month}月'
                  '${cal?.activityName.isNotEmpty == true ? ' · ${cal!.activityName}' : ''}',
                  textAlign: TextAlign.center,
                  style: AppText.cardTitle,
                ),
              ),
              _navArrow(Icons.chevron_right_rounded, () => _shiftMonth(1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: Center(
                    child: Text(w, style: AppText.label11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (cal == null)
            const SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else ...[
            for (final week in _weeks(cal)) _calendarRow(week),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('色阶：', style: AppText.label11),
                const SizedBox(width: 6),
                _legendDot('大吉', '旺'),
                const SizedBox(width: 8),
                _legendDot('吉/平', '平'),
                const SizedBox(width: 8),
                _legendDot('不宜', '煞'),
                const SizedBox(width: 8),
                _legendDot('避开', '大凶'),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '点任一日期查看当天通书；灰底为上月占位。',
              style: AppText.label11,
            ),
          ],
        ],
      ),
    );
  }

  /// 把整月切成「以周一为首」的周，首周前用 null 补齐
  List<List<AlmanacCalendarDay?>> _weeks(AlmanacCalendar cal) {
    final cells = <AlmanacCalendarDay?>[
      ...List<AlmanacCalendarDay?>.filled(cal.firstWeekday, null),
      ...cal.days,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return [
      for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7),
    ];
  }

  Widget _calendarRow(List<AlmanacCalendarDay?> week) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          for (final cell in week) ...[
            Expanded(child: _calendarCell(cell)),
          ],
        ],
      ),
    );
  }

  Widget _calendarCell(AlmanacCalendarDay? cell) {
    if (cell == null) {
      return Container(
        height: 46,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.btnSecondary.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(9),
        ),
      );
    }
    final parsed = DateTime.tryParse(cell.date);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: parsed == null ? null : () => _jumpToDate(parsed),
      child: Container(
        height: 46,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.palaceBg(cell.tone),
          borderRadius: BorderRadius.circular(9),
          border: cell.clash
              ? Border.all(color: AppColors.dangerBorder)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${cell.day}',
              style: AppText.medium12
                  .copyWith(color: AppColors.palaceFg(cell.tone)),
            ),
            Text(
              '${cell.score}',
              style: AppText.label11
                  .copyWith(color: AppColors.palaceFg(cell.tone)),
            ),
            if (cell.clash)
              Text('冲',
                  style: AppText.label11
                      .copyWith(color: AppColors.dangerDeep)),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(String label, String tone) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.palaceBg(tone),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.cardBorder),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppText.label11),
      ],
    );
  }

  Widget _picksCard() {
    final picks = _picks;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('推荐吉日', style: AppText.cardTitle),
              if (picks != null)
                Text(
                  '扫 ${picks.scanned} 天 · 达标 ${picks.recommendedCount} 天',
                  style: AppText.label11,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectLoading)
            const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_selectError != null)
            Text(_selectError!, style: AppText.body12)
          else if (picks == null || picks.items.isEmpty)
            const Text('本月没有达标的日子，可切换到其它月份看看。',
                style: AppText.body12)
          else
            for (final pick in picks.items) _pickTile(pick),
        ],
      ),
    );
  }

  Widget _pickTile(AlmanacPick pick) {
    final parsed = DateTime.tryParse(pick.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoftBg,
        borderRadius: BorderRadius.circular(AppDimens.rM),
        border: Border.all(color: AppColors.primarySoftBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${pick.score}',
                      style: AppText.value17
                          .copyWith(color: AppColors.palaceFg(pick.tone)),
                    ),
                    Text(
                      pick.level,
                      style: AppText.label11
                          .copyWith(color: AppColors.palaceFg(pick.tone)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          parsed == null
                              ? pick.date
                              : '${parsed.month}月${parsed.day}日',
                          style: AppText.cardTitle,
                        ),
                        const SizedBox(width: 6),
                        Text(pick.weekday, style: AppText.label11),
                        if (pick.clash) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.dangerSoftBg,
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: AppColors.dangerBorder),
                            ),
                            child: Text(
                              '冲${pick.chong.zodiac}',
                              style: AppText.label11
                                  .copyWith(color: AppColors.dangerDeep),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '农历${pick.lunar} · ${pick.ganZhi}日 · '
                      '${pick.jianChuLabel} · 宿${pick.xiu}(${pick.xiuLuck})',
                      style: AppText.label11,
                    ),
                    if (pick.bestHour.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '首选吉时 ${pick.bestHour}（共 ${pick.luckyHourCount} 个吉时）',
                        style: AppText.label11
                            .copyWith(color: AppColors.goldDeep),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final reason in pick.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child:
                        Icon(Icons.circle, size: 5, color: AppColors.muted),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(reason, style: AppText.label11)),
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
      margin: const EdgeInsets.only(top: 24),
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
        color: AppColors.tipBg,
        borderRadius: BorderRadius.circular(AppDimens.rM),
        border: Border.all(color: AppColors.tipBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('说明', style: AppText.medium12.copyWith(color: AppColors.goldDeep)),
          const SizedBox(height: 6),
          const Text(
            '历法数据取自天文历法库，不由大模型生成。择日分数由「宜忌命中 + 建除档位 '
            '+ 日天神 + 二十八宿 + 黄道吉时数」加权得出，每条加减分都列在结果里，'
            '你可以据此自行判断——吉日只是参考，最终以实际条件为准。',
            style: AppText.label11,
          ),
        ],
      ),
    );
  }
}

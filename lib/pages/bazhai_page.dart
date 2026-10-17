import 'package:flutter/material.dart';

import '../models/bazhai.dart';
import '../models/house.dart';
import '../models/palace_grid.dart';
import '../services/api_client.dart';
import '../services/auth_store.dart';
import '../services/bazi_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/save_record_button.dart';

/// S7 · 八宅吉方
///
/// 与玄空飞星的分工（两套体系，互补不替代）：
/// * 玄空看「某个方位此刻的星曜吉凶」，回答「今年财位在哪、今日忌哪个方向」；
/// * 八宅看「人与宅合不合、各房间该落在哪一宫」，回答「床朝哪、灶安哪、门开哪」。
///   装修落地最常用的是后者。
///
/// 前置数据两条，缺任一条都不请求后端、也不用示例数据顶替：
/// * 出生信息（出生年 + 性别）—— 定命卦，取自命理档案；
/// * 坐向 —— 定宅卦，取自当前房屋的罗盘测量值。
class BazhaiPage extends StatefulWidget {
  const BazhaiPage({
    super.key,
    this.house,
    this.onOpenBazi,
    this.onOpenCompass,
    this.initialParams,
  });

  /// 当前房屋；为空表示还没建档，未测量坐向时页面给出对应引导
  final HouseProfile? house;

  /// 缺出生信息时跳到八字页录入（由外层切换 tab）
  final VoidCallback? onOpenBazi;

  /// 缺坐向时跳到罗盘页测量
  final VoidCallback? onOpenCompass;

  /// 从测算记录打开时的入参快照；非 null 时按它直接排盘，
  /// 不读本地档案与当前房屋（档案可能已变，回放的是当时那份入参）
  final Map<String, dynamic>? initialParams;

  @override
  State<BazhaiPage> createState() => _BazhaiPageState();
}

/// 前置数据缺失的原因
enum _Blocker { none, noBazi, noHouse, noMeasure }

class _BazhaiPageState extends State<BazhaiPage> {
  final ApiClient _api = ApiClient();
  final BaziStore _store = BaziStore();

  BazhaiChart? _chart;
  String? _error;
  bool _loading = true;
  _Blocker _blocker = _Blocker.none;

  /// 从测算记录回放时的入参快照；非 null 时保存按钮按它存（而非当前档案）
  Map<String, dynamic>? _replayParams;

  @override
  void initState() {
    super.initState();
    // 从测算记录打开：按存的参数直接排盘，不读本地档案与当前房屋
    final ip = widget.initialParams;
    if (ip != null) {
      _replayParams = ip;
      _loadFromParams(ip);
      return;
    }
    _store.addListener(_onStoreChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    // 出生信息在别处被改了：重算一次（档案从无到有时也会走到这里）
    if (mounted) _load();
  }

  Future<void> _bootstrap() async {
    await _store.init();
    if (!mounted) return;
    // 本地与服务端都没有档案、且刷新报了错：先报错，不要误判成「没录过」
    if (_store.record == null && _store.lastError != null) {
      setState(() {
        _error = _store.lastError;
        _loading = false;
      });
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    final record = _store.record;
    if (record == null) {
      setState(() {
        _loading = false;
        _error = null;
        _blocker = _Blocker.noBazi;
      });
      return;
    }
    final house = widget.house;
    if (house == null) {
      setState(() {
        _loading = false;
        _error = null;
        _blocker = _Blocker.noHouse;
      });
      return;
    }
    if (!house.measured) {
      setState(() {
        _loading = false;
        _error = null;
        _blocker = _Blocker.noMeasure;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _blocker = _Blocker.none;
    });

    try {
      final chart = await _api.fetchBazhai(
        year: record.year,
        gender: record.gender,
        month: record.month,
        day: record.day,
        hour: record.hour,
        minute: record.minute,
        degree: house.degree,
        declination: house.declination,
        name: record.name,
      );
      if (!mounted) return;
      setState(() {
        _chart = chart;
        _loading = false;
      });
    } on ApiException catch (e) {
      // token 失效：全局登出，AuthGate 自动切回登录页
      if (e.isUnauthorized) {
        await AuthStore.instance?.forceLogout();
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.message;
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

  /// 从测算记录回放：按存的入参直接排盘。
  /// 不看本地档案与当前房屋——档案可能已变，回放的是当时那份入参。
  Future<void> _loadFromParams(Map<String, dynamic> params) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _blocker = _Blocker.none;
    });

    try {
      final chart = await _api.fetchBazhai(
        year: (params['year'] as num?)?.toInt() ?? 0,
        gender: params['gender']?.toString() ?? '',
        month: (params['month'] as num?)?.toInt() ?? 0,
        day: (params['day'] as num?)?.toInt() ?? 0,
        hour: (params['hour'] as num?)?.toInt() ?? 0,
        minute: (params['minute'] as num?)?.toInt() ?? 0,
        degree: (params['degree'] as num?)?.toDouble(),
        declination: (params['declination'] as num?)?.toDouble() ?? 0,
        trigram: params['trigram']?.toString() ?? '',
        name: params['name']?.toString() ?? '',
      );
      if (!mounted) return;
      setState(() {
        _chart = chart;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await AuthStore.instance?.forceLogout();
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.message;
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

  /// 保存用的入参：回放时按记录原参存（档案可能已变，不拿现在的覆盖过去的），
  /// 否则取当前命理档案 + 房屋档案
  Map<String, dynamic> _recordParams() {
    final replay = _replayParams;
    if (replay != null) return replay;

    final record = _store.record;
    final house = widget.house;
    return <String, dynamic>{
      'year': record?.year ?? 0,
      'gender': record?.gender ?? '',
      'month': record?.month ?? 0,
      'day': record?.day ?? 0,
      'hour': record?.hour ?? 0,
      'minute': record?.minute ?? 0,
      'declination': house?.declination ?? 0,
      'name': record?.name ?? '',
      if (house?.degree != null) 'degree': house!.degree,
    };
  }

  String get _recordTitle => '八宅 · ${_chart?.zhaiGua.name ?? ''}';

  String get _recordSummary {
    final chart = _chart;
    if (chart == null) return '';
    return '命卦${chart.mingGua.name} · 宅卦${chart.zhaiGua.name}';
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
                  ..._body(),
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
        const Text('八宅吉方', style: AppText.pageTitle),
        // 右侧槽位：阅读类产品的书签位——存这次测算的入参；
        // 没有盘时留占位保持标题居中
        _chart == null
            ? const SizedBox(width: 34, height: 34)
            : SaveRecordButton(
                kind: 'bazhai',
                title: _recordTitle,
                summary: _recordSummary,
                params: _recordParams(),
              ),
      ],
    );
  }

  List<Widget> _body() {
    if (_loading) {
      return const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ];
    }
    final err = _error;
    if (err != null) {
      return [
        _placeholder(
          icon: Icons.cloud_off,
          title: '无法获取八宅盘',
          desc: err,
          buttonText: '重试',
          onTap: _bootstrap,
        ),
      ];
    }
    switch (_blocker) {
      case _Blocker.noBazi:
        return [
          _placeholder(
            icon: Icons.badge_outlined,
            title: '还没有出生信息',
            desc: '八宅的命卦由出生年与性别决定，请先在「八字排盘」里录入一次出生信息。',
            buttonText: '去录入出生信息',
            onTap: widget.onOpenBazi,
          ),
        ];
      case _Blocker.noHouse:
        return [
          _placeholder(
            icon: Icons.home_outlined,
            title: '还没有房屋档案',
            desc: '八宅的宅卦由坐向决定，请先在「我的房屋」里添加一套房屋。',
            buttonText: '返回',
            onTap: () => Navigator.maybePop(context),
          ),
        ];
      case _Blocker.noMeasure:
        return [
          _placeholder(
            icon: Icons.explore_outlined,
            title: '尚未测量坐向',
            desc: '宅卦以坐山为准，请用罗盘实测一次，坐向会自动写入当前房屋。',
            buttonText: '去测量坐向',
            onTap: widget.onOpenCompass,
          ),
        ];
      case _Blocker.none:
        break;
    }
    final chart = _chart;
    if (chart == null) {
      return [
        _placeholder(
          icon: Icons.cloud_off,
          title: '尚未取得八宅盘',
          desc: '请稍后重试。',
          buttonText: '重试',
          onTap: _bootstrap,
        ),
      ];
    }
    return [
      _guaCard(chart),
      const SizedBox(height: AppDimens.gapL),
      _compatCard(chart),
      const SizedBox(height: AppDimens.gapL),
      _palaceCard(chart),
      const SizedBox(height: AppDimens.gapL),
      _starsCard(chart),
      const SizedBox(height: AppDimens.gapL),
      _roomsCard(chart),
      const SizedBox(height: AppDimens.gapL),
      _mingCard(chart),
      const SizedBox(height: AppDimens.gapL),
      _keyPointsCard(chart),
      const SizedBox(height: AppDimens.gapL),
      _footNote(chart),
    ];
  }

  // ---------------------------------------------------------------- 前置占位
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

  // ---------------------------------------------------------------- 命卦 / 宅卦
  Widget _guaCard(BazhaiChart chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _guaBox('命卦', chart.mingGua, chart)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Text(
                      chart.compat.matched ? '相配' : '不配',
                      style: AppText.medium11.copyWith(
                        color: chart.compat.matched
                            ? AppColors.primary
                            : AppColors.danger,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      chart.compat.matched
                          ? Icons.link_rounded
                          : Icons.link_off_rounded,
                      size: 16,
                      color: chart.compat.matched
                          ? AppColors.primary
                          : AppColors.danger,
                    ),
                  ],
                ),
              ),
              Expanded(child: _guaBox('宅卦', chart.zhaiGua, chart)),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Text(
            chart.birth.summary +
                (chart.birth.lichunAdjusted ? '（立春前出生，按上一年计）' : ''),
            style: AppText.label11,
          ),
        ],
      ),
    );
  }

  Widget _guaBox(String tag, BazhaiGua gua, BazhaiChart chart) {
    final isMing = tag == '命卦';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isMing ? AppColors.primarySoftBg : AppColors.goldSoftBg,
        borderRadius: BorderRadius.circular(AppDimens.rL),
        border: Border.all(
          color: isMing ? AppColors.primarySoftBorder : AppColors.tipBorder,
        ),
      ),
      child: Column(
        children: [
          Text(tag,
              style: AppText.medium11.copyWith(
                color: isMing ? AppColors.primary : AppColors.goldDeep,
                fontSize: 10,
              )),
          const SizedBox(height: 6),
          Text(gua.trigram,
              style: AppText.value17.copyWith(
                fontSize: 26,
                color: isMing ? AppColors.primary : AppColors.goldDeep,
              )),
          const SizedBox(height: 4),
          Text(gua.name, style: AppText.smallTitle),
          const SizedBox(height: 3),
          Text('${gua.group} · 洛书${gua.luoshu}', style: AppText.label11),
          const SizedBox(height: 3),
          Text(
            isMing
                ? gua.direction
                : (gua.hasOrientation
                    ? '${gua.title} · ${gua.readable}'
                    : gua.direction),
            textAlign: TextAlign.center,
            style: AppText.label11.copyWith(color: AppColors.body),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 宅命相配
  Widget _compatCard(BazhaiChart chart) {
    final c = chart.compat;
    final ok = c.matched;
    final accent = ok ? AppColors.primary : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('宅命关系', style: AppText.cardTitle),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ok ? AppColors.primarySoft : AppColors.dangerSoftBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c.level,
                  style: AppText.medium11.copyWith(color: accent, fontSize: 10),
                ),
              ),
              const Spacer(),
              Text('${c.mingGroup} × ${c.zhaiGroup}', style: AppText.label11),
            ],
          ),
          const SizedBox(height: 10),
          Text(c.summary,
              style: AppText.body13.copyWith(color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          for (final a in c.advice) _bullet(a, accent),
        ],
      ),
    );
  }

  Widget _bullet(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(child: Text(text, style: AppText.body12)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 游年八星
  Widget _palaceCard(BazhaiChart chart) {
    // 八宅用固定方位画法（上南下北），不按坐向旋转：
    // 游年八星本身就绑定在固定宫位上，旋转反而看不出「哪一宫是哪一星」。
    final byDirection = {for (final s in chart.stars) s.direction: s};
    final cells = [
      for (final d in PalaceGrid.fixedOrder) byDirection[d], // 中宫为 null
    ];
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
              const Text('游年八星 · 宅盘', style: AppText.cardTitle),
              Text('上南下北 · ${chart.zhaiGua.label}', style: AppText.label11),
            ],
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
              for (var i = 0; i < cells.length; i++)
                cells[i] == null
                    ? _centerCell(chart)
                    : _starCell(cells[i]!, chart),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _legend('生气 · 大吉', AppColors.primary),
              _legend('天医 / 延年 · 吉', AppColors.primary),
              _legend('伏位 · 小吉', AppColors.gold),
              _legend('祸害 / 六煞 · 凶', AppColors.danger),
              _legend('五鬼 / 绝命 · 大凶', AppColors.dangerDeep),
            ],
          ),
        ],
      ),
    );
  }

  /// 中宫格：八卦之外的太极位，八宅游年不落星
  Widget _centerCell(BazhaiChart chart) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.iconBg,
        borderRadius: BorderRadius.circular(AppDimens.rS),
        border: Border.all(color: AppColors.iconBorder),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('中宫', style: AppText.label11.copyWith(fontSize: 10)),
            const SizedBox(height: 4),
            Text(chart.zhaiGua.name,
                style: AppText.smallTitle.copyWith(color: AppColors.body)),
            const SizedBox(height: 2),
            Text('伏位在${chart.zhaiGua.direction}',
                style: AppText.label11.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _starCell(BazhaiStar s, BazhaiChart chart) {
    final fg = AppColors.palaceFg(s.level);
    // 坐方 / 向方角标：游年星落在坐山宫或向首宫时特别标注
    final isSitting = s.trigram == chart.zhaiGua.trigram;
    final isFacing = chart.zhaiGua.facingTrigram.isNotEmpty &&
        s.trigram == chart.zhaiGua.facingTrigram;
    final mark = isSitting
        ? AppColors.primary
        : (isFacing ? AppColors.gold : null);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.palaceBg(s.level),
        borderRadius: BorderRadius.circular(AppDimens.rS),
        border: Border.all(
          color: mark ??
              AppColors.palaceBorder(s.level) ??
              AppColors.cardBorder,
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
                  '${s.direction} · ${s.trigram}',
                  style: AppText.label11.copyWith(
                    color: AppColors.body,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.star,
                  style: AppText.value17.copyWith(color: fg, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.alias} · ${s.element}',
                  style: AppText.label11.copyWith(
                    color: fg.withValues(alpha: 0.75),
                    fontSize: 10,
                  ),
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
                  isSitting ? '坐' : '向',
                  style: AppText.medium11
                      .copyWith(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legend(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(text, style: AppText.label11.copyWith(color: AppColors.body)),
      ],
    );
  }

  // ---------------------------------------------------------------- 四吉四凶
  Widget _starsCard(BazhaiChart chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('各宫宜忌', style: AppText.cardTitle),
          const SizedBox(height: 12),
          Text('四吉方 · 宜用',
              style: AppText.medium12.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          for (final s in chart.auspicious) _starRow(s, true),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Text('四凶方 · 宜压',
              style: AppText.medium12.copyWith(color: AppColors.danger)),
          const SizedBox(height: 8),
          for (final s in chart.inauspicious) _starRow(s, false),
        ],
      ),
    );
  }

  Widget _starRow(BazhaiStar s, bool good) {
    final fg = AppColors.palaceFg(s.level);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: fg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(s.star, style: AppText.smallTitle.copyWith(color: fg)),
              const SizedBox(width: 6),
              Text(
                '${s.trigram}宫 · ${s.direction}',
                style: AppText.label11,
              ),
              if (s.isBase) ...[
                const SizedBox(width: 6),
                _miniTag('本宫'),
              ],
              const Spacer(),
              Text(s.level,
                  style: AppText.medium11.copyWith(color: fg, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.meaning, style: AppText.body12),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in s.suitable) _miniTag('宜 $t', good: true),
                    for (final t in s.avoid) _miniTag('忌 $t', bad: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String text, {bool good = false, bool bad = false}) {
    final Color bg = good
        ? AppColors.primarySoftBg
        : (bad ? AppColors.dangerSoftBg : AppColors.btnSecondary);
    final Color fg = good
        ? AppColors.primary
        : (bad ? AppColors.danger : AppColors.body);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(text, style: AppText.label11.copyWith(color: fg)),
    );
  }

  // ---------------------------------------------------------------- 房间选位
  Widget _roomsCard(BazhaiChart chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('房间选位', style: AppText.cardTitle),
              Text('按${chart.zhaiGua.label}游年', style: AppText.label11),
            ],
          ),
          const SizedBox(height: 12),
          for (final r in chart.rooms) _roomRow(r),
          const SizedBox(height: 2),
          const Text(
            '选位按宅卦游年八星推定：吉方宜用、凶方宜压（卫生间、储物间压在凶方反能镇煞）。',
            style: AppText.label11,
          ),
        ],
      ),
    );
  }

  Widget _roomRow(BazhaiRoom r) {
    final top = r.recommend.isNotEmpty ? r.recommend.first : null;
    final second = r.recommend.length > 1 ? r.recommend.skip(1) : const <BazhaiStar>[];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(r.name, style: AppText.medium13),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (top != null) ...[
                      Text(
                        '${top.direction} · ',
                        style: AppText.medium13
                            .copyWith(color: AppColors.primary),
                      ),
                      Text(
                        top.star,
                        style: AppText.medium13
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (second.isNotEmpty)
                      '次选 ${second.map((e) => e.direction).join('、')}',
                    if (r.avoid.isNotEmpty)
                      '忌 ${r.avoid.take(3).map((e) => e.direction).join('、')}',
                  ].join(' · '),
                  style: AppText.label11,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 本命吉方
  Widget _mingCard(BazhaiChart chart) {
    final d = chart.mingDirections;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoftBg,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.primarySoftBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('本命吉方', style: AppText.cardTitle),
              Text('按${chart.mingGua.label}游年', style: AppText.label11),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '宅卦定「房子」，命卦定「人」：床、书桌、办公位朝向看这一组。',
            style: AppText.label11,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in d.lucky)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppDimens.rPill),
                    border: Border.all(color: AppColors.primarySoftBorder),
                  ),
                  child: Text(
                    '${s.direction} · ${s.star}',
                    style: AppText.medium12.copyWith(color: AppColors.primary),
                  ),
                ),
              for (final s in d.unlucky.take(2))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoftBg,
                    borderRadius: BorderRadius.circular(AppDimens.rPill),
                    border: Border.all(color: AppColors.dangerBorder),
                  ),
                  child: Text(
                    '忌 ${s.direction} · ${s.star}',
                    style: AppText.medium12.copyWith(color: AppColors.danger),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _tipRow(Icons.bed_outlined, d.bed),
          const SizedBox(height: 8),
          _tipRow(Icons.desk_outlined, d.desk),
        ],
      ),
    );
  }

  Widget _tipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1, right: 8),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        Expanded(
          child: Text(text,
              style: AppText.body12.copyWith(color: AppColors.inkSoft)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- 行动要点
  Widget _keyPointsCard(BazhaiChart chart) {
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
          for (var i = 0; i < chart.keyPoints.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ',
                      style: AppText.medium12
                          .copyWith(color: AppColors.goldDeep)),
                  Expanded(
                    child: Text(chart.keyPoints[i],
                        style: AppText.body12.copyWith(color: AppColors.inkSoft)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _footNote(BazhaiChart chart) {
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
              Text('八宅与玄空的分工',
                  style: AppText.medium12.copyWith(color: AppColors.inkSoft)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '八宅断「人与宅、房间落宫」——床朝哪、灶安哪、门开哪；'
            '玄空断「方位星曜的时运吉凶」——今年财位在哪、今日忌哪个方向。'
            '两套体系互补，可结合「户型诊断」一起看。',
            style: AppText.label11,
          ),
          const SizedBox(height: 6),
          Text(
            '命卦以立春为界；本页全部结论由规则引擎计算（规则集 ${chart.rulesVersion}），不经过大模型。',
            style: AppText.label11,
          ),
        ],
      ),
    );
  }
}

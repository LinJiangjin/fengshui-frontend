import 'dart:async';

import 'package:flutter/material.dart';

import 'models/diagnosis.dart';
import 'models/house.dart';
import 'pages/bazi_page.dart';
import 'pages/compass_page.dart';
import 'pages/home_page.dart';
import 'pages/house_page.dart';
import 'pages/layout_page.dart';
import 'pages/library_page.dart';
import 'pages/report_page.dart';
import 'services/api_client.dart';
import 'services/compass_service.dart';
import 'services/house_store.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/app_tab_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 注意：Dart 侧不要再调用 SystemChrome 设置系统栏样式/模式——
  // PlatformPlugin 会重置系统 UI 标志，导致原生 edge-to-edge 失效。
  // 系统栏（透明 + 深色图标）由 MainActivity 原生控制。
  runApp(const FengShuiApp());
}

class FengShuiApp extends StatelessWidget {
  const FengShuiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '风水装修',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        canvasColor: AppColors.bg,
        splashFactory: NoSplash.splashFactory,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          background: AppColors.bg,
        ),
      ),
      home: const AppShell(),
    );
  }
}

/// 外壳：底部 Tab + 页面栈
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  final _api = ApiClient();
  final _compass = CompassServiceFactory.create();

  HouseStore? _store;
  Diagnosis? _diagnosis;
  String? _error;
  DateTime? _updatedAt;
  int _tab = 0;

  /// 罗盘回写坐向时先关掉自动重算，避免同一次测量请求两遍
  bool _autoReload = true;

  /// 是否正在请求后端（自动刷新去重）
  bool _loading = false;

  /// 上次算出的日盘日期（今日吉位 / 忌方随日期变化）
  DateTime? _chartDate;
  /// 零点整点重算的定时器
  Timer? _midnightTimer;
  /// 兜底轮询：后台长时间挂起导致整点定时器失准时，靠它补算
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final store = await HouseStore.load();
    if (!mounted) return;
    _store = store;
    store.addListener(_onHouseChanged);
    _tickTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshIfDayChanged(),
    );
    await _load();
  }

  /// 房屋变化（切换 / 编辑 / 删除）-> 带新房屋参数重新算一遍
  void _onHouseChanged() {
    if (_autoReload) _load();
  }

  /// 跨天了就重算：今日吉位 / 今日忌方按当日日家紫白推算
  void _refreshIfDayChanged() {
    final last = _chartDate;
    if (last == null) return;
    final now = DateTime.now();
    if (now.year != last.year || now.month != last.month || now.day != last.day) {
      _load();
    }
  }

  /// 对齐到次日 00:00 重算一次，并重排下一个零点
  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final next = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    _midnightTimer = Timer(next.difference(now) + const Duration(seconds: 1), () {
      _load();
      _scheduleMidnightRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // 从后台回来：先补算（可能已跨天），再重新对齐零点
    _refreshIfDayChanged();
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _tickTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _store?.removeListener(_onHouseChanged);
    super.dispose();
  }

  /// 当前房屋；仓库尚未就绪时回退到示例房屋
  HouseProfile get _house => _store?.current ?? HouseProfile.seed();

  Future<Diagnosis> _runDiagnose({double? degree, double? declination}) {
    final h = _house;
    return _api.diagnose(
      degree: degree ?? h.degree,
      declination: declination ?? h.declination,
      year: h.year,
      houseName: h.displayName,
      area: h.area,
    );
  }

  Future<void> _load({bool force = false}) async {
    if (_loading && !force) return; // 定时器与房屋变更可能同时触发，去重
    _loading = true;
    setState(() => _error = null);
    try {
      final d = await _runDiagnose();
      if (!mounted) return;
      setState(() {
        _diagnosis = d;
        _updatedAt = DateTime.now();
        _chartDate = DateTime.tryParse(d.daily?.date ?? '') ?? DateTime.now();
      });
      _scheduleMidnightRefresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      _loading = false;
    }
  }

  /// 罗盘确认 -> 坐向写回当前房屋 -> 生成诊断报告
  Future<Diagnosis> _diagnoseFrom(double degree, double declination) async {
    final store = _store;
    if (store != null) {
      _autoReload = false;
      await store.setOrientation(degree, declination: declination);
      _autoReload = true;
    }
    final d = await _runDiagnose(degree: degree, declination: declination);
    if (!mounted) return d;
    setState(() {
      _diagnosis = d;
      _updatedAt = DateTime.now();
      _chartDate = DateTime.tryParse(d.daily?.date ?? '') ?? DateTime.now();
    });
    _scheduleMidnightRefresh();
    await Navigator.of(context).push<void>(_page(ReportPage(
      diagnosis: d,
      onRemeasure: () => Navigator.of(context).pop(),
      onViewLayout: () =>
          Navigator.of(context).push<void>(_page(const LayoutPage())),
    )));
    return d;
  }

  /// 下拉刷新：强制重算一次，并告诉用户日盘是否有变化
  /// （日家紫白一日一换，同一天刷新结果必然相同）
  Future<void> _onRefresh() async {
    final before = _chartDate;
    await _load(force: true);
    if (!mounted) return;
    final after = _chartDate;
    final String msg;
    if (after != null && after != before) {
      msg = '已更新到 ${after.month}月${after.day}日的日盘';
    } else {
      msg = '今日日盘已是最新 · 日盘一日一换，零点自动更新';
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _openHouses() async {
    final store = _store;
    if (store == null) return;
    await Navigator.of(context).push<void>(_page(HousePage(store: store)));
  }

  Route<T> _page<T>(Widget child) {
    return MaterialPageRoute<T>(
      builder: (_) => DesignCanvas(
        child: ColoredBox(color: AppColors.bg, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _diagnosis;
    return DesignCanvas(
      child: ColoredBox(
        color: AppColors.bg,
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  d == null ? _statusPage() : _home(d),
                  CompassPage(
                    service: _compass,
                    initialDegree: _house.degree,
                    declination: _house.declination,
                    onConfirm: _diagnoseFrom,
                  ),
                  const LibraryPage(),
                  const BaziPage(),
                ],
              ),
            ),
            AppTabBar(
              current: _tab,
              onTap: (i) => setState(() => _tab = i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _home(Diagnosis d) {
    return HomePage(
      diagnosis: d,
      updatedAt: _updatedAt,
      onOpenHouses: _openHouses,
      onRefresh: _onRefresh,
      onQuickAction: (i) {
        // 0 罗盘定向 1 八字排盘 2 户型诊断 3 家具布局
        switch (i) {
          case 0:
            setState(() => _tab = 1);
            break;
          case 1:
            setState(() => _tab = 3);
            break;
          case 2:
            if (_diagnosis != null) {
              Navigator.of(context).push<void>(_page(ReportPage(
                diagnosis: _diagnosis!,
                onRemeasure: () => Navigator.of(context).pop(),
                onViewLayout: () =>
                    Navigator.of(context).push<void>(_page(const LayoutPage())),
              )));
            }
            break;
          case 3:
            Navigator.of(context).push<void>(_page(const LayoutPage()));
            break;
        }
      },
    );
  }

  Widget _statusPage() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40, color: AppColors.muted),
              const SizedBox(height: 16),
              Text(
                '无法连接后端服务\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.body),
              ),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

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
import 'pages/login_page.dart';
import 'pages/report_page.dart';
import 'services/api_client.dart';
import 'services/auth_store.dart';
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
      home: const AuthGate(),
    );
  }
}

/// 登录闸门：启动时恢复 token -> 校验 -> 未登录进登录页，已登录进主界面。
/// AuthStore 是全局唯一的登录态源，任何 401 触发 forceLogout 后自动回到登录页。
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthStore? _auth;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final store = await AuthStore.load();
    AuthStore.instance = store;
    if (!mounted) return;
    store.addListener(_onAuthChanged);
    setState(() => _auth = store);
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth;
    // 闪屏：token 校验是网络请求，不能转圈太久也不能卡死
    if (auth == null || !auth.booted) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (!auth.isLoggedIn) {
      return LoginPage(auth: auth);
    }
    // key 绑定用户 id：登录/换号时强制重建 AppShell，房屋数据重新拉取
    return KeyedSubtree(
      key: ValueKey('shell-${auth.user!.id}'),
      child: AppShell(auth: auth),
    );
  }
}

/// 外壳：底部 Tab + 页面栈
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.auth});

  final AuthStore auth;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  AuthStore get _auth => widget.auth;
  final _api = ApiClient();
  final _compass = CompassServiceFactory.create();

  HouseStore? _store;
  Diagnosis? _diagnosis;
  String? _error;

  /// 缺少诊断前置数据时的阻塞原因：
  /// 'no_house'   尚未建档（不拿示例房屋顶替）
  /// 'no_measure' 已建档但还没用罗盘测过坐向
  /// null         数据齐全，可以正常请求后端
  String? _blocker;
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
    // 旧版本存在本地的房屋一次性迁到服务端
    await store.migrateLegacyIfAny();
    if (!mounted) return;
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

  /// 当前房屋；仓库尚未就绪或尚未建档时为 null，不用示例房屋顶替
  HouseProfile? get _house => _store?.current;

  Future<Diagnosis> _runDiagnose({double? degree, double? declination}) {
    final h = _house;
    if (h == null) {
      throw Exception('请先在「我的房屋」里添加房屋');
    }
    final d = degree ?? h.degree;
    if (d == null) {
      // 坐向以罗盘实测为准，不做 0 度兜底
      throw Exception('尚未测量坐向');
    }
    return _api.diagnose(
      degree: d,
      declination: declination ?? h.declination,
      year: h.year,
      houseName: h.displayName,
      layout: h.layout,
      area: h.area,
    );
  }

  Future<void> _load({bool force = false}) async {
    if (_loading && !force) return; // 定时器与房屋变更可能同时触发，去重
    _loading = true;
    // 前置数据不全时不请求后端，避免把「没数据」显示成「连不上服务」
    final h = _house;
    if (h == null) {
      // 拉列表失败要显示成网络错误，不能被当成「没有房屋」
      final err = _store?.lastError;
      if (mounted) {
        setState(() {
          _blocker = err == null ? 'no_house' : null;
          _error = err;
        });
      }
      _loading = false;
      return;
    }
    if (!h.measured) {
      if (mounted) {
        setState(() {
          _blocker = 'no_measure';
          _error = null;
        });
      }
      _loading = false;
      return;
    }
    setState(() {
      _blocker = null;
      _error = null;
    });
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
      // token 失效：全局登出，AuthGate 自动切回登录页
      if (e is ApiException && e.isUnauthorized) {
        await _auth.forceLogout();
        return;
      }
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      _loading = false;
    }
  }

  /// 罗盘确认 -> 坐向写回当前房屋 -> 生成诊断报告
  Future<Diagnosis> _diagnoseFrom(double degree, double declination) async {
    final store = _store;
    if (store == null || store.current == null) {
      // 测量结果要写回房屋档案，没有房屋就先建档
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('请先在「我的房屋」里添加房屋')),
      );
      throw Exception('请先在「我的房屋」里添加房屋');
    }
    _autoReload = false;
    try {
      await store.setOrientation(degree, declination: declination);
    } catch (e) {
      // 写入失败也继续用本次测量值出报告，只是坐向没持久化
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('坐向未能写入房屋档案：$e')),
        );
      }
    } finally {
      _autoReload = true;
    }
    if (mounted) {
      setState(() => _blocker = null);
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
      onViewLayout: () => Navigator.of(context)
          .push<void>(_page(LayoutPage(
            diagnosis: d,
            house: _house,
            onApplyRooms: _applyLayout,
          ))),
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

  /// 把布局页推荐的房间方位保存到当前房屋档案
  Future<void> _applyLayout(List<RoomProfile> rooms) async {
    final store = _store;
    final house = _house;
    if (store == null || house == null) return;
    final updated = house.copyWith(rooms: rooms);
    try {
      await store.upsert(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('布局方案保存失败：$e')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('已将该布局方案保存到当前房屋')),
    );
  }

  Future<void> _openHouses() async {
    final store = _store;
    if (store == null) return;
    await Navigator.of(context).push<void>(_page(HousePage(store: store)));
  }

  Route<T> _page<T>(Widget child) {
    return MaterialPageRoute<T>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.bg,
        body: DesignCanvas(
          child: ColoredBox(color: AppColors.bg, child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _diagnosis;
    // 用 Scaffold 包裹，确保 TextField、Button 等 Material 组件能找到 ancestor
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: DesignCanvas(
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
                      initialDegree: _house?.degree ?? 0,
                      declination: _house?.declination ?? kDefaultDeclination,
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
                onViewLayout: () => Navigator.of(context).push<void>(
                    _page(LayoutPage(
                      diagnosis: _diagnosis,
                      house: _house,
                      onApplyRooms: _applyLayout,
                    ))),
              )));
            }
            break;
          case 3:
            Navigator.of(context).push<void>(
                _page(LayoutPage(
                diagnosis: _diagnosis,
                house: _house,
                onApplyRooms: _applyLayout,
              )));
            break;
        }
      },
    );
  }

  Widget _statusPage() {
    final blocker = _blocker;
    final err = _error;
    // 缺数据 / 出错都走同一套占位样式，内容按状态区分
    final IconData icon;
    final String title;
    final String btnText;
    final VoidCallback onTap;

    if (blocker == 'no_house') {
      icon = Icons.home_outlined;
      title = '尚未建立房屋档案\n请先在「我的房屋」里添加房屋';
      btnText = '去添加房屋';
      onTap = _openHouses;
    } else if (blocker == 'no_measure') {
      icon = Icons.explore_outlined;
      title = '尚未测量坐向\n请用罗盘实测一次，坐向会自动写入当前房屋';
      btnText = '去测量';
      onTap = () => setState(() => _tab = 1);
    } else if (err != null) {
      icon = Icons.cloud_off;
      title = '无法连接后端服务\n$err';
      btnText = '重试';
      onTap = _load;
    } else {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 40, color: AppColors.muted),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.body),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: onTap, child: Text(btnText)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

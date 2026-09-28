import 'package:flutter/material.dart';

import 'models/diagnosis.dart';
import 'pages/bazi_page.dart';
import 'pages/compass_page.dart';
import 'pages/home_page.dart';
import 'pages/layout_page.dart';
import 'pages/library_page.dart';
import 'pages/report_page.dart';
import 'services/api_client.dart';
import 'services/compass_service.dart';
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

class _AppShellState extends State<AppShell> {
  final _api = ApiClient();
  final _compass = CompassServiceFactory.create();

  Diagnosis? _diagnosis;
  String? _error;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = await _api.diagnose(
        degree: 358,
        declination: -5.2,
        year: DateTime.now().year,
        houseName: '朗诗国际 3室2厅',
        area: 96,
      );
      if (!mounted) return;
      setState(() => _diagnosis = d);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  /// 罗盘确认 -> 生成诊断报告
  Future<Diagnosis> _diagnoseFrom(double degree, double declination) async {
    final d = await _api.diagnose(
      degree: degree,
      declination: declination,
      year: DateTime.now().year,
      houseName: '朗诗国际 3室2厅',
      area: 96,
    );
    if (!mounted) return d;
    setState(() => _diagnosis = d);
    await Navigator.of(context).push<void>(_page(ReportPage(
      diagnosis: d,
      onRemeasure: () => Navigator.of(context).pop(),
      onViewLayout: () =>
          Navigator.of(context).push<void>(_page(const LayoutPage())),
    )));
    return d;
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

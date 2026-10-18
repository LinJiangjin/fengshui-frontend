import 'package:flutter/material.dart';

import 'demo_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/scheme_space_view.dart';

/// 开发预览入口：不随正式包发布。
///
/// 空间示意依赖「房屋档案 + 方案」，真机上要先有房才能看到，
/// 这里用一份样例数据直接渲染两种视角，方便对设计。
///
/// 构建：flutter build web -t lib/dev/space_preview.dart
void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    final house = demoHouse();
    final scheme = demoScheme();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.bg,
        body: DesignCanvas(
          child: ColoredBox(
            color: AppColors.bg,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('空间示意 · 预览', style: AppText.pageTitle),
                  const SizedBox(height: 6),
                  Text(
                    '样例：${house.displayName} · ${house.areaText} · '
                    '${house.orientation?.readable ?? ''}',
                    style: AppText.label11,
                  ),
                  const SizedBox(height: 16),
                  _block('平面图', SchemeSpaceView(
                    house: house,
                    scheme: scheme,
                    mode: SpaceViewMode.plan,
                  )),
                  const SizedBox(height: 16),
                  _block('立体图', SchemeSpaceView(
                    house: house,
                    scheme: scheme,
                    mode: SpaceViewMode.solid,
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _block(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(title, style: AppText.cardTitle),
          ),
          child,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'demo_data.dart';
import '../pages/scheme_detail_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// 开发预览入口：直接看「方案详情」整页（含新增的空间示意段）。
///
/// 构建：flutter build web -t lib/dev/scheme_detail_preview.dart
void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.bg,
        body: DesignCanvas(
          child: ColoredBox(
            color: AppColors.bg,
            child: SchemeDetailPage(
              scheme: demoScheme(),
              house: demoHouse(),
            ),
          ),
        ),
      ),
    );
  }
}

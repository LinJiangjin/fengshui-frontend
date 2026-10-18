import 'package:flutter/material.dart';

import 'demo_data.dart';
import '../pages/scheme_detail_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// 开发预览入口：方案详情页的「还没分配房间」空态（本页可直接点九宫格加房间）。
///
/// 构建：flutter build web -t lib/dev/scheme_empty_preview.dart
void main() {
  final house = demoHouse().copyWith(rooms: const []);
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: AppColors.bg,
      body: DesignCanvas(
        child: ColoredBox(
          color: AppColors.bg,
          child: SchemeDetailPage(scheme: demoScheme(), house: house),
        ),
      ),
    ),
  ));
}

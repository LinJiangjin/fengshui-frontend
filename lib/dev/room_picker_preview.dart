import 'package:flutter/material.dart';

import 'demo_data.dart';
import '../models/house.dart';
import '../pages/scheme_detail_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// 开发预览入口：「房间布局」弹层（含改宫位 / 删除房间）。
/// 真机上要先进方案详情再点「＋加房间」才弹得出来，这里直接摆出来对样式。
///
/// 构建：flutter build web -t lib/dev/room_picker_preview.dart
void main() {
  final rooms = demoHouse().rooms.take(4).toList();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: AppColors.bg,
      body: DesignCanvas(
        child: ColoredBox(
          color: AppColors.bg,
          child: Column(
            children: [
              const Spacer(),
              RoomPickerSheet(
                rooms: rooms,
                onAdd: (int cell) async {},
                onRemove: (RoomProfile room) async {},
                onEdit: (RoomProfile room) async {},
              ),
            ],
          ),
        ),
      ),
    ),
  ));
}

import 'package:flutter/material.dart';

import '../models/house.dart';
import '../models/library.dart';

/// 开发预览用的样例数据（不进正式包）。
/// 参数与 `server/app/seed_library.py` 里的「新中式 · 水墨禅意」一致。

/// 样例房屋：坐东朝西（与罗盘页同一角度），10 个房间铺满 9 个宫位
HouseProfile demoHouse() {
  return HouseProfile(
    id: 'preview',
    name: '朗诗国际',
    layout: '3室2厅',
    area: 96,
    degree: 101,
    declination: 0,
    rooms: [
      RoomProfile(id: '1', name: '客厅', cell: 1),
      RoomProfile(id: '2', name: '主卧', cell: 2),
      RoomProfile(id: '3', name: '次卧', cell: 0),
      RoomProfile(id: '4', name: '儿童房', cell: 0),
      RoomProfile(id: '5', name: '厨房', cell: 7),
      RoomProfile(id: '6', name: '卫生间', cell: 8),
      RoomProfile(id: '7', name: '书房', cell: 6),
      RoomProfile(id: '8', name: '餐厅', cell: 3),
      RoomProfile(id: '9', name: '玄关', cell: 4),
      RoomProfile(id: '10', name: '阳台', cell: 5),
    ],
  );
}

LibraryScheme demoScheme() {
  return LibraryScheme(
    id: 'preview',
    title: '新中式 · 水墨禅意',
    subtitle: '新中式',
    from: const Color(0xFFC9BDAA),
    to: const Color(0xFF4A4034),
    tag: '新中式',
    element: '木',
    area: 96,
    summary:
        '以宣纸白铺底、墨色压低重心，木色作骨架。留白多、进深浅，适合采光一般的紧凑户型；家具宜矮、宜疏，避免把墙面占满。',
    highlights: const [
      '墙面一律宣纸白，木饰面只做三分之一，留白是这一版的主体',
      '客厅主灯改间接光，压低色温到 2700K，墨玉色只用在地面收边',
      '书房用最深的一档木色，把视觉重心压到最里面那间',
    ],
    colors: [
      PaletteColor(name: '宣纸白', color: const Color(0xFFF5F1E8)),
      PaletteColor(name: '浅木', color: const Color(0xFFC9A57A)),
      PaletteColor(name: '灰陶', color: const Color(0xFFA79C88)),
      PaletteColor(name: '墨玉', color: const Color(0xFF24352F)),
    ],
    rooms: [
      RoomPlan(name: '客厅', color: const Color(0xFFD9D3C4), note: '大面积铺底，家具压低重心'),
      RoomPlan(name: '主卧', color: const Color(0xFFC9A57A), note: '床头墙一档浅木，其余留白'),
      RoomPlan(name: '书房', color: const Color(0xFF7C6B52), note: '整面木色，把光线收进来'),
      RoomPlan(name: '玄关', color: const Color(0xFF24352F), note: '墨玉收边，进门先压一层'),
    ],
    elementFit: '命局喜木、喜水的人住着最顺：木色骨架配宣纸白，气口留在东南与正东',
    elementAvoid: '忌大面积金属与高光烤漆，会把这套的木气削掉，住久了显冷',
  );
}

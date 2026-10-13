import 'dart:ui';

/// 装修方案库（由后端 /api/v1/library 下发，前端不再内置写死的方案与配色）
Color _hexColor(String? s) {
  final v = (s ?? '').replaceAll('#', '');
  if (v.length == 6) {
    final n = int.tryParse('FF$v', radix: 16);
    if (n != null) return Color(n);
  }
  return const Color(0xFFE4DCCB);
}

/// 配色色块（方案主色板 / 本月配色通用）
class PaletteColor {
  PaletteColor({required this.name, required this.color});

  final String name;
  final Color color;

  factory PaletteColor.fromJson(Map<String, dynamic> j) =>
      PaletteColor(name: j['name'] ?? '', color: _hexColor(j['hex'] as String?));
}

/// 分区配色建议：某个房间用什么色、怎么用
class RoomPlan {
  RoomPlan({required this.name, required this.color, required this.note});

  final String name;
  final Color color;
  final String note;

  factory RoomPlan.fromJson(Map<String, dynamic> j) => RoomPlan(
        name: j['name'] ?? '',
        color: _hexColor(j['hex'] as String?),
        note: j['note'] ?? '',
      );
}

class LibraryScheme {
  LibraryScheme({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.from,
    required this.to,
    required this.tag,
    required this.element,
    required this.area,
    required this.summary,
    required this.highlights,
    required this.colors,
    required this.rooms,
    required this.elementFit,
    required this.elementAvoid,
  });

  final String id;
  final String title;
  final String subtitle;
  final Color from;
  final Color to;
  final String tag;
  final String element;
  final int area;
  final String summary;
  final List<String> highlights;
  final List<PaletteColor> colors;
  final List<RoomPlan> rooms;

  /// 五行宜 / 忌，详情页的五行解读用
  final String elementFit;
  final String elementAvoid;

  /// 搜索用文本：把标题、风格、五行、面积拼在一起，
  /// 这样搜「木」「96」「侘寂」都能命中
  String get searchText => '$title $subtitle $tag $element $area';

  factory LibraryScheme.fromJson(Map<String, dynamic> j) {
    final note = (j['element_note'] as Map<String, dynamic>? ?? {});
    return LibraryScheme(
      id: j['id'] ?? '',
      title: j['title'] ?? '',
      subtitle: j['subtitle'] ?? '',
      from: _hexColor(j['from'] as String?),
      to: _hexColor(j['to'] as String?),
      tag: j['tag'] ?? '',
      element: j['element'] ?? '',
      area: (j['area'] as num?)?.toInt() ?? 0,
      summary: j['summary'] ?? '',
      highlights:
          (j['highlights'] as List? ?? []).map((e) => e.toString()).toList(),
      colors: (j['colors'] as List? ?? [])
          .map((e) => PaletteColor.fromJson(e as Map<String, dynamic>))
          .toList(),
      rooms: (j['rooms'] as List? ?? [])
          .map((e) => RoomPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      elementFit: note['fit'] ?? '',
      elementAvoid: note['avoid'] ?? '',
    );
  }
}

/// 面积区间筛选项；max == 0 表示不设上限
class AreaRange {
  AreaRange({required this.label, required this.min, required this.max});

  final String label;
  final int min;
  final int max;

  bool get unlimited => min == 0 && max == 0;

  bool contains(int area) => area >= min && (max == 0 || area <= max);

  factory AreaRange.fromJson(Map<String, dynamic> j) => AreaRange(
        label: j['label'] ?? '',
        min: (j['min'] as num?)?.toInt() ?? 0,
        max: (j['max'] as num?)?.toInt() ?? 0,
      );
}

class LibraryPalette {
  LibraryPalette({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.names,
  });

  /// 标题由后端按当前月份生成，如「10月五行配色推荐」
  final String title;
  final String subtitle;
  final List<PaletteColor> colors;
  final String names;

  factory LibraryPalette.fromJson(Map<String, dynamic> j) => LibraryPalette(
        title: j['title'] ?? '配色推荐',
        subtitle: j['subtitle'] ?? '',
        colors: (j['colors'] as List? ?? [])
            .map((e) => PaletteColor.fromJson(e as Map<String, dynamic>))
            .toList(),
        names: j['names'] ?? '',
      );
}

class LibraryData {
  LibraryData({
    required this.filters,
    required this.elements,
    required this.areaRanges,
    required this.schemes,
    required this.palette,
  });

  final List<String> filters;
  final List<String> elements;
  final List<AreaRange> areaRanges;
  final List<LibraryScheme> schemes;
  final LibraryPalette palette;

  factory LibraryData.fromJson(Map<String, dynamic> j) => LibraryData(
        filters: (j['filters'] as List? ?? []).map((e) => e.toString()).toList(),
        elements:
            (j['elements'] as List? ?? []).map((e) => e.toString()).toList(),
        areaRanges: (j['area_ranges'] as List? ?? [])
            .map((e) => AreaRange.fromJson(e as Map<String, dynamic>))
            .toList(),
        schemes: (j['schemes'] as List? ?? [])
            .map((e) => LibraryScheme.fromJson(e as Map<String, dynamic>))
            .toList(),
        palette: LibraryPalette.fromJson(
            j['palette'] as Map<String, dynamic>? ?? {}),
      );
}

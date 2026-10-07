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

class LibraryScheme {
  LibraryScheme({
    required this.title,
    required this.subtitle,
    required this.from,
    required this.to,
    required this.tag,
  });

  final String title;
  final String subtitle;
  final Color from;
  final Color to;
  final String tag;

  factory LibraryScheme.fromJson(Map<String, dynamic> j) => LibraryScheme(
        title: j['title'] ?? '',
        subtitle: j['subtitle'] ?? '',
        from: _hexColor(j['from'] as String?),
        to: _hexColor(j['to'] as String?),
        tag: j['tag'] ?? '',
      );
}

class PaletteColor {
  PaletteColor({required this.name, required this.color});

  final String name;
  final Color color;

  factory PaletteColor.fromJson(Map<String, dynamic> j) =>
      PaletteColor(name: j['name'] ?? '', color: _hexColor(j['hex'] as String?));
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
    required this.schemes,
    required this.palette,
  });

  final List<String> filters;
  final List<LibraryScheme> schemes;
  final LibraryPalette palette;

  factory LibraryData.fromJson(Map<String, dynamic> j) => LibraryData(
        filters: (j['filters'] as List? ?? []).map((e) => e.toString()).toList(),
        schemes: (j['schemes'] as List? ?? [])
            .map((e) => LibraryScheme.fromJson(e as Map<String, dynamic>))
            .toList(),
        palette: LibraryPalette.fromJson(
            j['palette'] as Map<String, dynamic>? ?? {}),
      );
}

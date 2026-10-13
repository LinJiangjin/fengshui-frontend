import 'package:flutter/material.dart';

import '../models/library.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import 'scheme_detail_page.dart';

/// S6 · 装修方案库
///
/// 方案与配色全部由后端 /api/v1/library 下发：
/// 「本月五行配色」由服务端按当前月份推算，页面内不再有写死的内容。
///
/// 筛选分三层，可叠加：
/// 1. 顶部风格 chips（对应方案 tag）
/// 2. 搜索框（匹配标题 / 风格 / 五行 / 面积）
/// 3. 右上角筛选面板（面积区间 + 五行属性）
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();

  late Future<LibraryData> _future;

  String _filter = '全部';
  String _keyword = '';
  String? _element; // 五行筛选，null = 不限
  AreaRange? _area; // 面积区间，null = 不限

  /// 除顶部 chips 外是否还有生效的筛选（用于右上角小红点）
  bool get _hasExtraFilter => _element != null || _area != null;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchLibrary();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _future = _api.fetchLibrary());
  }

  /// 按当前三层条件过滤；全部在本地做，方案量级很小
  List<LibraryScheme> _applyFilters(LibraryData data) {
    final kw = _keyword.trim().toLowerCase();
    return data.schemes.where((s) {
      if (_filter != '全部' && s.tag != _filter) return false;
      if (_element != null && s.element != _element) return false;
      if (_area != null && !_area!.unlimited && !_area!.contains(s.area)) {
        return false;
      }
      if (kw.isNotEmpty && !s.searchText.toLowerCase().contains(kw)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _clearAllFilters() {
    _searchCtrl.clear();
    setState(() {
      _keyword = '';
      _element = null;
      _area = null;
      _filter = '全部';
    });
  }

  void _openDetail(LibraryScheme scheme) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.bg,
          body: DesignCanvas(
            child: ColoredBox(
              color: AppColors.bg,
              child: SchemeDetailPage(scheme: scheme),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ 筛选面板
  Future<void> _openFilterSheet(LibraryData data) async {
    String? tmpElement = _element;
    AreaRange? tmpArea = _area;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.track,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    const Text('筛选', style: AppText.pageTitle),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setSheet(() {
                        tmpElement = null;
                        tmpArea = null;
                      }),
                      child: Text(
                        '重置',
                        style: AppText.medium13.copyWith(color: AppColors.body),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('面积', style: AppText.cardTitle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.areaRanges.map((r) {
                    final active = tmpArea == null
                        ? r.unlimited
                        : r.label == tmpArea!.label;
                    return _sheetChip(
                      r.label,
                      active,
                      () => setSheet(() => tmpArea = r.unlimited ? null : r),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('五行属性', style: AppText.cardTitle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _sheetChip(
                      '不限',
                      tmpElement == null,
                      () => setSheet(() => tmpElement = null),
                    ),
                    ...data.elements.map(
                      (e) => _sheetChip(
                        '属$e',
                        tmpElement == e,
                        () => setSheet(() => tmpElement = e),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.of(sheetContext).pop(true),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    alignment: Alignment.center,
                    child: const Text('确定', style: AppText.button14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (applied != true || !mounted) return;
    setState(() {
      _element = tmpElement;
      _area = tmpArea;
    });
  }

  Widget _sheetChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border:
              active ? null : Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Text(
          label,
          style: AppText.medium13.copyWith(
            color: active ? Colors.white : AppColors.body,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ 页面
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LibraryData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (!snap.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadH),
              child: _errorView(snap.error?.toString() ?? '加载失败'),
            ),
          );
        }
        return _content(snap.data!);
      },
    );
  }

  Widget _errorView(String msg) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 32, color: AppColors.muted),
          const SizedBox(height: AppDimens.gapL),
          const Text('方案库加载失败', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapXS),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: AppText.body12,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimens.gapXL),
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: _retry,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primarySoftBorder),
                backgroundColor: AppColors.primarySoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.rPill),
                ),
              ),
              child: Text(
                '重试',
                style: AppText.medium13.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(LibraryData data) {
    final schemes = _applyFilters(data);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadH, 4, AppDimens.pagePadH, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(data),
          const SizedBox(height: AppDimens.gapL),
          _search(),
          const SizedBox(height: AppDimens.gapL),
          _chips(data.filters),
          const SizedBox(height: AppDimens.gapL),
          _grid(schemes),
          const SizedBox(height: AppDimens.gapL),
          _paletteCard(data.palette),
        ],
      ),
    );
  }

  Widget _header(LibraryData data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 左侧不再放返回图标（此页为底部导航页），占位与右侧筛选图标等宽，让标题保持居中
        const SizedBox(width: 20),
        const Text('装修方案库', style: AppText.pageTitle),
        GestureDetector(
          onTap: () => _openFilterSheet(data),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const AppIcon(AppIconKind.filter, size: 20, color: AppColors.ink),
              if (_hasExtraFilter)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _search() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          const AppIcon(AppIconKind.search, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _keyword = v),
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              style: AppText.medium13,
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '搜风格 / 户型 / 五行配色',
                hintStyle: AppText.label12,
              ),
            ),
          ),
          if (_keyword.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _keyword = '');
              },
              child: const Icon(Icons.close, size: 16, color: AppColors.muted),
            ),
        ],
      ),
    );
  }

  Widget _chips(List<String> filters) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (i) {
          final active = filters[i] == _filter;
          return Padding(
            padding: EdgeInsets.only(right: i == filters.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = filters[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: active
                      ? null
                      : Border.all(color: AppColors.cardBorder, width: 1),
                ),
                child: Text(
                  filters[i],
                  style: AppText.medium12.copyWith(
                    color: active ? Colors.white : AppColors.body,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _grid(List<LibraryScheme> schemes) {
    if (schemes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimens.gapXL),
        decoration: appCard(),
        child: Column(
          children: [
            const Text('没有符合条件的方案', style: AppText.cardTitle),
            const SizedBox(height: AppDimens.gapXS),
            const Text(
              '换个关键词，或放宽面积与五行筛选',
              style: AppText.body12,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.gapXL),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: _clearAllFilters,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primarySoftBorder),
                  backgroundColor: AppColors.primarySoft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.rPill),
                  ),
                ),
                child: Text(
                  '清除筛选条件',
                  style: AppText.medium13.copyWith(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: schemes.map((s) {
        return GestureDetector(
          onTap: () => _openDetail(s),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 169,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 169,
                  height: 112,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [s.from, s.to],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.26),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '属${s.element}',
                          style: AppText.medium11
                              .copyWith(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(s.title, style: AppText.cardTitle.copyWith(fontSize: 13)),
                const SizedBox(height: 4),
                Text(s.subtitle, style: AppText.label11),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _paletteCard(LibraryPalette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(palette.title, style: AppText.cardTitle),
              ),
              Text(palette.subtitle, style: AppText.label11),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: palette.colors.map((p) {
              return Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: p.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(palette.names, style: AppText.label11),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/library.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// S6 · 装修方案库
///
/// 方案与配色全部由后端 /api/v1/library 下发：
/// 「本月五行配色」由服务端按当前月份推算，页面内不再有写死的内容。
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final ApiClient _api = ApiClient();

  late Future<LibraryData> _future;
  String _filter = '全部';

  @override
  void initState() {
    super.initState();
    _future = _api.fetchLibrary();
  }

  void _retry() {
    setState(() => _future = _api.fetchLibrary());
  }

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
    final schemes = _filter == '全部'
        ? data.schemes
        : data.schemes.where((s) => s.tag == _filter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadH, 4, AppDimens.pagePadH, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
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

  Widget _header() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppIcon(AppIconKind.back, size: 22, color: AppColors.ink),
        Text('装修方案库', style: AppText.pageTitle),
        AppIcon(AppIconKind.filter, size: 20, color: AppColors.ink),
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
      child: const Row(
        children: [
          AppIcon(AppIconKind.search, size: 18, color: AppColors.muted),
          SizedBox(width: 8),
          Text('搜风格 / 户型 / 五行配色', style: AppText.label12),
        ],
      ),
    );
  }

  Widget _chips(List<String> filters) {
    return Row(
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
    );
  }

  Widget _grid(List<LibraryScheme> schemes) {
    if (schemes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimens.gapXL),
        decoration: appCard(),
        child: const Center(
          child: Text('该分类下暂无方案', style: AppText.body12),
        ),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: schemes.map((s) {
        return SizedBox(
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
              ),
              const SizedBox(height: 8),
              Text(s.title, style: AppText.cardTitle.copyWith(fontSize: 13)),
              const SizedBox(height: 4),
              Text(s.subtitle, style: AppText.label11),
            ],
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

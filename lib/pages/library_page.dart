import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// S6 · 装修方案库
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  static const _filters = ['全部', '新中式', '日式侘寂', '现代原木'];

  static const _schemes = [
    ('新中式 · 水墨禅意', '五行属木 · 96㎡', Color(0xFFD9D3C4), Color(0xFF7C6B52)),
    ('日式侘寂 · 素白原木', '五行属土 · 88㎡', Color(0xFFE8E3D8), Color(0xFFA79C88)),
    ('现代原木 · 自然光宅', '五行属木 · 110㎡', Color(0xFFE4DCCB), Color(0xFFC0A97E)),
    ('轻奢东方 · 墨玉金线', '五行属金 · 128㎡', Color(0xFF2A3B35), Color(0xFFBE9351)),
  ];

  static const _palette = [
    ('墨玉', Color(0xFF24352F)),
    ('松绿', Color(0xFF3F7A5E)),
    ('宣纸', Color(0xFFF5F1E8)),
    ('原木', Color(0xFFC9A57A)),
    ('黄铜', Color(0xFFBE9351)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.pagePadH, 4, AppDimens.pagePadH, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: AppDimens.gapL),
                _search(),
                const SizedBox(height: AppDimens.gapL),
                _chips(),
                const SizedBox(height: AppDimens.gapL),
                _grid(),
                const SizedBox(height: AppDimens.gapL),
                _paletteCard(),
              ],
            ),
          ),
        ),
      ],
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

  Widget _chips() {
    return Row(
      children: List.generate(_filters.length, (i) {
        final active = i == 0;
        return Padding(
          padding: EdgeInsets.only(right: i == _filters.length - 1 ? 0 : 8),
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
              _filters[i],
              style: AppText.medium12.copyWith(
                color: active ? Colors.white : AppColors.body,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _grid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _schemes.map((s) {
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
                    colors: [s.$3, s.$4],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(s.$1, style: AppText.cardTitle.copyWith(fontSize: 13)),
              const SizedBox(height: 4),
              Text(s.$2, style: AppText.label11),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _paletteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('本月五行配色推荐', style: AppText.cardTitle),
              Text('木火相生 · 宜暖调', style: AppText.label11),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _palette.map((p) {
              return Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: p.$2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text('墨玉 · 松绿 · 宣纸 · 原木 · 黄铜', style: AppText.label11),
        ],
      ),
    );
  }
}

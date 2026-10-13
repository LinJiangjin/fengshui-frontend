import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/china_geo.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// 出生地选择结果：省份 + 城市坐标（含自动带出的东经度数）
class CityPickResult {
  const CityPickResult(this.province, this.city);

  final String province;
  final CityCoord city;
}

/// 出生地选择面板
///
/// 左侧省份、右侧城市，顶部支持按城市 / 省份关键字搜索。
/// 点选城市即返回该城市坐标，页面据此自动填充东经度数。
class CityPickerSheet extends StatefulWidget {
  const CityPickerSheet({super.key, this.selectedProvince, this.selectedCity});

  final String? selectedProvince;
  final String? selectedCity;

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  final TextEditingController _search = TextEditingController();

  int _provinceIndex = 0;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    final idx = ChinaGeo.provinces
        .indexWhere((p) => p.name == widget.selectedProvince);
    if (idx >= 0) _provinceIndex = idx;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// 关键字命中的城市（同时匹配城市名与省份名）
  List<CityPickResult> get _matches {
    final kw = _keyword.trim();
    if (kw.isEmpty) return const [];
    final out = <CityPickResult>[];
    for (final p in ChinaGeo.provinces) {
      final hitProvince = p.name.contains(kw);
      for (final c in p.cities) {
        if (hitProvince || c.name.contains(kw)) {
          out.add(CityPickResult(p.name, c));
        }
      }
    }
    return out;
  }

  void _choose(String province, CityCoord city) {
    Navigator.of(context).pop(CityPickResult(province, city));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final province = ChinaGeo.provinces[_provinceIndex];
    // 小屏 / 键盘弹出时按可用高度收缩，避免列表溢出
    final height = math.min(470.0, media.size.height * 0.7);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppDimens.gapS),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.track,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.pagePadH, AppDimens.gapM, AppDimens.gapM, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('选择出生地', style: AppText.section),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 20, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.pagePadH, AppDimens.gapM, AppDimens.pagePadH, 0),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _keyword = v),
                style: AppText.medium13.copyWith(color: AppColors.body),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '搜索城市，如 广州',
                  hintStyle: AppText.body12.copyWith(color: AppColors.muted),
                  prefixIcon:
                      const Icon(Icons.search, size: 18, color: AppColors.muted),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 34, minHeight: 34),
                  filled: true,
                  fillColor: AppColors.iconBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.rS),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.rS),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.rS),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.gapM),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            Expanded(
              child: _keyword.trim().isEmpty
                  ? _browse(province)
                  : _resultList(_matches),
            ),
          ],
        ),
      ),
    );
  }

  /// 浏览态：左省右市
  Widget _browse(ProvinceGeo province) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 104,
          child: Container(
            color: AppColors.primarySoftBg,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.gapS),
              itemCount: ChinaGeo.provinces.length,
              itemBuilder: (_, i) {
                final on = i == _provinceIndex;
                return GestureDetector(
                  onTap: () => setState(() => _provinceIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: on ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      ChinaGeo.provinces[i].name,
                      style: AppText.medium13.copyWith(
                        color: on ? AppColors.primary : AppColors.body,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.gapS),
            itemCount: province.cities.length,
            itemBuilder: (_, i) => _cityTile(province.name, province.cities[i]),
          ),
        ),
      ],
    );
  }

  Widget _resultList(List<CityPickResult> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('没有匹配的城市', style: AppText.body12),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.gapS),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final r = items[i];
        return _cityTile(r.province, r.city, prefix: r.province);
      },
    );
  }

  Widget _cityTile(String province, CityCoord city, {String? prefix}) {
    final on = widget.selectedProvince == province &&
        widget.selectedCity == city.name;
    return GestureDetector(
      onTap: () => _choose(province, city),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                prefix == null ? city.name : '$prefix · ${city.name}',
                style: AppText.medium13
                    .copyWith(color: on ? AppColors.primary : AppColors.ink),
              ),
            ),
            Text(
              '${city.longitude.toStringAsFixed(2)}°E',
              style: AppText.number12.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

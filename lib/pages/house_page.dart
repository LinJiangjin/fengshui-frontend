import 'package:flutter/material.dart';

import '../models/house.dart';
import '../models/orientation_calc.dart';
import '../services/house_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// 我的房屋：切换 / 新增 / 编辑房屋档案。
///
/// 房屋信息是诊断的唯一输入源，改动后 HouseStore 会通知上层，
/// 上层带新参数重新请求 /api/v1/diagnose，拿到该房屋真实算出的结果。
class HousePage extends StatelessWidget {
  const HousePage({super.key, required this.store});

  final HouseStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final houses = store.houses;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePadH, 4, AppDimens.pagePadH, 104),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              const SizedBox(height: AppDimens.gapXL),
              for (final h in houses)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.gapL),
                  child: _houseCard(context, h),
                ),
              const SizedBox(height: AppDimens.gapS),
              _addButton(context),
              const SizedBox(height: AppDimens.gapXL),
              const Text(
                '修改名称、户型、面积或坐向后，首页评分与建议会按新房屋重新计算。',
                style: AppText.label11,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('我的房屋', style: AppText.pageTitle),
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: const AppIcon(AppIconKind.back, size: 20, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _houseCard(BuildContext context, HouseProfile h) {
    final selected = store.isCurrent(h.id);
    final o = h.orientation;
    return GestureDetector(
      onTap: () => store.select(h.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: appCard(
          radius: AppDimens.rL,
          border: selected ? AppColors.primary : AppColors.cardBorder,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment(-0.7, -0.7),
                  end: Alignment(0.7, 1.0),
                  colors: [Color(0xFFC7AD78), Color(0xFF6B8C80)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                h.name.isNotEmpty ? h.name.substring(0, 1) : '宅',
                style: AppText.value17.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: AppDimens.gapL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.displayName, style: AppText.medium15),
                  const SizedBox(height: 4),
                  Text(
                    '${h.areaText} · ${o.title} · ${o.readable}',
                    style: AppText.label12,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '真北 ${h.trueNorth.toStringAsFixed(0)}° · 磁偏角 ${h.declination.toStringAsFixed(1)}°',
                    style: AppText.label11,
                  ),
                ],
              ),
            ),
            if (selected)
              const AppIcon(AppIconKind.check, size: 18, color: AppColors.primary),
            const SizedBox(width: AppDimens.gapS),
            GestureDetector(
              onTap: () => _edit(context, h),
              child: const AppIcon(AppIconKind.edit, size: 18, color: AppColors.muted),
            ),
            if (store.houses.length > 1) ...[
              const SizedBox(width: AppDimens.gapL),
              GestureDetector(
                onTap: () => _confirmDelete(context, h),
                child: const AppIcon(AppIconKind.warn,
                    size: 18, color: AppColors.danger),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _addButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _edit(context, null),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.iconBg,
          borderRadius: BorderRadius.circular(AppDimens.rL),
          border: Border.all(color: AppColors.primarySoftBorder, width: 1),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(AppIconKind.plan, size: 18, color: AppColors.primary),
            const SizedBox(width: AppDimens.gapS),
            Text('新增房屋',
                style: AppText.medium13.copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, HouseProfile? house) async {
    final result = await showModalBottomSheet<HouseProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: HouseFormSheet(house: house),
      ),
    );
    if (result != null) await store.upsert(result);
  }

  Future<void> _confirmDelete(BuildContext context, HouseProfile h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除房屋', style: AppText.cardTitle),
        content: Text('确定删除「${h.displayName}」？', style: AppText.body13),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: AppText.medium13),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除',
                style: AppText.medium13),
          ),
        ],
      ),
    );
    if (ok == true) await store.remove(h.id);
  }
}

/// 房屋编辑表单（新增 / 修改共用）
class HouseFormSheet extends StatefulWidget {
  const HouseFormSheet({super.key, this.house});

  final HouseProfile? house;

  @override
  State<HouseFormSheet> createState() => _HouseFormSheetState();
}

class _HouseFormSheetState extends State<HouseFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _layout;
  late final TextEditingController _area;
  late final TextEditingController _degree;
  late final TextEditingController _declination;

  static const layouts = ['1室1厅', '2室1厅', '3室2厅', '4室2厅'];

  @override
  void initState() {
    super.initState();
    final h = widget.house;
    _name = TextEditingController(text: h?.name ?? '');
    _layout = TextEditingController(text: h?.layout ?? '');
    _area = TextEditingController(text: h != null ? _num(h.area) : '96');
    _degree = TextEditingController(
        text: h != null ? h.trueNorth.toStringAsFixed(0) : '352');
    _declination =
        TextEditingController(text: _num(h?.declination ?? kDefaultDeclination));
  }

  @override
  void dispose() {
    _name.dispose();
    _layout.dispose();
    _area.dispose();
    _degree.dispose();
    _declination.dispose();
    super.dispose();
  }

  static String _num(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);

  double get _trueNorth => double.tryParse(_degree.text.trim()) ?? 0;

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _toast('请填写房屋名称');
      return;
    }
    final area = double.tryParse(_area.text.trim());
    if (area == null || area <= 0) {
      _toast('面积请填大于 0 的数字');
      return;
    }
    final degree = double.tryParse(_degree.text.trim());
    if (degree == null) {
      _toast('坐向请填 0 ~ 359 度');
      return;
    }
    final declination = double.tryParse(_declination.text.trim()) ?? kDefaultDeclination;
    final old = widget.house;
    final house = HouseProfile(
      id: old?.id ?? newHouseId(),
      name: name,
      layout: _layout.text.trim(),
      area: area,
      // 表单填的是真北度数，换算回磁北读数，后端统一做偏角校正
      degree: degree - declination,
      declination: declination,
      year: old?.year ?? DateTime.now().year,
    );
    Navigator.of(context).pop(house);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final o = OrientationCalc.of(_trueNorth);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.rXL)),
      ),
      padding: const EdgeInsets.fromLTRB(AppDimens.pagePadH, 12,
          AppDimens.pagePadH, AppDimens.pagePadH),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: AppDimens.gapXL),
              Text(
                widget.house == null ? '新增房屋' : '编辑房屋',
                style: AppText.pageTitle,
              ),
              const SizedBox(height: AppDimens.gapXL),
              _field('房屋名称', _name, '如：朗诗国际'),
              const SizedBox(height: AppDimens.gapL),
              _field('户型', _layout, '如：3室2厅'),
              const SizedBox(height: AppDimens.gapS),
              Wrap(
                spacing: AppDimens.gapS,
                children: [
                  for (final l in layouts)
                    GestureDetector(
                      onTap: () => setState(() => _layout.text = l),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _layout.text.trim() == l
                              ? AppColors.primarySoft
                              : AppColors.iconBg,
                          borderRadius: BorderRadius.circular(AppDimens.rPill),
                          border: Border.all(
                            color: _layout.text.trim() == l
                                ? AppColors.primary
                                : AppColors.iconBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          l,
                          style: AppText.label12.copyWith(
                            color: _layout.text.trim() == l
                                ? AppColors.primary
                                : AppColors.body,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.gapL),
              Row(
                children: [
                  Expanded(child: _field('建筑面积（㎡）', _area, '96', number: true)),
                  const SizedBox(width: AppDimens.gapL),
                  Expanded(
                      child: _field('坐向（真北°）', _degree, '0 ~ 359',
                          number: true)),
                ],
              ),
              const SizedBox(height: AppDimens.gapL),
              _field('磁偏角（°）', _declination, '如：-5.2', number: true),
              const SizedBox(height: AppDimens.gapL),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tipBg,
                  borderRadius: BorderRadius.circular(AppDimens.rM),
                  border: Border.all(color: AppColors.tipBorder, width: 1),
                ),
                child: Row(
                  children: [
                    const AppIcon(AppIconKind.compass,
                        size: 18, color: AppColors.gold),
                    const SizedBox(width: AppDimens.gapS),
                    Expanded(
                      child: Text(
                        '${_trueNorth.toStringAsFixed(0)}° → ${o.title} · ${o.readable} · ${o.houseType}',
                        style: AppText.body12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.gapXL),
              GestureDetector(
                onTap: _save,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimens.rPill),
                    boxShadow: primaryShadow,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.house == null ? '保存并使用' : '保存并重新测算',
                    style: AppText.button15,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.gapM),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c,
    String hint, {
    bool number = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label12),
        const SizedBox(height: AppDimens.gapS),
        TextField(
          controller: c,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true, signed: true)
              : TextInputType.text,
          onChanged: (_) => setState(() {}),
          style: AppText.medium13,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.card,
            hintText: hint,
            hintStyle: AppText.label12,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.rM),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.rM),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.rM),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

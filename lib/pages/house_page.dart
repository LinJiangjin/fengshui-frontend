import 'package:flutter/material.dart';

import '../models/house.dart';
import '../models/orientation_calc.dart';
import '../models/palace_grid.dart';
import '../services/api_client.dart' show ApiException, kApiBaseUrl;
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
    final orientText = o == null ? '尚未测量坐向' : '${o.title} · ${o.readable}';
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
                    '${h.areaText} · $orientText',
                    style: AppText.label12,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    h.rooms.isEmpty
                        ? '尚未录入房间'
                        : '${h.rooms.length} 个房间 · ${h.rooms.map((r) => r.name).join('、')}',
                    style: AppText.label11,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    h.measured
                        ? '真北 ${h.trueNorth!.toStringAsFixed(0)}° · 磁偏角 ${h.declination.toStringAsFixed(1)}°'
                        : '磁偏角 ${h.declination.toStringAsFixed(1)}° · 测量后自动写入坐向',
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
        child: HouseFormSheet(
          house: house,
          onSave: (h) => store.upsert(h),
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    // 坐向由罗盘回写，没测过就提示下一步
    if (!result.measured) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('已保存到服务端。到「罗盘」实测一次，坐向会自动写回这套房屋'),
          duration: Duration(seconds: 3),
        ),
      );
    }
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
    if (ok != true) return;
    try {
      await store.remove(h.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }
}

/// 房屋编辑表单（新增 / 修改共用）
class HouseFormSheet extends StatefulWidget {
  const HouseFormSheet({super.key, this.house, this.onSave});

  final HouseProfile? house;

  /// 保存动作（写服务端）。保存成功后表单才会关闭；失败时保留输入并提示。
  final Future<void> Function(HouseProfile house)? onSave;

  @override
  State<HouseFormSheet> createState() => _HouseFormSheetState();
}

class _HouseFormSheetState extends State<HouseFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _layout;
  late final TextEditingController _area;
  late final TextEditingController _degree;
  late final TextEditingController _declination;

  /// 房间布局：房间名 + 所在宫位
  late List<RoomProfile> _rooms;

  static const layouts = ['1室1厅', '2室1厅', '3室2厅', '4室2厅'];
  static const _roomPresets = [
    '客厅', '主卧', '次卧', '厨房', '卫生间', '书房', '餐厅', '阳台'
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.house;
    _name = TextEditingController(text: h?.name ?? '');
    _layout = TextEditingController(text: h?.layout ?? '');
    // 新建房屋一律留空，不预填任何示例值（面积 / 坐向 / 房间都要用户填）
    _area = TextEditingController(text: h != null && h.area > 0 ? _num(h.area) : '');
    // 已测过坐向才回填，未测量留空等罗盘写入
    _degree = TextEditingController(
        text: h != null && h.measured ? h.trueNorth!.toStringAsFixed(0) : '');
    _declination =
        TextEditingController(text: _num(h?.declination ?? kDefaultDeclination));
    _rooms = List<RoomProfile>.of(h?.rooms ?? const <RoomProfile>[]);
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

  /// 真北度数；未填 / 未测量时为 null（坐向以罗盘实测为准，不做 0 度兜底）
  double? get _trueNorth => double.tryParse(_degree.text.trim());

  /// 是否正在保存（请求期间按钮置灰，防止重复提交）
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      _showError('请填写房屋名称');
      return;
    }
    final area = double.tryParse(_area.text.trim());
    if (area == null || area <= 0) {
      _showError('面积请填大于 0 的数字');
      return;
    }
    // 坐向不手填：留空表示等罗盘实测后回写
    final degree = double.tryParse(_degree.text.trim());
    final declination = double.tryParse(_declination.text.trim()) ?? kDefaultDeclination;
    final old = widget.house;
    final house = HouseProfile(
      id: old?.id ?? newHouseId(),
      name: name,
      layout: _layout.text.trim(),
      area: area,
      // 表单填的是真北度数，换算回磁北读数，后端统一做偏角校正；
      // 未填则保持 null，等罗盘测量写入
      degree: degree == null ? null : degree - declination,
      declination: declination,
      year: old?.year ?? DateTime.now().year,
      rooms: _rooms,
    );
    final save = widget.onSave;
    if (save == null) {
      Navigator.of(context).pop(house);
      return;
    }
    setState(() => _saving = true);
    try {
      await save(house);
      if (!mounted) return;
      Navigator.of(context).pop(house);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final tip = (e is ApiException && e.statusCode == 404)
          ? '后端接口不存在（HTTP 404），请确认 127.0.0.1:8000 上启动的是本项目的 fengshui-api，并已加载 /api/v1/houses 路由'
          : '请确认后端服务已启动（API: $kApiBaseUrl）';
      _showError('保存失败：$e\n$tip');
    }
  }

  // ------------------------------------------------------- 房间布局
  /// 九宫点选：给房间定宫位，同一宫位可放多个房间
  Widget _roomPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('房间布局', style: AppText.label12),
            Text('${_rooms.length} 个房间', style: AppText.label11),
          ],
        ),
        const SizedBox(height: AppDimens.gapXS),
        const Text('点击九宫格把房间放到对应方位', style: AppText.label11),
        const SizedBox(height: AppDimens.gapS),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.15,
          children: [
            for (var i = 0; i < PalaceGrid.fixedOrder.length; i++)
              _roomCell(i),
          ],
        ),
        if (_rooms.isNotEmpty) ...[
          const SizedBox(height: AppDimens.gapS),
          Wrap(
            spacing: AppDimens.gapS,
            runSpacing: AppDimens.gapXS,
            children: [
              for (final r in _rooms)
                Container(
                  padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppDimens.rPill),
                    border: Border.all(color: AppColors.primary, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${r.name}·${PalaceGrid.fixedOrder[r.cell]}',
                        style: AppText.label12.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(
                            () => _rooms.removeWhere((e) => e.id == r.id)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.close,
                              size: 12, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _roomCell(int index) {
    final inCell = _rooms.where((r) => r.cell == index).toList();
    return GestureDetector(
      onTap: () => _addRoom(index),
      child: Container(
        decoration: BoxDecoration(
          color: inCell.isEmpty ? AppColors.iconBg : AppColors.primarySoftBg,
          borderRadius: BorderRadius.circular(AppDimens.rS),
          border: Border.all(
            color: inCell.isEmpty
                ? AppColors.iconBorder
                : AppColors.primary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              PalaceGrid.fixedOrder[index],
              style: AppText.label11.copyWith(
                color: AppColors.muted,
                fontSize: 9,
              ),
            ),
            if (inCell.isNotEmpty) ...[
              const SizedBox(height: 2),
              for (final r in inCell.take(2))
                Text(
                  r.name,
                  style: AppText.medium11.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.add, size: 12, color: AppColors.muted),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addRoom(int cell) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('在${PalaceGrid.fixedOrder[cell]}新增房间',
            style: AppText.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              style: AppText.medium13,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.card,
                hintText: '房间名称',
                hintStyle: AppText.label12,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.rM),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.rM),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in _roomPresets)
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.iconBg,
                        borderRadius:
                            BorderRadius.circular(AppDimens.rPill),
                        border:
                            Border.all(color: AppColors.iconBorder, width: 1),
                      ),
                      child: Text(p, style: AppText.label12),
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: AppText.medium13),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim().isEmpty
                    ? null
                    : controller.text.trim()),
            child: const Text('添加', style: AppText.medium13),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    if (!mounted) return;
    setState(() => _rooms.add(RoomProfile(
          id: newRoomId(),
          name: name,
          cell: cell,
        )));
  }

  /// 表单内错误提示：直接显示在保存按钮上方，避免 SnackBar 被弹窗挡住看不见
  String? _errorText;

  void _showError(String msg) {
    setState(() => _errorText = msg);
  }

  Widget _errorBanner() {
    if (_errorText == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimens.gapL),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.rM),
        border: Border.all(color: AppColors.danger, width: 1),
      ),
      child: Text(
        _errorText!,
        style: AppText.body12.copyWith(color: AppColors.danger),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tn = _trueNorth;
    final o = tn == null ? null : OrientationCalc.of(tn);
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
                      onTap: () =>
                          setState(() { _layout.text = l; _errorText = null; }),
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
                      child: _field('坐向（真北°，可留空）', _degree, '测量后自动填入',
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
                        o == null
                            ? '保存后到「罗盘」实测一次，坐向会自动写回这套房屋'
                            : '${tn!.toStringAsFixed(0)}° → ${o.title} · ${o.readable} · ${o.houseType}',
                        style: AppText.body12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.gapXL),
              _roomPicker(),
              const SizedBox(height: AppDimens.gapXL),
              _errorBanner(),
              GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimens.rPill),
                    boxShadow: primaryShadow,
                  ),
                  alignment: Alignment.center,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
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
          onChanged: (_) => setState(() => _errorText = null),
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

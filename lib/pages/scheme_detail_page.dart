import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/house.dart';
import '../models/library.dart';
import '../models/palace_grid.dart';
import '../services/house_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/scheme_space_view.dart';

/// S6-1 · 方案详情
///
/// 数据全部来自方案库列表接口（已含详情字段），本页不再发请求，
/// 点开即渲染，没有二次 loading。
///
/// 「空间示意」的几何来自当前房屋档案（房间按九宫宫位摆放），
/// 方案只提供分区配色；没有房屋/房间时给引导，并允许在本页直接补录。
class SchemeDetailPage extends StatelessWidget {
  const SchemeDetailPage({
    super.key,
    required this.scheme,
    this.store,
    this.house,
    this.onOpenHouses,
  });

  final LibraryScheme scheme;

  /// 房屋仓库：传了就以 `store.current` 为准（保存后本页实时刷新）
  final HouseStore? store;

  /// 无 store 时的静态快照（开发预览用）
  final HouseProfile? house;

  /// 「去建房屋档案」回调（由外层注入，页面内不直接操作导航栈）
  final VoidCallback? onOpenHouses;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.pagePadH, 4, AppDimens.pagePadH, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context),
                    const SizedBox(height: AppDimens.gapL),
                    _hero(),
                    const SizedBox(height: AppDimens.gapL),
                    _summaryCard(),
                    if (scheme.elementFit.isNotEmpty) ...[
                      const SizedBox(height: AppDimens.gapL),
                      _elementCard(),
                    ],
                    const SizedBox(height: AppDimens.gapL),
                    _SpaceBlock(
                      scheme: scheme,
                      store: store,
                      house: house,
                      onOpenHouses: onOpenHouses,
                    ),
                    if (scheme.colors.isNotEmpty) ...[
                      const SizedBox(height: AppDimens.gapL),
                      const Text('配色方案', style: AppText.section),
                      const SizedBox(height: AppDimens.gapL),
                      _paletteCard(context),
                    ],
                    if (scheme.highlights.isNotEmpty) ...[
                      const SizedBox(height: AppDimens.gapL),
                      const Text('设计要点', style: AppText.section),
                      const SizedBox(height: AppDimens.gapL),
                      _highlightsCard(),
                    ],
                    if (scheme.rooms.isNotEmpty) ...[
                      const SizedBox(height: AppDimens.gapL),
                      const Text('分区配色', style: AppText.section),
                      const SizedBox(height: AppDimens.gapL),
                      ...scheme.rooms.map(
                        (r) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppDimens.gapL),
                          child: _roomCard(r),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _bottomBar(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child:
              const AppIcon(AppIconKind.back, size: 22, color: AppColors.ink),
        ),
        const Text('方案详情', style: AppText.pageTitle),
        // 占位，让标题保持居中
        const SizedBox(width: 22),
      ],
    );
  }

  // ------------------------------------------------------- 效果图占位
  Widget _hero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.rXL),
      child: SizedBox(
        height: 190,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.from, scheme.to],
                ),
              ),
            ),
            // 压暗底部，保证浅色方案上白字依然可读
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.46),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (scheme.element.isNotEmpty) ...[
                        _heroChip('五行属${scheme.element}'),
                        const SizedBox(width: 8),
                      ],
                      if (scheme.area > 0) _heroChip('${scheme.area}㎡'),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    scheme.title,
                    style: AppText.pageTitle.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  if (scheme.tag.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      scheme.tag,
                      style: AppText.label12.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        style: AppText.medium11.copyWith(color: Colors.white, fontSize: 11),
      ),
    );
  }

  // ------------------------------------------------------- 方案简介
  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Text(
        scheme.summary,
        style: AppText.body13.copyWith(color: AppColors.inkSoft, height: 1.7),
      ),
    );
  }

  // ------------------------------------------------------- 五行宜忌
  Widget _elementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('五行属性', style: AppText.cardTitle),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.elementSoftBg(scheme.element),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '五行属${scheme.element} · ${scheme.area}㎡',
                  style: AppText.medium11.copyWith(
                    color: AppColors.elementDeep(scheme.element),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (scheme.elementFit.isNotEmpty)
            _noteRow(
              AppIconKind.check,
              AppColors.primary,
              AppColors.primarySoft,
              '宜',
              scheme.elementFit,
            ),
          if (scheme.elementFit.isNotEmpty && scheme.elementAvoid.isNotEmpty)
            const SizedBox(height: 12),
          if (scheme.elementAvoid.isNotEmpty)
            _noteRow(
              AppIconKind.warn,
              AppColors.danger,
              AppColors.dangerSoftBg,
              '忌',
              scheme.elementAvoid,
            ),
        ],
      ),
    );
  }

  Widget _noteRow(
    AppIconKind kind,
    Color fg,
    Color bg,
    String label,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: AppIcon(kind, size: 15, color: fg),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.medium12.copyWith(color: fg)),
              const SizedBox(height: 3),
              Text(text, style: AppText.body12),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------- 配色方案（点击复制）
  Widget _paletteCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < scheme.colors.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _swatch(context, scheme.colors[i])),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '点色块可复制色值，交给设计师或装修公司直接对色',
            style: AppText.label11,
          ),
        ],
      ),
    );
  }

  Widget _swatch(BuildContext context, PaletteColor p) {
    return GestureDetector(
      onTap: () => _copy(context, p.name, p.color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            p.name,
            style: AppText.medium11.copyWith(color: AppColors.body),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _hexOf(p.color),
            style: AppText.label11.copyWith(fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- 设计要点
  Widget _highlightsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < scheme.highlights.length; i++)
            Padding(
              padding: EdgeInsets.only(
                  bottom: i == scheme.highlights.length - 1 ? 0 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      scheme.highlights[i],
                      style: AppText.body13.copyWith(color: AppColors.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- 分区配色
  Widget _roomCard(RoomPlan r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: appCard(radius: AppDimens.rM),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: r.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: AppText.medium13),
                const SizedBox(height: 4),
                Text(r.note, style: AppText.body12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- 底部操作栏
  Widget _bottomBar(BuildContext context) {
    return Container(
      height: AppDimens.bottomBarH,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadH, 14, AppDimens.pagePadH, 24),
      child: GestureDetector(
        onTap: () => _copyAll(context),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(25),
            boxShadow: primaryShadow,
          ),
          alignment: Alignment.center,
          child: const Text('复制全套配色色值', style: AppText.button14),
        ),
      ),
    );
  }

  // ------------------------------------------------------- 复制
  static String _hexOf(Color c) {
    final argb = c.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${argb.substring(2).toUpperCase()}';
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _copy(BuildContext context, String name, Color color) {
    final hex = _hexOf(color);
    Clipboard.setData(ClipboardData(text: '$name $hex'));
    _toast(context, '已复制 $name $hex');
  }

  void _copyAll(BuildContext context) {
    if (scheme.colors.isEmpty) {
      _toast(context, '该方案暂无配色数据');
      return;
    }
    final lines = scheme.colors.map((c) => '${c.name} ${_hexOf(c.color)}');
    Clipboard.setData(
      ClipboardData(text: '${scheme.title} 配色方案\n${lines.join('\n')}'),
    );
    _toast(context, '已复制全套配色色值（${scheme.colors.length} 个）');
  }
}

// ------------------------------------------------------- 空间示意
/// 把方案配色铺到当前房屋的宫位平面上，平面 / 立体两种视角。
///
/// 几何一律来自房屋档案（房间的宫位由用户自己录），方案只提供配色，
/// 所以这里不会「凭空画一张户型」。缺房间时不必跳页：本卡内点九宫格
/// 直接加房间，存进服务端后平面图立即出现（store 通知刷新）。
class _SpaceBlock extends StatefulWidget {
  const _SpaceBlock({
    required this.scheme,
    this.store,
    this.house,
    this.onOpenHouses,
  });

  final LibraryScheme scheme;

  /// 有 store 时以 `store.current` 为准，保存后实时刷新
  final HouseStore? store;

  /// 无 store 时的静态快照（开发预览用）
  final HouseProfile? house;

  final VoidCallback? onOpenHouses;

  @override
  State<_SpaceBlock> createState() => _SpaceBlockState();
}

class _SpaceBlockState extends State<_SpaceBlock> {
  SpaceViewMode _mode = SpaceViewMode.plan;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    if (store == null) return _render(widget.house, editable: false);
    return AnimatedBuilder(
      animation: store,
      builder: (_, __) => _render(store.current, editable: true),
    );
  }

  Widget _render(HouseProfile? house, {required bool editable}) {
    final ready = house != null && house.rooms.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('空间示意', style: AppText.section),
            const Spacer(),
            if (ready) ...[
              _pill('平面图', SpaceViewMode.plan),
              const SizedBox(width: 6),
              _pill('立体图', SpaceViewMode.solid),
            ],
          ],
        ),
        const SizedBox(height: AppDimens.gapL),
        if (house == null)
          _guide(
            title: '还没有房屋档案',
            body: '空间示意按你自己的户型铺色：先建一套房子，填好户型与面积，'
                '再用罗盘测一次坐向。',
            action: editable ? '去建房屋档案' : null,
            onTap: widget.onOpenHouses,
          )
        else if (!ready)
          _guide(
            title: '差一步：这套房子还没分配房间',
            body: '空间示意要按宫位铺色。点下面的九宫格，把客厅、主卧'
                '这些房间放进对应方位，平面图立刻就能出来。',
            extra: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _RoomGrid(
                rooms: house.rooms,
                onTapCell: _addRoom,
              ),
            ),
            footer: editable ? '也可以在「我的房屋」里点铅笔，用完整表单录入' : null,
          )
        else
          _body(house, editable: editable),
      ],
    );
  }

  Widget _body(HouseProfile house, {required bool editable}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SchemeSpaceView(house: house, scheme: widget.scheme, mode: _mode),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final r in house.rooms)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: schemeRoomColor(widget.scheme, r.name),
                        borderRadius: BorderRadius.circular(3),
                        border:
                            Border.all(color: AppColors.cardBorder, width: 0.5),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      r.name,
                      style: AppText.label11.copyWith(color: AppColors.body),
                    ),
                  ],
                ),
              if (editable)
                GestureDetector(
                  onTap: _openPicker,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoftBg,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.primarySoftBorder),
                    ),
                    child: Text(
                      '＋ 加房间',
                      style: AppText.label11.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${house.displayName} · ${house.areaText} · ${_facingText(house)}',
            style: AppText.label11.copyWith(color: AppColors.body),
          ),
          const SizedBox(height: 3),
          const Text(
            '房间位置取自你的房屋档案，配色按方案分区套用；示意非施工图。',
            style: AppText.label11,
          ),
        ],
      ),
    );
  }

  String _facingText(HouseProfile house) {
    final o = house.orientation;
    if (o == null) return '未测坐向，按标准方位排布';
    return '向${o.facingDirection}朝上 · ${o.readable}';
  }

  Widget _pill(String label, SpaceViewMode mode) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(13),
          border: active ? null : Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: AppText.medium11.copyWith(
            color: active ? Colors.white : AppColors.body,
          ),
        ),
      ),
    );
  }

  Widget _guide({
    required String title,
    required String body,
    String? action,
    VoidCallback? onTap,
    Widget? extra,
    String? footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.iconBg,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.iconBorder),
                ),
                alignment: Alignment.center,
                child: const AppIcon(AppIconKind.plan,
                    size: 17, color: AppColors.body),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.medium13),
                    const SizedBox(height: 4),
                    Text(body, style: AppText.body12),
                  ],
                ),
              ),
            ],
          ),
          if (extra != null) extra,
          if (action != null && onTap != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onTap,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.btnSecondary,
                  borderRadius: BorderRadius.circular(19),
                ),
                alignment: Alignment.center,
                child: Text(action,
                    style: AppText.medium12.copyWith(color: AppColors.primary)),
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 8),
            Text(footer, style: AppText.label11),
          ],
        ],
      ),
    );
  }

  Future<void> _openPicker() async {
    final store = widget.store;
    if (store == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnimatedBuilder(
        animation: store,
        builder: (_, __) => RoomPickerSheet(
          rooms: store.current?.rooms ?? const <RoomProfile>[],
          onAdd: _addRoom,
          onRemove: _removeRoom,
          onEdit: _editRoom,
        ),
      ),
    );
  }

  /// 删房间（添加错了 / 重新布局）。
  /// 与加房间一样，房屋快照必须现取，否则会用旧列表覆盖掉刚加的那间。
  Future<void> _removeRoom(RoomProfile room) async {
    final store = widget.store;
    if (store == null || store.current == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除房间', style: AppText.cardTitle),
        content: Text('删掉「${room.name}」？只影响房间布局，不影响方案配色。',
            style: AppText.body13),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: AppText.medium13),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: AppText.medium13),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final house = store.current;
    if (house == null) return;
    final next = house.rooms.where((r) => r.id != room.id).toList();
    try {
      await store.upsert(house.copyWith(rooms: next));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    }
  }

  /// 改房间：改名 + 换宫位（调整布局不必删了再加）
  Future<void> _editRoom(RoomProfile room) async {
    final store = widget.store;
    final house = store?.current;
    if (store == null || house == null) return;
    final updated = await _showRoomEditor(room);
    if (updated == null) return;
    final next = house.rooms
        .map((r) => r.id == room.id ? updated : r)
        .toList();
    try {
      await store.upsert(house.copyWith(rooms: next));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  Future<RoomProfile?> _showRoomEditor(RoomProfile room) async {
    final ctrl = TextEditingController(text: room.name);
    var cell = room.cell;
    final result = await showDialog<RoomProfile>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('修改房间', style: AppText.cardTitle),
          content: SizedBox(
            width: 268,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    hintText: '房间名称',
                    hintStyle: AppText.label12,
                  ),
                ),
                const SizedBox(height: 14),
                const Text('所在宫位', style: AppText.label11),
                const SizedBox(height: 6),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 2.1,
                  children: [
                    for (var i = 0; i < PalaceGrid.fixedOrder.length; i++)
                      GestureDetector(
                        onTap: () => setLocal(() => cell = i),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cell == i
                                ? AppColors.primary
                                : AppColors.iconBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cell == i
                                  ? AppColors.primary
                                  : AppColors.iconBorder,
                            ),
                          ),
                          child: Text(
                            PalaceGrid.fixedOrder[i],
                            style: AppText.label11.copyWith(
                              color: cell == i
                                  ? Colors.white
                                  : AppColors.body,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: AppText.medium13),
            ),
            TextButton(
              onPressed: () {
                final name = ctrl.text.trim();
                Navigator.pop(
                  ctx,
                  room.copyWith(
                    name: name.isEmpty ? room.name : name,
                    cell: cell,
                  ),
                );
              },
              child: const Text('保存', style: AppText.medium13),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    return result;
  }

  /// 点宫位加房间：写服务端 -> store 通知 -> 本段自动刷新。
  /// 房屋必须每次都从 store 取最新值，否则连加两间会拿旧快照覆盖掉前一间。
  Future<void> _addRoom(int cell) async {
    final store = widget.store;
    final house = store?.current;
    if (store == null || house == null) return;
    final name = await _askRoomName(cell);
    if (name == null || name.isEmpty) return;
    final next = [
      ...house.rooms,
      RoomProfile(id: newRoomId(), name: name, cell: cell),
    ];
    try {
      await store.upsert(house.copyWith(rooms: next));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('房间保存失败：$e')),
      );
    }
  }

  Future<String?> _askRoomName(int cell) async {
    final ctrl = TextEditingController();
    const presets = ['客厅', '主卧', '次卧', '儿童房', '厨房', '卫生间', '书房', '餐厅', '玄关', '阳台'];
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('在${PalaceGrid.fixedOrder[cell]}新增房间',
            style: AppText.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '房间名称',
                hintStyle: AppText.label12,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in presets)
                  GestureDetector(
                    onTap: () => ctrl.text = p,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.iconBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.iconBorder),
                      ),
                      child: Text(p, style: AppText.label11),
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
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('添加', style: AppText.medium13),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return name;
  }
}

/// 房间布局弹层：点宫位加房间；点房间胶囊改宫位/改名，点 × 删除。
/// 纯 UI（房间列表 + 三个回调），数据与持久化由调用方负责，方便单测与预览。
class RoomPickerSheet extends StatelessWidget {
  const RoomPickerSheet({
    super.key,
    required this.rooms,
    required this.onAdd,
    required this.onRemove,
    required this.onEdit,
  });

  final List<RoomProfile> rooms;
  final Future<void> Function(int cell) onAdd;
  final Future<void> Function(RoomProfile room) onRemove;
  final Future<void> Function(RoomProfile room) onEdit;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 20 + MediaQuery.paddingOf(context).bottom),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('房间布局', style: AppText.cardTitle),
                  const Spacer(),
                  Text('${rooms.length} 个房间', style: AppText.label11),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '点宫位添加；点已加的房间可改宫位或改名，× 删除',
                style: AppText.label11,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RoomGrid(rooms: rooms, onTapCell: onAdd),
                      if (rooms.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final r in rooms)
                              _roomChip(r),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: const Text('完成', style: AppText.button14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 房间胶囊：点名字改宫位/改名，点 × 删除
  Widget _roomChip(RoomProfile r) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoftBg,
        borderRadius: BorderRadius.circular(AppDimens.rPill),
        border: Border.all(color: AppColors.primarySoftBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onEdit(r),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 5, 5, 5),
              child: Text(
                '${r.name} · ${PalaceGrid.fixedOrder[r.cell]}',
                style: AppText.label11.copyWith(color: AppColors.primary),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onRemove(r),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(3, 5, 9, 5),
              child: Icon(Icons.close, size: 13, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3×3 宫位格：显示方位 + 已放进去的房间，点击回调宫位索引
class _RoomGrid extends StatelessWidget {
  const _RoomGrid({required this.rooms, required this.onTapCell});

  final List<RoomProfile> rooms;
  final void Function(int cell) onTapCell;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.7,
      children: [
        for (var i = 0; i < PalaceGrid.fixedOrder.length; i++)
          _cell(i),
      ],
    );
  }

  Widget _cell(int i) {
    final names = rooms.where((r) => r.cell == i).map((r) => r.name).toList();
    return GestureDetector(
      onTap: () => onTapCell(i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: names.isEmpty ? AppColors.iconBg : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: names.isEmpty ? AppColors.iconBorder : AppColors.primary,
            width: names.isEmpty ? 1 : 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  PalaceGrid.fixedOrder[i],
                  style: AppText.label11.copyWith(
                    color: names.isEmpty ? AppColors.muted : AppColors.primary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '＋',
                  style: AppText.label11.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.55),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (names.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  names.join('、'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label11.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

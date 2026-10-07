import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/diagnosis.dart';
import '../models/house.dart';
import '../models/palace_grid.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// S5 · 家具布局建议
///
/// 页面分三层：
/// 1. 户型平面图：只显示房间块 + 九宫网格参考线，房间顶部按宫位吉凶着色。
/// 2. 九宫飞星盘：独立的 3×3 盘，方位 / 星曜 / 角标清晰可读。
/// 3. 各房间吉凶：按房间所在宫位给出建议。
class LayoutPage extends StatelessWidget {
  LayoutPage({
    super.key,
    this.diagnosis,
    this.house,
    this.onApplyRooms,
  });

  final Diagnosis? diagnosis;
  final HouseProfile? house;

  /// 点击「应用此布局方案」时把当前房间布局回传给上层保存
  final ValueChanged<List<RoomProfile>>? onApplyRooms;

  /// 整页渲染 key，用于导出完整布局方案图片
  final GlobalKey _planKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final d = diagnosis;
    final h = house;
    final rooms = h?.rooms ?? const <RoomProfile>[];
    final rotated = PalaceGrid.orderOf(d?.orientation.facingDir);
    final cells = d == null
        ? null
        : PalaceGrid.build(
            d.palaces,
            facing: d.orientation.facingDir,
            rotate: true,
          );

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: RepaintBoundary(
                  key: _planKey,
                  child: Container(
                    color: AppColors.bg,
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.pagePadH, 4, AppDimens.pagePadH, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(),
                        const SizedBox(height: AppDimens.gapL),
                        _planCard(cells, rotated, rooms, d, h),
                        const SizedBox(height: AppDimens.gapL),
                        _layoutGuideCard(h, rooms, d),
                        if (cells != null) ...[
                          const SizedBox(height: AppDimens.gapL),
                          _gridCard(cells, d),
                        ],
                        const SizedBox(height: AppDimens.gapL),
                        Text(
                          d == null ? '摆放建议' : '各房间吉凶',
                          style: AppText.section,
                        ),
                        const SizedBox(height: AppDimens.gapL),
                        if (d == null || cells == null)
                          // 不再展示写死的通用建议，改为明确的待生成提示
                          _pendingCard(
                            '完成测量后，这里会按各房间所在宫位给出吉凶与摆放建议。',
                          )
                        else
                          ..._roomCards(cells, rotated, rooms, d),
                        // 后端下发的家具摆放建议（按当日吉凶动态生成）
                        if (d != null && d.tips.isNotEmpty) ...[
                          const SizedBox(height: AppDimens.gapL),
                          const Text('家具摆放建议', style: AppText.section),
                          const SizedBox(height: AppDimens.gapL),
                          ...d.tips.map((t) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppDimens.gapL),
                                child: _tipCard(
                                    t.type == 'good', t.title, t.desc),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                  left: 0, right: 0, bottom: 0, child: _bottomBar(context, rooms)),
            ],
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
        Text('家具布局建议', style: AppText.pageTitle),
        AppIcon(AppIconKind.heart, size: 20, color: AppColors.ink),
      ],
    );
  }

  // ------------------------------------------------------- 户型平面图
  static const _wallColor = Color(0xFF7D6E58);

  Widget _planCard(
    List<Palace?>? cells,
    List<String> rotated,
    List<RoomProfile> rooms,
    Diagnosis? d,
    HouseProfile? h,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('户型平面', style: AppText.cardTitle),
              Text(_subtitle(d, h), style: AppText.label11),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6F0),
                  border: Border.all(color: _wallColor, width: 3),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _wallGrid(cells, rotated, rooms),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _compass(d, h),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '此图已按坐向旋转：向方 ${_facingText(d, h)} 朝上',
            style: AppText.label11.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  String _subtitle(Diagnosis? d, HouseProfile? h) {
    final o = h?.orientation;
    if (o != null) return '${h!.areaText} · ${o.readable}';
    if (d != null) return d.orientation.readable;
    // 没有房屋或还没测坐向，都不伪造面积与坐向
    return '未测量坐向';
  }

  String _facingText(Diagnosis? d, HouseProfile? h) {
    if (d != null) return d.orientation.facingDir;
    final o = h?.orientation;
    if (o != null) return o.facingDirection;
    return '—';
  }

  /// 房屋坐山所在的真实方位（如坐北朝南 -> 正北）
  String _sittingDir(Diagnosis? d, HouseProfile? h) {
    if (d != null) return d.orientation.sitting;
    final o = h?.orientation;
    if (o != null) return o.direction;
    return '—';
  }

  /// 真实北在户型图上的旋转角度（指南针箭头默认朝上）
  double _northAngle(Diagnosis? d, HouseProfile? h) {
    final direction = _sittingDir(d, h);
    const map = {
      '正北': 0.0,
      '东北': 45.0,
      '正东': 90.0,
      '东南': 135.0,
      '正南': 180.0,
      '西南': 225.0,
      '正西': 270.0,
      '西北': 315.0,
    };
    return (map[direction] ?? 0.0) * math.pi / 180;
  }

  /// 指南针：指北针会随坐向旋转，指向真实北方
  Widget _compass(Diagnosis? d, HouseProfile? h) {
    return Transform.rotate(
      angle: _northAngle(d, h),
      alignment: Alignment.center,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(230),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.navigation, size: 16, color: AppColors.primary),
            Text(
              'N',
              style: AppText.medium11.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  /// 3×3 墙体网格：每个格子就是一间或几间房，线条模拟隔墙
  Widget _wallGrid(
    List<Palace?>? cells,
    List<String> rotated,
    List<RoomProfile> rooms,
  ) {
    return Column(
      children: [
        for (int r = 0; r < 3; r++)
          Expanded(
            child: Row(
              children: [
                for (int c = 0; c < 3; c++)
                  Expanded(
                    child: _cell(r, c, cells, rotated, rooms),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(
    int row,
    int col,
    List<Palace?>? cells,
    List<String> rotated,
    List<RoomProfile> rooms,
  ) {
    final pos = row * 3 + col;
    final dir = rotated[pos];
    final fixedIdx = PalaceGrid.fixedOrder.indexOf(dir);
    final cellRooms =
        rooms.where((r) => r.cell == fixedIdx && dir != '中宫').toList();
    final palace = cells?[pos];

    final bg = palace == null
        ? const Color(0xFFF9F6F0)
        : AppColors.palaceBg(palace.level).withAlpha(80);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          right: BorderSide(color: _wallColor, width: col < 2 ? 2 : 0),
          bottom: BorderSide(color: _wallColor, width: row < 2 ? 2 : 0),
        ),
      ),
      child: cellRooms.isEmpty
          ? Center(
              child: Text(
                dir == '中宫' ? '中宫' : dir,
                style: AppText.label11.copyWith(color: AppColors.muted),
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < cellRooms.length; i++)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: i < cellRooms.length - 1
                            ? Border(
                                bottom: BorderSide(
                                  color: _wallColor.withAlpha(80),
                                  width: 1,
                                ),
                              )
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          cellRooms[i].name,
                          style:
                              AppText.medium13.copyWith(color: AppColors.body),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  // ------------------------------------------------------- 户型布局建议表
  /// 功能区布局建议直接取后端 `Diagnosis.layoutGuide`：
  /// 方位与吉凶由后端按坐向 / 当日星曜算出，前端只负责渲染，不再自行推算。
  String _layoutTip(Diagnosis? d) {
    if (d == null) {
      return '完成测量后，这里会按你的户型与坐向生成建议。';
    }
    return '${d.orientation.readable}：向方=${d.orientation.facingDir}，坐山方=${d.orientation.sitting}。';
  }

  Widget _layoutGuideCard(
    HouseProfile? h,
    List<RoomProfile> rooms,
    Diagnosis? d,
  ) {
    final title =
        h != null && h.layout.isNotEmpty ? '${h.layout} · 功能区布局建议' : '功能区布局建议';
    final list = d?.layoutGuide ?? const <LayoutGuideRow>[];

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimens.rXL),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.cardTitle),
            const SizedBox(height: 8),
            Text('完成测量后生成', style: AppText.body12.copyWith(color: AppColors.muted)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.cardTitle),
          const SizedBox(height: 6),
          Text(
            _layoutTip(d),
            style: AppText.label11.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          _tableHeader(),
          const Divider(height: 1, color: AppColors.divider),
          for (var i = 0; i < list.length; i++) ...[
            _tableRow(list[i].type, list[i].good, list[i].bad),
            if (i != list.length - 1)
              const Divider(height: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('功能区', style: AppText.medium13)),
          Expanded(flex: 3, child: Text('宜置方位', style: AppText.medium13)),
          Expanded(flex: 3, child: Text('忌置方位', style: AppText.medium13)),
        ],
      ),
    );
  }

  Widget _tableRow(String type, String good, String bad) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(type, style: AppText.body12)),
          Expanded(
            flex: 3,
            child: Text(
              good,
              style: AppText.body12.copyWith(color: AppColors.primary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              bad,
              style: AppText.body12.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- 九宫飞星盘
  Widget _gridCard(List<Palace?> cells, Diagnosis? d) {
    if (d == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('九宫飞星 · 流年盘', style: AppText.cardTitle),
              Text('${d.year}年 · ${d.orientation.houseType}',
                  style: AppText.label11),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: [
              for (var i = 0; i < cells.length; i++) _gridCell(i, cells[i], d),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legend('旺位', AppColors.primary),
              _legend('平位', AppColors.gold),
              _legend('煞位', AppColors.danger),
              _legend('大凶', AppColors.dangerDeep),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gridCell(int index, Palace? p, Diagnosis d) {
    if (p == null) return const SizedBox.shrink();
    final fg = AppColors.palaceFg(p.level);
    final isBest = d.todayBest.direction == p.direction;
    final isWorst = d.todayWorst.direction == p.direction;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.palaceBg(p.level),
        borderRadius: BorderRadius.circular(AppDimens.rS),
        border: Border.all(
          color: AppColors.palaceBorder(p.level) ??
              (p.isCenter ? AppColors.primarySoftBorder : AppColors.cardBorder),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.title,
                  style: AppText.label11.copyWith(
                    color: p.level == '大凶'
                        ? const Color(0xFF8A5443)
                        : AppColors.body,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.starName,
                  style: AppText.value17.copyWith(color: fg, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  p.element,
                  style: AppText.label11.copyWith(
                    color: fg.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.label,
                  style: AppText.medium11.copyWith(color: fg, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isBest || isWorst)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isBest ? AppColors.gold : AppColors.danger,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  // 角色名由后端下发（财位 / 五黄煞 / 病符位 / 破财位 …），
                  // 不再一律显示「财位」「五黄」
                  isBest ? d.todayBest.roleName : d.todayWorst.roleName,
                  style: AppText.medium11.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 数据尚未生成时的占位提示（替代过去写死的通用建议）
  Widget _pendingCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: cardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppText.body12.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(text, style: AppText.label11.copyWith(color: AppColors.body)),
      ],
    );
  }

  // ------------------------------------------------------- 各房间吉凶
  List<Widget> _roomCards(
    List<Palace?> cells,
    List<String> rotated,
    List<RoomProfile> rooms,
    Diagnosis? d,
  ) {
    if (d == null) return const [];
    final out = <Widget>[];
    for (final r in rooms) {
      final dir = PalaceGrid.fixedOrder[r.cell.clamp(0, 8)];
      final pos = rotated.indexOf(dir);
      final index = pos < 0 ? r.cell.clamp(0, 8) : pos;
      final p = index < cells.length ? cells[index] : null;
      if (p == null) continue;
      final good = p.level == '旺';
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.gapL),
          child: _tipCard(
            good,
            '${r.name} · ${p.direction}（${p.starName} · ${p.level}）',
            '${p.label}：${p.note}',
          ),
        ),
      );
    }
    return out;
  }

  // ------------------------------------------------------- 建议卡
  Widget _tipCard(bool good, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: appCard(radius: AppDimens.rM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            good ? AppIconKind.check : AppIconKind.warn,
            size: 18,
            color: good ? AppColors.primary : AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.medium13),
                const SizedBox(height: 5),
                Text(desc, style: AppText.body12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: good ? AppColors.primarySoft : AppColors.dangerSoftBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              good ? '宜' : '忌',
              style: AppText.medium11.copyWith(
                color: good ? AppColors.primary : AppColors.danger,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context, List<RoomProfile> rooms) {
    return Container(
      height: AppDimens.bottomBarH,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadH, 14, AppDimens.pagePadH, 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showExportOptions(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.btnSecondary,
                borderRadius: BorderRadius.circular(25),
              ),
              alignment: Alignment.center,
              child: Text('导出平面图',
                  style: AppText.button14.copyWith(color: AppColors.inkSoft)),
            ),
          ),
          const SizedBox(width: AppDimens.gapM),
          Expanded(
            child: GestureDetector(
              onTap: () => onApplyRooms?.call(rooms),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: const Text('应用此布局方案', style: AppText.button14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- 导出平面图
  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _showExportOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.ink),
              title: const Text('分享完整页面图片'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _exportPageImage(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.ink),
              title: const Text('复制文字方案'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _copyTextPlan(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.muted),
              title: const Text('取消'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _buildTextPlan() {
    final h = house;
    final d = diagnosis;
    final sb = StringBuffer();
    sb.writeln('${h?.displayName ?? '我的房屋'} 风水布局方案');
    final o = h?.orientation;
    if (o != null) sb.writeln('${h!.areaText} · ${o.readable}');
    if (d != null) {
      sb.writeln('${d.year}年 · ${d.orientation.houseType}');
      sb.writeln('综合评分：${d.score}分');
    }
    final guide = d?.layoutGuide ?? const <LayoutGuideRow>[];
    if (guide.isNotEmpty) {
      sb.writeln('');
      sb.writeln('【功能区布局建议】');
      for (final s in guide) {
        sb.writeln('${s.type}：宜 ${s.good}；忌 ${s.bad}');
      }
    }
    if (d != null) {
      sb.writeln('');
      sb.writeln('【今日吉凶】');
      sb.writeln('今日${d.todayBest.roleName}：${d.todayBest.title}');
      sb.writeln('今日${d.todayWorst.roleName}：${d.todayWorst.title}');
      if (d.tips.isNotEmpty) {
        sb.writeln('');
        sb.writeln('【家具摆放建议】');
        for (final t in d.tips) {
          sb.writeln('${t.title}：${t.desc}');
        }
      }
    }
    return sb.toString();
  }

  Future<void> _copyTextPlan(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _buildTextPlan()));
    if (context.mounted) _showSnack(context, '文字方案已复制到剪贴板');
  }

  /// 把整个页面内容（户型平面 + 布局建议表 + 九宫盘 + 各房间吉凶）导出为图片
  Future<void> _exportPageImage(BuildContext context) async {
    final boundary = _planKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      _showSnack(context, '页面尚未渲染，请稍后重试');
      return;
    }
    try {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('图片生成失败');
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/layout_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: '${house?.displayName ?? '户型'}风水布局方案');
    } catch (e) {
      if (context.mounted) _showSnack(context, '导出失败：$e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/library.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// S6-1 · 方案详情
///
/// 数据全部来自方案库列表接口（已含详情字段），本页不再发请求，
/// 点开即渲染，没有二次 loading。
class SchemeDetailPage extends StatelessWidget {
  const SchemeDetailPage({super.key, required this.scheme});

  final LibraryScheme scheme;

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
                          padding: const EdgeInsets.only(
                              bottom: AppDimens.gapL),
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
          child: const AppIcon(AppIconKind.back, size: 22, color: AppColors.ink),
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
          Text(
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
                      style:
                          AppText.body13.copyWith(color: AppColors.inkSoft),
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

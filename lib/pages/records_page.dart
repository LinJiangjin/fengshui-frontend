import 'package:flutter/material.dart';

import '../models/record.dart';
import '../services/api_client.dart';
import '../services/auth_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// S4 · 测算记录
///
/// 保存过的测算按更新时间倒序排列。点一条按 params 回放到对应测算页——
/// **回放的是参数、不是结果快照**：引擎规则随 RULES_VERSION 改版，
/// 存快照会留下过期判词；而各测算接口都是无状态纯计算（六爻 / 梅花的
/// 装卦也不含随机数），同一份入参必然还原同一次测算。
///
/// 号码八星不在可保存范围（隐私：不落完整号码），列表里不会出现。
class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key, required this.onOpenRecord});

  /// 打开一条记录：由外层（AppShell）按 kind 分发到对应测算页
  final Future<void> Function(CalcRecord record) onOpenRecord;

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  final ApiClient _api = ApiClient();

  List<CalcRecord> _records = const [];
  bool _loading = true;
  String? _error;

  /// 正在打开（拉详情中）的记录 id；用于防连点
  String? _openingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.fetchRecords();
      if (!mounted) return;
      setState(() {
        _records = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await AuthStore.instance?.forceLogout();
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败：$e';
        _loading = false;
      });
    }
  }

  /// 打开一条记录：**先取详情再分发**。
  ///
  /// 列表响应是轻量契约、不带 `params`（见 models/record.dart 的说明），
  /// 直接把列表项交给分发器，回放拿到的是空参数——用户会看到一张空表单
  /// 和一句「出生信息不完整」。详情接口才带 params。
  Future<void> _open(CalcRecord r) async {
    if (_openingId != null) return; // 防连点
    setState(() => _openingId = r.id);
    try {
      final full = await _api.fetchRecord(r.id);
      if (!mounted) return;
      await widget.onOpenRecord(full);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await AuthStore.instance?.forceLogout();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  Future<void> _confirmDelete(CalcRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.rXL),
        ),
        title: const Text('删除测算记录', style: AppText.pageTitle),
        content: Text(
          '将删除「${record.title}」。记录里存的是测算参数，删除后需要重新测算。',
          style: AppText.body13,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('取消',
                style: AppText.medium15.copyWith(color: AppColors.body)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('删除',
                style: AppText.medium15.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _api.deleteRecord(record.id);
      if (!mounted) return;
      setState(() =>
          _records = _records.where((r) => r.id != record.id).toList());
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('已删除'), duration: Duration(seconds: 2)),
      );
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await AuthStore.instance?.forceLogout();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.pagePadH, 4, AppDimens.pagePadH, 32),
              children: [
                _header(context),
                const SizedBox(height: AppDimens.gapL),
                ..._body(),
              ],
            ),
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
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.maybePop(context),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: AppIcon(AppIconKind.back, size: 22, color: AppColors.ink),
          ),
        ),
        const Text('测算记录', style: AppText.pageTitle),
        const Padding(
          padding: EdgeInsets.all(6),
          child: AppIcon(AppIconKind.bookmark, size: 20, color: AppColors.ink),
        ),
      ],
    );
  }

  List<Widget> _body() {
    if (_loading) {
      return const [
        SizedBox(height: 160),
        Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ];
    }
    final err = _error;
    if (err != null) {
      return [
        _placeholder(
          icon: Icons.cloud_off,
          title: '记录加载失败',
          desc: err,
          buttonText: '重试',
          onTap: _load,
        ),
      ];
    }
    if (_records.isEmpty) {
      return [
        _placeholder(
          icon: Icons.bookmark_border_rounded,
          title: '还没有保存过测算',
          desc: '在八字 / 八宅 / 玄空 / 黄历 / 问卦 / 合婚 / 户型诊断的\n'
              '结果页点右上角「保存测算」，这里就能一键回看。',
          buttonText: null,
          onTap: null,
        ),
      ];
    }
    return [
      for (final r in _records) ...[
        _recordCard(r),
        const SizedBox(height: AppDimens.gapM),
      ],
    ];
  }

  Widget _recordCard(CalcRecord r) {
    final opening = _openingId == r.id;
    return GestureDetector(
      onTap: opening ? null : () => _open(r),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.gapL),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimens.rL),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoftBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          recordKindLabel(r.kind),
                          style: AppText.label11
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_relativeTime(r.updatedAt),
                          style: AppText.label11
                              .copyWith(color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.title,
                    style: AppText.cardTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (r.summary.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      r.summary,
                      style: AppText.label12.copyWith(color: AppColors.body),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimens.gapS),
            // 拉详情期间把删除位换成转圈，告诉用户「正在打开」
            if (opening)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              )
            else
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _confirmDelete(r),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: AppIcon(AppIconKind.warn, size: 18,
                      color: AppColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder({
    required IconData icon,
    required String title,
    required String desc,
    String? buttonText,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.muted),
          const SizedBox(height: 14),
          Text(title, style: AppText.cardTitle),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: AppText.label12.copyWith(color: AppColors.body),
          ),
          if (buttonText != null && onTap != null) ...[
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onTap, child: Text(buttonText)),
          ],
        ],
      ),
    );
  }

  /// 相对时间：分钟 / 小时 / 昨天 / 月-日。跨天的小时数没有意义，按自然日算。
  String _relativeTime(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(t.year, t.month, t.day);
    final days = today.difference(that).inDays;
    if (days <= 0) {
      final minutes = now.difference(t).inMinutes;
      if (minutes < 1) return '刚刚';
      if (minutes < 60) return '$minutes 分钟前';
      return '今天 ${_hhmm(t)}';
    }
    if (days == 1) return '昨天 ${_hhmm(t)}';
    return '${t.month.toString().padLeft(2, '0')}-'
        '${t.day.toString().padLeft(2, '0')}';
  }

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

import 'package:flutter/material.dart';

import '../models/legal.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// S7 · 合规文档页（用户协议 / 隐私政策）
///
/// 正文从服务端拉取，本页只负责排版：条款更新后无需发版即可生效。
/// 打开即请求；失败给明确提示与重试入口，不用空白页糊弄过去。
///
/// 自带 Scaffold：主要入口是登录页（那里没有 DesignCanvas 包裹），
/// 这样任何地方 push 进来都能独立成页。
class LegalPage extends StatefulWidget {
  const LegalPage({super.key, required this.slug, required this.title});

  /// 文档标识：user-agreement / privacy-policy
  final String slug;

  /// 页面标题由调用方传入——打开瞬间就要有标题，不能等接口回来才显示
  final String title;

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  LegalDoc? _doc;
  String? _error;
  bool _loading = true;

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
      final doc = await ApiClient().fetchLegalDoc(widget.slug);
      if (!mounted) return;
      setState(() {
        _doc = doc;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : '文档加载失败，请检查网络后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(AppDimens.pagePadH, 8, AppDimens.pagePadH, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child:
                const AppIcon(AppIconKind.back, size: 22, color: AppColors.ink),
          ),
          Text(widget.title, style: AppText.pageTitle),
          // 占位，让标题保持居中
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final error = _error;
    if (error != null) return _errorView(error);

    final doc = _doc;
    if (doc == null) return const SizedBox.shrink();
    return _documentView(doc);
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(AppIconKind.warn, size: 28, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: AppText.body13),
            const SizedBox(height: 18),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _load,
                icon: const AppIcon(AppIconKind.refresh,
                    size: 16, color: AppColors.primary),
                label: Text('重新加载',
                    style: AppText.medium13.copyWith(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primarySoftBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 全文：一整张白卡包住，法律文本用同一套排版，不做花哨样式
  Widget _documentView(LegalDoc doc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadH, 4, AppDimens.pagePadH, 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        decoration: appCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_metaLine(doc) != null) ...[
              Text(_metaLine(doc)!, style: AppText.label11),
              const SizedBox(height: 16),
            ],
            ...doc.sections.map(_sectionView),
          ],
        ),
      ),
    );
  }

  /// 「版本 2026.1 · 更新于 2026-10-14」；两字段都缺时不占位
  String? _metaLine(LegalDoc doc) {
    final parts = <String>[
      if (doc.version.isNotEmpty) '版本 ${doc.version}',
      if (doc.updatedAt.isNotEmpty) '更新于 ${doc.updatedAt}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Widget _sectionView(LegalSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.heading, style: AppText.smallTitle),
          const SizedBox(height: 8),
          ...section.paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(p, style: AppText.body13),
            ),
          ),
        ],
      ),
    );
  }
}

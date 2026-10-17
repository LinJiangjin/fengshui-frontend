import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_icons.dart';

/// 「保存这次测算」按钮：把当前测算的入参存进测算记录。
///
/// 同参重复保存服务端走更新（不堆重复行），所以不需要「已保存」之外的复杂状态：
/// 保存过一次就切成「已保存」态；**入参一变**（[didUpdateWidget] 比对 params）
/// 自动复位——用户改个出生时刻再算一次，按钮重新可用，不会把旧记录的
/// 「已保存」错贴到新测算上。
///
/// 放置在各测算页的结果区；登录态由 AppShell 的登录闸门保证，
/// 这里只处理 token 过期（401 -> 全局登出回登录页）。
class SaveRecordButton extends StatefulWidget {
  const SaveRecordButton({
    super.key,
    required this.kind,
    required this.title,
    required this.summary,
    required this.params,
  });

  /// 测算类型，后端白名单之一（见 models/record.dart 的 kRecordKindLabels）
  final String kind;

  /// 列表标题，如「乾造 1990-05-20 14:30」
  final String title;

  /// 列表副标题，如「辛未 丁酉 癸未 丙辰」
  final String summary;

  /// 当前测算的入参快照；变化即视为一次新测算（保存状态复位）
  final Map<String, dynamic> params;

  @override
  State<SaveRecordButton> createState() => _SaveRecordButtonState();
}

class _SaveRecordButtonState extends State<SaveRecordButton> {
  final ApiClient _api = ApiClient();

  bool _saving = false;

  /// 当前这份入参是否已保存（服务端同参去重，重复保存也只是刷新）
  bool _saved = false;

  @override
  void didUpdateWidget(SaveRecordButton old) {
    super.didUpdateWidget(old);
    // 入参哈希比对：改任何一个字段都算新测算，之前的「已保存」作废
    if (jsonEncode(old.params) != jsonEncode(widget.params)) {
      _saved = false;
    }
  }

  Future<void> _save() async {
    if (_saving || _saved) return;
    setState(() => _saving = true);
    try {
      await _api.saveRecord(
        kind: widget.kind,
        title: widget.title,
        summary: widget.summary,
        params: widget.params,
      );
      if (!mounted) return;
      setState(() => _saved = true);
      _toast('已保存到测算记录，可随时回看');
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        // token 失效：全局登出，AuthGate 自动切回登录页
        await AuthStore.instance?.forceLogout();
        return;
      }
      _toast(e.message, isError: true);
    } catch (e) {
      _toast('保存失败：$e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: isError ? AppColors.danger : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color fg = _saved ? AppColors.primary : AppColors.body;
    final Color border =
        _saved ? AppColors.primarySoftBorder : AppColors.cardBorder;
    final Color bg = _saved ? AppColors.primarySoftBg : AppColors.card;

    return GestureDetector(
      onTap: _saving ? null : _save,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_saving)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            else
              AppIcon(AppIconKind.bookmark, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(
              _saved ? '已保存' : '保存测算',
              style: AppText.label12.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

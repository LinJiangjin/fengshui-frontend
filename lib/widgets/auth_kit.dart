import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_colors.dart';

/// 登录 / 注册页共用的部件与样式，保证两页视觉完全一致。

/// 页面骨架：宣纸底 + 顶部品牌区 + 内容滚动区
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),
              // 品牌区：罗盘意象 + 主标题
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.explore_outlined,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '风水装修',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '登录后房屋档案云端同步，换机不丢失',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              ...children,
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// 输入框：白底圆角卡片式，与 App 卡片风格一致
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.keyboardType,
    this.maxLength,
    this.obscure = false,
    this.suffix,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final int? maxLength;
  final bool obscure;
  final Widget? suffix;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.body,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          obscureText: obscure,
          enabled: enabled,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: AppColors.ink),
          decoration: InputDecoration(
            counterText: '', // 去掉右下角字数
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
            filled: true,
            fillColor: AppColors.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// 「获取验证码」按钮：60 秒倒计时，期间置灰
class SendCodeButton extends StatefulWidget {
  const SendCodeButton({
    super.key,
    required this.onSend,
    required this.enabled,
  });

  /// 返回是否已成功触发发送（失败时不进入倒计时）
  final Future<bool> Function() onSend;
  final bool enabled;

  @override
  State<SendCodeButton> createState() => _SendCodeButtonState();
}

class _SendCodeButtonState extends State<SendCodeButton> {
  static const _interval = 60;

  Timer? _timer;
  int _left = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_left > 0) return;
    final sent = await widget.onSend();
    if (!sent || !mounted) return;
    setState(() => _left = _interval);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _left = t.tick >= _interval ? 0 : _interval - t.tick);
      if (t.tick >= _interval) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final counting = _left > 0;
    final text = counting ? '${_left}s 后重发' : '获取验证码';
    return TextButton(
      onPressed: (counting || !widget.enabled) ? null : _tap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.muted,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 44),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}

/// 主按钮：松墨绿实底，带 loading 态
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.loading,
  });

  final String text;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.55),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }
}

/// 底部切换链接：登录 ↔ 注册
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.leading,
    required this.action,
    required this.onAction,
  });

  final String leading;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(leading,
            style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        GestureDetector(
          onTap: onAction,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// 校验中国大陆手机号
bool isValidPhone(String v) => RegExp(r'^1[3-9]\d{9}$').hasMatch(v);

/// 统一弹错误提示（透出后端 detail 的中文文案）
void showAuthError(BuildContext context, Object e) {
  final msg = e is ApiException ? e.message : '网络异常，请稍后重试';
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.danger,
      duration: const Duration(seconds: 2),
    ),
  );
}

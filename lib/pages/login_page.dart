import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_store.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_kit.dart';
import 'register_page.dart';

/// 验证码登录页。手机号未注册时后端自动创建账号，所以本页也是「快捷登录」。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth});

  final AuthStore auth;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // 用 controller 监听器而不是 TextField.onChanged：
    // 自动填入验证码（_code.text = ...）不触发 onChanged，会漏掉重建，
    // 导致登录按钮停留在空操作上——点击「没反应」就是这个原因。
    _phone.addListener(_onFieldChanged);
    _code.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phone.removeListener(_onFieldChanged);
    _code.removeListener(_onFieldChanged);
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _phoneOk => isValidPhone(_phone.text.trim());
  bool get _codeOk => _code.text.trim().length >= 4;

  /// 发验证码；console 开发模式下后端回传 debug_code，自动填入方便联调
  Future<bool> _sendCode() async {
    if (!_phoneOk) {
      showAuthError(context, ApiException('请输入正确的 11 位手机号'));
      return false;
    }
    try {
      final r = await ApiClient().sendCode(_phone.text.trim());
      if (!mounted) return false;
      if (r.isDevMode) {
        _code.text = r.debugCode!;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('${r.notice ?? ''}，验证码已自动填入'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('验证码已发送，请查收短信')),
        );
      }
      return true;
    } catch (e) {
      if (mounted) showAuthError(context, e);
      return false;
    }
  }

  Future<void> _submit() async {
    if (!_phoneOk || !_codeOk || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.auth.login(_phone.text.trim(), _code.text.trim());
      // 成功后 AuthGate 监听到 user 变化自动进主界面，这里不做跳转
    } catch (e) {
      if (mounted) showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(children: [
      AuthTextField(
        controller: _phone,
        label: '手机号',
        hint: '请输入 11 位手机号',
        keyboardType: TextInputType.phone,
        maxLength: 11,
      ),
      const SizedBox(height: 20),
      AuthTextField(
        controller: _code,
        label: '验证码',
        hint: '6 位短信验证码',
        keyboardType: TextInputType.number,
        maxLength: 6,
        suffix: SendCodeButton(
          enabled: _phoneOk,
          onSend: _sendCode,
        ),
      ),
      const SizedBox(height: 28),
      AuthSubmitButton(
        text: '登录',
        loading: _submitting,
        // 字段不全时给明确提示，绝不静默空操作
        onPressed: (_phoneOk && _codeOk)
            ? _submit
            : () => showAuthError(
                context, ApiException('请先填写手机号并获取验证码')),
      ),
      const SizedBox(height: 24),
      AuthSwitchLink(
        leading: '还没有账号？',
        action: '注册新账号',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RegisterPage(auth: widget.auth),
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        '登录即代表同意《用户协议》与《隐私政策》',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: AppColors.muted),
      ),
    ]);
  }
}

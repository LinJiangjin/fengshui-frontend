import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_store.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_kit.dart';

/// 注册页。后端「验证码登录即注册」，所以注册 = 登录接口 + 注册成功后补昵称。
/// 与登录页的区别仅在于多一个可选昵称栏，以及文案口径是「创建账号」。
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.auth});

  final AuthStore auth;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _nickname = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // 同登录页：controller 监听器对「自动填入验证码」也生效
    _phone.addListener(_onFieldChanged);
    _code.addListener(_onFieldChanged);
    _nickname.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phone.removeListener(_onFieldChanged);
    _code.removeListener(_onFieldChanged);
    _nickname.removeListener(_onFieldChanged);
    _phone.dispose();
    _code.dispose();
    _nickname.dispose();
    super.dispose();
  }

  bool get _phoneOk => isValidPhone(_phone.text.trim());
  bool get _codeOk => _code.text.trim().length >= 4;

  Future<bool> _sendCode() async {
    if (!_phoneOk) {
      showAuthError(context, ApiException('请输入正确的 11 位手机号'));
      return false;
    }
    try {
      debugPrint('[Auth] send-code start: phone=${_phone.text.trim()}');
      final r = await ApiClient()
          .sendCode(_phone.text.trim(), scene: 'register');
      debugPrint(
          '[Auth] send-code ok: devMode=${r.isDevMode}, code=${r.debugCode}');
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
      debugPrint('[Auth] send-code failed: $e');
      if (mounted) showAuthError(context, e);
      return false;
    }
  }

  Future<void> _submit() async {
    if (!_phoneOk || !_codeOk || _submitting) return;
    setState(() => _submitting = true);
    try {
      final user = await widget.auth.login(_phone.text.trim(), _code.text.trim());
      // 登录成功后会触发 AuthGate 跳主界面；若页面已被 dispose 就不再补资料
      if (!mounted) return;
      // 已有昵称的说明是老用户，直接进 App；新号默认是「用户+尾号」才补填
      final nickname = _nickname.text.trim();
      if (nickname.isNotEmpty && user.nickname != nickname) {
        await widget.auth.updateProfile(nickname: nickname);
      }
      // 成功后 AuthGate 自动进主界面
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
      const SizedBox(height: 20),
      AuthTextField(
        controller: _nickname,
        label: '昵称（可选）',
        hint: '给自己起个名字，如「南山居士」',
        keyboardType: TextInputType.text,
        maxLength: 20,
      ),
      const SizedBox(height: 28),
      AuthSubmitButton(
        text: '注册并登录',
        loading: _submitting,
        onPressed: (_phoneOk && _codeOk)
            ? _submit
            : () => showAuthError(
                context, ApiException('请先填写手机号并获取验证码')),
      ),
      const SizedBox(height: 24),
      AuthSwitchLink(
        leading: '已有账号？',
        action: '直接登录',
        onAction: () => Navigator.of(context).pop(),
      ),
      const SizedBox(height: 16),
      const Text(
        '新手机号验证通过后即自动创建账号',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: AppColors.muted),
      ),
    ]);
  }
}

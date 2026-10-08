import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';

/// 登录态仓库：token 持久化 + 当前用户 + 401 全局登出。
///
/// 用法：main.dart 持有单例并 listen；任何请求抛 401 时调 [forceLogout]，
/// AuthGate 监听到 user == null 自动切回登录页，无需逐页处理。
class AuthStore extends ChangeNotifier {
  AuthStore._(this._prefs);

  /// 全局单例引用：HouseStore 等无 context 的服务用它触发 401 登出
  static AuthStore? instance;

  static const _kToken = 'auth_token';

  final SharedPreferences _prefs;

  AppUser? _user;
  bool _booted = false;

  AppUser? get user => _user;
  bool get booted => _booted;
  bool get isLoggedIn => _user != null;

  /// 恢复登录态：有 token 就先带上，再向 /me 校验；失效则清掉。
  /// 无论成败都要置 booted，闪屏页不能永远转圈。
  static Future<AuthStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AuthStore._(prefs);
    kAuthToken = prefs.getString(_kToken);
    if (kAuthToken != null && kAuthToken!.isNotEmpty) {
      try {
        store._user = await ApiClient().fetchMe();
      } on ApiException catch (e) {
        if (e.isUnauthorized) await store._clearToken();
        // 网络差时保留 token，进主界面后房屋接口还会再试
      } catch (_) {}
    }
    store._booted = true;
    store.notifyListeners();
    return store;
  }

  /// 验证码登录（后端对新手机号自动注册，所以登录/注册共用此方法）。
  Future<AppUser> login(String phone, String code) async {
    final user = await ApiClient().login(phone, code);
    await _prefs.setString(_kToken, kAuthToken ?? '');
    _user = user;
    notifyListeners();
    return user;
  }

  /// 登录成功后补资料（注册页用）。
  Future<AppUser> updateProfile({String? nickname, String? avatar}) async {
    final user = await ApiClient().updateMe(nickname: nickname, avatar: avatar);
    _user = user;
    notifyListeners();
    return user;
  }

  /// 用户主动退出。
  Future<void> logout() async {
    await _clearToken();
    notifyListeners();
  }

  /// 401 时全局调用：清 token，AuthGate 自动切回登录页。
  Future<void> forceLogout() async {
    if (_user == null && (kAuthToken == null || kAuthToken!.isEmpty)) return;
    await _clearToken();
    notifyListeners();
  }

  Future<void> _clearToken() async {
    kAuthToken = null;
    _user = null;
    await _prefs.remove(_kToken);
  }
}

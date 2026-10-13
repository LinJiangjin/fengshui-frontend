import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bazi_record.dart';
import 'api_client.dart';
import 'auth_store.dart';

/// 命理档案仓库：记住用户上次录入的出生信息。
///
/// 本地用 shared_preferences 留一份，App 冷启动（或断网）也能立刻回填；
/// 同时写到服务端 `/api/v1/bazi/profile`，换设备不丢、管理后台可见。
class BaziStore extends ChangeNotifier {
  BaziStore({ApiClient? api}) : _api = api ?? ApiClient();

  /// 本地留存的出生信息（与提交给后端的 body 同构）
  static const _kLocalKey = 'bazi_profile_local';

  final ApiClient _api;

  BaziRecord? _record;
  String? _lastError;

  /// 上次录入的出生信息；null 表示还没录入过
  BaziRecord? get record => _record;

  /// 最近一次与服务端同步的错误；null 表示正常
  String? get lastError => _lastError;

  /// 本地先回填，再与服务端对齐（服务端有档案时以其为准）
  Future<void> init() async {
    final local = await _readLocal();
    if (local != null) {
      _record = local;
      notifyListeners();
    }
    await refresh();
  }

  /// 从服务端对齐档案。
  /// 服务端还没有而本地有时保留本地那份（说明是还没同步上去的新录入）。
  Future<void> refresh() async {
    try {
      final remote = await _api.fetchBaziProfile();
      if (remote != null) {
        _record = remote;
        await _writeLocal(remote);
      }
      _lastError = null;
    } catch (e) {
      _handleAuthError(e);
      _lastError = e.toString();
    }
    notifyListeners();
  }

  /// 保存出生信息：先落本地，再落服务端。
  ///
  /// 服务端失败时抛出异常由页面提示，但本地那份保留 —— 下次进入页面
  /// 依然能回填用户刚录入的信息，不会白填。
  Future<void> save(BaziRecord draft) async {
    _record = draft;
    await _writeLocal(draft);
    notifyListeners();

    try {
      final saved = await _api.saveBaziProfile(draft);
      _record = saved;
      await _writeLocal(saved);
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _handleAuthError(e);
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<BaziRecord?> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLocalKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return BaziRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // 本地数据损坏就当没记录，不要让页面崩在解析上
      return null;
    }
  }

  Future<void> _writeLocal(BaziRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocalKey, jsonEncode(record.toJson()));
  }

  /// token 失效时全局登出，AuthGate 监听后自动切回登录页
  void _handleAuthError(Object e) {
    if (e is ApiException && e.isUnauthorized) {
      AuthStore.instance?.forceLogout();
    }
  }
}

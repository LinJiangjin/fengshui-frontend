import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/house.dart';
import 'api_client.dart';
import 'auth_store.dart';
import 'compass_service.dart';

/// 房屋仓库：管理多套房屋档案 + 当前选中的房屋。
///
/// 房屋数据持久化在服务端（`/api/v1/houses`），本地只保留「当前选中哪一套」，
/// 这样换设备 / 重装 App 后档案还在；房屋一经变化（切换 / 编辑 / 罗盘重测）
/// 就 notifyListeners，上层带着新参数重新请求后端。
class HouseStore extends ChangeNotifier {
  HouseStore._(this._api, List<HouseProfile> houses, String currentId)
      : _houses = houses,
        _currentId = currentId;

  /// 本地只存当前选中的房屋 id，房屋本体不落本地
  static const _kCurrentId = 'house_current_id';

  final ApiClient _api;

  List<HouseProfile> _houses;
  String _currentId;

  /// 最近一次拉列表的错误；null 表示正常（空列表就是真的没有房屋）
  String? _lastError;

  String? get lastError => _lastError;

  static Future<HouseStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kCurrentId) ?? '';
    final store = HouseStore._(ApiClient(), <HouseProfile>[], id);
    await store.refresh();
    return store;
  }

  List<HouseProfile> get houses => List<HouseProfile>.unmodifiable(_houses);

  bool get isEmpty => _houses.isEmpty;

  /// 当前房屋；尚未建档时为 null，不要拿示例房屋顶替
  HouseProfile? get current {
    if (_houses.isEmpty) return null;
    return _houses.firstWhere(
      (h) => h.id == _currentId,
      orElse: () => _houses.first,
    );
  }

  bool isCurrent(String id) => id == _currentId;

  Future<void> _persistCurrentId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentId, _currentId);
  }

  /// 从服务端重新拉取房屋列表
  Future<void> refresh() async {
    try {
      _houses = await _api.fetchHouses();
      _lastError = null;
    } catch (e) {
      _handleAuthError(e);
      _houses = <HouseProfile>[];
      _lastError = e.toString();
    }
    if (_currentId.isEmpty || !_houses.any((h) => h.id == _currentId)) {
      _currentId = _houses.isEmpty ? '' : _houses.first.id;
    }
    notifyListeners();
  }

  /// token 失效时全局登出，AuthGate 监听后自动切回登录页
  void _handleAuthError(Object e) {
    if (e is ApiException && e.isUnauthorized) {
      AuthStore.instance?.forceLogout();
    }
  }

  /// 切换当前房屋（只是本地偏好，不改动房屋数据）
  Future<void> select(String id) async {
    if (_currentId == id) return;
    _currentId = id;
    await _persistCurrentId();
    notifyListeners();
  }

  /// 新增或保存房屋，并把它设为当前房屋（写服务端）
  Future<void> upsert(HouseProfile house) async {
    HouseProfile saved;
    try {
      saved = await _api.saveHouse(house);
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
    final i = _houses.indexWhere((h) => h.id == saved.id);
    if (i >= 0) {
      _houses[i] = saved;
    } else {
      _houses.add(saved);
    }
    _currentId = saved.id;
    await _persistCurrentId();
    notifyListeners();
  }

  /// 删除房屋
  Future<void> remove(String id) async {
    try {
      await _api.deleteHouse(id);
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
    _houses.removeWhere((h) => h.id == id);
    if (_currentId == id) {
      _currentId = _houses.isEmpty ? '' : _houses.first.id;
    }
    await _persistCurrentId();
    notifyListeners();
  }

  /// 写入磁北读数 + 磁偏角（罗盘测量后的回写，落库）
  Future<void> setOrientation(double degree, {double? declination}) async {
    final i = _houses.indexWhere((h) => h.id == _currentId);
    if (i < 0) return;
    HouseProfile updated;
    try {
      updated = await _api.patchHouse(
        _currentId,
        degree: Angle.normalize(degree),
        declination: declination,
      );
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
    _houses[i] = updated;
    notifyListeners();
  }

  /// 写入真北度数（内部换算回磁北读数，偏角校正交给后端统一处理）
  Future<void> setTrueNorth(double trueNorth, {double? declination}) async {
    final c = current;
    if (c == null) return;
    final decl = declination ?? c.declination;
    await setOrientation(Angle.normalize(trueNorth - decl),
        declination: decl);
  }

  /// 旧版本存在本地的房屋数据（key 保留仅用于一次性迁移）
  static const _kHousesLegacy = 'house_profiles';

  /// 把旧版本留在本地的房屋一次性迁到服务端（服务端已存在的跳过）
  Future<int> migrateLegacyIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHousesLegacy);
    if (raw == null || raw.isEmpty) return 0;
    List<HouseProfile> legacy;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      legacy = list
          .map((e) => HouseProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return 0;
    }
    var n = 0;
    for (final h in legacy) {
      if (_houses.any((x) => x.id == h.id)) continue;
      try {
        await upsert(h);
        n++;
      } catch (_) {
        // 单条失败不影响其余迁移
      }
    }
    await prefs.remove(_kHousesLegacy);
    return n;
  }
}

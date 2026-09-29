import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/house.dart';
import 'compass_service.dart';

/// 房屋仓库：管理多套房屋档案 + 当前选中的房屋。
///
/// 房屋一旦变化（切换 / 编辑 / 罗盘重新测量）就 notifyListeners，
/// 上层监听后带着新参数重新请求后端，拿到该房屋真实算出的结果。
class HouseStore extends ChangeNotifier {
  HouseStore._(List<HouseProfile> houses, String currentId)
      : _houses = houses,
        _currentId = currentId;

  static const _kHouses = 'house_profiles';
  static const _kCurrentId = 'house_current_id';

  static Future<HouseStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    var houses = <HouseProfile>[];
    final raw = prefs.getString(_kHouses);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        houses = list
            .map((e) => HouseProfile.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        houses = <HouseProfile>[];
      }
    }
    if (houses.isEmpty) houses = <HouseProfile>[HouseProfile.seed()];

    var id = prefs.getString(_kCurrentId) ?? '';
    if (!houses.any((h) => h.id == id)) id = houses.first.id;
    return HouseStore._(houses, id);
  }

  final List<HouseProfile> _houses;
  String _currentId;

  List<HouseProfile> get houses => List<HouseProfile>.unmodifiable(_houses);

  HouseProfile get current => _houses.firstWhere(
        (h) => h.id == _currentId,
        orElse: () => _houses.first,
      );

  bool isCurrent(String id) => id == _currentId;

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kHouses,
      jsonEncode(_houses.map((h) => h.toJson()).toList()),
    );
    await prefs.setString(_kCurrentId, _currentId);
  }

  /// 切换当前房屋
  Future<void> select(String id) async {
    if (_currentId == id) return;
    _currentId = id;
    await _save();
    notifyListeners();
  }

  /// 新增或保存房屋，并把它设为当前房屋
  Future<void> upsert(HouseProfile house) async {
    final i = _houses.indexWhere((h) => h.id == house.id);
    if (i >= 0) {
      _houses[i] = house;
    } else {
      _houses.add(house);
    }
    _currentId = house.id;
    await _save();
    notifyListeners();
  }

  /// 删除房屋（至少保留一套）
  Future<void> remove(String id) async {
    if (_houses.length <= 1) return;
    _houses.removeWhere((h) => h.id == id);
    if (_currentId == id) _currentId = _houses.first.id;
    await _save();
    notifyListeners();
  }

  /// 写入磁北读数 + 磁偏角（罗盘测量后的回写）
  Future<void> setOrientation(double degree, {double? declination}) async {
    final i = _houses.indexWhere((h) => h.id == _currentId);
    if (i < 0) return;
    final old = _houses[i];
    _houses[i] = old.copyWith(
      degree: Angle.normalize(degree),
      declination: declination ?? old.declination,
    );
    await _save();
    notifyListeners();
  }

  /// 写入真北度数（内部换算回磁北读数，偏角校正交给后端统一处理）
  Future<void> setTrueNorth(double trueNorth, {double? declination}) async {
    final decl = declination ?? current.declination;
    await setOrientation(Angle.normalize(trueNorth - decl),
        declination: decl);
  }
}

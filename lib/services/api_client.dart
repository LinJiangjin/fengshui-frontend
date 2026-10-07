import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/bazi.dart';
import '../models/diagnosis.dart';
import '../models/house.dart';
import '../models/library.dart';

/// 后端地址。
/// 默认本机调试；Android 模拟器自动改用 10.0.2.2 访问宿主机，
/// 真机请用 --dart-define=API_BASE_URL=http://<电脑局域网IP>:8000 覆盖。
///
/// 注意：Web 平台没有 dart:io，必须用 kIsWeb 先短路，避免运行时崩溃。
const String _kConfiguredBaseUrl = String.fromEnvironment('API_BASE_URL');

final String kApiBaseUrl = _kConfiguredBaseUrl.isNotEmpty
    ? _kConfiguredBaseUrl
    : (kIsWeb || !Platform.isAndroid
        ? 'http://127.0.0.1:8000'
        : 'http://10.0.2.2:8000');

/// 所有结果均来自后端确定性规则引擎，客户端不再内置任何结果快照。
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? kApiBaseUrl;

  final String baseUrl;

  Future<Diagnosis> diagnose({
    required double degree,
    required double declination,
    required String houseName,
    String layout = '',
    double area = 0,
    int? year,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final uri = Uri.parse('$baseUrl/api/v1/diagnose');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'degree': degree,
            'declination': declination,
            // 不传年份时由服务端按当前年计算
            'year': year ?? d.year,
            'house_name': houseName,
            'layout': layout,
            'area': area,
            // 日家紫白按测算当日推算，今日吉位 / 今日忌方随日期变化
            'month': d.month,
            'day': d.day,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('诊断失败：HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw Exception('诊断失败：${body['status']}');
    }
    return Diagnosis.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 八字排盘：四柱、五行占比、日主强弱与用神喜忌。
  /// 性别与经度直接决定排盘结果，必须显式传入，不能由客户端代填默认值。
  Future<BaziProfile> fetchBazi({
    required int year,
    required int month,
    required int day,
    required int hour,
    required String gender,
    required double longitude,
    int minute = 0,
    String name = '',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/bazi');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'year': year,
            'month': month,
            'day': day,
            'hour': hour,
            'minute': minute,
            'gender': gender,
            'longitude': longitude,
            'name': name,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('排盘失败：HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw Exception('排盘失败：${body['status']}');
    }
    return BaziProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ------------------------------------------------------- 房屋档案（落库）
  /// 房屋列表；房屋数据存服务端，不再只留在本地
  Future<List<HouseProfile>> fetchHouses() async {
    final uri = Uri.parse('$baseUrl/api/v1/houses');
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('房屋列表加载失败：HTTP ${res.statusCode}');
    }
    final body = _decode(res.body);
    final items = (body['items'] as List? ?? []);
    return items
        .map((e) => HouseProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 新建 / 保存房屋（按 id upsert），返回服务端落库后的数据
  Future<HouseProfile> saveHouse(HouseProfile house) async {
    final uri = Uri.parse('$baseUrl/api/v1/houses');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(house.toJson()),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('房屋保存失败：HTTP ${res.statusCode}');
    }
    return HouseProfile.fromJson(_decode(res.body));
  }

  /// 局部更新：罗盘测量后回写坐向、保存布局方案等
  Future<HouseProfile> patchHouse(
    String id, {
    double? degree,
    double? declination,
    List<RoomProfile>? rooms,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/houses/$id');
    final payload = <String, dynamic>{};
    if (degree != null) payload['degree'] = degree;
    if (declination != null) payload['declination'] = declination;
    if (rooms != null) {
      payload['rooms'] = rooms.map((r) => r.toJson()).toList();
    }
    final res = await http
        .patch(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('房屋更新失败：HTTP ${res.statusCode}');
    }
    return HouseProfile.fromJson(_decode(res.body));
  }

  Future<void> deleteHouse(String id) async {
    final uri = Uri.parse('$baseUrl/api/v1/houses/$id');
    final res = await http.delete(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('房屋删除失败：HTTP ${res.statusCode}');
    }
  }

  Map<String, dynamic> _decode(String body) {
    final j = jsonDecode(body) as Map<String, dynamic>;
    if (j['code'] != 0) {
      throw Exception('${j['status'] ?? '请求失败'}');
    }
    return j['data'] as Map<String, dynamic>;
  }

  /// 装修方案库与本月五行配色（内容由服务端下发，便于运营更新）
  Future<LibraryData> fetchLibrary({int month = 0}) async {
    final uri = Uri.parse('$baseUrl/api/v1/library').replace(
      queryParameters: month > 0 ? {'month': '$month'} : null,
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('方案库加载失败：HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw Exception('方案库加载失败：${body['status']}');
    }
    return LibraryData.fromJson(body['data'] as Map<String, dynamic>);
  }
}

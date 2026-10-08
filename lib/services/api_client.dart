import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/bazi.dart';
import '../models/diagnosis.dart';
import '../models/house.dart';
import '../models/library.dart';
import '../models/user.dart';

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

/// 当前登录 token（由 AuthStore 写入 / 清除）。
/// ApiClient 无状态，全局单例放这里最简单，避免层层传参。
String? kAuthToken;

/// 业务异常：带 HTTP 状态码，401 时上层据此回到登录页。
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// token 缺失 / 过期 / 伪造 —— 唯一应当触发重新登录的情况
  bool get isUnauthorized => statusCode == 401;

  /// 被封禁等 403 场景：明确提示，但不强制登出
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}

/// 发码结果。debugCode 仅在后端 console 开发模式下存在，用于联调自动填入。
class SendCodeResult {
  const SendCodeResult({
    required this.expiresIn,
    this.debugCode,
    this.notice,
  });

  final int expiresIn;
  final String? debugCode;
  final String? notice;

  bool get isDevMode => debugCode != null;
}

/// 所有结果均来自后端确定性规则引擎，客户端不再内置任何结果快照。
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? kApiBaseUrl;

  final String baseUrl;

  /// 所有请求统一带 Content-Type + Bearer token（未登录时省略）
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (kAuthToken != null && kAuthToken!.isNotEmpty)
          // 注意：不要写成 'Bearer $kAuthToken!'——插值后紧跟的 ! 会被当作
          // 普通字符拼进 token，后端验签会失败（踩过一次）。
          'Authorization': 'Bearer ${kAuthToken!}',
      };

  /// 统一把 HTTP 层错误翻成 ApiException，401/403 交给上层分流
  ApiException _httpError(int code, String fallback) {
    return ApiException(fallback, statusCode: code);
  }

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
          headers: _headers,
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
          headers: _headers,
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
    final res = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 8),
        );
    if (res.statusCode == 401) {
      throw _httpError(401, '登录已过期，请重新登录');
    }
    if (res.statusCode != 200) {
      throw _httpError(res.statusCode, '房屋列表加载失败：HTTP ${res.statusCode}');
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
          headers: _headers,
          body: jsonEncode(house.toJson()),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 401) {
      throw _httpError(401, '登录已过期，请重新登录');
    }
    if (res.statusCode != 200) {
      throw _httpError(res.statusCode, '房屋保存失败：HTTP ${res.statusCode}');
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
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 401) {
      throw _httpError(401, '登录已过期，请重新登录');
    }
    if (res.statusCode != 200) {
      throw _httpError(res.statusCode, '房屋更新失败：HTTP ${res.statusCode}');
    }
    return HouseProfile.fromJson(_decode(res.body));
  }

  Future<void> deleteHouse(String id) async {
    final uri = Uri.parse('$baseUrl/api/v1/houses/$id');
    final res = await http.delete(uri, headers: _headers).timeout(
          const Duration(seconds: 8),
        );
    if (res.statusCode == 401) {
      throw _httpError(401, '登录已过期，请重新登录');
    }
    if (res.statusCode != 200) {
      throw _httpError(res.statusCode, '房屋删除失败：HTTP ${res.statusCode}');
    }
  }

  // ------------------------------------------------------- 认证（验证码登录）
  /// 发送短信验证码。console 开发模式下后端会回传 debug_code，可直接自动填入。
  Future<SendCodeResult> sendCode(String phone, {String scene = 'login'}) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/send-code');
    final res = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({'phone': phone, 'scene': scene}),
        )
        .timeout(const Duration(seconds: 8));
    final body = _errorBodyOrData(res, fallback: '验证码发送失败');
    return SendCodeResult(
      expiresIn: (body['expires_in'] ?? 300) as int,
      debugCode: body['debug_code'] as String?,
      notice: body['notice'] as String?,
    );
  }

  /// 验证码登录；手机号未注册时后端自动创建账号（注册 = 同一接口）。
  Future<AppUser> login(String phone, String code) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/login');
    final res = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({'phone': phone, 'code': code}),
        )
        .timeout(const Duration(seconds: 8));
    final body = _errorBodyOrData(res, fallback: '登录失败');
    kAuthToken = body['token'] as String?;
    return AppUser.fromJson(body['user'] as Map<String, dynamic>);
  }

  /// 用已有 token 换用户资料；App 启动时校验 token 是否仍有效。
  Future<AppUser> fetchMe() async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/me');
    final res = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 8),
        );
    final body = _errorBodyOrData(res, fallback: '获取用户信息失败');
    return AppUser.fromJson(body);
  }

  /// 修改昵称 / 头像（注册页用它补昵称）。
  Future<AppUser> updateMe({String? nickname, String? avatar}) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/me');
    final payload = <String, dynamic>{};
    if (nickname != null) payload['nickname'] = nickname;
    if (avatar != null) payload['avatar'] = avatar;
    final res = await http
        .patch(
          uri,
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));
    final body = _errorBodyOrData(res, fallback: '资料保存失败');
    return AppUser.fromJson(body);
  }

  /// 非 200 时抛 ApiException（detail 透出后端中文提示）；200 时返回 data。
  Map<String, dynamic> _errorBodyOrData(
    http.Response res, {
    required String fallback,
  }) {
    if (res.statusCode == 401) {
      throw _httpError(401, '登录已过期，请重新登录');
    }
    if (res.statusCode != 200) {
      String detail = fallback;
      try {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        // FastAPI 的 HTTPException detail 就是给用户看的中文提示
        detail = (j['detail'] ?? j['status'] ?? fallback).toString();
      } catch (_) {}
      throw _httpError(res.statusCode, detail);
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['code'] != 0) {
      throw ApiException((j['status'] ?? fallback).toString());
    }
    return j['data'] as Map<String, dynamic>;
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
    final res = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 8),
        );
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

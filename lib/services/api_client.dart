import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;

import '../models/almanac.dart';
import '../models/bazi.dart';
import '../models/bazi_record.dart';
import '../models/bazhai.dart';
import '../models/diagnosis.dart';
import '../models/house.dart';
import '../models/legal.dart';
import '../models/library.dart';
import '../models/ziwei.dart';
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

  /// 紫微斗数：排十二宫命盘，并给出感情 / 职业 / 运势解读。
  /// 与排盘接口同样无状态、不落库，用同一份出生信息请求。
  Future<ZiweiChart> fetchZiwei({
    required int year,
    required int month,
    required int day,
    required int hour,
    required String gender,
    required double longitude,
    int minute = 0,
    String name = '',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/ziwei');
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
      throw Exception('紫微排盘失败：HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw Exception('紫微排盘失败：${body['status']}');
    }
    return ZiweiChart.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ------------------------------------------------------- 命理档案（落库）
  /// 读取当前用户的命理档案；后端 data 为 null（还没录入过）时返回 null
  Future<BaziRecord?> fetchBaziProfile() async {
    final uri = Uri.parse('$baseUrl/api/v1/bazi/profile');
    final res = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 8),
        );
    if (res.statusCode == 401) {
      throw _httpError(401, '登录已过期，请重新登录');
    }
    if (res.statusCode != 200) {
      throw _httpError(res.statusCode, '命理档案加载失败：HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw ApiException('${body['status'] ?? '命理档案加载失败'}');
    }
    final data = body['data'];
    // 还没录入过档案不是错误，交给页面展示录入表单
    if (data == null) return null;
    return BaziRecord.fromJson(data as Map<String, dynamic>);
  }

  /// 保存 / 覆盖当前用户的命理档案，返回服务端落库后的数据
  Future<BaziRecord> saveBaziProfile(BaziRecord record) async {
    final uri = Uri.parse('$baseUrl/api/v1/bazi/profile');
    final res = await http
        .put(
          uri,
          headers: _headers,
          body: jsonEncode(record.toJson()),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 401) {
      throw _httpError(401, '登录已过期，请重新登录');
    }
    if (res.statusCode != 200) {
      throw _httpError(res.statusCode, '命理档案保存失败：HTTP ${res.statusCode}');
    }
    return BaziRecord.fromJson(_decode(res.body));
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
    debugPrint(
        '[ApiClient] POST $uri body={"phone":"$phone","scene":"$scene"}');
    final res = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({'phone': phone, 'scene': scene}),
        )
        .timeout(const Duration(seconds: 8));
    debugPrint('[ApiClient] send-code status=${res.statusCode} body=${res.body}');
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
    debugPrint(
        '[ApiClient] POST $uri body={"phone":"$phone","code":"$code"}');
    final res = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({'phone': phone, 'code': code}),
        )
        .timeout(const Duration(seconds: 8));
    debugPrint('[ApiClient] login status=${res.statusCode} body=${res.body}');
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

  /// 注销账号。不可恢复：后端会物理删除命理档案与房屋档案、清掉验证码记录，
  /// 并把账号行匿名化，返回后旧 token 立即失效。
  /// 调用方（AuthStore）负责在成功后清理本地登录态。
  Future<void> deleteAccount() async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/delete-account');
    final res = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({'confirm': true}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 401) {
      throw _httpError(401, '登录已过期，请重新登录');
    }
    if (res.statusCode != 200) {
      String detail = '注销失败，请稍后重试';
      try {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        // FastAPI 的 HTTPException detail 就是给用户看的中文提示
        detail = (j['detail'] ?? j['status'] ?? detail).toString();
      } catch (_) {}
      throw _httpError(res.statusCode, detail);
    }
  }

  /// 拉取用户协议 / 隐私政策正文。条款由服务端下发，更新后无需发版。
  Future<LegalDoc> fetchLegalDoc(String slug) async {
    final uri = Uri.parse('$baseUrl/api/v1/legal/$slug');
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw _httpError(res.statusCode, '文档加载失败：HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw ApiException('${body['status'] ?? '文档加载失败'}');
    }
    return LegalDoc.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 八宅游年：出生年 + 性别定命卦，坐向定宅卦，再出各宫吉凶与房间选位。
  ///
  /// [degree] 与 [trigram] 二者取一：传度数会顺带返回坐向明细（推荐），
  /// 只知卦名时传 [trigram]。两者都不传后端会返回 400。
  /// [month]/[day]/[hour]/[minute] 用于立春分界——命卦按立春换年，
  /// 只传年份会把年初出生的人算错一年。
  Future<BazhaiChart> fetchBazhai({
    required int year,
    required String gender,
    int month = 0,
    int day = 0,
    int hour = 0,
    int minute = 0,
    double? degree,
    double declination = 0,
    String trigram = '',
    String name = '',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/bazhai');
    final payload = <String, dynamic>{
      'year': year,
      'gender': gender,
      'month': month,
      'day': day,
      'hour': hour,
      'minute': minute,
      'declination': declination,
      'trigram': trigram,
      'name': name,
    };
    if (degree != null) payload['degree'] = degree;

    final res = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      String detail = '八宅排盘失败';
      try {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        // FastAPI 的 HTTPException detail 就是给用户看的中文提示
        detail = (j['detail'] ?? j['message'] ?? detail).toString();
      } catch (_) {}
      throw _httpError(res.statusCode, detail);
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw ApiException('${body['status'] ?? '八宅排盘失败'}');
    }
    return BazhaiChart.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 黄历：指定日期的通书。date 传「YYYY-MM-DD」，留空取服务端今天。
  Future<AlmanacDay> fetchAlmanacDay({String? date}) async {
    final uri = Uri.parse('$baseUrl/api/v1/almanac/day').replace(
      queryParameters: (date == null || date.isEmpty) ? null : {'date': date},
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    return AlmanacDay.fromJson(
      _errorBodyOrData(res, fallback: '黄历加载失败，请稍后重试'),
    );
  }

  /// 可择日的事项清单（装修开工 / 入宅搬家 / 安床 …）。
  Future<List<AlmanacActivity>> fetchAlmanacActivities() async {
    final uri = Uri.parse('$baseUrl/api/v1/almanac/activities');
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    final data = _errorBodyOrData(res, fallback: '事项加载失败');
    return (data['activities'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AlmanacActivity.fromJson)
        .toList();
  }

  /// 择日：在 [days] 天区间内为 [activity] 挑吉日，按分数降序返回。
  ///
  /// [zodiac] 传用户生肖时，冲该生肖的日子会被扣分并在结果里标记
  /// （后端保留这些日期并标注 clash，不静默剔除）。
  Future<AlmanacSelectResult> selectAlmanacDates({
    required String activity,
    String? startDate,
    int days = 30,
    String zodiac = '',
    int limit = 8,
    int minScore = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/almanac/select');
    final payload = <String, dynamic>{
      'activity': activity,
      'days': days,
      'zodiac': zodiac,
      'limit': limit,
      'min_score': minScore,
    };
    if (startDate != null && startDate.isNotEmpty) {
      payload['start_date'] = startDate;
    }
    final res = await http
        .post(uri, headers: _headers, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 15));
    return AlmanacSelectResult.fromJson(
      _errorBodyOrData(res, fallback: '择日失败，请稍后重试'),
    );
  }

  /// 整月每日吉凶。activity 留空则返回「当日总体吉凶」。
  Future<AlmanacCalendar> fetchAlmanacCalendar({
    required int year,
    required int month,
    String activity = '',
    String zodiac = '',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/almanac/month').replace(
      queryParameters: {
        'year': '$year',
        'month': '$month',
        if (activity.isNotEmpty) 'activity': activity,
        if (zodiac.isNotEmpty) 'zodiac': zodiac,
      },
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    return AlmanacCalendar.fromJson(
      _errorBodyOrData(res, fallback: '月历加载失败，请稍后重试'),
    );
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

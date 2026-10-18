import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 后端端口（与 server 启动参数保持一致）。
const int kApiPort = 8000;

/// 编译期指定的地址，优先级最高：
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.2:8000
const String kConfiguredBaseUrl = String.fromEnvironment('API_BASE_URL');

/// 静态兜底地址：探测完成前 / Web 平台使用。
/// 注意：Web 平台没有 dart:io，必须用 kIsWeb 先短路，避免运行时崩溃。
final String kDefaultApiBaseUrl = kIsWeb || !Platform.isAndroid
    ? 'http://127.0.0.1:$kApiPort'
    : 'http://10.0.2.2:$kApiPort';

/// 当前生效的后端地址。每次请求读它，所以自动探测结果能立即对所有 ApiClient 生效。
String kActiveApiBaseUrl =
    kConfiguredBaseUrl.isNotEmpty ? kConfiguredBaseUrl : kDefaultApiBaseUrl;

const Duration _kProbeTimeout = Duration(milliseconds: 900);
const Duration _kTotalBudget = Duration(seconds: 3);
const int _kScanLastOctetMax = 40; // 家用路由器 DHCP 池基本落在这一区间
const String _kCacheKey = 'api_base_url';

String? _resolvedCache;
Future<String>? _pending;

/// 在 App 启动阶段调用：确定后端地址。
///
/// - 编译期指定了 API_BASE_URL：直接用，零耗时；
/// - 否则先验证上次成功的地址（局域网 IP 换了 / 后端没起时会自动失效），
///   再依次探测本机已知地址，最后按本机 Wi-Fi 网段小范围扫描。
///
/// 整个探测有 3 秒总预算，超时就退回默认值，不影响进入界面。
Future<String> resolveApiBaseUrl({Duration budget = _kTotalBudget}) {
  if (kConfiguredBaseUrl.isNotEmpty) {
    _resolvedCache = kConfiguredBaseUrl;
    kActiveApiBaseUrl = kConfiguredBaseUrl;
    return Future<String>.value(kConfiguredBaseUrl);
  }
  // 并发调用合并为一次探测，避免多个 Store 同时触发重复扫描。
  return _pending ??= _doResolve(budget).whenComplete(() => _pending = null);
}

Future<String> _doResolve(Duration budget) async {
  if (_resolvedCache != null) return _resolvedCache!;
  final clock = Stopwatch()..start();

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('[baseUrl] shared prefs unavailable: $e');
  }

  // 1) 上次成功的地址——命中就几乎零延迟（一次 /health 的 RTT）。
  final cached = prefs?.getString(_kCacheKey);
  if (cached != null && cached.isNotEmpty && await _ping(cached)) {
    return _commit(prefs, cached);
  }

  // 2) 已知地址：adb reverse 的本机映射 / 模拟器宿主机 / 本机回环。
  final known = <String>[
    if (!kIsWeb && Platform.isAndroid) 'http://127.0.0.1:$kApiPort',
    kDefaultApiBaseUrl,
  ];
  final hit = await _race(known, budget - clock.elapsed);
  if (hit != null) return _commit(prefs, hit);

  // 3) 按本机 Wi-Fi 网段探测（真机最常见的情况：手机连同一 Wi-Fi，
  //    但电脑的局域网 IP 无法从手机侧推断，只能扫同网段常见地址）。
  final lan = await _lanCandidates();
  final remaining = budget - clock.elapsed;
  if (lan.isNotEmpty && remaining > Duration.zero) {
    final lanHit = await _race(lan, remaining, concurrency: 20);
    if (lanHit != null) return _commit(prefs, lanHit);
  }

  // Web 端兜底：本机探测不到后端时，按「前后端同域部署」处理——
  // baseUrl 置空即走相对路径（/api/v1/...），浏览器自动请求页面所在域名。
  // 本地 flutter run 时后端在本机，上面的 127.0.0.1 探测会命中，不会走到这里。
  if (kIsWeb) {
    kActiveApiBaseUrl = '';
    return '';
  }
  kActiveApiBaseUrl = kDefaultApiBaseUrl;
  return kDefaultApiBaseUrl;
}

String _commit(SharedPreferences? prefs, String url) {
  _resolvedCache = url;
  kActiveApiBaseUrl = url;
  debugPrint('[baseUrl] resolved -> $url');
  prefs?.setString(_kCacheKey, url);
  return url;
}

/// 地址失效时（比如换 Wi-Fi、后端重启到别的机器）清掉缓存，下次重新探测。
Future<void> invalidateApiBaseUrl() async {
  _resolvedCache = null;
  kActiveApiBaseUrl = kDefaultApiBaseUrl;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCacheKey);
  } catch (_) {
    // 清不掉也不影响功能：启动时会对缓存地址做一次探活。
  }
}

/// 并发探活，返回第一个可用的地址。
Future<String?> _race(
  List<String> urls,
  Duration budget, {
  int concurrency = 8,
}) async {
  if (urls.isEmpty || budget <= Duration.zero) return null;
  final completer = Completer<String?>();
  var pending = urls.length;
  var cursor = 0;

  void launch() {
    // completer 已完成时不再起飞新请求，省掉一次整网的无效连接。
    if (completer.isCompleted || cursor >= urls.length) return;
    final url = urls[cursor++];
    _ping(url).then((ok) {
      if (ok && !completer.isCompleted) completer.complete(url);
      pending--;
      if (pending == 0 && !completer.isCompleted) completer.complete(null);
      if (!completer.isCompleted) launch();
    });
  }

  for (var i = 0; i < concurrency && i < urls.length; i++) {
    launch();
  }

  try {
    return await completer.future.timeout(budget, onTimeout: () => null);
  } catch (_) {
    return null;
  }
}

/// 探活：只认本项目后端，避免扫到网关/别的 8000 端口服务。
Future<bool> _ping(String base) async {
  try {
    final res = await http
        .get(Uri.parse('$base/health'))
        .timeout(_kProbeTimeout);
    if (res.statusCode != 200) return false;
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) return false;
    final data = body['data'];
    return data is Map && data['service'] == 'fengshui-api';
  } catch (_) {
    return false;
  }
}

/// 本机所在私有网段的候选地址（排除自己）。
Future<List<String>> _lanCandidates() async {
  if (kIsWeb) return const <String>[];
  final urls = <String>[];
  try {
    final interfaces =
        await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        final parts = addr.address.split('.');
        if (parts.length != 4) continue;
        final nums = parts.map(int.tryParse).toList();
        if (nums.any((n) => n == null)) continue;
        final a = nums[0]!;
        final b = nums[1]!;
        if (!_isPrivateIPv4(a, b)) continue;
        final prefix = '$a.$b.${nums[2]}.';
        final self = nums[3]!;
        for (var i = 1; i <= _kScanLastOctetMax; i++) {
          if (i == self) continue;
          urls.add('http://$prefix$i:$kApiPort');
        }
      }
    }
  } catch (e) {
    debugPrint('[baseUrl] enumerate interfaces failed: $e');
  }
  return urls;
}

bool _isPrivateIPv4(int a, int b) {
  if (a == 10) return true; // 10.0.0.0/8
  if (a == 192 && b == 168) return true; // 192.168.0.0/16
  if (a == 172 && b >= 16 && b <= 31) return true; // 172.16.0.0/12
  return false;
}

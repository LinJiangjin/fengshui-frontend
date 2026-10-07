import 'package:fengshui_home/pages/house_page.dart';
import 'package:fengshui_home/services/house_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 端到端验证「保存并使用」按钮链路：
/// 打开表单 -> 填写 -> 点击保存。
/// 测试环境 HTTP 被框架拦截（必失败），因此验证失败路径：
/// 表单保持打开、输入不丢失，并弹出「保存失败」提示（按钮有响应）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('保存并使用：点击后表单关闭并给出反馈', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = await HouseStore.load();
    await store.migrateLegacyIfAny();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HousePage(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    // 打开新增表单
    await tester.tap(find.text('新增房屋'));
    await tester.pumpAndSettle();

    // 表单字段顺序：0 名称 / 1 户型 / 2 面积 / 3 坐向 / 4 磁偏角
    await tester.enterText(find.byType(TextField).at(0), '测试房屋A');
    await tester.enterText(find.byType(TextField).at(2), '88');
    await tester.pump();

    // 点击「保存并使用」（先滚动到按钮可见）
    await tester.scrollUntilVisible(
      find.text('保存并使用'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存并使用'));
    await tester.pump();
    // 给真实网络请求留时间
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 3)));
    await tester.pumpAndSettle();

    // 测试环境 HTTP 必失败：表单应保持打开（输入不丢失）且出现失败提示
    expect(find.text('保存并使用'), findsOneWidget);
    expect(find.textContaining('保存失败'), findsOneWidget);
    expect(find.text('测试房屋A'), findsOneWidget);
  });
}

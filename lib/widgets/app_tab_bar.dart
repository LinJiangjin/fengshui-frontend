import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';

/// 底部胶囊 Tab 栏（设计稿 88 高，位于 y=756）
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.current,
    required this.onTap,
  });

  final int current;
  final ValueChanged<int> onTap;

  static const _items = [
    (AppIconKind.home, '首页'),
    (AppIconKind.compass, '罗盘'),
    (AppIconKind.plan, '方案'),
    (AppIconKind.user, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.tabBarH,
      width: AppDimens.screenW,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(21, 6, 21, 20),
        child: Container(
          height: 62,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: AppColors.cardBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A1F1914),
                offset: Offset(0, 8),
                blurRadius: 24,
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Color(0x0F1F1914),
                offset: Offset(0, 2),
                blurRadius: 6,
                spreadRadius: -1,
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = i == current;
              final item = _items[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          item.$1,
                          size: 24,
                          color: active ? Colors.white : AppColors.muted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$2,
                          style: AppText.medium11.copyWith(
                            color: active ? Colors.white : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

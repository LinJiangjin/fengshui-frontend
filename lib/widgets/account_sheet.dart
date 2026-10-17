import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';

/// 账户入口（页头头像按钮）：点开账户面板，提供测算记录 / 退出登录 / 注销账号。
///
/// 首页正常态放在页头右上角；首页空态（无房屋 / 无坐向 / 网络出错）
/// 也必须放一个，否则用户没有地方可以退出登录或注销账号。
class AccountAvatarButton extends StatelessWidget {
  const AccountAvatarButton({
    super.key,
    this.user,
    required this.onLogout,
    this.onDeleteAccount,
    this.onOpenRecords,
  });

  /// 当前登录用户；为 null 时面板只显示退出按钮
  final AppUser? user;

  /// 退出登录：AuthStore.logout 后 AuthGate 自动切回登录页
  final VoidCallback onLogout;

  /// 注销账号：返回 null 表示成功，非 null 是可展示给用户的错误文案。
  final Future<String?> Function()? onDeleteAccount;

  /// 打开测算记录列表（保存过的测算，按参数回放重算）
  final VoidCallback? onOpenRecords;

  @override
  Widget build(BuildContext context) {
    final loggedIn = user != null;
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: loggedIn ? AppColors.primarySoft : AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: loggedIn
                ? AppColors.primarySoftBorder
                : AppColors.cardBorder,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: AppIcon(AppIconKind.user,
            size: 24,
            color: loggedIn ? AppColors.primary : AppColors.muted),
      ),
    );
  }

  /// 账户面板：退出登录 / 注销账号
  ///
  /// 返回值为动作标识：logout / delete / cancel（点蒙层或返回键为 null）。
  Future<void> _openSheet(BuildContext context) async {
    final u = user;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.track,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primarySoftBorder),
                    ),
                    alignment: Alignment.center,
                    child: const AppIcon(AppIconKind.user,
                        size: 26, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u == null || u.nickname.isEmpty
                              ? '未设置昵称'
                              : u.nickname,
                          style: AppText.cardTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          u?.phone ?? '未登录',
                          style: AppText.label12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 测算记录入口：常驻动作里唯一的「看自己的数据」，放最前面
              if (onOpenRecords != null) ...[
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(sheetContext).pop('records'),
                    icon: const AppIcon(AppIconKind.bookmark,
                        size: 17, color: AppColors.primary),
                    label: Text('测算记录',
                        style: AppText.medium15
                            .copyWith(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primarySoftBorder),
                      backgroundColor: AppColors.primarySoftBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop('logout'),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text('退出登录',
                      style:
                          AppText.medium15.copyWith(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.dangerBorder),
                    backgroundColor: AppColors.dangerSoftBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop('cancel'),
                  child: Text('取消',
                      style: AppText.medium15.copyWith(color: AppColors.body)),
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 6),
              // 注销入口：合规要求必须能被找到，但视觉上弱化，避免误点
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop('delete'),
                child: Text('注销账号',
                    style: AppText.medium13.copyWith(color: AppColors.muted)),
              ),
            ],
          ),
        ),
      ),
    );

    // 面板关闭后 context 才可用：跨过 await 必须重新确认宿主还在
    if (!context.mounted) return;
    if (action == 'records') {
      onOpenRecords?.call();
    } else if (action == 'logout') {
      onLogout();
    } else if (action == 'delete') {
      await _confirmDeleteAccount(context);
    }
  }

  /// 注销账号：不可恢复，先把后果逐条讲清楚再执行。
  ///
  /// 刻意做成两段式确认（面板 -> 对话框），并在对话框里逐条列出将被删除的数据、
  /// 说明手机会被释放，避免用户在不知情的情况下销毁自己的档案。
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final handler = onDeleteAccount;
    if (handler == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.rXL),
        ),
        title: const Text('注销账号', style: AppText.pageTitle),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('注销后下列数据将被永久删除，无法恢复：', style: AppText.body13),
            SizedBox(height: 10),
            Text(
              '· 账号与登录信息\n· 全部房屋档案与坐向数据\n· 命理档案（出生信息）\n· 测算记录',
              style: AppText.body13,
            ),
            SizedBox(height: 12),
            Text('该手机号会被释放，你可以重新注册，但历史数据不会保留。',
                style: AppText.body12),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('再想想',
                style: AppText.medium15.copyWith(color: AppColors.body)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('确认注销',
                style: AppText.medium15.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await handler();
    // 成功时 AuthGate 已切回登录页，本页 context 多半已失效：先判存活再提示
    if (!context.mounted) return;
    if (error == null) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(error), backgroundColor: AppColors.danger),
    );
  }
}

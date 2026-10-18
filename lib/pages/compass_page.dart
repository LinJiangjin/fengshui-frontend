import 'dart:async';

import 'package:flutter/material.dart';

import '../models/diagnosis.dart';
import '../models/house.dart';
import '../models/orientation_calc.dart';
import '../services/compass_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/compass_dial.dart';

/// S2 · 罗盘定向
class CompassPage extends StatefulWidget {
  const CompassPage({
    super.key,
    required this.service,
    required this.onConfirm,
    this.initialDegree = 0.0,
    this.declination = kDefaultDeclination,
  });

  final CompassService service;
  final Future<Diagnosis> Function(double degree, double declination) onConfirm;

  /// 当前房屋的坐向读数（磁北），切换房屋后作为罗盘初始值
  final double initialDegree;

  /// 当前房屋的磁偏角（真北 = 磁北 + 偏角）
  final double declination;

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> {
  StreamSubscription<double>? _sub;
  Timer? _silentTimer;
  late double _heading;
  bool _loading = false;
  bool _manual = false; // 用户手动输入后不再被传感器流覆盖
  bool _unavailable = false; // 传感器无读数：不编造角度，引导手动输入

  @override
  void initState() {
    super.initState();
    _heading = Angle.normalize(widget.initialDegree);
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant CompassPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换房屋后，用新房屋的坐向 / 磁偏角重置罗盘
    if (oldWidget.initialDegree != widget.initialDegree ||
        oldWidget.declination != widget.declination) {
      _manual = false;
      _unavailable = false;
      _heading = Angle.normalize(widget.initialDegree);
      _subscribe();
    }
  }

  /// 订阅传感器；若 2 秒内没有任何读数（无磁力计 / 未授权），
  /// 标记为不可用并引导手动输入，不再自动生成扫描中的假读数。
  void _subscribe() {
    _sub?.cancel();
    _silentTimer?.cancel();
    _manual = false;
    _unavailable = false;
    var received = false;
    _sub = widget.service.heading.listen((v) {
      received = true;
      if (!mounted) return;
      setState(() => _heading = v);
    });
    _silentTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || received || _manual) return;
      _markUnavailable();
    });
  }

  void _markUnavailable() {
    _sub?.cancel();
    if (mounted) setState(() => _unavailable = true);
  }

  @override
  void dispose() {
    _silentTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  double get _trueNorth => Angle.normalize(_heading + widget.declination);

  /// 当前坐向（随罗盘实时换算）
  OrientationResult get _orientation => OrientationCalc.of(_trueNorth);

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await widget.onConfirm(_heading, widget.declination);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _manualInput() async {
    final controller = TextEditingController(text: _trueNorth.toStringAsFixed(0));
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('手动输入房屋坐向', style: AppText.cardTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '请输入 0 ~ 359 度',
            hintStyle: AppText.label12,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: AppText.medium13),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text)),
            child: const Text('确定',
                style: AppText.medium13),
          ),
        ],
      ),
    );
    if (value == null) return;
    // 手动值优先：断开传感器 / 演示流，避免被立刻覆盖
    _sub?.cancel();
    _silentTimer?.cancel();
    setState(() {
      _manual = true;
      _unavailable = false;
      _heading = Angle.normalize(value - widget.declination);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.pagePadH, 4, AppDimens.pagePadH, 172),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    const SizedBox(height: AppDimens.gapL),
                    _compassCard(),
                    const SizedBox(height: AppDimens.gapL),
                    _calibrationTip(),
                  ],
                ),
              ),
              // 底部操作区：不透明底 + 上缘渐变。
              // 之前只放了按钮本体，滚动内容会从按钮与下方文字之间的空隙穿过，
              // 两层文字叠在一起像"糊住"了。
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 22,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00E9EDE6), AppColors.bg],
                        ),
                      ),
                    ),
                    Container(
                      color: AppColors.bg,
                      padding: const EdgeInsets.fromLTRB(
                          AppDimens.pagePadH, 2, AppDimens.pagePadH, 18),
                      child: _actions(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('罗盘定向', style: AppText.pageTitle),
        GestureDetector(
          onTap: _subscribe,
          child: const AppIcon(AppIconKind.refresh, size: 20, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _compassCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: cardShadow,
      ),
      child: Column(
        children: [
          // 罗盘 + 金色光晕
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x1ABE9351), Color(0x00BE9351)],
                  ),
                ),
              ),
              CompassDial(heading: _trueNorth),
            ],
          ),
          const SizedBox(height: 12),
          // 读数
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text('真北朝向', style: AppText.label11),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_trueNorth.toStringAsFixed(0), style: AppText.degree),
              const SizedBox(width: 2),
              const Padding(
                padding: EdgeInsets.only(bottom: 7),
                child: Text('°', style: AppText.degreeUnit),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_orientation.summary, style: AppText.section),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          // 2 x 2 信息瓦片
          Column(
            children: [
              Row(
                children: [
                  _tile(
                    label: '二十四山',
                    value: '${_orientation.mountain}山',
                    sub: '${_orientation.trigram}宫 · ${_orientation.direction}',
                  ),
                  const SizedBox(width: 10),
                  _tile(
                    label: '宅卦',
                    value: _orientation.houseType,
                    sub: '向${_orientation.facingDirection}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _tile(
                    label: '本地磁偏角',
                    value: '${widget.declination.toStringAsFixed(1)}°',
                    sub: '已自动校正',
                  ),
                  const SizedBox(width: 10),
                  _tile(
                    label: '测量精度',
                    value: _accuracyValue(),
                    sub: _accuracySub(),
                    warning: _unavailable,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _accuracyValue() {
    if (_manual) return '手动输入';
    if (_unavailable) return '传感器不可用';
    if (widget.service.available) return '高';
    return '检测中';
  }

  String _accuracySub() {
    if (_manual) return '${_trueNorth.toStringAsFixed(0)}°';
    if (_unavailable) return '请手动输入坐向';
    if (widget.service.available) return '陀螺仪 + GPS';
    return '等待传感器读数';
  }

  Widget _tile({
    required String label,
    required String value,
    required String sub,
    bool warning = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: warning ? AppColors.dangerSoftBg : AppColors.iconBg,
          borderRadius: BorderRadius.circular(AppDimens.rS),
          border: Border.all(
            color: warning ? AppColors.dangerBorder : AppColors.iconBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.label11),
            const SizedBox(height: 5),
            Text(
              value,
              style: AppText.smallTitle.copyWith(
                color: warning ? AppColors.dangerDeep : AppColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(sub, style: AppText.label11),
          ],
        ),
      ),
    );
  }

  Widget _calibrationTip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tipBg,
        borderRadius: BorderRadius.circular(AppDimens.rM),
        border: Border.all(color: AppColors.tipBorder, width: 1),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIconKind.target, size: 18, color: AppColors.body),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '远离金属电器，持机水平旋转一周自动校准',
              style: AppText.body12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Column(
      children: [
        GestureDetector(
          onTap: _loading ? null : _confirm,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimens.rPill),
              boxShadow: primaryShadow,
            ),
            alignment: Alignment.center,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('确认坐向 · 生成诊断报告', style: AppText.button15),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _manualInput,
          child: const Text('手动输入房屋坐向', style: AppText.medium12),
        ),
      ],
    );
  }
}

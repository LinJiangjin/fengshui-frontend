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
                    AppDimens.pagePadH, 4, AppDimens.pagePadH, 140),
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
              Positioned(
                left: AppDimens.pagePadH,
                right: AppDimens.pagePadH,
                bottom: 18,
                child: _actions(),
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
          CompassDial(heading: _trueNorth),
          const SizedBox(height: 14),
          // 读数
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_trueNorth.toStringAsFixed(0), style: AppText.degree),
                  const SizedBox(width: 2),
                  const Text('°', style: AppText.degreeUnit),
                ],
              ),
              const SizedBox(height: 4),
              Text(_orientation.summary, style: AppText.medium13),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          _infoRow('二十四山', '${_orientation.mountain}山（${_orientation.trigram}宫）'),
          const SizedBox(height: 14),
          _infoRow('宅卦', '${_orientation.houseType} · 向${_orientation.facingDirection}'),
          const SizedBox(height: 14),
          _infoRow(
            '本地磁偏角',
            '${widget.declination.toStringAsFixed(1)}°（已自动校正）',
          ),
          const SizedBox(height: 14),
          _infoRow('测量精度', _accuracyText()),
        ],
      ),
    );
  }

  String _accuracyText() {
    if (_manual) return '手动输入（${_trueNorth.toStringAsFixed(0)}°）';
    if (_unavailable) return '未获取到传感器数据，请手动输入';
    return widget.service.available ? '高（陀螺仪 + GPS）' : '手动模式（无磁力计）';
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppText.label12),
        Text(value, style: AppText.medium13),
      ],
    );
  }

  Widget _calibrationTip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.iconBg,
        borderRadius: BorderRadius.circular(AppDimens.rM),
        border: Border.all(color: AppColors.iconBorder, width: 1),
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

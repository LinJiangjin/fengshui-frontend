import 'package:flutter/material.dart';

import '../models/divination.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/save_record_button.dart';

/// 问卦：六爻纳甲 / 梅花易数
///
/// **起卦在客户端完成**——铜钱摇哪一面、随手取什么数，本质是随机事件，
/// 不是服务端该掺和的东西。这里只把起卦的**结果**（六个爻值 / 两三个数）
/// 交给服务端做确定性的装卦与解读，因此同一份入参永远得到同一份卦例。
///
/// 页面不做任何吉凶推导，只把后端下发的内容排好版。
class DivinationPage extends StatefulWidget {
  const DivinationPage({super.key, this.initialParams});

  /// 从测算记录打开时的入参快照；非 null 时按它直接装卦
  /// （同样的爻值 / 数字 + 同样的起卦时刻 = 同一份卦例）
  final Map<String, dynamic>? initialParams;

  @override
  State<DivinationPage> createState() => _DivinationPageState();
}

enum _Mode { liuyao, meihua }

class _DivinationPageState extends State<DivinationPage> {
  final ApiClient _api = ApiClient();

  _Mode _mode = _Mode.liuyao;

  DivinationChart? _chart;
  bool _loading = false;
  String? _error;

  /// 所问之事（决定六爻取哪一亲为用神）
  String _topic = '决策';

  /// 六爻：六个爻值，自初爻到上爻。null 表示尚未起卦
  List<int>? _lines;

  /// 六爻：是否正在逐爻摇（摇卦动画期间为 true）
  bool _shaking = false;

  /// 梅花：数字起卦的两个 / 三个数
  final TextEditingController _n1 = TextEditingController();
  final TextEditingController _n2 = TextEditingController();
  final TextEditingController _n3 = TextEditingController();

  /// 当前这一卦的起卦时刻（记录回放时是记录里存的时刻，不是现在）
  String _when = '';

  /// 从测算记录回放时的入参快照；非 null 时保存按钮按它存。
  /// 用户当场另起一卦即清掉——回放的和新摇的不是同一卦。
  Map<String, dynamic>? _replayParams;

  @override
  void dispose() {
    _n1.dispose();
    _n2.dispose();
    _n3.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final ip = widget.initialParams;
    if (ip != null) {
      _replayParams = ip;
      _replay(ip);
    }
  }

  /// 按存的入参重装一卦：爻值 / 数字回填进输入区，起卦时刻也按记录里
  /// 那个算——服务端装卦是纯函数，同样的入参必得同一份卦例。
  void _replay(Map<String, dynamic> params) {
    final mode = params['mode']?.toString() ?? 'liuyao';
    _topic = params['topic']?.toString() ?? '决策';
    final when = params['when']?.toString() ?? '';

    if (mode == 'meihua') {
      _mode = _Mode.meihua;
      final numbers = (params['numbers'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[];
      if (numbers.isNotEmpty) _n1.text = '${numbers[0]}';
      if (numbers.length > 1) _n2.text = '${numbers[1]}';
      if (numbers.length > 2) _n3.text = '${numbers[2]}';
    } else {
      _mode = _Mode.liuyao;
      final lines =
          (params['lines'] as List?)?.map((e) => (e as num).toInt()).toList();
      if (lines != null && lines.length == 6) _lines = lines;
    }
    _ask(when: when.isEmpty ? null : when);
  }

  void _switchMode(_Mode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _chart = null;
      _error = null;
      _lines = null;
      // 换了模式就是另起一卦，回放快照作废
      _replayParams = null;
    });
  }

  // ------------------------------------------------------- 起卦
  /// 铜钱摇卦：三枚铜钱抛一次得 6/7/8/9，抛六次成卦。
  ///
  /// 采用现代通行的「背为阳」算法：背面 3 分、字面 2 分，三枚相加
  /// 得 9 老阳 / 8 少阴 / 7 少阳 / 6 老阴。这一约定只在客户端出现，
  /// 服务端只认 6/7/8/9 这四个结果值。
  void _shake() {
    // 当场摇的卦：回放快照作废，保存按钮之后存这份新入参
    _replayParams = null;
    setState(() => _shaking = true);
    final rand = DateTime.now().microsecondsSinceEpoch;
    final values = <int>[];
    for (var i = 0; i < 6; i++) {
      // 用「时间 + 序号」混出伪随机；同一毫秒内连摇也能拉开差异
      final seed = (rand ~/ (i + 3)) + i * 7919;
      var sum = 0;
      for (var c = 0; c < 3; c++) {
        final bit = (seed >> (c * 3 + i)) & 1;
        sum += bit == 1 ? 3 : 2;
      }
      values.add(sum);
    }
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      setState(() {
        _lines = values;
        _shaking = false;
      });
      _ask();
    });
  }

  void _manualLines() {
    // 手动指定也是另起一卦：回放快照作废
    _replayParams = null;
    final picked = List<int>.from(_lines ?? <int>[8, 8, 8, 8, 8, 8]);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ManualLineSheet(
        initial: picked,
        onDone: (values) {
          setState(() => _lines = values);
          _ask();
        },
      ),
    );
  }

  static String _nowString() =>
      '${DateTime.now().year.toString().padLeft(4, '0')}-'
      '${DateTime.now().month.toString().padLeft(2, '0')}-'
      '${DateTime.now().day.toString().padLeft(2, '0')} '
      '${DateTime.now().hour.toString().padLeft(2, '0')}:'
      '${DateTime.now().minute.toString().padLeft(2, '0')}';

  /// 用户当场起的一卦（区别于记录回放）：清掉回放快照再算
  Future<void> _askLive() async {
    _replayParams = null;
    await _ask();
  }

  /// [when] 非空时按给定时刻装卦（记录回放），为空按当前时刻
  Future<void> _ask({String? when}) async {
    _when = when ?? _nowString();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chart = await _api.fetchDivination(
        mode: _mode == _Mode.liuyao ? 'liuyao' : 'meihua',
        lines: _mode == _Mode.liuyao ? _lines : null,
        numbers: _mode == _Mode.meihua ? _numbersOrNull() : null,
        when: when,
        topic: _topic,
        question: '',
      );
      if (!mounted) return;
      setState(() {
        _chart = chart;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '起卦失败，请检查网络后重试';
        _loading = false;
      });
    }
  }

  List<int>? _numbersOrNull() {
    final raw = <String>[_n1.text, _n2.text, _n3.text]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final parsed = raw.map(int.tryParse).whereType<int>().toList();
    return parsed.length >= 2 ? parsed : null;
  }

  // ------------------------------------------------------- 测算记录
  /// 保存用的入参：回放时按记录原参存，否则取当前这一卦的爻值 / 数字。
  /// 装卦是纯函数，这份入参足以完整还原同一份卦例。
  Map<String, dynamic> _recordParams() {
    final replay = _replayParams;
    if (replay != null) return replay;

    if (_mode == _Mode.liuyao) {
      return <String, dynamic>{
        'mode': 'liuyao',
        'lines': _lines ?? const <int>[],
        'when': _when,
        'topic': _topic,
      };
    }
    return <String, dynamic>{
      'mode': 'meihua',
      'numbers': _numbersOrNull() ?? const <int>[],
      'when': _when,
      'topic': _topic,
    };
  }

  String get _recordTitle {
    final c = _chart;
    if (c == null) return '问卦';
    final gua = c.ben?.name ?? c.zhu?.name ?? '';
    return gua.isEmpty ? c.modeName : '${c.modeName} · $gua';
  }

  String get _recordSummary {
    final c = _chart;
    if (c == null) return '';
    return '${c.topic} · ${c.when}';
  }

  // ------------------------------------------------------- 页面
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.pagePadH, 4, AppDimens.pagePadH, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context),
                const SizedBox(height: AppDimens.gapL),
                _modeSwitch(),
                const SizedBox(height: AppDimens.gapL),
                _topicBar(),
                const SizedBox(height: AppDimens.gapL),
                if (_mode == _Mode.liuyao) _liuyaoInput() else _meihuaInput(),
                const SizedBox(height: AppDimens.gapL),
                ..._result(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.maybePop(context),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: AppIcon(AppIconKind.back, size: 22, color: AppColors.ink),
          ),
        ),
        const Text('问卦', style: AppText.pageTitle),
        // 右侧槽位：阅读类产品的书签位——存这一卦的入参；没卦可存
        _chart == null
            ? const SizedBox(width: 34, height: 34)
            : SaveRecordButton(
                kind: 'divination',
                title: _recordTitle,
                summary: _recordSummary,
                params: _recordParams(),
              ),
      ],
    );
  }

  Widget _modeSwitch() {
    Widget item(_Mode mode, String label) {
      final active = _mode == mode;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _switchMode(mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimens.rM - 4),
            ),
            child: Text(
              label,
              style: AppText.medium13.copyWith(
                color: active ? AppColors.primaryDeep : AppColors.body,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.btnSecondary,
        borderRadius: BorderRadius.circular(AppDimens.rM),
      ),
      child: Row(
        children: [
          item(_Mode.liuyao, '六爻纳甲'),
          item(_Mode.meihua, '梅花易数'),
        ],
      ),
    );
  }

  /// 所问之事：决定六爻取哪一亲为用神
  Widget _topicBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('问什么事', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapS),
          const Text(
            '六爻按所问之事取「用神」（该看哪一亲），选错则用神选错。',
            style: AppText.label11,
          ),
          const SizedBox(height: AppDimens.gapM),
          Wrap(
            spacing: AppDimens.gapS,
            runSpacing: AppDimens.gapS,
            children: DivinationTopic.all
                .map((t) => _topicChip(t))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _topicChip(DivinationTopic t) {
    final active = _topic == t.key;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _topic = t.key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.btnSecondary,
          borderRadius: BorderRadius.circular(AppDimens.rPill),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          t.label,
          style: AppText.medium12.copyWith(
            color: active ? AppColors.primaryDeep : AppColors.body,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------- 六爻输入
  Widget _liuyaoInput() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('起卦', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapS),
          const Text(
            '铜钱摇卦用「背为阳」：背面记 3 分、字面记 2 分，三枚相加得 '
            '9 老阳 / 8 少阴 / 7 少阳 / 6 老阴，摇六次自下而上成卦。'
            '老阴老阳是动爻，会变出变卦。',
            style: AppText.label11,
          ),
          const SizedBox(height: AppDimens.gapM),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: _shaking ? '摇卦中…' : '铜钱摇卦',
                  primary: true,
                  onTap: _shaking ? null : _shake,
                ),
              ),
              const SizedBox(width: AppDimens.gapM),
              Expanded(
                child: _actionButton(
                  label: '手动指定',
                  onTap: _manualLines,
                ),
              ),
            ],
          ),
          if (_lines != null) ...[
            const SizedBox(height: AppDimens.gapM),
            Row(
              children: [
                const Text('本次爻值', style: AppText.label11),
                const SizedBox(width: AppDimens.gapS),
                Expanded(
                  child: Text(
                    '${_lines!.join(' ')}（自初爻到上爻）',
                    textAlign: TextAlign.right,
                    style: AppText.number12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------- 梅花输入
  Widget _meihuaInput() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('起卦', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapS),
          const Text(
            '填两个或三个数：前两个除 8 取余定上卦、下卦，第三个数除 6 '
            '取余定动爻（不填则取前两数之和）。全部留空则按当前时辰起卦。',
            style: AppText.label11,
          ),
          const SizedBox(height: AppDimens.gapM),
          Row(
            children: [
              Expanded(child: _numField(_n1, '上卦数')),
              const SizedBox(width: AppDimens.gapS),
              Expanded(child: _numField(_n2, '下卦数')),
              const SizedBox(width: AppDimens.gapS),
              Expanded(child: _numField(_n3, '动爻数（可空）')),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          SizedBox(
            width: double.infinity,
            child: _actionButton(
              label: '起卦',
              primary: true,
              onTap: _askLive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: AppText.medium13,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.label11.copyWith(fontSize: 10),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.rS),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.rS),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : AppColors.btnSecondary,
          borderRadius: BorderRadius.circular(AppDimens.rM),
        ),
        child: Text(
          label,
          style: AppText.medium13.copyWith(
            color: primary ? Colors.white : AppColors.body,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------- 结果
  List<Widget> _result() {
    if (_loading) {
      return const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ];
    }
    final err = _error;
    if (err != null) {
      return [_errorCard(err)];
    }
    final c = _chart;
    if (c == null) {
      return [
        _hintCard(
          _mode == _Mode.liuyao
              ? '点「铜钱摇卦」起一卦；若已知爻值，用「手动指定」逐爻填写。'
              : '填两个数起卦，或全部留空按时辰起卦。',
        ),
      ];
    }
    return [
      _verdictCard(c),
      const SizedBox(height: AppDimens.gapL),
      if (c.isLiuyao) ..._liuyaoBody(c) else ..._meihuaBody(c),
      const SizedBox(height: AppDimens.gapL),
      _pointsCard(c.points),
      const SizedBox(height: AppDimens.gapL),
      _footNote(c),
    ];
  }

  Widget _verdictCard(DivinationChart c) {
    final fg = AppColors.palaceFg(c.level);
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: BoxDecoration(
        color: AppColors.palaceBg(c.level),
        borderRadius: BorderRadius.circular(AppDimens.rXL),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${c.modeName} · ${c.topic}',
                  style: AppText.cardTitle,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppDimens.rPill),
                ),
                child: Text(
                  c.stance.isEmpty ? c.verdict : c.stance,
                  style: AppText.medium11.copyWith(color: fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          Text(c.plain, style: AppText.body12),
          const SizedBox(height: 4),
          Text('起卦时间 ${c.when}', style: AppText.label11),
        ],
      ),
    );
  }

  List<Widget> _liuyaoBody(DivinationChart c) {
    return [
      _hexagramPairCard(c),
      const SizedBox(height: AppDimens.gapL),
      _linesCard(c),
      const SizedBox(height: AppDimens.gapL),
      _shiYongCard(c),
    ];
  }

  Widget _hexagramPairCard(DivinationChart c) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('本卦 · 变卦', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapM),
          Row(
            children: [
              Expanded(child: _hexagramBox('本卦', c.ben)),
              const SizedBox(width: AppDimens.gapM),
              Expanded(
                child: _hexagramBox(
                  '变卦',
                  c.bian,
                  empty: c.moving.isEmpty ? '无动爻' : null,
                ),
              ),
            ],
          ),
          if (c.day != null) ...[
            const SizedBox(height: AppDimens.gapM),
            Text(
              '${c.day!['day_gan_zhi']}日 · 月建${c.day!['month_zhi']}月'
              ' · 农历${c.day!['lunar']}',
              style: AppText.label11,
            ),
          ],
        ],
      ),
    );
  }

  Widget _hexagramBox(String tag, DivinationHexagram? g, {String? empty}) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapM),
      decoration: BoxDecoration(
        color: AppColors.iconBg,
        borderRadius: BorderRadius.circular(AppDimens.rS),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tag, style: AppText.label11),
          const SizedBox(height: 6),
          if (g == null)
            Text(empty ?? '—', style: AppText.body12)
          else ...[
            Text(g.symbol, style: AppText.medium13),
            const SizedBox(height: 4),
            Text(g.name, style: AppText.medium13.copyWith(color: AppColors.ink)),
            if (g.subtitle.isNotEmpty)
              Text(g.subtitle, style: AppText.label11),
          ],
        ],
      ),
    );
  }

  /// 六爻明细：自上爻到初爻（传统画法）
  Widget _linesCard(DivinationChart c) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('六爻装卦', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapS),
          const Text(
            '自初爻到上爻：纳甲干支、六亲（以卦宫五行为「我」）、'
            '六神（按日干起）、旺衰（相对月令），世为「我」、应为对方。',
            style: AppText.label11,
          ),
          const SizedBox(height: AppDimens.gapM),
          ...c.linesTopDown.map(_lineRow),
        ],
      ),
    );
  }

  Widget _lineRow(DivinationLine l) {
    final markText = l.mark;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.gapS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.gapM,
        vertical: AppDimens.gapS,
      ),
      decoration: BoxDecoration(
        color: l.isMoving ? AppColors.goldSoftBg : AppColors.iconBg,
        borderRadius: BorderRadius.circular(AppDimens.rS),
        border: Border.all(
          color: l.isMoving ? AppColors.goldDeep : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(l.position, style: AppText.label11),
          ),
          Text(l.symbol, style: AppText.medium12),
          const SizedBox(width: AppDimens.gapS),
          if (markText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                markText,
                style: AppText.medium11.copyWith(fontSize: 10),
              ),
            ),
          const Spacer(),
          Text(
            l.pillar,
            style: AppText.medium12.copyWith(color: l.elementColor),
          ),
          const SizedBox(width: AppDimens.gapS),
          Text(l.liuQin, style: AppText.label11),
          const SizedBox(width: AppDimens.gapS),
          Text(l.liuShen, style: AppText.label11),
          const SizedBox(width: AppDimens.gapS),
          Text(l.wangXiang, style: AppText.label11.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _shiYongCard(DivinationChart c) {
    final shi = c.shi;
    final yong = c.yong;
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('世爻 · 用神', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapS),
          const Text(
            '世爻是你自己，应爻是对方或所问之事；用神是这件事该看的那一亲。',
            style: AppText.label11,
          ),
          const SizedBox(height: AppDimens.gapM),
          if (shi != null)
            _kvRow('世爻', '${shi['position']} · ${shi['pillar']}'
                ' · ${shi['liu_qin']} · ${shi['liu_shen']}'
                ' · ${shi['wang_xiang']}'),
          if (c.ying != null)
            _kvRow('应爻', '${c.ying!['position']} · ${c.ying!['pillar']}'
                ' · ${c.ying!['liu_qin']} · ${c.ying!['liu_shen']}'),
          if (yong != null) ...[
            _kvRow('用神', '${yong['name']}（${yong['note']}）'),
            _kvRow(
              '用神落点',
              (yong['positions'] as List? ?? []).isEmpty
                  ? '不上卦'
                  : (yong['positions'] as List).join('、'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kvRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(key, style: AppText.label11),
          ),
          Expanded(child: Text(value, style: AppText.body12)),
        ],
      ),
    );
  }

  List<Widget> _meihuaBody(DivinationChart c) {
    return [
      _threeGuaCard(c),
      const SizedBox(height: AppDimens.gapL),
      _tiYongCard(c),
    ];
  }

  Widget _threeGuaCard(DivinationChart c) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('主卦 · 互卦 · 变卦', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapS),
          const Text(
            '主卦看当下，互卦看过程，变卦看结果；动爻在第几爻由起卦数决定。',
            style: AppText.label11,
          ),
          const SizedBox(height: AppDimens.gapM),
          Row(
            children: [
              Expanded(child: _hexagramBox('主卦', c.zhu)),
              const SizedBox(width: AppDimens.gapS),
              Expanded(child: _hexagramBox('互卦', c.hu)),
              const SizedBox(width: AppDimens.gapS),
              Expanded(child: _hexagramBox('变卦', c.bian)),
            ],
          ),
          const SizedBox(height: AppDimens.gapM),
          Text(
            '${c.source}（动爻第 ${c.movingIndex} 爻）',
            style: AppText.label11,
          ),
          const SizedBox(height: 4),
          Text(c.basis, style: AppText.body12.copyWith(color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _tiYongCard(DivinationChart c) {
    final ti = c.ti;
    final yong = c.yongGua;
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('体用', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapS),
          const Text(
            '动爻所在的那一个经卦是「用」（所问之事），另一个是「体」（你自己）；'
            '看两者五行生克定吉凶。',
            style: AppText.label11,
          ),
          const SizedBox(height: AppDimens.gapM),
          if (ti != null)
            _kvRow('体（我）',
                '${ti['trigram']}${ti['symbol']} · ${ti['element']} · ${ti['wang_xiang']}'),
          if (yong != null)
            _kvRow('用（事）', '${yong['trigram']}${yong['symbol']} · ${yong['element']}'),
          if (c.relation.isNotEmpty)
            _kvRow('关系', '${c.relation} —— ${c.verdict}'),
        ],
      ),
    );
  }

  Widget _pointsCard(List<String> points) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('怎么看这一卦', style: AppText.cardTitle),
          const SizedBox(height: AppDimens.gapM),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.gapS),
              child: Text(p, style: AppText.body12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintCard(String text) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: AppIcon(AppIconKind.spark, size: 15, color: AppColors.body),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.body12)),
        ],
      ),
    );
  }

  Widget _errorCard(String err) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AppIcon(AppIconKind.warn, size: 16, color: AppColors.danger),
              SizedBox(width: 8),
              Text('起卦失败', style: AppText.cardTitle),
            ],
          ),
          const SizedBox(height: AppDimens.gapS),
          Text(err, style: AppText.body12),
        ],
      ),
    );
  }

  Widget _footNote(DivinationChart c) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gapXL),
      decoration: appCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AppIcon(AppIconKind.spark, size: 15, color: AppColors.body),
              SizedBox(width: 8),
              Text('三条务必知道的口径', style: AppText.smallTitle),
            ],
          ),
          const SizedBox(height: AppDimens.gapS),
          const Text(
            '1. 起卦（摇铜钱、取数）在手机上完成，服务端只做装卦与解读，'
            '不含随机数——同一份入参永远得到同一份卦例。',
            style: AppText.label11,
          ),
          const SizedBox(height: 4),
          const Text(
            '2. 六爻的旺衰看月令（月建地支的五行），同一爻在不同月份的'
            '强弱会变，这是它区别于静态查表的地方。',
            style: AppText.label11,
          ),
          const SizedBox(height: 4),
          const Text(
            '3. 卦给的是倾向不是定论：不断具体事件，也不替代专业判断。'
            '疾病、投资、法律一类的事，请以其专业意见为准。',
            style: AppText.label11,
          ),
          const SizedBox(height: 8),
          Text('规则版本 ${c.rulesVersion}', style: AppText.label11),
        ],
      ),
    );
  }
}

/// 手动指定六爻：逐爻选 6 / 7 / 8 / 9
class _ManualLineSheet extends StatefulWidget {
  const _ManualLineSheet({required this.initial, required this.onDone});

  final List<int> initial;
  final ValueChanged<List<int>> onDone;

  @override
  State<_ManualLineSheet> createState() => _ManualLineSheetState();
}

class _ManualLineSheetState extends State<_ManualLineSheet> {
  static const _positionNames = ['初', '二', '三', '四', '五', '上'];

  late List<int> _values;

  @override
  void initState() {
    super.initState();
    _values = List<int>.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('逐爻指定', style: AppText.cardTitle),
            const SizedBox(height: AppDimens.gapS),
            const Text(
              '自初爻到上爻：6 老阴（阴·动）、7 少阳（阳·静）、'
              '8 少阴（阴·静）、9 老阳（阳·动）。',
              style: AppText.label11,
            ),
            const SizedBox(height: AppDimens.gapM),
            ...List.generate(6, (i) => _linePicker(i)),
            const SizedBox(height: AppDimens.gapL),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.pop(context);
                  widget.onDone(_values);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimens.rM),
                  ),
                  child: Text('确定',
                      style: AppText.medium13.copyWith(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linePicker(int i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapS),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text('${_positionNames[i]}爻', style: AppText.label11),
          ),
          Expanded(
            child: Row(
              children: [6, 7, 8, 9].map((v) {
                final active = _values[i] == v;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _values[i] = v),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primarySoft
                              : AppColors.btnSecondary,
                          borderRadius: BorderRadius.circular(AppDimens.rS),
                          border: Border.all(
                            color: active
                                ? AppColors.primary
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          '$v ${_yaoName(v)}',
                          style: AppText.label11.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _yaoName(int v) {
    switch (v) {
      case 6:
        return '老阴';
      case 7:
        return '少阳';
      case 8:
        return '少阴';
      default:
        return '老阳';
    }
  }
}

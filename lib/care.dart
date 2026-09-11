import 'period_picker.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'main.dart' show PrescriptionHome;
import 'medicine.dart';
import 'care_store.dart';
export 'care_store.dart';

const _navy = Color(0xFF142F56);
const _muted = Color(0xFF738093);
const _group = Color(0xFFE1F1F8);

const _dots = [
  Color(0xFFB9FB83),
  Color(0xFF00C580),
  Color(0xFF0B4948),
  Color(0xFF83D5F1),
  Color(0xFF494DDF),
  Color(0xFF262360),
  Color(0xFF53B9B1),
  Color(0xFFA7B6F6),
];
Widget _button(String text, VoidCallback? action) => SizedBox(
  width: double.infinity,
  child: FilledButton(
    onPressed: action,
    style: FilledButton.styleFrom(
      backgroundColor: _navy,
      padding: const EdgeInsets.all(17),
      shape: const StadiumBorder(),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
);
Widget _note(String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 12),
  child: Text(
    text,
    style: const TextStyle(color: _muted, fontSize: 12, height: 1.7),
  ),
);
Widget _frame(List<Widget> children) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
      children: children,
    ),
  ),
);
void _message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

class AppTabs extends StatefulWidget {
  const AppTabs({super.key});
  @override
  State<AppTabs> createState() => _AppTabsState();
}

class _AppTabsState extends State<AppTabs> with WidgetsBindingObserver {
  final store = CareStore();
  int tab = 0;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store.load();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      store.refresh();
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      store.refresh();
      setState(() {});
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      body: !store.ready
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
              children: [
                if (store.error != null)
                  SafeArea(
                    bottom: false,
                    child: MaterialBanner(
                      content: Text(store.error!),
                      actions: [
                        TextButton(
                          onPressed: () => store.persist(),
                          child: const Text('重试保存'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: AbsorbPointer(
                    absorbing: store.loadFailed,
                    child: IndexedStack(
                      index: tab,
                      children: [
                        PrescriptionHome(store: store),
                        TodayPage(store: store, active: tab == 1),
                        RecordPage(store: store),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: CupertinoTabBar(
        height: 62,
        iconSize: 22,
        currentIndex: tab,
        activeColor: _navy,
        backgroundColor: const Color(0xFFF0F9FD),
        onTap: (value) => setState(() => tab = value),
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 7, bottom: 3),
              child: Icon(CupertinoIcons.doc_text),
            ),
            label: '处方',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 7, bottom: 3),
              child: Icon(CupertinoIcons.square_grid_2x2),
            ),
            label: '今日用药',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 7, bottom: 3),
              child: Icon(CupertinoIcons.calendar),
            ),
            label: '用药记录',
          ),
        ],
      ),
    ),
  );
}

class _Draft {
  final Medicine medicine;
  int slot;
  List<int> times;
  bool enabled;
  _Draft(this.medicine, this.slot)
    : times = suggestedTimes(medicine.frequency),
      enabled = slot < 8;
}

class SchedulePage extends StatefulWidget {
  final CareStore store;
  final List<Medicine> medicines;
  const SchedulePage({super.key, required this.store, required this.medicines});
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late List<_Draft> rows;
  DateTime from = DateTime.now();
  DateTime? until;
  bool checked = false, saving = false;
  @override
  void initState() {
    super.initState();
    rows = List.generate(
      widget.medicines.length,
      (i) => _Draft(widget.medicines[i], i),
    );
  }

  Future<void> time(_Draft row, [int? old]) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (old ?? 480) ~/ 60,
        minute: (old ?? 480) % 60,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (old != null) row.times.remove(old);
        row.times.add(result.hour * 60 + result.minute);
        row.times = row.times.toSet().toList()..sort();
        checked = false;
      });
    }
  }

  Future<void> date(bool isStart) async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: isStart ? from : until ?? from,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (result != null && mounted) {
      setState(() {
        if (isStart) {
          from = result;
          if (until != null && until!.isBefore(from)) until = from;
        } else {
          until = result;
        }
        checked = false;
      });
    }
  }

  Future<void> save() async {
    final active = rows.where((r) => r.enabled).toList();
    if (active.isEmpty) {
      _message(context, '请至少选择一种药品');
      return;
    }
    if (active.map((r) => r.slot).toSet().length != active.length ||
        active.any((r) => r.slot > 7)) {
      _message(context, '每种药请分配一个不同的药格，最多 8 种');
      return;
    }
    if (active.any((r) => r.times.isEmpty)) {
      _message(context, '请为每种药设置时间');
      return;
    }
    if (active.any(
      (r) => [
        r.medicine.name,
        r.medicine.dose,
        r.medicine.method,
        r.medicine.frequency,
      ].any((s) => s.trim().isEmpty || s.contains('待确认')),
    )) {
      _message(context, '有用药信息待确认，请先返回处方核对并编辑');
      return;
    }
    if (until != null && dayKey(until!).compareTo(dayKey(from)) < 0) {
      _message(context, '结束日期不能早于开始日期');
      return;
    }
    if (widget.store.plan.isNotEmpty) {
      final replace = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('更新每日安排？'),
          content: const Text('新的安排会替换当前安排。之前的用药记录保留，之后按新的药格和时间显示。'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('更新'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    setState(() => saving = true);
    final ok = await widget.store.setPlan(
      active
          .map(
            (r) => {
              ...medicineJson(r.medicine),
              'slot': r.slot,
              'times': r.times,
            },
          )
          .toList(),
      from,
      until,
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      Navigator.pop(context);
      _message(context, '每日安排已保存，前往“今日用药”查看');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('每日提醒', style: TextStyle(fontSize: 18))),
    body: _frame([
      const Text(
        '药格与时间',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: _navy,
        ),
      ),
      _note('一日三次先填入早、中、晚时间，请按处方确认。间隔用药、按需用药等不自动排程。药格颜色是暂定配色，请与实体药箱核对。'),
      for (final row in rows)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _group,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.medicine.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    value: row.enabled,
                    activeTrackColor: _navy,
                    onChanged: (v) => setState(() {
                      row.enabled = v;
                      checked = false;
                    }),
                  ),
                ],
              ),
              _note(
                '${row.medicine.dose} · ${row.medicine.frequency}\n${row.medicine.method}',
              ),
              if (row.enabled) ...[
                const Text(
                  "对应药格",
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: row.slot < 8 ? row.slot : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    fillColor: row.slot < 8 ? _dots[row.slot] : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  style: TextStyle(
                    color:
                        row.slot < 8 && _dots[row.slot].computeLuminance() < 0.3
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 17,
                  ),
                  dropdownColor: const Color(0xFFF0F9FD),
                  selectedItemBuilder: (context) =>
                      List.generate(8, (i) => Text('${i + 1} 号药格')),
                  items: List.generate(
                    8,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _dots[i],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${i + 1} 号药格',
                          style: TextStyle(
                            color: _dots[i].computeLuminance() < 0.3
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  onChanged: (v) => setState(() {
                    row.slot = v!;
                    checked = false;
                  }),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in row.times)
                      InputChip(
                        label: Text(clockText(t)),
                        onPressed: () => time(row, t),
                        onDeleted: () => setState(() {
                          row.times.remove(t);
                          checked = false;
                        }),
                      ),
                    ActionChip(
                      avatar: const Icon(CupertinoIcons.plus, size: 16),
                      label: const Text('添加时间'),
                      onPressed: () => time(row),
                    ),
                  ],
                ),
                if (row.times.isEmpty) _note('请手动确认服用时间'),
              ],
            ],
          ),
        ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _group,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            ListTile(
              title: const Text('开始日期'),
              subtitle: Text(dayKey(from)),
              trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
              onTap: () => date(true),
            ),
            ListTile(
              title: const Text('结束日期'),
              subtitle: Text(until == null ? '长期服用' : dayKey(until!)),
              trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
              onTap: () => date(false),
            ),
            if (until != null)
              TextButton(
                onPressed: () => setState(() {
                  until = null;
                  checked = false;
                }),
                child: const Text('改为长期服用'),
              ),
          ],
        ),
      ),
      _note('当前提供页面内用药安排；尚未开启锁屏、后台响铃通知。今天已经过去的时间不会补记成漏服。'),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: checked,
        onChanged: (v) => setState(() => checked = v!),
        title: const Text('已核对药格、服法、时间及疗程', style: TextStyle(fontSize: 14)),
      ),
      _button(saving ? '正在保存…' : '保存每日安排', checked && !saving ? save : null),
    ]),
  );
}

class TodayPage extends StatefulWidget {
  final CareStore store;
  final bool active;
  const TodayPage({super.key, required this.store, required this.active});
  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  final tts = FlutterTts();
  int? selected;
  String? currentDay;
  String? spoken;
  bool voiceReady = false;
  @override
  void initState() {
    super.initState();
    tts.setErrorHandler((_) {
      if (mounted) _message(context, '语音暂不可用，请查看卡片上的药名、药格和服法');
    });
    prepareVoice();
  }

  Future<void> prepareVoice() async {
    try {
      await tts.setLanguage('zh-CN');
      await tts.setSpeechRate(0.4);
      if (mounted) setState(() => voiceReady = true);
    } catch (_) {
      /* User can retry speech via a tap. */
    }
  }

  @override
  void didUpdateWidget(covariant TodayPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && oldWidget.active) tts.stop();
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  void speak(String text) {
    setState(() => spoken = text);
    if (!voiceReady) {
      prepareVoice();
      _message(context, '语音正在准备，请再点一次');
      return;
    }
    // Call directly during the tap so Safari retains the user gesture.
    tts.stop();
    tts
        .speak(text)
        .then((result) {
          if (result == 0 && mounted) _message(context, '语音未能播放，请检查音量和浏览器语音支持');
        })
        .catchError((_) {
          if (mounted) _message(context, '语音暂不可用，请查看文字');
        });
  }

  Future<void> mark(Map<String, dynamic> e) async {
    final ok = await widget.store.mark(e['id'], true);
    if (!mounted || !ok) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${e['name']} · 已确认服用'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => widget.store.mark(e['id'], false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = dayKey(DateTime.now());
    if (currentDay != today) {
      currentDay = today;
      selected = null;
    }
    final events = widget.store.events.where((e) => e['day'] == today).toList();
    final planApplies =
        widget.store.start != null &&
        widget.store.start!.compareTo(today) <= 0 &&
        (widget.store.end == null || widget.store.end!.compareTo(today) >= 0);
    final times = <int>{
      ...events.map((e) => e['minute'] as int),
      if (planApplies)
        ...widget.store.plan.expand(
          (row) => (row['times'] as List).cast<int>(),
        ),
    }.toList()..sort();
    if (!times.contains(selected)) {
      final now = DateTime.now();
      final minute = now.hour * 60 + now.minute;
      selected = times.isEmpty
          ? null
          : times.firstWhere((t) => t >= minute, orElse: () => times.last);
    }
    final current = events.where((e) => e['minute'] == selected).toList();
    final count = current.where((e) => e['taken'] != null).length;
    return SafeArea(
      child: _frame([
        Row(
          children: [
            const Expanded(
              child: Text(
                '今日用药',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(
              tooltip: '设置每日安排',
              onPressed: widget.store.prescription.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SchedulePage(
                          store: widget.store,
                          medicines: widget.store.prescription,
                        ),
                      ),
                    ),
              icon: const Icon(
                CupertinoIcons.slider_horizontal_3,
                color: _navy,
              ),
            ),
          ],
        ),
        _note(
          '${DateTime.now().month} 月 ${DateTime.now().day} 日 · 短按听说明，按住 1 秒确认服用',
        ),
        if (times.isNotEmpty)
          PeriodPicker(
            times: times,
            selected: selected!,
            onSelected: (time) {
              tts.stop();
              setState(() {
                selected = time;
                spoken = null;
              });
            },
          ),
        const SizedBox(height: 16),
        if (times.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _group,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Text(
              widget.store.plan.isEmpty
                  ? '请在“处方”中设置每日提醒'
                  : '今天没有待执行的安排\n新设置的提醒从下一个服用时间开始',
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              current.isEmpty
                  ? '此时段仅供查看，今天未生成服用任务'
                  : '本次 $count / ${current.length} 项已确认',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) => Column(
            children: List.generate(8, (slot) {
              final matches = current.where((e) => e['slot'] == slot).toList();
              final e = matches.isEmpty ? null : matches.first;
              final planned = widget.store.plan
                  .where((e) => e['slot'] == slot)
                  .toList();
              final name =
                  e?['name'] ??
                  (planned.isEmpty ? '未设置药品' : planned.first['name']);
              final preview =
                  e == null &&
                  planApplies &&
                  planned.isNotEmpty &&
                  (planned.first['times'] as List).contains(selected);
              final taken = e?['taken'] != null;
              final text = e == null
                  ? preview
                        ? '$name，${boxNames[slot]}${slot + 1}号药格。这个时间在今天的安排启用之前，仅供查看，无需补服。'
                        : '${boxNames[slot]}${slot + 1}号药格，本次不用服用。'
                  : '${e['name']}，${boxNames[slot]}${slot + 1}号药格，${e['dose']}，${e['method']}。${taken ? '本次已确认服用，请勿重复服用。' : ''}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DoseTile(
                  key: ValueKey('${e?['id'] ?? slot}/$selected'),
                  slot: slot,
                  name: name,
                  dose: e?['dose'],
                  inactiveLabel: preview ? '安排启用前 · 仅供查看' : null,
                  taken: taken,
                  scheduled: e != null,
                  onTap: () => speak(text),
                  onHold: e == null || taken ? null : () => mark(e),
                ),
              );
            }),
          ),
        ),
        if (spoken != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _group,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(CupertinoIcons.speaker_2, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(spoken!, style: const TextStyle(height: 1.7)),
                ),
                IconButton(
                  tooltip: '停止播报',
                  onPressed: () => tts.stop(),
                  icon: const Icon(CupertinoIcons.stop_circle),
                ),
              ],
            ),
          ),
        _note('已确认表示手动确认，不代表药箱检测结果。误操作可在“用药记录”撤销。当前未开启后台响铃。'),
      ]),
    );
  }
}

class DoseTile extends StatefulWidget {
  final int slot;
  final String name;
  final String? dose;
  final String? inactiveLabel;
  final bool taken, scheduled;
  final VoidCallback onTap;
  final VoidCallback? onHold;
  const DoseTile({
    super.key,
    required this.slot,
    required this.name,
    this.dose,
    this.inactiveLabel,
    required this.taken,
    required this.scheduled,
    required this.onTap,
    this.onHold,
  });
  @override
  State<DoseTile> createState() => _DoseTileState();
}

class _DoseTileState extends State<DoseTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController hold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  @override
  void initState() {
    super.initState();
    hold.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onHold?.call();
    });
  }

  @override
  void dispose() {
    hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.taken
        ? const Color(0xFF68717D)
        : _dots[widget.slot].computeLuminance() < 0.3
        ? Colors.white
        : Colors.black87;
    final color = widget.taken ? const Color(0xFFDFDDDA) : _dots[widget.slot];
    return Semantics(
      button: true,
      label:
          '${widget.slot + 1}号 ${boxNames[widget.slot]}药格，${widget.name}，${widget.taken
              ? '已确认服用'
              : widget.scheduled
              ? '待服用'
              : '本次不用服用'}',
      onTap: widget.onTap,
      onLongPress: widget.onHold,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPressStart: widget.onHold == null
            ? null
            : (_) => hold.forward(from: 0),
        onLongPressEnd: (_) => hold.reset(),
        onLongPressCancel: () => hold.reset(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 23),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(28),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 260 ||
                  MediaQuery.textScalerOf(context).scale(16) > 22;
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.slot + 1} 号药格',
                    style: TextStyle(
                      fontSize: 13,
                      color: foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    widget.taken
                        ? '✓ 已确认服用'
                        : widget.scheduled
                        ? widget.dose!
                        : widget.inactiveLabel ?? '本次不用服用',
                    style: TextStyle(
                      fontSize: 14,
                      color: foreground,
                      height: 1.6,
                    ),
                  ),
                ],
              );
              final pill = Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 14 : 18,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      widget.taken
                          ? CupertinoIcons.checkmark
                          : CupertinoIcons.speaker_2_fill,
                      color: Colors.black87,
                      size: 19,
                    ),
                    Text(
                      widget.taken ? '已服用' : '听说明',
                      style: TextStyle(
                        color: widget.taken ? _muted : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compact) ...[
                    content,
                    const SizedBox(height: 14),
                    pill,
                  ] else
                    Row(
                      children: [
                        Expanded(child: content),
                        const SizedBox(width: 18),
                        pill,
                      ],
                    ),
                  AnimatedBuilder(
                    animation: hold,
                    builder: (_, _) => hold.value == 0
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: LinearProgressIndicator(
                              value: hold.value,
                              color: Colors.white,
                              backgroundColor: Colors.white24,
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class RecordPage extends StatefulWidget {
  final CareStore store;
  const RecordPage({super.key, required this.store});
  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  DateTime date = DateTime.now();
  Future<void> undo(Map<String, dynamic> e) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('撤销服用确认？'),
        content: Text('${e['name']}将恢复为未确认状态。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('撤销确认'),
          ),
        ],
      ),
    );
    if (ok == true) await widget.store.mark(e['id'], false);
  }

  @override
  Widget build(BuildContext context) {
    final events =
        widget.store.events.where((e) => e['day'] == dayKey(date)).toList()
          ..sort((a, b) => (a['minute'] as int).compareTo(b['minute'] as int));
    final taken = events.where((e) => e['taken'] != null).length;
    final pending = events
        .where(
          (e) =>
              e['taken'] == null &&
              DateTime.parse(e['due']).isBefore(DateTime.now()),
        )
        .length;
    return SafeArea(
      child: _frame([
        const Text(
          '用药记录',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            IconButton(
              tooltip: '前一天',
              onPressed: () => setState(
                () => date = DateTime(date.year, date.month, date.day - 1),
              ),
              icon: const Icon(CupertinoIcons.chevron_left),
            ),
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && mounted) setState(() => date = picked);
                },
                child: Text(
                  dayKey(date),
                  style: const TextStyle(fontSize: 20, color: _navy),
                ),
              ),
            ),
            IconButton(
              tooltip: '后一天',
              onPressed: dayKey(date) == dayKey(DateTime.now())
                  ? null
                  : () => setState(
                      () =>
                          date = DateTime(date.year, date.month, date.day + 1),
                    ),
              icon: const Icon(CupertinoIcons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final item in [
                ('$taken', '已确认'),
                ('$pending', '未确认'),
                ('${events.length - taken - pending}', '待服用'),
              ])
                Column(
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      style: const TextStyle(
                        color: Color(0xFFCBD7E7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (events.isEmpty) _note('这一天没有用药安排记录'),
        for (final time in events.map((e) => e['minute'] as int).toSet()) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Text(
              clockText(time),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _group,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                for (final e in events.where((e) => e['minute'] == time))
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _dots[e['slot']],
                      foregroundColor: _dots[e['slot']].computeLuminance() < 0.3
                          ? Colors.white
                          : Colors.black87,
                      child: Text('${e['slot'] + 1}'),
                    ),
                    title: Text(
                      e['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${boxNames[e['slot']]}药格 · ${e['dose']}\n${e['taken'] == null
                          ? DateTime.parse(e['due']).isBefore(DateTime.now())
                                ? '未确认'
                                : '待服用'
                          : '已确认服用 · ${clockText(DateTime.parse(e['taken']).hour * 60 + DateTime.parse(e['taken']).minute)}'}',
                      style: const TextStyle(height: 1.6, fontSize: 12),
                    ),
                    trailing: e['taken'] == null
                        ? null
                        : TextButton(
                            onPressed: () => undo(e),
                            child: const Text('撤销'),
                          ),
                  ),
              ],
            ),
          ),
        ],
        _note('记录来自手动确认，不等同于实际服药监测。仅保存在当前设备和浏览器；清除网站数据或更换预览网址可能看不到原记录。'),
      ]),
    );
  }
}

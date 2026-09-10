import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MedicineApp());

const navy = Color(0xFF142F56);
const ink = Color(0xFF1C304B);
const muted = Color(0xFF8B929A);
const canvas = Color(0xFFFAF9F6);

class MedicineApp extends StatelessWidget {
  const MedicineApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '安心药箱',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy),
      fontFamily: 'PingFang SC',
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: navy,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: 'PingFang SC', color: ink),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink, fontSize: 15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: canvas,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    home: const PrescriptionHome(),
  );
}

class PrescriptionHome extends StatefulWidget {
  const PrescriptionHome({super.key});
  @override
  State<PrescriptionHome> createState() => _PrescriptionHomeState();
}

class _PrescriptionHomeState extends State<PrescriptionHome> {
  List<Medicine>? saved;
  Future<void> start() async {
    final result = await Navigator.of(context).push<List<Medicine>>(
      CupertinoPageRoute(builder: (_) => const CapturePage()),
    );
    if (result != null && mounted) setState(() => saved = result);
  }

  Future<void> openPrescriptions() async {
    if (saved == null) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: canvas,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.doc_text, size: 32, color: navy),
                const SizedBox(height: 20),
                const Text(
                  '暂无处方',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                const Text(
                  '添加后可在这里查看和修改。',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 26),
                primaryButton('添加第一张处方', () {
                  Navigator.pop(context);
                  start();
                }),
              ],
            ),
          ),
        ),
      );
      return;
    }
    final result = await Navigator.of(context).push<List<Medicine>>(
      CupertinoPageRoute(builder: (_) => ReviewPage(initial: saved)),
    );
    if (result != null && mounted) setState(() => saved = result);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 38, 20, 32),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  '处方',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: navy,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 25,
                ),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '添加处方',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '拍摄医院纸质处方',
                            style: TextStyle(
                              color: Color(0xFFBDC9DC),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      onPressed: start,
                      child: const Text(
                        '拍摄',
                        style: TextStyle(
                          color: navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: actionPill(CupertinoIcons.photo, '相册导入', start),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: actionPill(
                      CupertinoIcons.doc_text,
                      '我的处方',
                      openPrescriptions,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 0, 10),
                child: Text(
                  '我的处方',
                  style: TextStyle(
                    color: muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEBEDF0),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: saved == null
                    ? const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '暂无处方',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              '添加后可在这里查看和修改',
                              style: TextStyle(color: muted, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 23,
                        ),
                        onPressed: openPrescriptions,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '用药处方',
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    '${saved!.length} 种药品 · 已确认',
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_right,
                              color: muted,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '演示版 · 暂未接入识别，处方仅本次运行保存',
                  style: TextStyle(color: muted, fontSize: 11, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget actionPill(IconData icon, String label, VoidCallback onPressed) =>
      CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 17),
        color: const Color(0xFFEBEDF0),
        borderRadius: BorderRadius.circular(28),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: navy, size: 19),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class StepLabel extends StatelessWidget {
  final String number, title;
  const StepLabel({super.key, required this.number, required this.title});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        number,
        style: const TextStyle(color: muted, fontSize: 11, letterSpacing: 1),
      ),
      const SizedBox(height: 6),
      Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});
  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  bool preview = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        preview ? '确认处方照片' : '拍摄处方',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                preview ? '确认照片' : '将整张处方放入取景框',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '保持纸张平整、光线充足，避免遮挡药品和用法。',
                style: TextStyle(color: muted, fontSize: 13, height: 1.7),
              ),
              const SizedBox(height: 24),
              Container(
                height: 365,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCAD4E2)),
                ),
                child: const PrescriptionPaper(),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  '界面演示 · 当前为示例处方，未启用相机或相册',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ),
              const SizedBox(height: 28),
              primaryButton(
                preview ? '使用此照片，查看示例结果' : '模拟拍摄',
                () async {
                  if (!preview) {
                    setState(() => preview = true);
                    return;
                  }
                  final result = await Navigator.of(context)
                      .push<List<Medicine>>(
                        MaterialPageRoute(builder: (_) => const ReviewPage()),
                      );
                  if (result != null && context.mounted) {
                    Navigator.pop(context, result);
                  }
                },
                icon: preview
                    ? CupertinoIcons.doc_text_search
                    : CupertinoIcons.camera,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => preview = !preview),
                child: Text(preview ? '重新拍摄' : '模拟从相册选择'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class PrescriptionPaper extends StatelessWidget {
  const PrescriptionPaper({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    color: Colors.white,
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '处 方 笺',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 5,
            ),
          ),
        ),
        SizedBox(height: 7),
        Center(
          child: Text('仅用于界面演示', style: TextStyle(color: muted, fontSize: 10)),
        ),
        SizedBox(height: 19),
        Divider(),
        SizedBox(height: 9),
        Text(
          '姓名：示例家人       科别：门诊',
          style: TextStyle(fontSize: 11, color: muted),
        ),
        SizedBox(height: 20),
        Text(
          'Rp.',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 14),
        Text(
          '示例药品 A\n用量：待核对    频次：待核对\n\n示例药品 B\n用法：待核对',
          style: TextStyle(fontSize: 12, height: 1.8),
        ),
        Spacer(),
        Divider(),
        Text('示例内容，不作为用药依据', style: TextStyle(fontSize: 10, color: muted)),
      ],
    ),
  );
}

class Medicine {
  String name, dose, frequency, method;
  Medicine(this.name, this.dose, this.frequency, this.method);
  Medicine copy() => Medicine(name, dose, frequency, method);
}

class ReviewPage extends StatefulWidget {
  final List<Medicine>? initial;
  const ReviewPage({super.key, this.initial});
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late List<Medicine> medicines;
  bool confirmed = false;
  @override
  void initState() {
    super.initState();
    medicines =
        widget.initial?.map((m) => m.copy()).toList() ??
        [
          Medicine('示例药品 A', '每次 1 片（示例）', '每日 2 次（示例）', '口服 · 饭后（示例）'),
          Medicine('示例药品 B', '每次 1 袋（示例）', '每日 1 次（示例）', '冲服（示例）'),
        ];
  }

  Future<void> edit(int index) async {
    final m = medicines[index];
    final controllers = [
      m.name,
      m.dose,
      m.frequency,
      m.method,
    ].map((s) => TextEditingController(text: s)).toList();
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '编辑用药信息',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextField(
                      controller: controllers[i],
                      decoration: InputDecoration(
                        labelText: ['药品名称', '每次用量', '服用频次', '服用方式'][i],
                      ),
                    ),
                  ),
                primaryButton('保存修改', () {
                  if (controllers.every((c) => c.text.trim().isNotEmpty)) {
                    Navigator.pop(context, true);
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
    if (accepted == true && mounted) {
      setState(() {
        medicines[index] = Medicine(
          controllers[0].text.trim(),
          controllers[1].text.trim(),
          controllers[2].text.trim(),
          controllers[3].text.trim(),
        );
        confirmed = false;
      });
    }
    // Controllers remain alive until the bottom-sheet dismissal animation ends.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    for (final c in controllers) {
      c.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        '核对用药信息',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                '用药信息',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                '请对照原处方，确认药品、用量及服用方式。',
                style: TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEFEA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(CupertinoIcons.info_circle, size: 18, color: navy),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '以下为演示数据，尚未接入处方识别。\n实际用药请以医生处方为准。',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.7,
                          color: navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '用药清单 · ${medicines.length} 项',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => const Padding(
                        padding: EdgeInsets.all(30),
                        child: SizedBox(
                          height: 370,
                          child: PrescriptionPaper(),
                        ),
                      ),
                    ),
                    child: const Text('查看原处方', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              for (var i = 0; i < medicines.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: canvas,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              CupertinoIcons.capsule,
                              size: 22,
                              color: navy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              medicines[i].name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: '编辑用药信息',
                            onPressed: () => edit(i),
                            icon: const Icon(
                              CupertinoIcons.pencil,
                              size: 20,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: canvas),
                      detail('每次用量', medicines[i].dose),
                      detail('服用频次', medicines[i].frequency),
                      detail('服用方式', medicines[i].method),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: confirmed,
                onChanged: (value) => setState(() => confirmed = value!),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  '我已逐项核对以上用药信息',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              primaryButton(
                '确认并保存',
                confirmed ? () => Navigator.pop(context, medicines) : null,
                icon: CupertinoIcons.checkmark_alt,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  '演示版仅在本次会话保存',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 13)),
        const SizedBox(width: 24),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

Widget primaryButton(
  String text,
  VoidCallback? onPressed, {
  IconData? icon,
}) => SizedBox(
  width: double.infinity,
  child: FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: navy,
      padding: const EdgeInsets.symmetric(vertical: 17),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 9)],
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  ),
);

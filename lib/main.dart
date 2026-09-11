import 'press_button.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'medicine.dart';
import 'care.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MedicineApp());

const navy = Color(0xFF142F56);
const ink = Color(0xFF1C304B);
const muted = Color(0xFF8B929A);
const canvas = Color(0xFFF2EFEB);

TextTheme spacedTextTheme() {
  final base = ThemeData().textTheme.apply(
    fontFamily: 'AppNotoSansSC',
    bodyColor: ink,
    displayColor: ink,
  );
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(letterSpacing: 0.35),
    displayMedium: base.displayMedium?.copyWith(letterSpacing: 0.35),
    displaySmall: base.displaySmall?.copyWith(letterSpacing: 0.35),
    headlineLarge: base.headlineLarge?.copyWith(letterSpacing: 0.35),
    headlineMedium: base.headlineMedium?.copyWith(letterSpacing: 0.35),
    headlineSmall: base.headlineSmall?.copyWith(letterSpacing: 0.35),
    titleLarge: base.titleLarge?.copyWith(letterSpacing: 0.35),
    titleMedium: base.titleMedium?.copyWith(letterSpacing: 0.35),
    titleSmall: base.titleSmall?.copyWith(letterSpacing: 0.35),
    bodyLarge: base.bodyLarge?.copyWith(letterSpacing: 0.35),
    bodyMedium: base.bodyMedium?.copyWith(letterSpacing: 0.35, fontSize: 15),
    bodySmall: base.bodySmall?.copyWith(letterSpacing: 0.35),
    labelLarge: base.labelLarge?.copyWith(letterSpacing: 0.35),
    labelMedium: base.labelMedium?.copyWith(letterSpacing: 0.35),
    labelSmall: base.labelSmall?.copyWith(letterSpacing: 0.35),
  );
}

class MedicineApp extends StatelessWidget {
  const MedicineApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '安心药箱',
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy),
      fontFamily: 'AppNotoSansSC',
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: navy,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            fontFamily: 'AppNotoSansSC',
            color: ink,
            letterSpacing: 0.35,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: spacedTextTheme(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: canvas,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    home: const AppTabs(),
  );
}

class PrescriptionHome extends StatefulWidget {
  final CareStore store;
  const PrescriptionHome({super.key, required this.store});
  @override
  State<PrescriptionHome> createState() => _PrescriptionHomeState();
}

class _PrescriptionHomeState extends State<PrescriptionHome> {
  List<Medicine>? saved;
  @override
  void initState() {
    super.initState();
    if (widget.store.prescription.isNotEmpty) saved = widget.store.prescription;
  }

  Future<void> accept(List<Medicine> result) async {
    setState(() => saved = result);
    final stored = await widget.store.savePrescription(result);
    if (!stored) return;
    if (!mounted) return;
    final add = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("处方已保存"),
        content: const Text("要为这些药品设置每日提醒吗？"),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("稍后设置"),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("设置提醒"),
          ),
        ],
      ),
    );
    if (add == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SchedulePage(store: widget.store, medicines: result),
        ),
      );
    }
  }

  Future<void> start({ImageSource source = ImageSource.camera}) async {
    final result = await Navigator.of(context).push<List<Medicine>>(
      CupertinoPageRoute(builder: (_) => CapturePage(source: source)),
    );
    if (result != null && mounted) await accept(result);
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
    if (result != null && mounted) await accept(result);
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
                    PressButton(
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
                    child: actionPill(
                      CupertinoIcons.photo,
                      '相册导入',
                      () => start(source: ImageSource.gallery),
                    ),
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
                  color: const Color(0xFFEAE7E3),
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
                    : PressButton(
                        color: const Color(0xFFEAE7E3),
                        borderRadius: BorderRadius.circular(28),
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
              if (saved != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: primaryButton(
                    '设置每日提醒',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SchedulePage(
                          store: widget.store,
                          medicines: saved!,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '用药信息保存在本机，原照片仅本次运行可看',
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
      PressButton(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 17),
        color: const Color(0xFFEAE7E3),
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
  final ImageSource source;
  const CapturePage({super.key, this.source = ImageSource.camera});
  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  Uint8List? photo;
  bool busy = false;
  String? error;
  Future<void> pick(ImageSource source) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2600,
        maxHeight: 2600,
        imageQuality: 92,
        requestFullMetadata: false,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        throw Exception('照片超过 10 MB，请选择较小照片。');
      }
      final jpeg =
          bytes.length > 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      final png =
          bytes.length > 8 &&
          listEquals(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
      if (!jpeg && !png) throw Exception('请使用 JPEG 或 PNG 照片，HEIC 请先转换。');
      if (mounted) setState(() => photo = bytes);
    } catch (e) {
      if (mounted) {
        setState(
          () => error =
              '无法选择照片，请检查权限或改用相册。\n${e is Exception ? e.toString().replaceFirst('Exception: ', '') : ''}',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> recognize() async {
    setState(() {
      busy = true;
      error = null;
    });
    const configured = String.fromEnvironment('API_BASE_URL');
    final base = configured.isNotEmpty
        ? configured
        : kIsWeb
        ? '${Uri.base.scheme}://${Uri.base.host}:8787'
        : 'http://127.0.0.1:8787';
    try {
      final response = await http
          .post(
            Uri.parse('$base/recognize'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image': base64Encode(photo!)}),
          )
          .timeout(const Duration(seconds: 100));
      final result =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw Exception(result['error'] ?? '识别失败，请重试。');
      }
      final rows = result['medicines'] as List;
      if (rows.isEmpty) throw Exception('未识别到药品，请确认照片包含清晰的处方用药信息。');
      final warnings = (result['warnings'] as List).cast<String>().join('\n');
      final medicines = rows
          .map(
            (row) => Medicine(
              row['name'] ?? '待确认',
              row['dose'] ?? '待确认',
              row['frequency'] ?? '待确认',
              row['method'] ?? '待确认',
              specification: row['specification'] ?? '待确认',
              sourceText: row['source_text'] ?? '',
              photo: photo,
              warnings: warnings,
            ),
          )
          .toList();
      if (!mounted) return;
      final saved = await Navigator.of(context).push<List<Medicine>>(
        CupertinoPageRoute(builder: (_) => ReviewPage(initial: medicines)),
      );
      if (saved != null && mounted) Navigator.pop(context, saved);
    } on TimeoutException {
      if (mounted) setState(() => error = '识别超时，请稍后重试。');
    } on http.ClientException {
      if (mounted) setState(() => error = '无法连接识别服务，请确认电脑后端已启动，手机和电脑在同一网络。');
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is FormatException || e is TypeError
              ? '返回结果格式异常，请重试。'
              : e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        '添加处方',
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
              Container(
                height: 365,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE7E3),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: photo == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.doc_text_viewfinder,
                              size: 52,
                              color: muted,
                            ),
                            SizedBox(height: 18),
                            Text('拍摄或选择一张处方', style: TextStyle(color: muted)),
                          ],
                        ),
                      )
                    : InteractiveViewer(
                        child: Image.memory(photo!, fit: BoxFit.contain),
                      ),
              ),
              const SizedBox(height: 20),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Color(0xFFAA493E),
                      height: 1.6,
                    ),
                  ),
                ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CupertinoActivityIndicator()),
                ),
              primaryButton(
                photo == null
                    ? (widget.source == ImageSource.camera ? '拍摄处方' : '选择照片')
                    : '识别并整理',
                busy
                    ? null
                    : photo == null
                    ? () => pick(widget.source)
                    : recognize,
                icon: photo == null
                    ? CupertinoIcons.camera
                    : CupertinoIcons.doc_text_search,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: busy ? null : () => pick(ImageSource.camera),
                      child: Text(photo == null ? '使用相机' : '重新拍摄'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: busy ? null : () => pick(ImageSource.gallery),
                      child: const Text('从相册选择'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '点击识别后，照片将发送至硅基流动进行处理。建议遮住姓名等个人信息，保留完整药品和用法。识别结果需对照原处方确认。',
                style: TextStyle(color: muted, fontSize: 12, height: 1.8),
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
    medicines = widget.initial?.map((m) => m.copy()).toList() ?? [];
  }

  Future<void> edit(int index) async {
    final m = medicines[index];
    final controllers = [
      m.name,
      m.dose,
      m.frequency,
      m.method,
      m.specification,
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
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextField(
                      controller: controllers[i],
                      decoration: InputDecoration(
                        labelText: ['药品名称', '每次用量', '服用频次', '服用方式', '药品规格'][i],
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
          specification: controllers[4].text.trim(),
          sourceText: m.sourceText,
          photo: m.photo,
          warnings: m.warnings,
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
                        '识别结果可能有误，请逐项核对。\n“待确认”表示未识别清楚，不要据此安排用药。',
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
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          height: 450,
                          child:
                              medicines.isNotEmpty &&
                                  medicines.first.photo != null
                              ? InteractiveViewer(
                                  child: Image.memory(
                                    medicines.first.photo!,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : const Center(child: Text("原照片不可用")),
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
                      detail('药品规格', medicines[i].specification),
                      detail('每次用量', medicines[i].dose),
                      detail('服用频次', medicines[i].frequency),
                      detail('服用方式', medicines[i].method),
                      detail('对应原文', medicines[i].sourceText),
                    ],
                  ),
                ),
              if (medicines.isNotEmpty && medicines.first.warnings.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    medicines.first.warnings,
                    style: const TextStyle(
                      color: Color(0xFFAA493E),
                      fontSize: 13,
                    ),
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
                confirmed && medicines.isNotEmpty
                    ? () => Navigator.pop(context, medicines)
                    : null,
                icon: CupertinoIcons.checkmark_alt,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  '确认后保存用药信息到本机',
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

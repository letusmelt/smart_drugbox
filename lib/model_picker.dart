import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const recognitionModels = [
  'Qwen/Qwen3-VL-32B-Instruct',
  'Qwen/Qwen3-VL-8B-Instruct',
  'Qwen/Qwen3-VL-30B-A3B-Instruct',
];
final recognitionModel = ValueNotifier<String>(recognitionModels.last);
Future<void>? _loading;
Future<void> loadRecognitionModel() => _loading ??= _load();
Future<void> _load() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('recognition.model');
  if (recognitionModels.contains(saved)) recognitionModel.value = saved!;
}

class ModelPicker extends StatefulWidget {
  final bool enabled;
  const ModelPicker({super.key, this.enabled = true});
  @override
  State<ModelPicker> createState() => _ModelPickerState();
}

class _ModelPickerState extends State<ModelPicker> {
  @override
  void initState() {
    super.initState();
    loadRecognitionModel();
  }

  Future<void> choose() async {
    await loadRecognitionModel();
    if (!mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFF2EFEB),
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '识别模型',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '服务异常时可切换后重试，识别结果请核对。',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 20),
              for (final model in recognitionModels)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    tileColor: recognitionModel.value == model
                        ? const Color(0xFFDCE3F2)
                        : const Color(0xFFEAE7E3),
                    title: Text(
                      model.split('/').last,
                      style: const TextStyle(fontSize: 15),
                    ),
                    trailing: recognitionModel.value == model
                        ? const Icon(Icons.check, size: 20)
                        : null,
                    onTap: () => Navigator.pop(context, model),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    recognitionModel.value = selected;
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString('recognition.model', selected);
    if (!saved && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已切换，但未能保存选择，下次打开请重新选择。')));
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: recognitionModel,
    builder: (context, model, _) => TextButton(
      onPressed: widget.enabled ? choose : null,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFEAE7E3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '识别模型 · ${model.split('/').last}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const Icon(Icons.expand_more, size: 18),
        ],
      ),
    ),
  );
}

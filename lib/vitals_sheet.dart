import 'package:flutter/material.dart';
import 'care_store.dart';

Future<void> showVitalsSheet(
  BuildContext context,
  CareStore store,
  Map<String, dynamic> event,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: const Color(0xFFF0F9FD),
  builder: (_) => _VitalsSheet(store: store, event: event),
);

class _VitalsSheet extends StatefulWidget {
  final CareStore store;
  final Map<String, dynamic> event;
  const _VitalsSheet({required this.store, required this.event});
  @override
  State<_VitalsSheet> createState() => _VitalsSheetState();
}

class _VitalsSheetState extends State<_VitalsSheet> {
  static const labels = ['体温（℃）', '收缩压（mmHg）', '舒张压（mmHg）', '心率（次/分）', '备注'];
  static const keys = ['temperature', 'systolic', 'diastolic', 'pulse', 'note'];
  late final fields = List.generate(
    keys.length,
    (i) => TextEditingController(text: widget.event['vitals']?[keys[i]] ?? ''),
  );
  final form = GlobalKey<FormState>();
  bool saving = false;
  String? error;
  @override
  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '记录体征',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(widget.event['name'], style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            for (var i = 0; i < fields.length; i++) ...[
              Text(labels[i], style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: fields[i],
                enabled: !saving,
                maxLines: i == 4 ? 3 : 1,
                keyboardType: i == 4
                    ? TextInputType.multiline
                    : const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFE1F1F8),
                  hintText: '选填',
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
                validator: (v) =>
                    i < 4 &&
                        v!.trim().isNotEmpty &&
                        (double.tryParse(v.trim()) == null ||
                            !double.parse(v.trim()).isFinite ||
                            double.parse(v.trim()) <= 0)
                    ? '请输入有效数值'
                    : null,
              ),
              const SizedBox(height: 14),
            ],
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        setState(() => saving = true);
                        final ok = await widget.store
                            .saveVitals(widget.event['id'], {
                              for (var i = 0; i < keys.length; i++)
                                keys[i]: fields[i].text.trim(),
                            });
                        if (!context.mounted) return;
                        if (ok) {
                          Navigator.pop(context);
                        } else {
                          setState(() {
                            saving = false;
                            error = widget.store.error ?? '保存失败';
                          });
                        }
                      },
                child: Text(saving ? '保存中…' : '保存体征'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

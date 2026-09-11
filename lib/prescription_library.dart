import 'package:flutter/material.dart';
import 'care.dart';
import 'main.dart';
import 'medicine.dart';

class PrescriptionLibrary extends StatelessWidget {
  final CareStore store;
  const PrescriptionLibrary({super.key, required this.store});

  Future<void> open(BuildContext context, [Map<String, dynamic>? row]) async {
    final result = await Navigator.of(context).push<List<Medicine>>(
      MaterialPageRoute(
        builder: (_) => row == null
            ? const CapturePage()
            : ReviewPage(
                initial: (row['medicines'] as List)
                    .map((m) => readMedicine(Map<String, dynamic>.from(m)))
                    .toList(),
              ),
      ),
    );
    if (result == null || !context.mounted) return;
    DateTime? date;
    if (row == null) {
      date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        helpText: '选择处方日期',
        cancelText: '使用今天',
      );
      if (!context.mounted) return;
      date ??= DateTime.now();
    }
    final ok = await store.savePrescription(result, id: row?['id'], date: date);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '处方已保存' : store.error ?? '保存失败')),
      );
    }
  }

  Future<void> remove(BuildContext context, Map<String, dynamic> row) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这张处方？'),
        content: const Text('删除后无法恢复。已设置的每日提醒和用药记录会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    final ok = await store.deletePrescription(row['id']);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(store.error ?? '删除失败')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('我的处方'),
      actions: [
        IconButton(
          tooltip: '添加处方',
          onPressed: () => open(context),
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final rows = List<Map<String, dynamic>>.from(store.prescriptions)
          ..sort(
            (a, b) => (b['date'] as String? ?? '').compareTo(
              a['date'] as String? ?? '',
            ),
          );
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (rows.isEmpty) ...[
                  const SizedBox(height: 60),
                  const Center(
                    child: Text('暂无处方', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(height: 24),
                  primaryButton('添加第一张处方', () => open(context)),
                ],
                for (final row in rows)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F1F8),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                            20,
                            12,
                            8,
                            4,
                          ),
                          title: Text(
                            row['date'] == null
                                ? '已有处方 · 日期待补充'
                                : '${dayKey(DateTime.parse(row['date']))} 处方',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${(row['medicines'] as List).length} 种药品 · ${(row['medicines'] as List).map((m) => m['name']).join('、')}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          onTap: () => open(context, row),
                          trailing: IconButton(
                            tooltip: '删除处方',
                            onPressed: () => remove(context, row),
                            icon: const Icon(Icons.delete_outline, size: 21),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Wrap(
                            children: [
                              TextButton(
                                onPressed: () => open(context, row),
                                child: const Text('查看 / 编辑'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        DateTime.tryParse(row['date'] ?? '') ??
                                        DateTime.now(),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    helpText: '处方日期',
                                  );
                                  if (date == null) return;
                                  final ok = await store.savePrescription(
                                    (row['medicines'] as List)
                                        .map(
                                          (m) => readMedicine(
                                            Map<String, dynamic>.from(m),
                                          ),
                                        )
                                        .toList(),
                                    id: row['id'],
                                    date: date,
                                  );
                                  if (!ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(store.error ?? '保存失败'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('修改日期'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SchedulePage(
                                      store: store,
                                      medicines: (row['medicines'] as List)
                                          .map(
                                            (m) => readMedicine(
                                              Map<String, dynamic>.from(m),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                                child: const Text('设置提醒'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

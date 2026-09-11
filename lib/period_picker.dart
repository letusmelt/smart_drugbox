import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'care_store.dart';

String periodName(int minute) => minute < 11 * 60
    ? '早上'
    : minute < 15 * 60
    ? '中午'
    : minute < 21 * 60
    ? '晚上'
    : '睡前';
IconData periodIcon(int minute) => minute < 11 * 60
    ? CupertinoIcons.sunrise
    : minute < 15 * 60
    ? CupertinoIcons.sun_max
    : CupertinoIcons.moon;

class PeriodPicker extends StatelessWidget {
  final List<int> times;
  final int selected;
  final ValueChanged<int> onSelected;
  const PeriodPicker({
    super.key,
    required this.times,
    required this.selected,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    heightFactor: 1,
    widthFactor: 1,
    child: PopupMenuButton<int>(
      tooltip: '切换早中晚',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 10),
      color: const Color(0xFFF0F9FD),
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      constraints: BoxConstraints(
        minWidth: 240,
        maxWidth: MediaQuery.sizeOf(context).width < 340 ? 280 : 310,
      ),
      onSelected: onSelected,
      itemBuilder: (_) => times.map((time) {
        final active = selected == time;
        final foreground = active ? Colors.white : const Color(0xFF142F56);
        return PopupMenuItem<int>(
          value: time,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF142F56) : const Color(0xFFE1F1F8),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              children: [
                Icon(periodIcon(time), color: foreground, size: 25),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        periodName(time),
                        style: TextStyle(
                          color: foreground,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clockText(time),
                        style: TextStyle(color: foreground, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (active)
                  Icon(CupertinoIcons.checkmark, color: foreground, size: 19),
              ],
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E7F1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              periodName(selected),
              style: const TextStyle(
                color: Color(0xFF142F56),
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              CupertinoIcons.chevron_down,
              color: Color(0xFF142F56),
              size: 15,
            ),
          ],
        ),
      ),
    ),
  );
}

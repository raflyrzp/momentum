import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/day.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../domain/frequency.dart';
import '../../domain/pillar.dart';

/// Lembar tambah/ubah kebiasaan. [habit] null = kebiasaan baru.
Future<void> showHabitFormSheet(BuildContext context, {Habit? habit}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _HabitForm(habit: habit),
  );
}

class _HabitForm extends ConsumerStatefulWidget {
  const _HabitForm({this.habit});

  final Habit? habit;

  @override
  ConsumerState<_HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends ConsumerState<_HabitForm> {
  late final _name = TextEditingController(text: widget.habit?.name ?? '');
  late Pillar _pillar = widget.habit?.pillar ?? Pillar.vitality;
  late FrequencyType _type = widget.habit?.frequencyType ?? FrequencyType.daily;
  late int _mask = widget.habit?.weekdaysMask ?? 0x1F; // Sen–Jum
  late int _times = widget.habit?.timesPerWeek ?? 3;
  late int? _reminder = widget.habit?.reminderMinutes;
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Frequency get _frequency => switch (_type) {
    FrequencyType.daily => const Frequency.daily(),
    FrequencyType.weekdays => Frequency.weekdays(_mask),
    FrequencyType.timesPerWeek => Frequency.timesPerWeek(_times),
  };

  Future<void> _pickReminder() async {
    final initial = _reminder ?? 7 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
      helpText: 'Jam pengingat',
    );
    if (picked != null) {
      setState(() => _reminder = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Beri nama kebiasaan ini');
      return;
    }
    if (_type == FrequencyType.weekdays && _mask == 0) {
      setState(() => _error = 'Pilih minimal satu hari');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(habitActionsProvider)
          .save(
            id: widget.habit?.id,
            name: name,
            pillar: _pillar,
            frequency: _frequency,
            reminderMinutes: _reminder,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Gagal menyimpan. Coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.habit != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editing ? 'Ubah kebiasaan' : 'Kebiasaan baru',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: !editing,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Contoh: Membaca 20 halaman',
                counterText: '',
              ),
            ),
            const _Label('Pilar atribut'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in Pillar.values)
                  ChoiceChip(
                    selected: _pillar == p,
                    showCheckmark: false,
                    avatar: Icon(p.icon, size: 18, color: p.color),
                    label: Text(p.label),
                    selectedColor: p.color.withValues(alpha: 0.22),
                    onSelected: (_) => setState(() => _pillar = p),
                  ),
              ],
            ),
            const _Label('Frekuensi'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<FrequencyType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: FrequencyType.daily,
                    label: Text('Setiap hari'),
                  ),
                  ButtonSegment(
                    value: FrequencyType.weekdays,
                    label: Text('Hari tertentu'),
                  ),
                  ButtonSegment(
                    value: FrequencyType.timesPerWeek,
                    label: Text('Per minggu'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ),
            if (_type == FrequencyType.weekdays) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    _DayToggle(
                      label: dayShortNames[i],
                      selected: _mask & (1 << i) != 0,
                      onTap: () => setState(() => _mask ^= 1 << i),
                    ),
                ],
              ),
            ],
            if (_type == FrequencyType.timesPerWeek) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _times > 1
                        ? () => setState(() => _times--)
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                    tooltip: 'Kurangi',
                  ),
                  Expanded(
                    child: Text(
                      '$_times× seminggu',
                      textAlign: TextAlign.center,
                      style: monoStyle(size: 16, weight: FontWeight.w700),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _times < 6
                        ? () => setState(() => _times++)
                        : null,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Tambah',
                  ),
                ],
              ),
            ],
            const _Label('Pengingat'),
            Material(
              color: AppColors.surfaceHigh,
              borderRadius: AppRadius.borderRadius,
              child: InkWell(
                borderRadius: AppRadius.borderRadius,
                onTap: _pickReminder,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _reminder == null
                            ? const Text(
                                'Tanpa pengingat',
                                style: TextStyle(color: AppColors.textMuted),
                              )
                            : Text(
                                _formatMinutes(_reminder!),
                                style: monoStyle(size: 16),
                              ),
                      ),
                      if (_reminder != null)
                        IconButton(
                          onPressed: () => setState(() => _reminder = null),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Hapus pengingat',
                        )
                      else
                        const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(editing ? 'Simpan perubahan' : 'Tambah kebiasaan'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceHigh,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 42,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.text : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

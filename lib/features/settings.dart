import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/csv.dart';
import '../core/fmt.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../data/store.dart';
import 'modules.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wed = ref.watch(weddingProvider).value;
    final s = ref.watch(sessionProvider);
    final theme = ref.watch(themeProvider);

    return PageFrame(
      title: 'Settings',
      subtitle: 'Your wedding, your way',
      bottomPad: 40,
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wedding code', style: context.tt.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Share this with your partner so you both plan in the same place.',
                style: context.tt.bodySmall?.copyWith(color: context.muted),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: context.soft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SelectableText(
                        s?.weddingId ?? '',
                        style: context.tt.titleLarge?.copyWith(
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    tooltip: 'Copy',
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: s?.weddingId ?? ''),
                      );
                      toast(context, 'Code copied');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Signed in as ',
                    style: context.tt.bodySmall?.copyWith(color: context.muted),
                  ),
                  Text(s?.name ?? '', style: context.tt.labelMedium),
                  const SizedBox(width: 8),
                  if (s != null) SideChip(s.side, small: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Wedding details',
                      style: context.tt.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: wed == null
                        ? null
                        : () => _edit(context, ref, wed),
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _kv(context, 'Bride', wed?.s('brideName') ?? '—'),
              _kv(context, 'Groom', wed?.s('groomName') ?? '—'),
              _kv(
                context,
                'Date',
                wed?.dt('date') == null ? '—' : dateShort(wed!.dt('date')!),
              ),
              _kv(
                context,
                'City',
                (wed?.s('city') ?? '').isEmpty ? '—' : wed!.s('city'),
              ),
              _kv(context, 'Total budget', money(wed?.n('totalBudget') ?? 0)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appearance', style: context.tt.titleMedium),
              const SizedBox(height: 14),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  backgroundColor: context.soft,
                  selectedBackgroundColor: context.accent,
                  selectedForegroundColor: Theme.of(context)
                      .colorScheme
                      .onPrimary,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Auto'),
                    icon: Icon(Icons.brightness_auto_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_rounded, size: 18),
                  ),
                ],
                selected: {theme},
                onSelectionChanged: (v) =>
                    ref.read(themeProvider.notifier).set(v.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export data', style: context.tt.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Download any section as a CSV spreadsheet.',
                style: context.tt.bodySmall?.copyWith(color: context.muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in [...allModules, budgetLines])
                    ActionChip(
                      avatar: Icon(
                        Icons.download_rounded,
                        size: 16,
                        color: context.accent,
                      ),
                      label: Text(m.title),
                      onPressed: () {
                        final rows = ref.read(colProvider(m.col)).value ?? [];
                        if (rows.isEmpty) {
                          toast(context, 'Nothing to export in ${m.title}');
                          return;
                        }
                        downloadCsv('knots-${m.id}', rows, [
                          ...m.fields.map((f) => f.key),
                          'createdBy',
                          'createdBySide',
                        ]);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Log out of this wedding?'),
                content: const Text(
                  'Your data stays safe. You can come back any time with the wedding code.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Stay'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Log out'),
                  ),
                ],
              ),
            );
            if (ok == true) ref.read(sessionProvider.notifier).clear();
          },
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Log out'),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Knots · made for ${wed?.s('brideName') ?? ''} & ${wed?.s('groomName') ?? ''}',
            style: context.tt.bodySmall?.copyWith(color: context.muted),
          ),
        ),
      ],
    );
  }

  Widget _kv(BuildContext c, String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(k, style: c.tt.bodyMedium?.copyWith(color: c.muted)),
        ),
        Expanded(
          child: Text(
            v,
            style: c.tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  Future<void> _edit(BuildContext context, WidgetRef ref, Rec w) async {
    final g = TextEditingController(text: w.s('groomName'));
    final b = TextEditingController(text: w.s('brideName'));
    final city = TextEditingController(text: w.s('city'));
    final budget = TextEditingController(
      text: w.n('totalBudget').round().toString(),
    );
    var date = w.dt('date') ?? DateTime.now();
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Wedding details'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: b,
                    decoration: const InputDecoration(labelText: 'Bride'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: g,
                    decoration: const InputDecoration(labelText: 'Groom'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final p = await showDatePicker(
                        context: c,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (p != null) set(() => date = p);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Text(dateShort(date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: city,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: budget,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total budget',
                      prefixText: '₹ ',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(repoProvider).updateWedding({
                  'groomName': g.text.trim(),
                  'brideName': b.text.trim(),
                  'city': city.text.trim(),
                  'date': Timestamp.fromDate(date),
                  'totalBudget':
                      double.tryParse(budget.text.replaceAll(',', '')) ?? 0,
                });
                Navigator.pop(c);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

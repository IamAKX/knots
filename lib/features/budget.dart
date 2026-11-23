import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fmt.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../data/store.dart';
import 'module_screen.dart';
import 'modules.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = listOf(ref, 'budget');
    final exp = listOf(ref, 'expenses');
    final wed = ref.watch(weddingProvider).value;
    final planned = lines.fold(0.0, (a, r) => a + r.n('planned'));
    final total = wed?.n('totalBudget') ?? 0;
    final cap = total > 0 ? total : planned;
    final spent = exp.fold(0.0, (a, r) => a + r.n('amount'));
    double actual(String c) => exp
        .where((e) => e.s('category') == c)
        .fold(0.0, (a, e) => a + e.n('amount'));

    return Stack(
      children: [
        PageFrame(
          title: 'Budget',
          subtitle: 'Planned vs actual by category',
          actions: [
            if (context.wide)
              FilledButton.icon(
                onPressed: () => showRecordForm(context, ref, budgetLines),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add category'),
              ),
          ],
          children: [
            AppCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall',
                    style: context.tt.bodySmall?.copyWith(color: context.muted),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CountText(spent, style: context.tt.headlineLarge),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          'of ${money(cap)}',
                          style: context.tt.bodyMedium?.copyWith(
                            color: context.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ProgressBar(value: cap == 0 ? 0 : spent / cap, height: 10),
                  const SizedBox(height: 10),
                  Text(
                    cap == 0
                        ? 'Set a total budget in Settings to track progress.'
                        : spent > cap
                        ? 'Over budget by ${money(spent - cap)}'
                        : '${money(cap - spent)} left · ${(spent / cap * 100).round()}% used',
                    style: context.tt.bodyMedium?.copyWith(
                      color: spent > cap
                          ? const Color(0xFFC0443C)
                          : context.muted,
                    ),
                  ),
                  if (planned != total && total > 0 && planned > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Categories planned: ${money(planned)}',
                      style: context.tt.bodySmall?.copyWith(
                        color: context.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SectionTitle('Categories'),
            if (lines.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.pie_chart_rounded,
                  title: 'No categories yet',
                  text: 'Split your total budget into categories like Venue, Catering and Decor.',
                  action: FilledButton.icon(
                    onPressed: () => showRecordForm(context, ref, budgetLines),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add category'),
                  ),
                ),
              )
            else
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _Line(rec: l, actual: actual(l.s('category'))),
                ),
          ],
        ),
        if (!context.wide)
          Positioned(
            right: 18,
            bottom: 18,
            child: FloatingActionButton.extended(
              onPressed: () => showRecordForm(context, ref, budgetLines),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add category'),
            ),
          ),
      ],
    );
  }
}

class _Line extends ConsumerWidget {
  const _Line({required this.rec, required this.actual});
  final Rec rec;
  final double actual;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planned = rec.n('planned');
    final ratio = planned == 0 ? 0.0 : actual / planned;
    final over = ratio > 1;
    return Dismissible(
      key: ValueKey(rec.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFC0443C),
          borderRadius: BorderRadius.circular(K.r),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(repoProvider).remove('budget', rec.id);
        toast(
          context,
          'Deleted',
          action: 'Undo',
          onAction: () => ref.read(repoProvider).restore('budget', rec),
        );
      },
      child: AppCard(
        onTap: () => showRecordForm(context, ref, budgetLines, rec: rec),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(rec.s('category'), style: context.tt.titleMedium),
                ),
                if (over) const Pill('Over budget', Color(0xFFC0443C)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  money(actual),
                  style: context.tt.titleMedium?.copyWith(
                    color: over ? const Color(0xFFC0443C) : null,
                  ),
                ),
                Text(
                  '  of ${money(planned)}',
                  style: context.tt.bodySmall?.copyWith(color: context.muted),
                ),
                const Spacer(),
                Text(
                  '${(ratio * 100).round()}%',
                  style: context.tt.labelMedium?.copyWith(color: context.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ProgressBar(value: ratio),
          ],
        ),
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/fmt.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../data/store.dart';
import 'module_screen.dart';
import 'modules.dart' as mod;

double _sum(Iterable<Rec> l, String k) => l.fold(0.0, (a, r) => a + r.n(k));
int _heads(Iterable<Rec> l) =>
    l.fold(0, (a, r) => a + r.n('adults').round() + r.n('kids').round());

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wed = ref.watch(weddingProvider).value;
    final exp = listOf(ref, 'expenses');
    final guests = listOf(ref, 'guests');
    final gifts = listOf(ref, 'gifts');
    final tasks = listOf(ref, 'tasks');
    final budget = listOf(ref, 'budget');
    final session = ref.watch(sessionProvider);

    final planned = _sum(budget, 'planned');
    final total = (wed?.n('totalBudget') ?? 0) > 0
        ? wed!.n('totalBudget')
        : planned;
    final spent = _sum(exp, 'amount');
    final paid = _sum(exp, 'paid');

    // category slices
    final byCat = <String, double>{};
    for (final e in exp) {
      final c = e.s('category').isEmpty ? 'Misc' : e.s('category');
      byCat[c] = (byCat[c] ?? 0) + e.n('amount');
    }
    final catKeys = byCat.keys.toList()
      ..sort((a, b) => byCat[b]!.compareTo(byCat[a]!));
    final catSlices = [
      for (var i = 0; i < catKeys.length; i++)
        Slice(catKeys[i], byCat[catKeys[i]]!, K.chart[i % K.chart.length]),
    ];

    double bySide(Iterable<Rec> l, String s, String k) =>
        _sum(l.where((r) => r.side == s), k);
    List<Slice> sideSlices(double Function(String) f) => [
      for (final s in const ['groom', 'bride', 'shared'])
        Slice(K.sideLabel(s), f(s), K.sideColor(s)),
    ];

    final rsvp = <String, double>{};
    for (final g in guests) {
      rsvp[g.s('status').isEmpty ? 'Not invited' : g.s('status')] =
          (rsvp[g.s('status').isEmpty ? 'Not invited' : g.s('status')] ?? 0) +
          (g.n('adults') + g.n('kids'));
    }
    final rsvpSlices = [
      for (final s in const ['Confirmed', 'Invited', 'Not invited', 'Declined'])
        Slice(s, rsvp[s] ?? 0, mod.statusColor(s)),
    ];

    final open = tasks.where((t) => t.s('status') != 'Done').toList()
      ..sort(
        (a, b) => (a.dt('due') ?? DateTime(2100)).compareTo(
          b.dt('due') ?? DateTime(2100),
        ),
      );

    final days = wed?.dt('date')?.difference(DateTime.now()).inDays;
    final me = session?.name.isNotEmpty == true ? session!.name : null;

    return PageFrame(
      title: me == null ? 'Overview' : 'Hello, $me',
      subtitle: 'Here is where your wedding stands today',
      children: [
        _Hero(wed: wed, days: days, total: total, spent: spent),
        const SizedBox(height: 14),
        _QuickActions(ref: ref),
        const SizedBox(height: 18),
        Tiles(
          min: 160,
          children: [
            StatTile(
              label: 'Total budget',
              value: moneyShort(total),
              icon: Icons.account_balance_wallet_rounded,
            ),
            StatTile(
              label: 'Spent',
              value: moneyShort(spent),
              icon: Icons.north_east_rounded,
              color: const Color(0xFFC06C52),
              sub: '${moneyShort(paid)} paid',
            ),
            StatTile(
              label: 'Remaining',
              value: moneyShort(total - spent),
              icon: Icons.savings_rounded,
              color: total - spent < 0
                  ? const Color(0xFFC0443C)
                  : const Color(0xFF4E9A6B),
            ),
            StatTile(
              label: 'Guests',
              value: '${_heads(guests)}',
              icon: Icons.groups_rounded,
              color: K.groom,
              sub:
                  '${_heads(guests.where((g) => g.s('status') == 'Confirmed'))} confirmed',
            ),
          ],
        ),
        const SectionTitle('Spending'),
        Tiles(
          min: 320,
          children: [
            _ChartCard(
              title: 'By category',
              child: Donut(slices: catSlices, centerLabel: 'Spent'),
            ),
            _ChartCard(
              title: 'By side',
              child: Donut(
                slices: sideSlices((s) => bySide(exp, s, 'amount')),
                centerLabel: 'Spent',
              ),
            ),
          ],
        ),
        const SizedBox(height: K.gap),
        _ChartCard(
          title: 'Spending over time',
          trailing: Text(
            'cumulative',
            style: context.tt.bodySmall?.copyWith(color: context.muted),
          ),
          child: _TimeLine(exp),
        ),
        const SizedBox(height: K.gap),
        _ChartCard(
          title: 'Groom vs Bride',
          trailing: const Legend(),
          child: Column(
            children: [
              SplitBar(
                label: 'Money spent',
                groom: bySide(exp, 'groom', 'amount'),
                bride: bySide(exp, 'bride', 'amount'),
              ),
              const SizedBox(height: 18),
              SplitBar(
                label: 'Guests invited',
                groom: _heads(guests.where((g) => g.side == 'groom'))
                    .toDouble(),
                bride: _heads(guests.where((g) => g.side == 'bride'))
                    .toDouble(),
                fmt: (v) => '${v.round()}',
              ),
              const SizedBox(height: 18),
              SplitBar(
                label: 'Gifts received',
                groom: bySide(gifts, 'groom', 'value'),
                bride: bySide(gifts, 'bride', 'value'),
              ),
              const SizedBox(height: 18),
              SplitBar(
                label: 'Tasks completed',
                groom: tasks
                    .where((t) => t.side == 'groom' && t.s('status') == 'Done')
                    .length
                    .toDouble(),
                bride: tasks
                    .where((t) => t.side == 'bride' && t.s('status') == 'Done')
                    .length
                    .toDouble(),
                fmt: (v) => '${v.round()}',
              ),
            ],
          ),
        ),
        const SectionTitle('Guests & gifts'),
        Tiles(
          min: 270,
          children: [
            _ChartCard(
              title: 'RSVP status',
              child: Donut(
                slices: rsvpSlices,
                centerLabel: 'People',
                formatter: (v) => '${v.round()}',
              ),
            ),
            _ChartCard(
              title: 'Guests by side',
              child: Donut(
                slices: sideSlices(
                  (s) => _heads(guests.where((g) => g.side == s)).toDouble(),
                ),
                centerLabel: 'People',
                formatter: (v) => '${v.round()}',
              ),
            ),
            _ChartCard(
              title: 'Gifts by side',
              child: Donut(
                slices: sideSlices((s) => bySide(gifts, s, 'value')),
                centerLabel: 'Gifts',
              ),
            ),
          ],
        ),
        const SectionTitle('Budget check'),
        _BudgetBars(budget: budget, exp: exp),
        SectionTitle(
          'Coming up',
          trailing: TextButton(
            onPressed: () => context.go('/tasks'),
            child: const Text('See all'),
          ),
        ),
        if (open.isEmpty)
          AppCard(
            child: Text(
              'Nothing pending. Enjoy the calm.',
              style: context.tt.bodyMedium?.copyWith(color: context.muted),
            ),
          )
        else
          for (final t in open.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                onTap: () => showRecordForm(context, ref, mod.tasks, rec: t),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 34,
                      decoration: BoxDecoration(
                        color: K.sideColor(t.side),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.s('title'),
                            style: context.tt.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            mod.tasks.sub(t),
                            style: context.tt.bodySmall?.copyWith(
                              color: context.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SideChip(t.side, small: true),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.wed,
    required this.days,
    required this.total,
    required this.spent,
  });
  final Rec? wed;
  final int? days;
  final double total, spent;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF26323A);
    const gold = Color(0xFFE3C58A);
    final g = wed?.s('groomName') ?? 'Groom';
    final b = wed?.s('brideName') ?? 'Bride';
    final pct = total == 0 ? 0.0 : spent / total;
    final wide = context.wide;
    final names = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WEDDING OF',
          style: context.tt.labelSmall?.copyWith(color: gold, letterSpacing: 2),
        ),
        const SizedBox(height: 10),
        Text(
          '$b & $g',
          style: (wide ? context.tt.displayMedium : context.tt.headlineLarge)
              ?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          [
            if (wed?.dt('date') != null) dateShort(wed!.dt('date')!),
            if ((wed?.s('city') ?? '').isNotEmpty) wed!.s('city'),
          ].join(' · '),
          style: context.tt.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
    final count = Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          days == null ? '—' : (days! < 0 ? 'Married' : '${days!}'),
          style: context.tt.displayLarge?.copyWith(
            color: gold,
            fontSize: wide ? 64 : 52,
          ),
        ),
        Text(
          days == null || days! < 0
              ? ''
              : (days == 1 ? 'day to go' : 'days to go'),
          style: context.tt.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: ink,
        padding: EdgeInsets.all(wide ? 32 : 22),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: gold.withValues(alpha: .22),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: gold.withValues(alpha: .15),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: names),
                          count,
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [names, const SizedBox(height: 18), count],
                      ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0, 1).toDouble(),
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    color: pct > 1 ? const Color(0xFFE57373) : gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  total == 0
                      ? 'Set your budget in Settings'
                      : '${moneyShort(spent)} spent of ${moneyShort(total)}  ·  ${(pct * 100).round()}%',
                  style: context.tt.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.ref});
  final WidgetRef ref;
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Expense', Icons.receipt_long_rounded, mod.expenses),
      ('Guest', Icons.person_add_alt_1_rounded, mod.guests),
      ('Task', Icons.add_task_rounded, mod.tasks),
      ('Gift', Icons.card_giftcard_rounded, mod.gifts),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onTap: () => showRecordForm(context, ref, items[i].$3),
              child: Column(
                children: [
                  Icon(items[i].$2, size: 22, color: context.accent),
                  const SizedBox(height: 6),
                  Text('+ ${items[i].$1}', style: context.tt.labelMedium),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: context.tt.titleMedium)),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: Center(child: child),
        ),
      ],
    ),
  );
}

class _TimeLine extends StatelessWidget {
  const _TimeLine(this.exp);
  final List<Rec> exp;
  @override
  Widget build(BuildContext context) {
    if (exp.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Add expenses to see the trend',
            style: context.tt.bodyMedium?.copyWith(color: context.muted),
          ),
        ),
      );
    }
    final byMonth = <DateTime, double>{};
    for (final e in exp) {
      final d = e.dt('date') ?? e.created;
      final k = DateTime(d.year, d.month);
      byMonth[k] = (byMonth[k] ?? 0) + e.n('amount');
    }
    final months = byMonth.keys.toList()..sort();
    var run = 0.0;
    final spots = <FlSpot>[];
    for (var i = 0; i < months.length; i++) {
      run += byMonth[months[i]]!;
      spots.add(FlSpot(i.toDouble(), run));
    }
    if (spots.length == 1) spots.insert(0, FlSpot(-1, 0));
    final off = spots.first.x < 0 ? 1 : 0;
    final c = context.accent;
    final step = (months.length / 5).ceil().clamp(1, 99);
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: context.line,
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  getTitlesWidget: (v, m) => v == m.max || v == m.min && v != 0
                      ? const SizedBox()
                      : Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            moneyShort(v),
                            style: context.tt.bodySmall?.copyWith(
                              color: context.muted,
                              fontSize: 10.5,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 28,
                  getTitlesWidget: (v, m) {
                    final i = v.toInt() - off;
                    if (v != v.roundToDouble() ||
                        i < 0 ||
                        i >= months.length ||
                        i % step != 0)
                      return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        monthKey(months[i]),
                        style: context.tt.bodySmall?.copyWith(
                          color: context.muted,
                          fontSize: 10.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF26323A),
                getTooltipItems: (t) => [
                  for (final s in t)
                    LineTooltipItem(
                      money(s.y),
                      const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: .25,
                preventCurveOverShooting: true,
                color: c,
                barWidth: 3,
                dotData: FlDotData(
                  getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                    radius: 4,
                    color: context.card,
                    strokeWidth: 2.5,
                    strokeColor: c,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.withValues(alpha: .18), c.withValues(alpha: 0)],
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }
}

class _BudgetBars extends StatelessWidget {
  const _BudgetBars({required this.budget, required this.exp});
  final List<Rec> budget, exp;
  @override
  Widget build(BuildContext context) {
    if (budget.isEmpty) {
      return AppCard(
        child: Text(
          'Add budget categories to compare planned vs actual.',
          style: context.tt.bodyMedium?.copyWith(color: context.muted),
        ),
      );
    }
    final rows = budget.toList()
      ..sort((a, b) => b.n('planned').compareTo(a.n('planned')));
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          for (var i = 0; i < rows.length && i < 6; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Builder(
              builder: (_) {
                final c = rows[i].s('category');
                final a = exp
                    .where((e) => e.s('category') == c)
                    .fold(0.0, (s, e) => s + e.n('amount'));
                final p = rows[i].n('planned');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(c, style: context.tt.titleSmall)),
                        Text(
                          '${moneyShort(a)} / ${moneyShort(p)}',
                          style: context.tt.bodySmall?.copyWith(
                            color: a > p
                                ? const Color(0xFFC0443C)
                                : context.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ProgressBar(
                      value: p == 0 ? 0 : a / p,
                      color: K.chart[i % K.chart.length],
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

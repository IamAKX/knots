import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'fmt.dart';
import 'theme.dart';

/// Page frame: centred max-width column with a serif title block.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.children,
    this.bottomPad = 100,
  });
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    final wide = context.wide;
    final pad = wide ? 32.0 : 18.0;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: K.maxW),
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, wide ? 28 : 8, pad, bottomPad),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: wide
                            ? context.tt.displayMedium
                            : context.tt.headlineLarge,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: context.tt.bodyMedium?.copyWith(
                            color: context.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(K.r),
      side: BorderSide(color: context.line),
    );
    return Material(
      color: color ?? context.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 24, 2, 12),
    child: Row(
      children: [
        Expanded(child: Text(text, style: context.tt.titleLarge)),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class SideChip extends StatelessWidget {
  const SideChip(this.side, {super.key, this.small = false});
  final String side;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final c = K.sideColor(side);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            K.sideLabel(side),
            style: context.tt.labelSmall?.copyWith(
              color: context.dark ? c : Color.lerp(c, Colors.black, .35),
              fontSize: small ? 10.5 : 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, this.color, {super.key});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: context.tt.labelSmall?.copyWith(
        color: context.dark ? color : Color.lerp(color, Colors.black, .3),
      ),
    ),
  );
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.sub,
  });
  final String label;
  final String value;
  final String? sub;
  final IconData? icon;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? context.accent;
    final compact = MediaQuery.sizeOf(context).width < 520;
    return AppCard(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: compact ? 84 : 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null && !compact)
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 16, color: c),
                  ),
                if (icon != null && !compact) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: context.tt.bodySmall?.copyWith(color: context.muted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: context.tt.headlineSmall?.copyWith(fontSize: 24),
              ),
            ),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(
                sub!,
                style: context.tt.bodySmall?.copyWith(color: context.muted),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Responsive grid of equal-width tiles without fixed heights.
class Tiles extends StatelessWidget {
  const Tiles({super.key, required this.children, this.min = 200});
  final List<Widget> children;
  final double min;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (c, box) {
      final cols = math.min(
        children.length,
        math.max(1, ((box.maxWidth + K.gap) / (min + K.gap)).floor()),
      );
      final w = (box.maxWidth - K.gap * (cols - 1)) / cols;
      return Wrap(
        spacing: K.gap,
        runSpacing: K.gap,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    },
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.action,
  });
  final IconData icon;
  final String title;
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: context.soft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 30, color: context.muted),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: context.tt.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: context.tt.bodyMedium?.copyWith(color: context.muted),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

/// Pulsing placeholder block.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 70, this.radius = 18});
  final double height;
  final double radius;
  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Color.lerp(context.soft, context.line, _c.value),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 5});
  final int count;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < count; i++)
        const Padding(padding: EdgeInsets.only(bottom: 10), child: Skeleton()),
    ],
  );
}

/// Counts up to [value] on first show and whenever it changes.
class CountText extends StatelessWidget {
  const CountText(this.value, {super.key, this.style, this.compact = false});
  final double value;
  final TextStyle? style;
  final bool compact;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (_, v, _) =>
        Text(compact ? moneyShort(v) : money(v), style: style),
  );
}

class Slice {
  const Slice(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

/// Donut chart with tap-to-inspect centre label and legend.
class Donut extends StatefulWidget {
  const Donut({
    super.key,
    required this.slices,
    this.centerLabel = 'Total',
    this.formatter,
    this.size = 170,
  });
  final List<Slice> slices;
  final String centerLabel;
  final String Function(double)? formatter;
  final double size;
  @override
  State<Donut> createState() => _DonutState();
}

class _DonutState extends State<Donut> {
  int _t = -1;
  @override
  Widget build(BuildContext context) {
    final f = widget.formatter ?? moneyShort;
    final data = widget.slices.where((s) => s.value > 0).toList();
    final total = data.fold<double>(0, (a, b) => a + b.value);
    if (data.isEmpty) {
      return SizedBox(
        height: widget.size,
        child: Center(
          child: Text(
            'No data yet',
            style: context.tt.bodyMedium?.copyWith(color: context.muted),
          ),
        ),
      );
    }
    final sel = (_t >= 0 && _t < data.length) ? data[_t] : null;
    return Column(
      children: [
        SizedBox(
          height: widget.size,
          width: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: widget.size * .3,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (e, r) {
                      final i = r?.touchedSection?.touchedSectionIndex ?? -1;
                      if (i != _t)
                        setState(
                          () => _t = e.isInterestedForInteractions ? i : -1,
                        );
                    },
                  ),
                  sections: [
                    for (var i = 0; i < data.length; i++)
                      PieChartSectionData(
                        value: data[i].value,
                        color: data[i].color,
                        radius: i == _t ? widget.size * .21 : widget.size * .17,
                        showTitle: false,
                      ),
                  ],
                ),
                duration: const Duration(milliseconds: 250),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sel?.label ?? widget.centerLabel,
                    style: context.tt.bodySmall?.copyWith(color: context.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(f(sel?.value ?? total), style: context.tt.titleLarge),
                  if (sel != null)
                    Text(
                      '${(sel.value / total * 100).round()}%',
                      style: context.tt.bodySmall?.copyWith(
                        color: context.muted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final s in data)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: s.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(s.label, style: context.tt.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Two-tone bar comparing groom vs bride.
class SplitBar extends StatelessWidget {
  const SplitBar({
    super.key,
    required this.label,
    required this.groom,
    required this.bride,
    this.fmt,
  });
  final String label;
  final double groom;
  final double bride;
  final String Function(double)? fmt;
  @override
  Widget build(BuildContext context) {
    final f = fmt ?? moneyShort;
    final t = groom + bride;
    final gf = t == 0 ? 1.0 : groom / t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: context.tt.titleSmall),
            const Spacer(),
            Text(
              f(groom),
              style: context.tt.labelMedium?.copyWith(color: K.groom),
            ),
            Text(
              '  ·  ',
              style: context.tt.labelMedium?.copyWith(color: context.muted),
            ),
            Text(
              f(bride),
              style: context.tt.labelMedium?.copyWith(color: K.bride),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: double.infinity,
            height: 10,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: gf),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: t == 0 ? context.soft : K.bride),
                  ),
                  if (t > 0)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: v.clamp(0.0, 1.0),
                          heightFactor: 1,
                          child: const ColoredBox(color: K.groom),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
  });
  final double value; // 0..n  (>1 = over)
  final Color? color;
  final double height;
  @override
  Widget build(BuildContext context) {
    final over = value > 1;
    final c = over ? const Color(0xFFC0443C) : (color ?? context.accent);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: context.soft,
          color: c,
        ),
      ),
    );
  }
}

class Legend extends StatelessWidget {
  const Legend({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final s in const ['groom', 'bride']) ...[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: K.sideColor(s),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(K.sideLabel(s), style: context.tt.bodySmall),
        const SizedBox(width: 12),
      ],
    ],
  );
}

void toast(
  BuildContext context,
  String msg, {
  String? action,
  VoidCallback? onAction,
}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 4),
      width: context.wide ? 420 : null,
      action: action == null
          ? null
          : SnackBarAction(label: action, onPressed: onAction ?? () {}),
    ),
  );
}

/// Segmented selector for groom / bride / shared.
class SidePicker extends StatelessWidget {
  const SidePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.includeShared = true,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final bool includeShared;
  @override
  Widget build(BuildContext context) {
    final items = ['groom', 'bride', if (includeShared) 'shared'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final s in items)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(s),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: value == s ? context.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: value == s
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: K.sideColor(s),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        K.sideLabel(s),
                        style: context.tt.labelLarge?.copyWith(
                          fontWeight: value == s
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

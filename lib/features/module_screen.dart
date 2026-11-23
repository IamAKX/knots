import 'package:cloud_firestore/cloud_firestore.dart' hide Field;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fmt.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../data/store.dart';
import 'modules.dart';

class ModuleScreen extends ConsumerStatefulWidget {
  const ModuleScreen(this.m, {super.key});
  final Module m;
  @override
  ConsumerState<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends ConsumerState<ModuleScreen> {
  String _q = '';
  String _side = 'all';
  String _flt = 'all';

  Module get m => widget.m;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(colProvider(m.col));
    final all = async.value ?? const <Rec>[];
    final stats = m.stats?.call(ref, all) ?? const [];

    var list = all.where((r) {
      if (_side != 'all' && r.side != _side) return false;
      if (_flt != 'all' && m.filterKey != null && r.s(m.filterKey!) != _flt)
        return false;
      if (_q.isNotEmpty) {
        final hay = r.d.values.whereType<String>().join(' ').toLowerCase();
        if (!hay.contains(_q.toLowerCase())) return false;
      }
      return true;
    }).toList();
    // Open items first for check-off modules
    if (m.toggleKey != null) {
      list.sort((a, b) => (m.isDone(a) ? 1 : 0).compareTo(m.isDone(b) ? 1 : 0));
    }

    return Stack(
      children: [
        PageFrame(
          title: m.title,
          subtitle: m.subtitle,
          actions: [
            if (context.wide)
              FilledButton.icon(
                onPressed: () => showRecordForm(context, ref, m),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(m.addLabel),
              ),
          ],
          children: [
            if (stats.isNotEmpty)
              Tiles(
                min: 100,
                children: [
                  for (final s in stats)
                    StatTile(
                      label: s.label,
                      value: s.value,
                      icon: s.icon,
                      color: s.color,
                    ),
                ],
              ),
            const SizedBox(height: 18),
            TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Search ${m.title.toLowerCase()}',
                prefixIcon: Icon(Icons.search_rounded, color: context.muted),
                isDense: false,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (m.hasSide)
                    for (final s in const ['all', 'groom', 'bride', 'shared'])
                      _chip(
                        s == 'all' ? 'All' : K.sideLabel(s),
                        _side == s,
                        () => setState(() => _side = s),
                        dot: s == 'all' ? null : K.sideColor(s),
                      ),
                  if (m.filterKey != null) ...[
                    if (m.hasSide) const SizedBox(width: 8),
                    for (final o in ['all', ...m.filterOptions])
                      _chip(
                        o == 'all' ? 'Any status' : o,
                        _flt == o,
                        () => setState(() => _flt = o),
                        outline: true,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (async.isLoading && all.isEmpty)
              const SkeletonList()
            else if (list.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: m.icon,
                  title: all.isEmpty ? 'Nothing here yet' : 'No matches',
                  text: all.isEmpty
                      ? m.emptyText
                      : 'Try a different search or filter.',
                  action: all.isEmpty
                      ? FilledButton.icon(
                          onPressed: () => showRecordForm(context, ref, m),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(m.addLabel),
                        )
                      : null,
                ),
              )
            else
              for (final r in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _Row(m, r),
                ),
          ],
        ),
        if (!context.wide)
          Positioned(
            right: 18,
            bottom: 18,
            child: FloatingActionButton.extended(
              onPressed: () => showRecordForm(context, ref, m),
              icon: const Icon(Icons.add_rounded),
              label: Text(m.addLabel),
            ),
          ),
      ],
    );
  }

  Widget _chip(
    String label,
    bool sel,
    VoidCallback onTap, {
    Color? dot,
    bool outline = false,
  }) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel
              ? context.accent
              : (outline ? Colors.transparent : context.soft),
          border: Border.all(
            color: sel
                ? context.accent
                : (outline ? context.line : Colors.transparent),
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: context.tt.labelMedium?.copyWith(
                color: sel
                    ? Theme.of(context).colorScheme.onPrimary
                    : context.ink,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Row extends ConsumerWidget {
  const _Row(this.m, this.r);
  final Module m;
  final Rec r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = m.isDone(r);
    final badge = m.badge?.call(r);
    final sub = m.sub(r);
    final trailing = m.trailing?.call(r);
    final sc = K.sideColor(r.side);
    return Dismissible(
      key: ValueKey(r.id),
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
        ref.read(repoProvider).remove(m.col, r.id);
        toast(
          context,
          'Deleted',
          action: 'Undo',
          onAction: () => ref.read(repoProvider).restore(m.col, r),
        );
      },
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        onTap: () => showRecordForm(context, ref, m, rec: r),
        child: Row(
          children: [
            if (m.toggleKey != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Checkbox(
                  value: done,
                  onChanged: (v) => ref.read(repoProvider).update(m.col, r.id, {
                    m.toggleKey!: v == true ? m.toggleOn : m.toggleOff,
                    if (m.toggleKey == 'purchased' &&
                        v == true &&
                        r.n('actual') == 0)
                      'actual': r.n('estimate'),
                  }),
                ),
              )
            else
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  m.title_(r).isEmpty ? '?' : m.title_(r)[0].toUpperCase(),
                  style: context.tt.titleMedium?.copyWith(
                    color: context.dark ? sc : Color.lerp(sc, Colors.black, .3),
                  ),
                ),
              ),
            Expanded(
              child: Opacity(
                opacity: done ? .5 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title_(r),
                      style: context.tt.titleMedium?.copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: context.tt.bodySmall?.copyWith(
                          color: context.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (m.hasSide) SideChip(r.side, small: true),
                        if (badge != null) Pill(badge.text, badge.color),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              Text(trailing, style: context.tt.titleMedium),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showRecordForm(
  BuildContext context,
  WidgetRef ref,
  Module m, {
  Rec? rec,
}) {
  final body = _Form(m: m, rec: rec);
  if (context.wide) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: body,
        ),
      ),
    );
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => body,
  );
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.m, this.rec});
  final Module m;
  final Rec? rec;
  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _key = GlobalKey<FormState>();
  final Map<String, TextEditingController> _c = {};
  final Map<String, dynamic> _v = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.rec;
    final me = ref.read(sessionProvider);
    for (final f in widget.m.fields) {
      final raw = r?.d[f.key];
      switch (f.type) {
        case FT.text || FT.multiline:
          _c[f.key] = TextEditingController(
            text: (raw ?? f.def ?? '').toString(),
          );
        case FT.number || FT.money:
          final n = raw is num ? raw : (r == null ? f.def : null);
          _c[f.key] = TextEditingController(
            text: n == null || n == 0 && r == null ? '' : _plain(n),
          );
        case FT.side:
          _v[f.key] = raw ?? me?.side ?? 'shared';
        case FT.select:
          _v[f.key] = raw ?? f.def;
        case FT.date:
          _v[f.key] = raw is Timestamp
              ? raw.toDate()
              : (r == null && f.key == 'date' ? DateTime.now() : null);
        case FT.bool:
          _v[f.key] = raw == true;
      }
    }
  }

  String _plain(num n) =>
      n == n.roundToDouble() ? n.round().toString() : n.toString();

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{};
    for (final f in widget.m.fields) {
      switch (f.type) {
        case FT.text || FT.multiline:
          data[f.key] = _c[f.key]!.text.trim();
        case FT.number || FT.money:
          data[f.key] =
              double.tryParse(_c[f.key]!.text.replaceAll(',', '').trim()) ?? 0;
        case FT.date:
          final d = _v[f.key] as DateTime?;
          data[f.key] = d == null ? null : Timestamp.fromDate(d);
        default:
          data[f.key] = _v[f.key];
      }
    }
    // Expense convenience: keep paid in sync with status.
    if (widget.m.id == 'expenses') {
      final amt = data['amount'] as double;
      if (data['status'] == 'Paid' && (data['paid'] as double) == 0)
        data['paid'] = amt;
      if (data['status'] == 'Pending') data['paid'] = 0.0;
    }
    final repo = ref.read(repoProvider);
    final nav = Navigator.of(context);
    final msg = ScaffoldMessenger.of(context);
    // Firestore writes resolve from the local cache instantly, then sync.
    final fut = widget.rec == null
        ? repo.add(widget.m.col, data)
        : repo.update(widget.m.col, widget.rec!.id, data);
    nav.pop();
    msg.hideCurrentSnackBar();
    msg.showSnackBar(
      SnackBar(
        content: Text(widget.rec == null ? 'Added' : 'Saved'),
        duration: const Duration(seconds: 2),
      ),
    );
    await fut;
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final editing = widget.rec != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      editing ? 'Edit ${m.title.toLowerCase()}' : m.addLabel,
                      style: context.tt.headlineSmall,
                    ),
                  ),
                  if (editing)
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () {
                        final r = widget.rec!;
                        final repo = ref.read(repoProvider);
                        final msgr = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        repo.remove(m.col, r.id);
                        msgr.hideCurrentSnackBar();
                        msgr.showSnackBar(
                          SnackBar(
                            content: const Text('Deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () => repo.restore(m.col, r),
                            ),
                          ),
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in m.fields)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _field(f),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(editing ? 'Save changes' : m.addLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(Field f) {
    switch (f.type) {
      case FT.text || FT.multiline:
        return TextFormField(
          controller: _c[f.key],
          minLines: f.type == FT.multiline ? 2 : 1,
          maxLines: f.type == FT.multiline ? 4 : 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: f.label + (f.req ? ' *' : '')),
          validator: f.req
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        );
      case FT.number || FT.money:
        return TextFormField(
          controller: _c[f.key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: f.label + (f.req ? ' *' : ''),
            prefixText: f.type == FT.money ? '₹ ' : null,
          ),
          validator: (v) {
            final t = (v ?? '').replaceAll(',', '').trim();
            if (t.isEmpty) return f.req ? 'Required' : null;
            return double.tryParse(t) == null ? 'Enter a number' : null;
          },
        );
      case FT.select:
        return DropdownButtonFormField<String>(
          initialValue: f.options.contains(_v[f.key])
              ? _v[f.key] as String
              : null,
          items: [
            for (final o in f.options)
              DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: (v) => setState(() => _v[f.key] = v),
          decoration: InputDecoration(labelText: f.label),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: context.card,
          validator: f.req ? (v) => v == null ? 'Required' : null : null,
        );
      case FT.side:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                f.label,
                style: context.tt.bodySmall?.copyWith(color: context.muted),
              ),
            ),
            SidePicker(
              value: _v[f.key] as String,
              onChanged: (s) => setState(() => _v[f.key] = s),
            ),
          ],
        );
      case FT.date:
        final d = _v[f.key] as DateTime?;
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final p = await showDatePicker(
              context: context,
              initialDate: d ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (p != null) setState(() => _v[f.key] = p);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: f.label,
              suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
            ),
            child: Text(
              d == null ? 'Not set' : dateShort(d),
              style: context.tt.bodyLarge?.copyWith(
                color: d == null ? context.muted : null,
              ),
            ),
          ),
        );
      case FT.bool:
        return Container(
          decoration: BoxDecoration(
            color: context.soft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: SwitchListTile(
            value: _v[f.key] == true,
            onChanged: (v) => setState(() => _v[f.key] = v),
            title: Text(f.label, style: context.tt.bodyLarge),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
    }
  }
}

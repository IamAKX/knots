import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../core/ui.dart';
import '../data/store.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});
  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  bool _join = false;
  bool _busy = false;
  String? _err;
  String _side = 'groom';
  final _me = TextEditingController(text: 'Akash');
  final _groom = TextEditingController(text: 'Akash');
  final _bride = TextEditingController(text: 'Sonal');
  final _budget = TextEditingController(text: '3000000');
  final _code = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 120));

  @override
  void dispose() {
    for (final c in [_me, _groom, _bride, _budget, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    final repo = ref.read(repoProvider);
    try {
      if (_join) {
        final ok = await repo.joinWedding(_code.text, _side, _me.text.trim());
        if (!ok && mounted)
          setState(
            () =>
                _err = 'No wedding found with that code. Check and try again.',
          );
      } else {
        await repo
            .createWedding(
              groom: _groom.text.trim(),
              bride: _bride.text.trim(),
              date: _date,
              budget: double.tryParse(_budget.text.replaceAll(',', '')) ?? 0,
              side: _side,
              myName: _me.text.trim(),
            )
            .timeout(const Duration(seconds: 12));
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _err = 'Could not connect. Check your internet and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.wide;
    final form = _form(context);
    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  Expanded(child: _Brand()),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: form,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Logo(),
                    const SizedBox(height: 28),
                    Text(
                      'Plan your wedding,\ntogether.',
                      style: context.tt.displayMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Budget, guests, gifts and every detail in one calm place.',
                      style: context.tt.bodyMedium?.copyWith(
                        color: context.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    form,
                  ],
                ),
              ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.soft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              for (final j in [false, true])
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _join = j;
                      _err = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _join == j ? context.card : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        j ? 'Join with code' : 'New wedding',
                        style: context.tt.labelLarge?.copyWith(
                          fontWeight: _join == j
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'I am the',
          style: context.tt.bodySmall?.copyWith(color: context.muted),
        ),
        const SizedBox(height: 8),
        SidePicker(
          value: _side,
          onChanged: (s) => setState(() => _side = s),
          includeShared: false,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _me,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        const SizedBox(height: 14),
        if (_join)
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Wedding code',
              hintText: 'e.g. K7M2QX9TAB',
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bride,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Bride'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _groom,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Groom'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final p = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime(2100),
              );
              if (p != null) setState(() => _date = p);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Wedding date',
                suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
              ),
              child: Text(
                '${_date.day}/${_date.month}/${_date.year}',
                style: context.tt.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _budget,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total budget',
              prefixText: '₹ ',
            ),
          ),
        ],
        if (_err != null) ...[
          const SizedBox(height: 12),
          Text(
            _err!,
            style: context.tt.bodySmall?.copyWith(
              color: const Color(0xFFC0443C),
            ),
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy || _me.text.trim().isEmpty ? null : _go,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(_join ? 'Join wedding' : 'Start planning'),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _join ? 'Ask your partner for the code in Settings.' : 'You will get a code to share with your partner. No sign-up needed.',
          style: context.tt.bodySmall?.copyWith(color: context.muted),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const KnotsMark(size: 34),
      const SizedBox(width: 10),
      Text(
        'Knots',
        style: context.tt.headlineSmall?.copyWith(
          color: light ? Colors.white : null,
        ),
      ),
    ],
  );
}

/// Placeholder logo mark: two interlocking rings (swap with the real logo later).
class KnotsMark extends StatelessWidget {
  const KnotsMark({super.key, this.size = 32});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final r = s.width * .3;
    final w = s.width * .09;
    canvas.drawCircle(
      Offset(s.width * .36, s.height / 2),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = K.groom,
    );
    canvas.drawCircle(
      Offset(s.width * .64, s.height / 2),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = K.bride,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(48),
    decoration: BoxDecoration(
      color: const Color(0xFF26323A),
      borderRadius: BorderRadius.circular(32),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -80,
          bottom: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE3C58A).withValues(alpha: .25),
                width: 1.5,
              ),
            ),
          ),
        ),
        Positioned(
          right: -30,
          bottom: -30,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE3C58A).withValues(alpha: .18),
                width: 1.5,
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Logo(light: true),
            const Spacer(),
            Text(
              'Plan your wedding,\ntogether.',
              style: context.tt.displayLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Budget, guests, gifts and every little detail,\nshared between groom and bride.',
              style: context.tt.bodyLarge?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ],
    ),
  );
}

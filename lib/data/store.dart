import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A Firestore record: id + raw map with typed helpers.
class Rec {
  Rec(this.id, this.d);
  final String id;
  final Map<String, dynamic> d;

  String s(String k) => (d[k] ?? '').toString();
  double n(String k) => (d[k] is num) ? (d[k] as num).toDouble() : 0;
  bool b(String k) => d[k] == true;
  DateTime? dt(String k) =>
      d[k] is Timestamp ? (d[k] as Timestamp).toDate() : null;
  String get side {
    final v = s('side');
    return v.isEmpty ? 'shared' : v;
  }

  DateTime get created => dt('createdAt') ?? DateTime.now();
}

class Session {
  const Session(this.weddingId, this.side, this.name);
  final String weddingId;
  final String side; // groom | bride
  final String name;
}

final prefsProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(),
);

class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() {
    final p = ref.read(prefsProvider);
    final w = p.getString('wid');
    if (w == null) return null;
    return Session(
      w,
      p.getString('side') ?? 'groom',
      p.getString('name') ?? '',
    );
  }

  Future<void> set(Session s) async {
    final p = ref.read(prefsProvider);
    await p.setString('wid', s.weddingId);
    await p.setString('side', s.side);
    await p.setString('name', s.name);
    state = s;
  }

  Future<void> clear() async {
    await ref.read(prefsProvider).remove('wid');
    state = null;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(
  SessionNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final v = ref.read(prefsProvider).getString('theme');
    return ThemeMode.values.firstWhere(
      (e) => e.name == v,
      orElse: () => ThemeMode.system,
    );
  }

  void set(ThemeMode m) {
    ref.read(prefsProvider).setString('theme', m.name);
    state = m;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

final _db = FirebaseFirestore.instance;

DocumentReference<Map<String, dynamic>> _wref(String id) =>
    _db.collection('weddings').doc(id);

/// Wedding header document (names, date, budget).
final weddingProvider = StreamProvider<Rec?>((ref) {
  final s = ref.watch(sessionProvider);
  if (s == null) return const Stream.empty();
  return _wref(s.weddingId)
      .snapshots()
      .map((d) => d.exists ? Rec(d.id, d.data()!) : null);
});

/// Live list of a sub-collection, newest first.
final colProvider = StreamProvider.family<List<Rec>, String>((ref, col) {
  final s = ref.watch(sessionProvider);
  if (s == null) return const Stream.empty();
  return _wref(s.weddingId).collection(col).limit(1000).snapshots().map((q) {
    final l = q.docs.map((d) => Rec(d.id, d.data())).toList();
    l.sort((a, b) => b.created.compareTo(a.created));
    return l;
  });
});

List<Rec> listOf(WidgetRef ref, String col) =>
    ref.watch(colProvider(col)).value ?? const [];

const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
String _four(String name, Random r) {
  final l = name.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
  final p = l.length >= 4 ? l.substring(0, 4) : l;
  return p +
      List.generate(4 - p.length, (_) => _alphabet[r.nextInt(26)]).join();
}

/// 8 letters: first 4 of the bride's name + first 4 of the groom's name
/// (e.g. Alice + Bob -> ALICBOBX; short names are padded with random letters).
String newCode(String bride, String groom) {
  final r = Random.secure();
  return _four(bride, r) + _four(groom, r);
}

class Repo {
  Repo(this.ref);
  final Ref ref;
  Session get _s => ref.read(sessionProvider)!;
  CollectionReference<Map<String, dynamic>> _c(String col) =>
      _wref(_s.weddingId).collection(col);

  Future<String> createWedding({
    required String groom,
    required String bride,
    required DateTime date,
    required double budget,
    required String side,
    required String myName,
  }) async {
    // Keep the code unique and 8 characters: on a clash the number replaces
    // the last letters (ALICBOBX -> ALICBOB1, ALICBOB2 ... ALICBO10).
    final base = newCode(bride, groom);
    var id = base;
    for (var i = 1; (await _wref(id).get()).exists; i++) {
      final n = '$i';
      id = base.substring(0, 8 - n.length) + n;
    }
    await _wref(id).set({
      'groomName': groom,
      'brideName': bride,
      'date': Timestamp.fromDate(date),
      'totalBudget': budget,
      'currency': 'INR',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ref.read(sessionProvider.notifier).set(Session(id, side, myName));
    return id;
  }

  Future<bool> joinWedding(String code, String side, String name) async {
    final id = code.trim().toUpperCase();
    if (id.length < 6) return false;
    // Timeout lives here (not at the call site) so a slow read throws before
    // the session is set — otherwise it would log in after the error shows.
    final d = await _wref(id).get().timeout(const Duration(seconds: 25));
    if (!d.exists) return false;
    await ref.read(sessionProvider.notifier).set(Session(id, side, name));
    return true;
  }

  Future<void> updateWedding(Map<String, dynamic> data) =>
      _wref(_s.weddingId).update(data);

  Future<void> add(String col, Map<String, dynamic> data) => _c(col).add({
    ...data,
    'createdBy': _s.name,
    'createdBySide': _s.side,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> update(String col, String id, Map<String, dynamic> data) =>
      _c(col)
          .doc(id)
          .update({...data, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> remove(String col, String id) => _c(col).doc(id).delete();

  /// Used by "Undo" after delete.
  Future<void> restore(String col, Rec r) => _c(col).doc(r.id).set(r.d);

  static const _cols = [
    'expenses',
    'budget',
    'tasks',
    'purchases',
    'guests',
    'menu',
    'gifts',
    'vendors',
  ];

  /// Deletes every record in every section of the current wedding.
  Future<void> clearAll() async {
    for (final col in _cols) {
      final snap = await _c(col).get();
      for (var i = 0; i < snap.docs.length; i += 400) {
        final batch = _db.batch();
        for (final d in snap.docs.skip(i).take(400)) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }
  }
}

final repoProvider = Provider<Repo>((ref) => Repo(ref));

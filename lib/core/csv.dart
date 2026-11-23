import 'dart:js_interop';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web/web.dart' as web;

import '../data/store.dart';

String _cell(dynamic v) {
  if (v == null) return '';
  if (v is Timestamp) return v.toDate().toIso8601String().substring(0, 10);
  final s = v.toString().replaceAll('"', '""');
  return s.contains(',') || s.contains('\n') || s.contains('"') ? '"$s"' : s;
}

/// Builds a CSV from records and triggers a browser download.
void downloadCsv(String name, List<Rec> rows, List<String> keys) {
  final sb = StringBuffer()..writeln(keys.join(','));
  for (final r in rows) {
    sb.writeln(keys.map((k) => _cell(r.d[k])).join(','));
  }
  final blob = web.Blob(
    [sb.toString().toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = '$name.csv';
  a.click();
  web.URL.revokeObjectURL(url);
}

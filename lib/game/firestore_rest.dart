import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// A minimal Firestore client over the REST API, using the signed-in user's
/// ID token for auth.
///
/// Why not the `cloud_firestore` SDK? It is broken on Flutter web here — it
/// throws "Int64 accessor not supported by dart2js" on the dart2js build and
/// silently makes no network calls on the WASM build. The REST API works
/// reliably on both, so we talk to it directly. Real-time waits use short
/// polling (fine for a turn-based duel with a move timer).
class FirestoreRest {
  static const _project = 'mastersofmagic2';
  static const _base =
      'https://firestore.googleapis.com/v1/projects/$_project/databases/(default)/documents';

  static Future<String?> _token() =>
      FirebaseAuth.instance.currentUser?.getIdToken() ?? Future.value(null);

  static Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Reads a document. Returns its decoded fields, or null if missing.
  static Future<Map<String, dynamic>?> get(String path) async {
    final res =
        await http.get(Uri.parse('$_base/$path'), headers: await _headers());
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw FirestoreRestException(res.statusCode, res.body);
    }
    final doc = jsonDecode(res.body) as Map<String, dynamic>;
    return decodeFields(doc['fields'] as Map<String, dynamic>? ?? {});
  }

  /// Writes (merges) [data] into a document, creating it if needed. When
  /// [updateOnly] is given, only those field paths are touched.
  static Future<void> set(String path, Map<String, dynamic> data,
      {List<String>? updateOnly}) async {
    final mask = (updateOnly ?? data.keys.toList())
        .map((f) => 'updateMask.fieldPaths=${Uri.encodeQueryComponent(f)}')
        .join('&');
    final res = await http.patch(
      Uri.parse('$_base/$path?$mask'),
      headers: await _headers(),
      body: jsonEncode({'fields': encodeFields(data)}),
    );
    if (res.statusCode != 200) {
      throw FirestoreRestException(res.statusCode, res.body);
    }
  }

  /// Creates a document only if it does not already exist. Returns false if it
  /// already existed (precondition failed).
  static Future<bool> createIfAbsent(
      String collection, String docId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse(
          '$_base/$collection?documentId=$docId&currentDocument.exists=false'),
      headers: await _headers(),
      body: jsonEncode({'fields': encodeFields(data)}),
    );
    if (res.statusCode == 200) return true;
    if (res.statusCode == 409 || res.statusCode == 400) return false;
    throw FirestoreRestException(res.statusCode, res.body);
  }

  static Future<void> delete(String path) async {
    await http.delete(Uri.parse('$_base/$path'), headers: await _headers());
  }

  /// Runs a simple single-collection query with an optional equality filter
  /// and ordering. Returns each match as (id, fields).
  static Future<List<({String id, Map<String, dynamic> data})>> query(
    String collection, {
    ({String field, Object value})? equals,
    String? orderBy,
    int limit = 10,
  }) async {
    final structured = <String, dynamic>{
      'from': [
        {'collectionId': collection}
      ],
      'limit': limit,
      if (orderBy != null)
        'orderBy': [
          {
            'field': {'fieldPath': orderBy},
            'direction': 'ASCENDING'
          }
        ],
      if (equals != null)
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': equals.field},
            'op': 'EQUAL',
            'value': encodeValue(equals.value),
          }
        },
    };
    final res = await http.post(
      Uri.parse('$_base:runQuery'),
      headers: await _headers(),
      body: jsonEncode({'structuredQuery': structured}),
    );
    if (res.statusCode != 200) {
      throw FirestoreRestException(res.statusCode, res.body);
    }
    final rows = jsonDecode(res.body) as List<dynamic>;
    final out = <({String id, Map<String, dynamic> data})>[];
    for (final row in rows) {
      final doc = (row as Map<String, dynamic>)['document'];
      if (doc == null) continue;
      final name = doc['name'] as String;
      out.add((
        id: name.split('/').last,
        data: decodeFields(doc['fields'] as Map<String, dynamic>? ?? {}),
      ));
    }
    return out;
  }

  // ---- Value encoding (Dart <-> Firestore REST typed values) -----------

  static Map<String, dynamic> encodeFields(Map<String, dynamic> data) =>
      data.map((k, v) => MapEntry(k, encodeValue(v)));

  static Map<String, dynamic> encodeValue(Object? value) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is String) return {'stringValue': value};
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(encodeValue).toList()}
      };
    }
    if (value is Map) {
      return {
        'mapValue': {
          'fields': value.map((k, v) => MapEntry('$k', encodeValue(v)))
        }
      };
    }
    return {'stringValue': '$value'};
  }

  static Map<String, dynamic> decodeFields(Map<String, dynamic> fields) =>
      fields.map((k, v) => MapEntry(k, decodeValue(v as Map<String, dynamic>)));

  static Object? decodeValue(Map<String, dynamic> value) {
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('booleanValue')) return value['booleanValue'];
    if (value.containsKey('integerValue')) {
      return int.parse(value['integerValue'] as String);
    }
    if (value.containsKey('doubleValue')) {
      return (value['doubleValue'] as num).toDouble();
    }
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('timestampValue')) return value['timestampValue'];
    if (value.containsKey('arrayValue')) {
      final vals = (value['arrayValue'] as Map<String, dynamic>)['values']
              as List<dynamic>? ??
          [];
      return vals.map((v) => decodeValue(v as Map<String, dynamic>)).toList();
    }
    if (value.containsKey('mapValue')) {
      final f = (value['mapValue'] as Map<String, dynamic>)['fields']
              as Map<String, dynamic>? ??
          {};
      return decodeFields(f);
    }
    return null;
  }
}

class FirestoreRestException implements Exception {
  final int status;
  final String body;
  FirestoreRestException(this.status, this.body);
  @override
  String toString() => 'Firestore REST $status: $body';
}

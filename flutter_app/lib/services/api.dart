import 'dart:convert';

import 'package:http/http.dart' as http;

import 'storage.dart';

/// Backend client (Rust server in /server). Offline-first: every call is
/// fire-and-forget with a short timeout; failures never affect gameplay.
class Api {
  Api({this.baseUrl = const String.fromEnvironment('API_URL',
      defaultValue: 'http://localhost:8080')});

  final String baseUrl;
  String? _uid;
  String? _token;
  static const _timeout = Duration(seconds: 4);

  bool get connected => _uid != null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Anonymous sign-in; silently no-ops when the server is unreachable.
  Future<void> init() async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/api/auth/anonymous'),
              headers: {'Content-Type': 'application/json'})
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        _uid = j['uid'] as String?;
        _token = j['token'] as String?;
      }
    } catch (_) {/* offline: fine */}
  }

  /// Daily seed from remote config — everyone races the same universe today.
  Future<int?> fetchDailySeed() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/config'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        return (j['dailySeed'] as num?)?.toInt();
      }
    } catch (_) {}
    return null;
  }

  Future<void> submitScore(int height, int perfects, int prestige) async {
    if (_uid == null) return;
    try {
      await http
          .post(Uri.parse('$baseUrl/api/leaderboard/submit'),
              headers: _headers,
              body: jsonEncode({
                'height': height,
                'perfects': perfects,
                'prestige': prestige,
              }))
          .timeout(_timeout);
    } catch (_) {}
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/leaderboard/top'), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        return ((j['entries'] ?? []) as List)
            .map((e) => LeaderboardEntry(
                e['name'] as String? ?? 'star',
                e['height'] as int? ?? 0,
                e['prestige'] as int? ?? 0))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Ghost racing: upload this run's path so rivals on the same universe
  /// (world seed) can race against it. Best height per player per seed.
  Future<void> submitGhost(int seed, int height, List<double> path) async {
    if (_uid == null) return;
    try {
      await http
          .post(Uri.parse('$baseUrl/api/ghosts/submit'),
              headers: _headers,
              body: jsonEncode({'seed': seed, 'height': height, 'path': path}))
          .timeout(_timeout);
    } catch (_) {}
  }

  /// Top rival ghosts recorded on this universe (empty when offline).
  Future<List<GhostRun>> fetchGhosts(int seed) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/ghosts?seed=$seed'), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        return ((j['ghosts'] ?? []) as List)
            .map((e) => GhostRun(
                e['name'] as String? ?? 'star',
                (e['height'] as num?)?.toInt() ?? 0,
                ((e['path'] ?? []) as List)
                    .map((v) => (v as num).toDouble())
                    .toList()))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> pushSave(SaveData data) async {
    if (_uid == null) return;
    try {
      await http
          .put(Uri.parse('$baseUrl/api/save'),
              headers: _headers, body: jsonEncode(data.toJson()))
          .timeout(_timeout);
    } catch (_) {}
  }

  /// Pulls the cloud save; the caller merges (monotonic max, docs/04).
  Future<Map<String, dynamic>?> pullSave() async {
    if (_uid == null) return null;
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/save'), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}

class LeaderboardEntry {
  const LeaderboardEntry(this.name, this.height, this.prestige);
  final String name;
  final int height;
  final int prestige;
}

/// A rival player's recorded run on a given universe seed.
class GhostRun {
  const GhostRun(this.name, this.height, this.path);
  final String name;
  final int height;
  final List<double> path; // x,y pairs @ 10 Hz
}

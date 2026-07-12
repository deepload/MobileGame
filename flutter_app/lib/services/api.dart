import 'dart:convert';

import 'package:http/http.dart' as http;

import 'storage.dart';

/// Backend client (Rust server in /server). Offline-first: every call is
/// fire-and-forget with a short timeout; failures never affect gameplay.
class Api {
  Api({String? baseUrl, Storage? storage})
      : baseUrl = baseUrl ?? defaultUrl,
        _storage = storage;

  /// Persists the anonymous identity so a player stays the SAME player
  /// across launches (one leaderboard row, one cloud save).
  final Storage? _storage;

  static const defaultUrl = String.fromEnvironment('API_URL',
      defaultValue: 'http://localhost:8080');

  String baseUrl; // mutable: in-game "private server" override
  String? _uid;
  String? _token;
  static const _timeout = Duration(seconds: 4);

  bool get connected => _uid != null;

  /// True while pointed at the master server (no private override).
  bool get isMaster => baseUrl == defaultUrl;

  /// Registered on THIS server with name+password (not just a guest name).
  bool get registered => _storage?.isRegistered(baseUrl) ?? false;

  /// Last health-check result — drives the home-screen status dot.
  bool online = false;

  /// Probe /health; also self-heals auth when the server comes back
  /// (e.g. the app launched offline and the network returned later).
  Future<bool> ping() async {
    try {
      final res =
          await http.get(Uri.parse('$baseUrl/health')).timeout(_timeout);
      online = res.statusCode == 200;
    } catch (_) {
      online = false;
    }
    if (online && _uid == null) await init();
    return online;
  }

  /// Chosen pilot name; re-pushed to the server after every (re)auth.
  String? displayName;

  /// Name shown in multiplayer: the chosen one, else Star-xxxxxx (like the
  /// server-side fallback on the leaderboard).
  String get playerName {
    final n = displayName;
    if (n != null && n.isNotEmpty) return n;
    final u = _uid;
    if (u == null) return '';
    return 'Star-${u.length > 6 ? u.substring(0, 6) : u}';
  }

  /// ALPHA login — one form, two behaviours (server /api/auth/enter):
  /// unknown name+password registers the pilot, known name checks the
  /// password. On success the identity is stored for silent resume.
  Future<AuthResult> enter(String name, String password) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/api/auth/enter'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'name': name, 'password': password}))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        _uid = j['uid'] as String?;
        _token = j['token'] as String?;
        online = true;
        final settled = j['name'] as String? ?? name;
        displayName = settled;
        final u = _uid, t = _token;
        if (u != null && t != null) _storage?.setAuth(baseUrl, u, t);
        _storage?.setRegistered(baseUrl, true);
        return AuthResult(
            ok: true, created: j['created'] as bool? ?? false, name: settled);
      }
      if (res.statusCode == 401) return const AuthResult(wrongPassword: true);
      return const AuthResult(badInput: true); // 422: name/password too short
    } catch (_) {
      return const AuthResult(offline: true);
    }
  }

  /// Register the display name (leaderboard, ghosts). Returns the sanitized
  /// name the server settled on, or null when offline.
  Future<String?> pushName(String name) async {
    if (_uid == null) return null;
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/api/profile/name'),
              headers: _headers, body: jsonEncode({'name': name}))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        return j['name'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Sign-in: resume the stored identity for this server when there is one,
  /// else anonymous sign-up. Silently no-ops when the server is unreachable.
  Future<void> init() async {
    // 1) Resume — same uid every launch = ONE row on the leaderboards.
    final saved = _storage?.getAuth(baseUrl);
    if (saved != null) {
      try {
        final res = await http.post(Uri.parse('$baseUrl/api/auth/resume'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${saved.$2}',
            }).timeout(_timeout);
        if (res.statusCode == 200) {
          _uid = saved.$1;
          _token = saved.$2;
          online = true;
          final n = displayName;
          if (n != null && n.isNotEmpty) pushName(n);
          return;
        }
        // Server no longer knows this token (wipe/reset): the account is
        // gone too — drop the registered flag so the login gate re-opens.
        _storage?.clearAuth(baseUrl);
        _storage?.setRegistered(baseUrl, false);
      } catch (_) {
        return; // offline: keep the identity, ping() retries init later
      }
    }
    // 2) Fresh anonymous sign-up, persisted for next launch.
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/api/auth/anonymous'),
              headers: {'Content-Type': 'application/json'})
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        _uid = j['uid'] as String?;
        _token = j['token'] as String?;
        online = true;
        final u = _uid, t = _token;
        if (u != null && t != null) _storage?.setAuth(baseUrl, u, t);
        // New session/server: make sure it knows who we are on the boards.
        final n = displayName;
        if (n != null && n.isNotEmpty) pushName(n);
      }
    } catch (_) {/* offline: fine */}
  }

  /// Switch to another server (private server play) and re-authenticate.
  Future<void> setServer(String url) async {
    baseUrl = url.isEmpty ? defaultUrl : url;
    _uid = null;
    _token = null;
    await init();
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

  Future<void> submitScore(int height, int perfects, int prestige, int galaxy,
      String galaxyName) async {
    if (_uid == null) return;
    try {
      await http
          .post(Uri.parse('$baseUrl/api/leaderboard/submit'),
              headers: _headers,
              body: jsonEncode({
                'height': height,
                'perfects': perfects,
                'prestige': prestige,
                'galaxy': galaxy,
                'gname': galaxyName,
              }))
          .timeout(_timeout);
    } catch (_) {}
  }

  /// Weekly top for ONE galaxy. Empty list = board is empty; null =
  /// offline/unreachable (the UI tells those two apart).
  Future<List<LeaderboardEntry>?> fetchLeaderboard(int galaxy) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/leaderboard/top?galaxy=$galaxy'),
              headers: _headers)
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
    return null;
  }

  /// Weekly CHAMPIONS: per-galaxy bests weighted by galaxy difficulty and
  /// summed — height, galaxies opened, perfects, everything counts.
  Future<List<ChampionEntry>?> fetchChampions() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/leaderboard/top'), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        return ((j['entries'] ?? []) as List)
            .map((e) => ChampionEntry(
                e['name'] as String? ?? 'star',
                (e['score'] as num?)?.toInt() ?? 0,
                (e['height'] as num?)?.toInt() ?? 0,
                (e['galaxy'] as num?)?.toInt() ?? 0,
                e['gname'] as String? ?? '',
                (e['galaxies'] as num?)?.toInt() ?? 0,
                (e['perfects'] as num?)?.toInt() ?? 0,
                (e['prestige'] as num?)?.toInt() ?? 0))
            .toList();
      }
    } catch (_) {}
    return null;
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

/// One row of the weekly CHAMPIONS board (difficulty-weighted, all galaxies).
class ChampionEntry {
  const ChampionEntry(this.name, this.score, this.height, this.galaxy,
      this.galaxyName, this.galaxies, this.perfects, this.prestige);
  final String name;
  final int score; // sum of round(height x difficulty x 10) + 5/perfect
  final int height; // best height anywhere
  final int galaxy; // deepest galaxy flown
  final String galaxyName; // deepest galaxy's display name
  final int galaxies; // number of galaxies flown this week
  final int perfects;
  final int prestige;
}

/// Outcome of the alpha login form (api.enter).
class AuthResult {
  const AuthResult(
      {this.ok = false,
      this.created = false,
      this.wrongPassword = false,
      this.badInput = false,
      this.offline = false,
      this.name});
  final bool ok;
  final bool created; // true = this login just registered the pilot
  final bool wrongPassword;
  final bool badInput;
  final bool offline;
  final String? name;
}

/// A rival player's recorded run on a given universe seed.
class GhostRun {
  const GhostRun(this.name, this.height, this.path);
  final String name;
  final int height;
  final List<double> path; // x,y pairs @ 10 Hz
}

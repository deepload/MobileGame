import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One recorded run that flies again as a ghost Echo.
class EchoRecording {
  EchoRecording(
      {required this.dust,
      required this.height,
      required this.path,
      this.seed = 0});

  final int dust;
  final int height;
  final List<double> path; // x,y pairs sampled at 10 Hz
  final int seed; // universe it was flown in (aligns visually on replays)

  Map<String, dynamic> toJson() => {'d': dust, 'h': height, 'p': path, 's': seed};

  static EchoRecording fromJson(Map<String, dynamic> j) => EchoRecording(
        dust: j['d'] as int,
        height: j['h'] as int,
        path: (j['p'] as List).map((e) => (e as num).toDouble()).toList(),
        seed: (j['s'] as num?)?.toInt() ?? 0,
      );
}

/// One finished run — roguelite history: any universe can be replayed by seed.
class RunRecord {
  RunRecord(
      {required this.seed,
      required this.height,
      required this.dust,
      required this.perfects,
      required this.dateMs,
      this.galaxy = 0});

  final int seed;
  final int height;
  final int dust;
  final int perfects;
  final int dateMs;
  final int galaxy; // galaxy the run was flown in (replays return there)

  Map<String, dynamic> toJson() =>
      {'s': seed, 'h': height, 'd': dust, 'p': perfects, 't': dateMs, 'g': galaxy};

  static RunRecord fromJson(Map<String, dynamic> j) => RunRecord(
        seed: (j['s'] as num?)?.toInt() ?? 0,
        height: (j['h'] as num?)?.toInt() ?? 0,
        dust: (j['d'] as num?)?.toInt() ?? 0,
        perfects: (j['p'] as num?)?.toInt() ?? 0,
        dateMs: (j['t'] as num?)?.toInt() ?? 0,
        galaxy: (j['g'] as num?)?.toInt() ?? 0,
      );
}

/// Full player profile — the device is the source of truth (offline-first).
class SaveData {
  int dust = 0;
  int photons = 0;
  int prestige = 0;
  int bestHeight = 0;
  int bestThisPrestige = 0;
  int totalRuns = 0;
  Map<String, int> upgrades = {};
  List<EchoRecording> echoes = [];
  List<RunRecord> history = []; // most recent first, capped at 20
  int dailyKey = 0;
  List<int> dailyProg = [0, 0, 0];
  List<bool> dailyClaimed = [false, false, false];
  int galaxy = 0; // currently selected galaxy
  Map<String, int> galaxyBest = {}; // galaxy id -> best height (drives unlocks)
  int playSeconds = 0; // lifetime seconds spent in runs — wear it proudly
  List<String> skinsOwned = []; // market: purchased skin ids
  String skin = ''; // market: equipped skin id ('' = prestige tier color)

  double get globalMult => 1 + photons * 0.10;

  Map<String, dynamic> toJson() => {
        'dust': dust,
        'photons': photons,
        'prestige': prestige,
        'bestHeight': bestHeight,
        'bestThisPrestige': bestThisPrestige,
        'totalRuns': totalRuns,
        'upgrades': upgrades,
        'echoes': echoes.map((e) => e.toJson()).toList(),
        'hist': history.map((e) => e.toJson()).toList(),
        'dailyKey': dailyKey,
        'dailyProg': dailyProg,
        'dailyClaimed': dailyClaimed,
        'galaxy': galaxy,
        'gBest': galaxyBest,
        'playSeconds': playSeconds,
        'skins': skinsOwned,
        'skin': skin,
      };

  void loadJson(Map<String, dynamic> j) {
    dust = j['dust'] ?? 0;
    photons = j['photons'] ?? 0;
    prestige = j['prestige'] ?? 0;
    bestHeight = j['bestHeight'] ?? 0;
    bestThisPrestige = j['bestThisPrestige'] ?? 0;
    totalRuns = j['totalRuns'] ?? 0;
    upgrades = Map<String, int>.from(j['upgrades'] ?? {});
    echoes = ((j['echoes'] ?? []) as List)
        .map((e) => EchoRecording.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    history = ((j['hist'] ?? []) as List)
        .map((e) => RunRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    dailyKey = j['dailyKey'] ?? 0;
    dailyProg = List<int>.from(j['dailyProg'] ?? [0, 0, 0]);
    dailyClaimed = List<bool>.from(j['dailyClaimed'] ?? [false, false, false]);
    galaxy = j['galaxy'] ?? 0;
    galaxyBest = Map<String, int>.from(j['gBest'] ?? {});
    playSeconds = j['playSeconds'] ?? 0;
    skinsOwned = List<String>.from(j['skins'] ?? []);
    skin = j['skin'] ?? '';
  }
}

class Storage {
  Storage._(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'echoOrbitSave_v1';

  final SaveData data = SaveData();

  static Future<Storage> load() async {
    final s = Storage._(await SharedPreferences.getInstance());
    final raw = s._prefs.getString(_key);
    if (raw != null) {
      try {
        s.data.loadJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {/* corrupt save: start fresh */}
    }
    return s;
  }

  void save() => _prefs.setString(_key, jsonEncode(data.toJson()));

  /// Chosen pilot name — shown on leaderboards, ghosts and live multiplayer.
  String? get playerName => _prefs.getString('playerName');
  void setPlayerName(String? name) {
    if (name == null || name.isEmpty) {
      _prefs.remove('playerName');
    } else {
      _prefs.setString('playerName', name);
    }
  }

  /// Stable anonymous identity, one per server — without it every launch
  /// would create a brand-new player on the leaderboards.
  (String, String)? getAuth(String server) {
    final raw = _prefs.getString('auth:$server');
    if (raw == null) return null;
    final i = raw.indexOf('|');
    if (i <= 0) return null;
    return (raw.substring(0, i), raw.substring(i + 1)); // (uid, token)
  }

  void setAuth(String server, String uid, String token) =>
      _prefs.setString('auth:$server', '$uid|$token');

  void clearAuth(String server) => _prefs.remove('auth:$server');

  /// True once the pilot has REGISTERED (name+password) on this server —
  /// a locally chosen guest name is not enough to pass the login gate.
  bool isRegistered(String server) => _prefs.getBool('acct:$server') ?? false;
  void setRegistered(String server, bool v) =>
      v ? _prefs.setBool('acct:$server', true) : _prefs.remove('acct:$server');

  /// Private server override (compete with friends on any hosted backend).
  String? get serverUrl => _prefs.getString('serverUrl');
  void setServerUrl(String? url) {
    if (url == null || url.isEmpty) {
      _prefs.remove('serverUrl');
    } else {
      _prefs.setString('serverUrl', url);
    }
  }
}

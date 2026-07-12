import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

import '../services/api.dart';
import '../services/music.dart';
import '../services/storage.dart';

/// Palette (docs/03: "luminous minimalism").
class Palette {
  static const bgTop = Color(0xFF0B1026);
  static const bgBottom = Color(0xFF1B2350);
  static const mint = Color(0xFF5DF2C8);
  static const coral = Color(0xFFFF7E6B);
  static const lavender = Color(0xFF8E9BFF);
  static const gold = Color(0xFFFFD166);
  static const violet = Color(0xFFB388FF);
  static const text = Color(0xFFEAF2FF);
}

enum RunState { home, running, over }

/// A galaxy: its own look, difficulty, rewards and seed family.
/// Same core mechanic everywhere — the universe just gets meaner and richer.
class GalaxyDef {
  const GalaxyDef({
    required this.id,
    required this.name,
    required this.tagline,
    required this.bgTop,
    required this.bgBottom,
    required this.ring,
    required this.accent,
    required this.difficulty,
    required this.reward,
    required this.unlockHeight,
    required this.seedSalt,
  });

  final String id;
  final String name;
  final String tagline;
  final Color bgTop;
  final Color bgBottom;
  final Color ring;
  final Color accent;
  final double difficulty; // scales speed / ring size / storm rate
  final double reward; // scales all dust income
  final int unlockHeight; // reach this height in the PREVIOUS galaxy
  final int seedSalt; // seed family: same seed number = different universe
}

const galaxies = [
  GalaxyDef(
      id: 'lumen',
      name: 'LUMEN',
      tagline: 'Where every star is born',
      bgTop: Color(0xFF0B1026),
      bgBottom: Color(0xFF1B2350),
      ring: Color(0xFF8E9BFF),
      accent: Color(0xFF5DF2C8),
      difficulty: 1.0,
      reward: 1.0,
      unlockHeight: 0,
      seedSalt: 0),
  GalaxyDef(
      id: 'ember',
      name: 'EMBER NEBULA',
      tagline: 'Burning skies, richer dust',
      bgTop: Color(0xFF1A0B14),
      bgBottom: Color(0xFF3A1226),
      ring: Color(0xFFFF9E6B),
      accent: Color(0xFFFFD166),
      difficulty: 1.18,
      reward: 1.4,
      unlockHeight: 30,
      seedSalt: 741852963),
  GalaxyDef(
      id: 'frost',
      name: 'FROST VEIL',
      tagline: 'Fast, icy, unforgiving',
      bgTop: Color(0xFF05131F),
      bgBottom: Color(0xFF0E2C44),
      ring: Color(0xFF7DD8FF),
      accent: Color(0xFFB8F1FF),
      difficulty: 1.38,
      reward: 1.9,
      unlockHeight: 45,
      seedSalt: 159263487),
  GalaxyDef(
      id: 'void',
      name: 'VOID BLOOM',
      tagline: 'The edge of everything',
      bgTop: Color(0xFF0A0512),
      bgBottom: Color(0xFF1E0F33),
      ring: Color(0xFFB388FF),
      accent: Color(0xFFFF7E9B),
      difficulty: 1.6,
      reward: 2.6,
      unlockHeight: 60,
      seedSalt: 852741963),
];

/// Permanent upgrade definitions (docs/02 economy).
class UpgradeDef {
  const UpgradeDef(this.id, this.name, this.desc, this.base, this.max);
  final String id;
  final String name;
  final String desc;
  final int base;
  final int max;

  int cost(int level) => (base * math.pow(1.6, level)).round();
}

const upgradeDefs = [
  UpgradeDef('guide', 'Aim Guide', 'Longer launch preview line', 30, 6),
  UpgradeDef('magnet', 'Dust Magnet', 'Pull stardust from farther away', 40, 6),
  UpgradeDef('save', 'Save Ring', 'Extra rescue per run', 150, 2),
  UpgradeDef('slots', 'Echo Slots', 'More ghost runs earn beside you', 120, 2),
  UpgradeDef('yield', 'Echo Yield', 'Echoes earn a bigger share', 80, 6),
  UpgradeDef('keeper', 'Combo Keeper', 'Chance to keep combo when rescued', 100, 5),
  UpgradeDef('precision', 'Star Sense', 'Slightly wider capture window', 90, 5),
];

/// Daily challenge definitions.
class DailyDef {
  const DailyDef(this.label, this.target);
  final String label;
  final int target;
}

const dailyDefs = [
  DailyDef('Reach height 15 in one run', 15),
  DailyDef('Collect 250 stardust in one run', 250),
  DailyDef('3 Perfect Arcs in one run', 3),
];

int dayKey() {
  final d = DateTime.now();
  return d.year * 10000 + d.month * 100 + d.day;
}

class Ring {
  Ring({
    required this.index,
    required this.center,
    required this.radius,
    required this.omega,
    this.moveAmp = 0,
    this.movePhase = 0,
    this.storm = false,
  }) : baseX = center.x;

  final int index;
  final Vector2 center;
  final double baseX;
  final double radius;
  final double omega;
  final double moveAmp;
  final double movePhase;
  final bool storm;

  void update(double t) {
    if (moveAmp > 0) {
      center.x = baseX + math.sin(t * 0.8 + movePhase) * moveAmp;
    }
  }
}

class Mote {
  Mote(this.pos, this.value);
  final Vector2 pos;
  final int value;
  bool collected = false;
  double pull = 0;
}

class _Particle {
  _Particle(this.pos, this.vel, this.life, this.color);
  Vector2 pos;
  Vector2 vel;
  double life;
  double t = 0;
  final Color color;
}

class _FloatText {
  _FloatText(this.x, this.y, this.text, this.color, this.size);
  double x, y;
  final String text;
  final Color color;
  final double size;
  double t = 0;
}

class _Ghost {
  _Ghost(this.path, this.dustVal);
  final List<double> path;
  final int dustVal;
  double t = 0;
  bool done = false;
  double x = 0, y = 0;
}

/// Another player's run replaying live on the same universe (ghost racing).
class _Rival {
  _Rival(this.name, this.path);
  final String name;
  final List<double> path;
  double t = 0;
  bool done = false;
  double x = 0, y = 0;
}

/// Full game: run sim + complete meta (upgrades, echoes, prestige, dailies).
/// No physics engine — closed-form orbits (battery budget, docs/04).
class EchoOrbitGame extends FlameGame with TapCallbacks {
  EchoOrbitGame(this.storage, this.api);

  final Storage storage;
  final Api api;
  final MusicEngine music = MusicEngine();
  SaveData get profile => storage.data;

  // UI-observable state.
  final ValueNotifier<int> height = ValueNotifier(0);
  final ValueNotifier<int> runDust = ValueNotifier(0);
  final ValueNotifier<int> echoDust = ValueNotifier(0);
  final ValueNotifier<int> combo = ValueNotifier(0);
  final ValueNotifier<RunState> state = ValueNotifier(RunState.home);
  final ValueNotifier<String> toast = ValueNotifier('');
  final ValueNotifier<int> profileVersion = ValueNotifier(0); // bump = refresh UI
  int perfects = 0;
  bool doubleUsed = false;

  // Roguelite seeds: the universe is a pure function of the seed.
  int runSeed = 0;
  int? _remoteDailySeed;

  /// Everyone races the same universe today (server seed; offline mirrors it).
  int get dailySeed =>
      _remoteDailySeed ?? (dayKey() * 2654435761) % 4294967291;

  /* ---------- galaxies ---------- */
  GalaxyDef get galaxy =>
      galaxies[profile.galaxy.clamp(0, galaxies.length - 1)];

  /// Seed family: the same seed number is a different universe per galaxy.
  int get worldSeed => runSeed ^ galaxy.seedSalt;

  bool galaxyUnlocked(int i) {
    if (i <= 0) return true;
    if (i >= galaxies.length) return false;
    return (profile.galaxyBest[galaxies[i - 1].id] ?? 0) >=
        galaxies[i].unlockHeight;
  }

  void selectGalaxy(int i) {
    if (i < 0 || i >= galaxies.length || i == profile.galaxy) return;
    if (!galaxyUnlocked(i)) {
      _showToast(
          'Reach height ${galaxies[i].unlockHeight} in ${galaxies[i - 1].name} to unlock ${galaxies[i].name}');
      return;
    }
    profile.galaxy = i;
    storage.save();
    _resetWorld();
    profileVersion.value++;
  }

  static const spacing = 175.0;
  static const flightSpeed = 560.0;

  math.Random _rng = math.Random(0);
  final List<Ring> _rings = [];
  final List<Mote> _motes = [];
  final List<_Particle> _particles = [];
  final List<_FloatText> _floats = [];
  final List<Vector2> _trail = [];
  List<_Ghost> _ghosts = [];
  List<_Rival> _rivals = [];
  int _rivalFetchSeed = 0;

  // Star state.
  bool _flying = false;
  int _ringIndex = 0;
  int _lastRing = 0;
  double _angle = -math.pi / 2;
  final Vector2 _pos = Vector2.zero();
  final Vector2 _vel = Vector2.zero();
  double _flightDist = 0;
  int _saves = 1;
  double _camY = 0;
  double _time = 0;
  double _recT = 0;
  final List<double> _rec = [];
  double _echoFrac = 0;

  /* ---------- upgrade effects ---------- */
  int upgLevel(String id) => profile.upgrades[id] ?? 0;
  double get guideLen => 40 + upgLevel('guide') * 38;
  double get magnetR => 34 + upgLevel('magnet') * 16;
  int get savesMax => 1 + upgLevel('save');
  int get echoSlots => 1 + upgLevel('slots');
  double get echoYield => 0.10 + upgLevel('yield') * 0.05;
  double get keeperChance => upgLevel('keeper') * 0.15;
  double get precisionMult => 1 + upgLevel('precision') * 0.06;

  bool buyUpgrade(UpgradeDef def) {
    final lvl = upgLevel(def.id);
    final cost = def.cost(lvl);
    if (lvl >= def.max || profile.dust < cost) return false;
    profile.dust -= cost;
    profile.upgrades[def.id] = lvl + 1;
    storage.save();
    profileVersion.value++;
    return true;
  }

  /* ---------- prestige ---------- */
  bool get canPrestige => profile.bestThisPrestige >= 50;
  int get novaGain => math.max(
      1, math.pow(math.max(0, profile.bestThisPrestige - 40), 0.8).floor());

  void goSupernova() {
    profile.photons += novaGain;
    profile.prestige++;
    profile.dust = 0;
    profile.upgrades = {};
    profile.echoes = [];
    profile.bestThisPrestige = 0;
    storage.save();
    _showToast('SUPERNOVA - your star burns brighter');
    goHome();
  }

  /// Full wipe — a brand-new game (unlike Supernova, nothing survives).
  void resetProfile() {
    profile.loadJson(const {});
    storage.save();
    _resetWorld();
    profileVersion.value++;
    _showToast('Fresh start — good luck, little star');
  }

  Color tierColor() {
    const tiers = [
      Palette.mint,
      Color(0xFF7DD8FF),
      Palette.gold,
      Color(0xFFFF9E6B),
      Color(0xFFFF7E9B),
      Palette.violet,
      Color(0xFFFFFFFF),
    ];
    return tiers[math.min(profile.prestige, tiers.length - 1)];
  }

  /* ---------- dailies ---------- */
  void checkDailyReset() {
    if (profile.dailyKey != dayKey()) {
      profile.dailyKey = dayKey();
      profile.dailyProg = [0, 0, 0];
      profile.dailyClaimed = [false, false, false];
      storage.save();
    }
  }

  void _dailyProgress(int i, int v) {
    checkDailyReset();
    if (profile.dailyClaimed[i]) return;
    profile.dailyProg[i] = math.max(profile.dailyProg[i], v);
    if (profile.dailyProg[i] >= dailyDefs[i].target) {
      profile.dailyClaimed[i] = true;
      final reward = (100 * profile.globalMult).round();
      profile.dust += reward;
      _showToast('Daily complete!  +$reward stardust');
    }
  }

  void _showToast(String msg) {
    toast.value = msg;
    profileVersion.value++;
  }

  /* ---------- lifecycle ---------- */
  @override
  Color backgroundColor() => galaxy.bgTop;

  @override
  Future<void> onLoad() async {
    checkDailyReset();
    runSeed = dailySeed;
    // Fire-and-forget: adopt the server's daily seed when reachable.
    api.fetchDailySeed().then((s) {
      if (s != null) _remoteDailySeed = s;
    });
    _resetWorld();
    _camY = -size.y * 0.62;
    await music.init();
  }

  @override
  void onRemove() {
    music.dispose();
    super.onRemove();
  }

  void _resetWorld() {
    // Roguelite: the seed fully defines the universe. Echo ghosts align
    // perfectly when replaying the same seed; otherwise they are decorative.
    _rng = math.Random(worldSeed);
    _lastStormI = -99;
    _rings.clear();
    _motes.clear();
    _particles.clear();
    _floats.clear();
    _trail.clear();
    _addRing(first: true);
    while (_rings.length < 14) {
      _addRing();
    }
    _ringIndex = 0;
    _lastRing = 0;
    _flying = false;
    _angle = -math.pi / 2;
    _syncOrbitPos();
  }

  int _lastStormI = -99;

  void _addRing({bool first = false}) {
    final i = _rings.length;
    // Layer 1 — deterministic difficulty curve: identical for EVERY seed, so
    // height 40 is always "height-40 hard" and no universe is unfairly brutal.
    // Galaxy multiplier is part of layer 1: deterministic, same for all seeds
    // of that galaxy — harder galaxies stay fair from seed to seed.
    final gd = galaxy.difficulty;
    final breather = !first && i % 8 == 7; // guaranteed easy ring every bar
    final baseRadius =
        lerpDouble(63, 45, (i / 60).clamp(0, 1))! - (gd - 1) * 14;
    final speedUp = (1 + math.min(i * 0.012, 0.55)) * (1 + (gd - 1) * 0.65);
    final stormChance = (0.16 + math.min(i * 0.003, 0.24)) * gd;
    // Layer 2 — the seed only shuffles within those fair bounds.
    final radius = first
        ? 70.0
        : baseRadius + _rng.nextDouble() * 10 + (breather ? 8 : 0);
    final prevX = first ? size.x * 0.5 : _rings[i - 1].center.x;
    final x = first
        ? size.x * 0.5
        // Reachability guard: next ring stays within a fair horizontal leap.
        : (prevX + (_rng.nextDouble() - 0.5) * size.x * 0.5)
            .clamp(size.x * 0.28, size.x * 0.72);
    // Hazard guards: storms need i>9, never on breathers, min 5 rings apart.
    final canStorm = !first && !breather && i > 9 && i - _lastStormI >= 5;
    final storm = canStorm && _rng.nextDouble() < stormChance;
    if (storm) _lastStormI = i;
    // Movers: never on storms/breathers, never two in a row.
    final mover = !first &&
        !breather &&
        !storm &&
        i > 7 &&
        _rings[i - 1].moveAmp == 0 &&
        _rng.nextDouble() < 0.30;
    final ring = Ring(
      index: i,
      center: Vector2(x, -i * spacing),
      radius: radius,
      omega: (1.35 + _rng.nextDouble() * 0.5) *
          speedUp *
          (breather ? 0.85 : 1) *
          (_rng.nextBool() ? 1 : -1),
      moveAmp: mover ? 26 + _rng.nextDouble() * 34 : 0,
      movePhase: _rng.nextDouble() * math.pi * 2,
      storm: storm,
    );
    _rings.add(ring);
    if (!first) {
      final prev = _rings[_rings.length - 2];
      final n = storm ? 13 : 7;
      for (var k = 0; k < n; k++) {
        final t = (k + 1) / (n + 1);
        final Vector2 p;
        if (storm) {
          final a = _rng.nextDouble() * math.pi * 2;
          final d = ring.radius + 26 + _rng.nextDouble() * 20;
          p = Vector2(ring.center.x + math.cos(a) * d,
              ring.center.y + math.sin(a) * d);
        } else {
          p = Vector2(
            lerpDouble(prev.center.x, ring.center.x, t)! +
                (_rng.nextDouble() * 90 - 45),
            lerpDouble(prev.center.y, ring.center.y, t)! +
                (_rng.nextDouble() * 40 - 20),
          );
        }
        _motes.add(Mote(p, storm ? 3 : (_rng.nextDouble() < 0.25 ? 2 : 1)));
      }
    }
  }

  void _syncOrbitPos() {
    final r = _rings[_ringIndex];
    _pos
      ..setFrom(r.center)
      ..add(Vector2(math.cos(_angle), math.sin(_angle))..scale(r.radius));
  }

  void startRun({int? seed, int? galaxyIndex}) {
    checkDailyReset();
    if (galaxyIndex != null &&
        galaxyIndex != profile.galaxy &&
        galaxyUnlocked(galaxyIndex)) {
      profile.galaxy = galaxyIndex;
      storage.save();
    }
    runSeed = seed ?? dailySeed;
    _resetWorld();
    _camY = -size.y * 0.62;
    height.value = 0;
    runDust.value = 0;
    echoDust.value = 0;
    combo.value = 0;
    perfects = 0;
    doubleUsed = false;
    _saves = savesMax;
    _rec.clear();
    _recT = 0;
    _echoFrac = 0;
    _ghosts = profile.echoes
        .take(echoSlots)
        .map((e) => _Ghost(e.path, e.dust))
        .toList();
    // Ghost racing: fetch rival runs recorded on this exact universe.
    _rivals = [];
    final ws = worldSeed;
    _rivalFetchSeed = ws;
    api.fetchGhosts(ws).then((gs) {
      if (state.value == RunState.running && _rivalFetchSeed == ws) {
        _rivals = gs.map((g) => _Rival(g.name, g.path)).toList();
      }
    });
    state.value = RunState.running;
    music.setHeight(0);
    music.start();
  }

  void goHome() {
    _resetWorld();
    _ghosts = [];
    _rivals = [];
    music.stop();
    state.value = RunState.home;
    profileVersion.value++;
  }

  /// Rewarded-ad reward: double this run's income (ad flow lives in the UI).
  void grantDoubleDust() {
    if (doubleUsed) return;
    doubleUsed = true;
    final bonus = runDust.value + echoDust.value;
    profile.dust += bonus;
    storage.save();
    _showToast('x2!  +$bonus stardust');
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (state.value == RunState.running && !_flying) {
      final r = _rings[_ringIndex];
      final dir = r.omega.sign == 0 ? 1.0 : r.omega.sign;
      _vel.setValues(-math.sin(_angle) * dir, math.cos(_angle) * dir);
      _vel.scale(flightSpeed);
      _flying = true;
      _flightDist = 0;
    } else if (state.value == RunState.home) {
      startRun();
    }
  }

  /* ---------- update ---------- */
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    for (final r in _rings) {
      r.update(_time);
    }

    if (_flying) {
      _pos.add(_vel * dt);
      _flightDist += _vel.length * dt;
      _checkCapture();
      if (_flying && _isMiss()) _fall();
    } else {
      final r = _rings[_ringIndex];
      _angle += r.omega * dt;
      _syncOrbitPos();
    }

    _trail.add(_pos.clone());
    if (_trail.length > 30) _trail.removeAt(0);

    if (state.value == RunState.running) {
      music.setHeight(height.value);
      // record path @10 Hz for the future Echo (cap ~5 min)
      _recT += dt;
      if (_recT >= 0.1 && _rec.length < 6000) {
        _recT = 0;
        _rec..add(_pos.x)..add(_pos.y);
      }
      final targetY = _pos.y - size.y * 0.55;
      if (targetY < _camY) {
        _camY = lerpDouble(_camY, targetY, math.min(1, dt * 6))!;
      }
      _collectMotes(dt);
      _updateGhosts(dt);
      _updateRivals(dt);
    }

    for (var i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.t += dt;
      if (p.t > p.life) {
        _particles.removeAt(i);
      } else {
        p.pos.add(p.vel * dt);
        p.vel.scale(0.98);
      }
    }
    for (var i = _floats.length - 1; i >= 0; i--) {
      final f = _floats[i];
      f.t += dt;
      f.y -= 28 * dt;
      if (f.t > 1.1) _floats.removeAt(i);
    }
  }

  void _updateGhosts(double dt) {
    for (final g in _ghosts) {
      if (g.done) continue;
      g.t += dt;
      final idx = (g.t / 0.1).floor() * 2;
      if (idx >= g.path.length - 2) {
        g.done = true;
        continue;
      }
      final f = (g.t % 0.1) / 0.1;
      g.x = lerpDouble(g.path[idx], g.path[idx + 2], f)!;
      g.y = lerpDouble(g.path[idx + 1], g.path[idx + 3], f)!;
      final perSec = (g.dustVal * echoYield) / (g.path.length / 2 * 0.1);
      _echoFrac += perSec * dt * profile.globalMult;
      if (_echoFrac >= 25) {
        _echoFrac -= 25;
        echoDust.value += 25;
        _floats.add(_FloatText(g.x, g.y, '+25 echo', Palette.mint, 11));
      }
    }
  }

  void _updateRivals(double dt) {
    for (final r in _rivals) {
      if (r.done) continue;
      r.t += dt;
      final idx = (r.t / 0.1).floor() * 2;
      if (idx >= r.path.length - 2) {
        r.done = true;
        continue;
      }
      final f = (r.t % 0.1) / 0.1;
      r.x = lerpDouble(r.path[idx], r.path[idx + 2], f)!;
      r.y = lerpDouble(r.path[idx + 1], r.path[idx + 3], f)!;
    }
  }

  void _checkCapture() {
    final maxK = math.min(_ringIndex + 5, _rings.length);
    for (var k = _ringIndex + 1; k < maxK; k++) {
      final r = _rings[k];
      final d = _pos.distanceTo(r.center);
      if (d < r.radius * precisionMult) {
        // Perfect Arc = velocity line passes near the ring core
        // (impact parameter, docs/01 "through the center").
        final rel = r.center - _pos;
        final b = (_vel.x * rel.y - _vel.y * rel.x).abs() / _vel.length;
        _capture(r, perfect: b < r.radius * 0.34);
        return;
      }
    }
  }

  bool _isMiss() =>
      _pos.y > _camY + size.y + 80 ||
      _flightDist > math.max(size.y * 1.5, 1200) ||
      _pos.x < -size.x * 0.4 ||
      _pos.x > size.x * 1.4;

  void _capture(Ring r, {required bool perfect}) {
    final skipped = r.index - _lastRing > 1;
    _flying = false;
    _ringIndex = r.index;
    _lastRing = r.index;
    _angle = math.atan2(_pos.y - r.center.y, _pos.x - r.center.x);
    if (r.index > height.value) height.value = r.index;
    if (perfect) {
      perfects++;
      combo.value++;
      _floats.add(_FloatText(_pos.x, _pos.y - 30, 'PERFECT x2', Palette.coral, 17));
    } else if (skipped) {
      combo.value += 2;
      _floats.add(_FloatText(_pos.x, _pos.y - 48, 'SKIP! +combo', Palette.mint, 14));
    }
    final gain = (5 *
            (1 + 0.1 * combo.value) *
            (perfect ? 2 : 1) *
            (skipped ? 2 : 1) *
            profile.globalMult *
            galaxy.reward)
        .round();
    runDust.value += gain;
    _floats.add(_FloatText(_pos.x, _pos.y - 12, '+$gain', Palette.gold, 13));
    _burst(perfect ? Palette.coral : tierColor(), perfect ? 16 : 9);
    _dailyProgress(0, r.index);
    while (_rings.length < r.index + 14) {
      _addRing();
    }
  }

  void _fall() {
    if (_saves > 0) {
      _saves--;
      _flying = false;
      final r = _rings[_ringIndex];
      _angle = math.atan2(_pos.y - r.center.y, _pos.x - r.center.x);
      _syncOrbitPos();
      _floats.add(
          _FloatText(_pos.x, _pos.y - 24, 'SAVED! ($_saves left)', Palette.mint, 16));
      _burst(Palette.mint, 14);
      if (_rng.nextDouble() >= keeperChance) {
        combo.value = 0;
      } else {
        _floats.add(_FloatText(_pos.x, _pos.y + 16, 'combo kept!', Palette.gold, 12));
      }
      return;
    }
    _endRun();
  }

  void _endRun() {
    state.value = RunState.over;
    music.stop();
    profile.totalRuns++;
    profile.dust += runDust.value + echoDust.value;
    if (height.value > profile.bestHeight) profile.bestHeight = height.value;
    if (height.value > profile.bestThisPrestige) {
      profile.bestThisPrestige = height.value;
    }
    _dailyProgress(1, runDust.value);
    _dailyProgress(2, perfects);
    // Galaxy progression: track per-galaxy best; unlocking is derived from it.
    final gi = profile.galaxy;
    final nextWasLocked = !galaxyUnlocked(gi + 1);
    if (height.value > (profile.galaxyBest[galaxy.id] ?? 0)) {
      profile.galaxyBest[galaxy.id] = height.value;
      if (nextWasLocked && galaxyUnlocked(gi + 1)) {
        _showToast('NEW GALAXY UNLOCKED: ${galaxies[gi + 1].name}');
      }
    }
    // Roguelite history: any past universe can be replayed by its seed.
    profile.history.insert(
        0,
        RunRecord(
            seed: runSeed,
            height: height.value,
            dust: runDust.value + echoDust.value,
            perfects: perfects,
            dateMs: DateTime.now().millisecondsSinceEpoch,
            galaxy: gi));
    if (profile.history.length > 20) {
      profile.history = profile.history.sublist(0, 20);
    }
    // Record this run as an Echo candidate (keep top 3 by dust).
    if (_rec.length > 20) {
      profile.echoes.add(EchoRecording(
          dust: runDust.value,
          height: height.value,
          path: List.of(_rec),
          seed: runSeed));
      profile.echoes.sort((a, b) => b.dust.compareTo(a.dust));
      if (profile.echoes.length > 3) {
        profile.echoes = profile.echoes.sublist(0, 3);
      }
    }
    storage.save();
    profileVersion.value++;
    // Fire-and-forget backend sync (offline-first: failures are silent).
    api.submitScore(height.value, perfects, profile.prestige);
    api.pushSave(profile);
    // Ghost racing: publish this run so others on the same universe race it.
    if (height.value >= 3 && _rec.length > 20) {
      api.submitGhost(worldSeed, height.value, List.of(_rec));
    }
  }

  void _collectMotes(double dt) {
    for (final m in _motes) {
      if (m.collected) continue;
      final d = m.pos.distanceTo(_pos);
      if (d < magnetR) {
        m.pull = math.min(1, m.pull + dt * 4);
        m.pos.add((_pos - m.pos)..scale(m.pull * dt * 9));
      }
      if (d < 20) {
        m.collected = true;
        final g = (m.value * profile.globalMult * galaxy.reward).round();
        runDust.value += g;
        _floats.add(_FloatText(m.pos.x, m.pos.y, '+$g', Palette.gold, 11));
      }
    }
  }

  void _burst(Color color, int n) {
    for (var i = 0; i < n; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final s = 60 + _rng.nextDouble() * 160;
      _particles.add(_Particle(
        _pos.clone(),
        Vector2(math.cos(a), math.sin(a))..scale(s),
        0.5 + _rng.nextDouble() * 0.3,
        color,
      ));
    }
    if (_particles.length > 220) {
      _particles.removeRange(0, _particles.length - 220);
    }
  }

  /* ---------- render ---------- */
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final shift = ((state.value == RunState.running ? height.value : 0) / 120)
        .clamp(0.0, 1.0);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = Gradient.linear(rect.topCenter, rect.bottomCenter, [
          // Galaxy theme: sky warms toward the accent as you climb.
          Color.lerp(galaxy.bgTop, galaxy.accent, shift * 0.22)!,
          galaxy.bgBottom,
        ]),
    );

    canvas.save();
    canvas.translate(0, -_camY);

    // motes
    final motePaint = Paint()..color = Palette.gold;
    final stormPaint = Paint()..color = const Color(0xFFFFE9A8);
    for (final m in _motes) {
      if (m.collected) continue;
      if (m.pos.y < _camY - 40 || m.pos.y > _camY + size.y + 40) continue;
      canvas.drawCircle(m.pos.toOffset(), m.value >= 3 ? 5 : (m.value == 2 ? 4 : 3),
          m.value >= 3 ? stormPaint : motePaint);
    }

    // rings (galaxy-themed)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = galaxy.ring.withValues(alpha: 0.8);
    final stormRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Palette.gold.withValues(alpha: 0.85);
    final corePaint = Paint()..color = galaxy.ring.withValues(alpha: 0.35);
    for (final r in _rings) {
      if (r.center.y < _camY - 120 || r.center.y > _camY + size.y + 120) continue;
      canvas.drawCircle(r.center.toOffset(), r.radius, r.storm ? stormRing : ringPaint);
      canvas.drawCircle(r.center.toOffset(), 3, corePaint);
      if (r.index > 0 && r.index % 10 == 0) {
        _drawText(canvas, '${r.index}', r.center.x, r.center.y - r.radius - 18,
            Palette.text.withValues(alpha: 0.28), 13);
      }
    }

    // echo ghosts
    final ghostPaint = Paint()..color = Palette.mint.withValues(alpha: 0.35);
    for (final g in _ghosts) {
      if (g.done) continue;
      canvas.drawCircle(Offset(g.x, g.y), 7, ghostPaint);
    }

    // rival ghosts (other players on this universe) — named so you know
    // exactly who you are beating.
    final rivalPaint = Paint()..color = Palette.coral.withValues(alpha: 0.45);
    for (final r in _rivals) {
      if (r.done) continue;
      canvas.drawCircle(Offset(r.x, r.y), 7, rivalPaint);
      _drawText(canvas, r.name, r.x, r.y - 14,
          Palette.coral.withValues(alpha: 0.75), 9);
    }

    // aim guide — dashed arrow showing the launch direction (forward on purpose)
    if (state.value == RunState.running && !_flying) {
      final r = _rings[_ringIndex];
      final dir = r.omega.sign == 0 ? 1.0 : r.omega.sign;
      final tangent = Vector2(-math.sin(_angle) * dir, math.cos(_angle) * dir);
      final guidePaint = Paint()
        ..color = Palette.mint.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      const dash = 4.0, gap = 7.0;
      var offset = 12.0; // start a little away from the star
      while (offset + dash < guideLen) {
        canvas.drawLine(
          (_pos + tangent * offset).toOffset(),
          (_pos + tangent * (offset + dash)).toOffset(),
          guidePaint,
        );
        offset += dash + gap;
      }
      // arrowhead
      final tip = _pos + tangent * guideLen;
      final perp = Vector2(-tangent.y, tangent.x);
      canvas.drawLine(tip.toOffset(),
          (tip - tangent * 8 + perp * 5).toOffset(), guidePaint);
      canvas.drawLine(tip.toOffset(),
          (tip - tangent * 8 - perp * 5).toOffset(), guidePaint);
    }

    // trail + star — comet tail: fades & thins toward the oldest point
    final tc = tierColor();
    for (var i = 1; i < _trail.length; i++) {
      final f = i / _trail.length; // 0 = tail tip, 1 = at the star
      canvas.drawLine(
        _trail[i - 1].toOffset(),
        _trail[i].toOffset(),
        Paint()
          ..color = tc.withValues(alpha: f * f * 0.6)
          ..strokeWidth = 1 + f * 4.5
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(_pos.toOffset(), 9, Paint()..color = tc);
    canvas.drawCircle(_pos.toOffset(), 4, Paint()..color = const Color(0xFFFFFFFF));

    // particles
    for (final p in _particles) {
      canvas.drawRect(
        Rect.fromCenter(center: p.pos.toOffset(), width: 4, height: 4),
        Paint()..color = p.color.withValues(alpha: (1 - p.t / p.life).clamp(0, 1)),
      );
    }
    // float texts
    for (final f in _floats) {
      _drawText(canvas, f.text, f.x, f.y,
          f.color.withValues(alpha: (1 - f.t / 1.1).clamp(0, 1)), f.size);
    }

    canvas.restore();
  }

  void _drawText(
      Canvas canvas, String text, double x, double y, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color, fontSize: size, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }
}

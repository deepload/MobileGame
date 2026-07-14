import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart'
    show HSLColor, TextPainter, TextSpan, TextStyle;

import '../services/api.dart';
import '../services/live.dart';
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

const _gNameA = [
  'CRIMSON', 'AZURE', 'OBSIDIAN', 'SOLAR', 'PHANTOM', 'RADIANT',
  'ASHEN', 'ETERNAL', 'SHATTERED', 'HOLLOW', 'GILDED', 'SILENT',
];
const _gNameB = [
  'DRIFT', 'CROWN', 'ABYSS', 'CASCADE', 'SPIRE', 'HALO',
  'EXPANSE', 'REACH', 'TEMPEST', 'GARDEN', 'FORGE', 'VEIL',
];

final Map<int, GalaxyDef> _galaxyCache = {};

/// LORE: every universe is 12 galaxies deep and ends at a LIGHT — the end of
/// its story. Crossing a Light is the tryhard grail... and reveals the next
/// universe. The ladder itself never ends.
const universeLen = 12;

const _lightOrdinals = [
  'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'FIFTH', 'SIXTH',
  'SEVENTH', 'EIGHTH', 'NINTH', 'TENTH', 'ELEVENTH', 'TWELFTH',
];

/// 1-based universe number a galaxy index belongs to.
int universeOf(int i) => i ~/ universeLen + 1;

/// True for the last galaxy of a universe — the story's end gate.
bool isLightGate(int i) => i % universeLen == universeLen - 1;

String lightName(int u) => u <= _lightOrdinals.length
    ? 'THE ${_lightOrdinals[u - 1]} LIGHT'
    : 'THE LIGHT $u';

/// Endless galaxy ladder: the first 4 are handcrafted, everything beyond is
/// generated deterministically forever. Balance rule: rewards grow slightly
/// faster than difficulty, so pushing deeper is always the optimal play —
/// there is no end for speedrunners and tryharders.
/// IMPORTANT: difficulty stays 1.6 + k*0.12 for ALL procedural galaxies
/// (Light gates included) — the server mirrors this exact curve for scoring.
GalaxyDef galaxyAt(int i) {
  if (i < 0) return galaxies[0];
  if (i < galaxies.length) return galaxies[i];
  return _galaxyCache.putIfAbsent(i, () {
    final k = i - (galaxies.length - 1); // sectors past VOID BLOOM
    final hue = (i * 47.0) % 360;
    final gate = isLightGate(i);
    return GalaxyDef(
      id: 'gx$i',
      name: gate
          ? lightName(universeOf(i))
          : '${_gNameA[i * 7 % _gNameA.length]} ${_gNameB[i * 13 % _gNameB.length]}${i >= 16 ? ' $k' : ''}',
      tagline: gate
          ? 'The end of the story — or a door'
          : 'Uncharted space — sector $k',
      bgTop: gate
          ? const Color(0xFF0B0A07)
          : HSLColor.fromAHSL(1, hue, 0.55, 0.06).toColor(),
      bgBottom: gate
          ? const Color(0xFF2B2416)
          : HSLColor.fromAHSL(1, (hue + 24) % 360, 0.50, 0.14).toColor(),
      ring: gate
          ? const Color(0xFFFFF3C4)
          : HSLColor.fromAHSL(1, (hue + 180) % 360, 0.85, 0.72).toColor(),
      accent: gate
          ? const Color(0xFFFFFFFF)
          : HSLColor.fromAHSL(1, (hue + 120) % 360, 0.90, 0.70).toColor(),
      difficulty: 1.6 + k * 0.12,
      reward: 2.6 * math.pow(1.30, k).toDouble(),
      unlockHeight: 60 + k * 12,
      seedSalt: (i * 2654435761) & 0x7fffffffffff,
    );
  });
}

/* ---------- galaxy mutations (deep-space rule twists) ---------- */

/// Every procedural galaxy (5+) carries ONE seeded rule twist — a reason to
/// scout ahead and pick your hunting ground. Pure function of the galaxy
/// index: identical for every player = fair racing. Light gates stay pure
/// (classic rules), and no rng draws are added or removed, so world
/// generation stays deterministic per seed.
class MutationDef {
  const MutationDef(this.id, this.name, this.up, this.down,
      {this.radiusMult = 1,
      this.omegaMult = 1,
      this.moverBoost = 1,
      this.stormBoost = 1,
      this.bumperBoost = 1,
      this.moteMult = 1});
  final String id, name, up, down;
  final double radiusMult; // ring size
  final double omegaMult; // orbit spin speed
  final double moverBoost; // drifting-ring chance
  final double stormBoost; // storm chance
  final double bumperBoost; // pulsar bumper chance
  final double moteMult; // mote dust value
}

const mutationDefs = [
  MutationDef('drift', 'UNSTABLE ORBITS', 'motes x1.4', 'rings drift wildly',
      moverBoost: 2.2, moteMult: 1.4),
  MutationDef('storm', 'STORMLANDS', 'motes x1.25', 'storms strike often',
      stormBoost: 1.6, moteMult: 1.25),
  MutationDef('hyper', 'HYPERSPIN', 'rings 15% wider', 'spin x1.25',
      omegaMult: 1.25, radiusMult: 1.15),
  MutationDef('dwarf', 'DWARF STARS', 'motes x1.6', 'rings 15% smaller',
      radiusMult: 0.85, moteMult: 1.6),
  MutationDef('pulsar', 'PULSAR FIELD', 'bumpers everywhere', 'pinball chaos',
      bumperBoost: 2.3),
  MutationDef('calm', 'SLOW NEBULA', 'spin x0.85', 'motes x0.7',
      omegaMult: 0.85, moteMult: 0.7),
];

/// The mutation of a galaxy — null for the 4 handcrafted ones & Light gates.
MutationDef? mutationAt(int i) {
  if (i < galaxies.length || isLightGate(i)) return null;
  return mutationDefs[math.Random(i * 7919).nextInt(mutationDefs.length)];
}

/* ---------- pilot ranks (career ladder — the tryhard identity) ---------- */

/// Rank points use the same math as the weekly Champions board
/// (height x galaxy difficulty x 10), but over your CAREER bests —
/// permanent, offline-computable, impossible to farm in easy galaxies.
class RankDef {
  const RankDef(this.name, this.points, this.color);
  final String name;
  final int points; // career points required
  final Color color;
}

const rankDefs = [
  RankDef('STARDUST', 0, Color(0xFF8E9BFF)),
  RankDef('SPARK', 300, Color(0xFF5DF2C8)),
  RankDef('COMET', 1000, Color(0xFF7DD8FF)),
  RankDef('NOVA', 2600, Color(0xFFFFD166)),
  RankDef('PULSAR', 6000, Color(0xFFFF9E6B)),
  RankDef('QUASAR', 13000, Color(0xFFFF7E9B)),
  RankDef('SINGULARITY', 28000, Color(0xFFB388FF)),
  RankDef('FIRST LIGHT', 60000, Color(0xFFFFFFFF)),
];

/// Galaxy index from a SaveData.galaxyBest key ('lumen'... or 'gx17').
int galaxyIndexOf(String id) {
  for (var i = 0; i < galaxies.length; i++) {
    if (galaxies[i].id == id) return i;
  }
  return id.startsWith('gx') ? (int.tryParse(id.substring(2)) ?? 0) : 0;
}

/// Display name for a rank index — endless above FIRST LIGHT (✕2, ✕3...).
String rankName(int idx) => idx < rankDefs.length
    ? rankDefs[idx].name
    : '${rankDefs.last.name} ✕${idx - rankDefs.length + 2}';

Color rankColor(int idx) => rankDefs[math.min(idx, rankDefs.length - 1)].color;

/// Permanent upgrade definitions (docs/02 economy).
///
/// Endless progression (tryhard-friendly): no level caps. Balance comes from
/// two opposing curves — effects follow soft asymptotes l/(l+c) (every level
/// helps, none ever breaks the game) while costs grow geometrically faster
/// than income, so each next level is a real goal, forever.
class UpgradeDef {
  const UpgradeDef(this.id, this.name, this.desc, this.base,
      {this.growth = 1.7});
  final String id;
  final String name;
  final String desc;
  final int base;
  final double growth;

  int cost(int level) => (base * math.pow(growth, level)).round();
}

const upgradeDefs = [
  UpgradeDef('guide', 'Aim Guide', 'Longer launch preview line', 60),
  UpgradeDef('magnet', 'Dust Magnet', 'Pull stardust from farther away', 80),
  UpgradeDef('save', 'Save Ring', 'Extra rescue per run', 400, growth: 2.2),
  UpgradeDef('slots', 'Echo Slots', 'More ghost runs earn beside you', 300,
      growth: 2.0),
  UpgradeDef('yield', 'Echo Yield', 'Echoes earn a bigger share', 160,
      growth: 1.75),
  UpgradeDef('keeper', 'Combo Keeper', 'Chance to keep combo when rescued', 200,
      growth: 1.75),
  UpgradeDef('precision', 'Star Sense', 'Slightly wider capture window', 180,
      growth: 1.8),
];

/// Market cosmetics: skins recolor your star and its comet trail.
/// Pure style — no gameplay power, so competition stays fair.
class SkinDef {
  const SkinDef(this.id, this.name, this.desc, this.color, this.cost,
      {this.premium = false});
  final String id;
  final String name;
  final String desc;
  final Color color;
  final int cost; // stardust — or photons when premium
  final bool premium;
}

const skinDefs = [
  SkinDef('comet', 'Comet Blue', 'Cool and steady', Color(0xFF6BB8FF), 1500),
  SkinDef('jade', 'Deep Jade', 'Old-forest calm', Color(0xFF4CE0A0), 3500),
  SkinDef('rose', 'Rose Nova', 'Sweet but deadly', Color(0xFFFF7EC2), 8000),
  SkinDef('ember', 'Ember Heart', 'Runs hot', Color(0xFFFF8A50), 16000),
  SkinDef('solar', 'Solar Flare', 'Blinding pace', Color(0xFFFFE066), 32000),
  SkinDef('aurora', 'Aurora', 'Northern lights made star', Color(0xFF9DFFE8), 3,
      premium: true),
  SkinDef('void', 'Void Touched', 'It looked back', Color(0xFFC58CFF), 8,
      premium: true),
  SkinDef('singular', 'Singularity', 'All light, no escape', Color(0xFFFFFFFF), 20,
      premium: true),
];

/// SIGILS — run-defining pacts offered at height milestones (pick 1 of 3).
/// Every sigil gives AND takes; stacking them turns a run into a build.
/// Offers are seeded from the world seed: same universe = same choices
/// for every racer. Fairness first, Balatro-style variety second.
class SigilDef {
  const SigilDef(this.id, this.name, this.up, this.down,
      {this.dustMult = 1,
      this.captureMult = 1,
      this.perfectMult = 1,
      this.speedMult = 1,
      this.spinMult = 1,
      this.magnetMult = 1,
      this.echoMult = 1,
      this.comboMult = 1,
      this.skipBonus = 0,
      this.savesDelta = 0,
      this.noSaves = false});
  final String id;
  final String name;
  final String up; // what it gives
  final String down; // what it costs
  final double dustMult;
  final double captureMult; // capture window scale
  final double perfectMult; // perfect-arc window scale
  final double speedMult; // launch speed scale
  final double spinMult; // orbit spin scale
  final double magnetMult;
  final double echoMult; // echo income scale
  final double comboMult; // scales the +10%-per-combo step
  final int skipBonus; // extra combo on ring skips
  final int savesDelta; // instant rescue change when picked
  final bool noSaves; // GLASS STAR: no rescues at all
}

const sigilDefs = [
  SigilDef('glass', 'GLASS STAR', 'All dust x2',
      'No rescues — one mistake ends the run',
      dustMult: 2, noSaves: true),
  SigilDef('gravity', 'GRAVITY KISS', 'Capture window +30%',
      'Combo builds half as fast',
      captureMult: 1.3, comboMult: 0.5),
  SigilDef('comet', 'COMET HEART', 'Launch +25% faster · dust +50%',
      'Capture window -15%',
      speedMult: 1.25, dustMult: 1.5, captureMult: 0.85),
  SigilDef('still', 'STILL SKY', 'Rings spin 25% slower', 'Dust -30%',
      spinMult: 0.75, dustMult: 0.7),
  SigilDef('bloom', 'ECHO BLOOM', 'Echo income x2', 'Your own dust -25%',
      echoMult: 2, dustMult: 0.75),
  SigilDef('phoenix', 'PHOENIX FEATHER', '+1 rescue right now',
      'Perfect window -30%',
      savesDelta: 1, perfectMult: 0.7),
  SigilDef('wild', 'WILD ARC', 'Ring skips give +4 combo',
      'Launch +15% faster — hold on',
      skipBonus: 2, speedMult: 1.15),
  SigilDef('tide', 'GOLD TIDE', 'Magnet radius x2', 'Rings spin +15% faster',
      magnetMult: 2, spinMult: 1.15),
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
  double flash = 0; // 1 → 0 blink after the star leaves this ring

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

/// Pulsar bumper (galaxy 5+): a pinball pin floating between rings.
/// Clip it mid-flight to bank off with a speed kick, dust and +combo.
class Bumper {
  Bumper(this.pos, this.r);
  final Vector2 pos;
  final double r;
  double hitT = 0; // >0 = just hit: flash + short re-hit cooldown
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

class _Star {
  _Star(this.x, this.y, this.size, this.par, this.phase, this.tint);
  final double x, y, size;
  final double par; // parallax factor (0 = fixed sky, 1 = world speed)
  final double phase; // twinkle offset
  final bool tint; // a few stars take the galaxy accent color
}

class _Nebula {
  _Nebula(this.x, this.y, this.radius, this.par, this.color);
  final double x, y, radius, par;
  final Color color;
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
  final LiveRoom live = LiveRoom(); // real players in this universe, right now
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

  /* ---------- galaxies (endless ladder) ---------- */
  GalaxyDef get galaxy => galaxyAt(profile.galaxy);

  /// Seed family: the same seed number is a different universe per galaxy.
  int get worldSeed => runSeed ^ galaxy.seedSalt;

  bool galaxyUnlocked(int i) {
    if (i <= 0) return true;
    return (profile.galaxyBest[galaxyAt(i - 1).id] ?? 0) >=
        galaxyAt(i).unlockHeight;
  }

  void selectGalaxy(int i) {
    if (i < 0 || i == profile.galaxy) return;
    if (!galaxyUnlocked(i)) {
      _showToast(
          'Reach height ${galaxyAt(i).unlockHeight} in ${galaxyAt(i - 1).name} to unlock ${galaxyAt(i).name}');
      return;
    }
    profile.galaxy = i;
    storage.save();
    music.setTheme(worldSeed, galaxy.difficulty);
    _resetWorld();
    profileVersion.value++;
  }

  static const spacing = 175.0;
  static const flightSpeed = 560.0;

  math.Random _rng = math.Random(0);
  final List<Ring> _rings = [];
  final List<Mote> _motes = [];
  final List<Bumper> _bumpers = [];
  final List<_Particle> _particles = [];
  final List<_FloatText> _floats = [];
  final List<Vector2> _trail = [];
  List<_Ghost> _ghosts = [];
  List<_Rival> _rivals = [];
  int _rivalFetchSeed = 0;

  // Procedural space sky (per-galaxy starfield + nebulae).
  final List<_Star> _stars = [];
  final List<_Nebula> _nebulae = [];
  int _skyGalaxy = -1;
  double _skyW = 0, _skyH = 0;

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
  double _liveT = 0; // live-position send throttle (~10 Hz)
  double _playAcc = 0; // sub-second play-time accumulator
  double _pingT = 0; // server health-check countdown (home screen)
  bool _pinging = false;

  /* ---------- upgrade effects (soft asymptotes — endless but bounded) ---- */
  int upgLevel(String id) => profile.upgrades[id] ?? 0;
  double get guideLen => 40 + 170 * _soft(upgLevel('guide'), 6);
  double get magnetR => 34 + 90 * _soft(upgLevel('magnet'), 8);
  int get savesMax => 1 + upgLevel('save');
  int get echoSlots => 1 + upgLevel('slots');
  double get echoYield => 0.10 + 0.60 * _soft(upgLevel('yield'), 8);
  double get keeperChance => 0.90 * _soft(upgLevel('keeper'), 5);
  double get precisionMult => 1 + 0.5 * _soft(upgLevel('precision'), 7);

  static double _soft(int l, int c) => l / (l + c);

  /// Human-readable effect at a given level — shown as "now → next" in the
  /// shop so progression is always understandable.
  String upgValue(String id, int l) => switch (id) {
        'guide' => '${(40 + 170 * _soft(l, 6)).round()} reach',
        'magnet' => '${(34 + 90 * _soft(l, 8)).round()} range',
        'save' => '${1 + l} rescues',
        'slots' => '${1 + l} echoes',
        'yield' => '${(100 * (0.10 + 0.60 * _soft(l, 8))).round()}%',
        'keeper' => '${(90 * _soft(l, 5)).round()}%',
        'precision' => '+${(50 * _soft(l, 7)).round()}% window',
        _ => '',
      };

  bool buyUpgrade(UpgradeDef def) {
    final lvl = upgLevel(def.id);
    final cost = def.cost(lvl);
    if (profile.dust < cost) return false;
    profile.dust -= cost;
    profile.upgrades[def.id] = lvl + 1;
    storage.save();
    profileVersion.value++;
    return true;
  }

  /* ---------- market (cosmetics) ---------- */
  /// The Market opens once the first run is done (i.e. after the tutorial).
  bool get marketUnlocked => profile.totalRuns >= 1;
  bool ownsSkin(String id) => profile.skinsOwned.contains(id);

  bool buySkin(SkinDef def) {
    if (ownsSkin(def.id)) return false;
    if (def.premium) {
      if (profile.photons < def.cost) return false;
      profile.photons -= def.cost;
    } else {
      if (profile.dust < def.cost) return false;
      profile.dust -= def.cost;
    }
    profile.skinsOwned.add(def.id);
    profile.skin = def.id; // wear it right away
    storage.save();
    profileVersion.value++;
    return true;
  }

  void equipSkin(String id) {
    if (id.isNotEmpty && !ownsSkin(id)) return;
    profile.skin = id;
    storage.save();
    profileVersion.value++;
  }

  /// Star + trail color: equipped market skin, else the prestige tier color.
  Color starColor() {
    for (final s in skinDefs) {
      if (s.id == profile.skin) return s.color;
    }
    return tierColor();
  }

  /* ---------- sigils (run builds) ---------- */
  final List<SigilDef> sigils = []; // active pacts, this run only
  final ValueNotifier<List<SigilDef>?> sigilOffer = ValueNotifier(null);
  final ValueNotifier<int> sigilVersion = ValueNotifier(0); // HUD refresh
  int _sigilCount = 0;
  int _nextSigilAt = 10; // heights 10, 24, 40, then every +25

  bool hasSigil(String id) => sigils.any((s) => s.id == id);

  /// Product of one multiplier across every active sigil.
  double _sig(double Function(SigilDef s) f) =>
      sigils.fold(1.0, (m, s) => m * f(s));

  void _offerSigils() {
    final pool = sigilDefs.where((s) => !hasSigil(s.id)).toList();
    if (pool.length < 3) return;
    // Seeded by universe + offer number: same seed = same three cards
    // for every racer — builds differ by CHOICE, never by luck.
    pool.shuffle(math.Random(worldSeed ^ ((_sigilCount + 1) * 40503)));
    sigilOffer.value = pool.take(3).toList();
  }

  /// Tap a card (or pass). The star keeps orbiting while you decide —
  /// choosing is always safe, launching waits for you.
  void pickSigil(SigilDef? s) {
    if (sigilOffer.value == null) return;
    if (s != null) {
      sigils.add(s);
      _saves = math.max(0, _saves + s.savesDelta);
      if (s.noSaves) _saves = 0;
      _floats.add(_FloatText(_pos.x, _pos.y - 30, s.name, Palette.violet, 15));
      _burst(Palette.violet, 12);
    }
    sigilOffer.value = null;
    _sigilCount++;
    _nextSigilAt = _sigilCount < 3
        ? const [10, 24, 40][_sigilCount]
        : 40 + (_sigilCount - 2) * 25;
    sigilVersion.value++;
  }

  void _resetSigils() {
    sigils.clear();
    sigilOffer.value = null;
    _sigilCount = 0;
    _nextSigilAt = 10;
    sigilVersion.value++;
  }

  /* ---------- galaxy mutation (current) ---------- */
  MutationDef? get mutation => mutationAt(profile.galaxy);

  /// Current mutation multiplier (1 when flying classic space).
  double _mut(double Function(MutationDef m) f) {
    final m = mutation;
    return m == null ? 1 : f(m);
  }

  /* ---------- career rank ---------- */
  /// Champions math over career bests: height x difficulty x 10 per galaxy.
  int careerPoints() {
    var pts = 0;
    profile.galaxyBest.forEach((id, best) {
      pts += (best * galaxyAt(galaxyIndexOf(id)).difficulty * 10).round();
    });
    return pts;
  }

  int get rankIndex {
    final p = careerPoints();
    var idx = 0;
    for (var i = 1; i < rankDefs.length; i++) {
      if (p >= rankDefs[i].points) idx = i;
    }
    // Endless tail: every 30k career points past FIRST LIGHT is another ✕.
    if (p >= rankDefs.last.points) idx += (p - rankDefs.last.points) ~/ 30000;
    return idx;
  }

  /// Career points needed for the next rank (endless past FIRST LIGHT).
  int nextRankAt() {
    final i = rankIndex;
    if (i + 1 < rankDefs.length) return rankDefs[i + 1].points;
    return rankDefs.last.points + (i - rankDefs.length + 2) * 30000;
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

  /// Pilot name shown on leaderboards, ghost races and live rooms.
  String get playerName => api.playerName;
  bool get hasCustomName => (storage.playerName ?? '').isNotEmpty;

  /// ALPHA login: first time = registers the pilot, next times = same two
  /// fields. Offline falls back to a local guest name that syncs later.
  Future<bool> login(String name, String password) async {
    final n = name.trim();
    final r = await api.enter(n, password);
    if (r.ok) {
      storage.setPlayerName(r.name);
      _showToast(r.created
          ? 'Pilot registered — you fly as ${r.name}'
          : 'Welcome back, ${r.name}');
    } else if (r.wrongPassword) {
      _showToast('Wrong password for $n');
    } else if (r.badInput) {
      _showToast('Name min 2 chars, password min 3');
    } else {
      // Offline: keep the name locally, real login when the server is back.
      storage.setPlayerName(n.isEmpty ? null : n);
      api.displayName = n.isEmpty ? null : n;
      _showToast('Offline — flying as guest, log in when connected');
    }
    profileVersion.value++;
    return r.ok;
  }

  /// Point the game at a private server (empty = back to the default) and
  /// re-auth + refetch the daily seed. Returns true when the server answered.
  Future<bool> setServer(String url) async {
    storage.setServerUrl(url.isEmpty ? null : url);
    await api.setServer(url);
    _remoteDailySeed = null;
    final s = await api.fetchDailySeed();
    if (s != null) _remoteDailySeed = s;
    await api.ping(); // refresh the status dot right away
    profileVersion.value++;
    return api.connected;
  }

  /// Health-check the server and refresh the home UI when the state flips.
  Future<void> refreshServerStatus() async {
    if (_pinging) return;
    _pinging = true;
    final was = api.online;
    final wasConn = api.connected;
    await api.ping();
    _pinging = false;
    if (api.online != was || api.connected != wasConn) profileVersion.value++;
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
    music.setTheme(worldSeed, galaxy.difficulty);
  }

  @override
  void onRemove() {
    live.close();
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
    _bumpers.clear();
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
    // ENDLESS curves: asymptote + slow linear tail. Height never stops getting
    // harder, but the slope flattens so it remains humanly fair forever.
    final gd = galaxy.difficulty;
    final breather = !first && i % 8 == 7; // guaranteed easy ring every bar
    final baseRadius = 63 -
        18 * (i / (i + 60)) -
        math.min(8, i * 0.008) -
        math.min(16.0, (gd - 1) * 14);
    final speedUp =
        (1 + 0.55 * (i / (i + 40)) + i * 0.0012) * (1 + (gd - 1) * 0.65);
    final stormChance = ((0.16 + 0.24 * (i / (i + 80)) + math.min(0.15, i * 0.0002)) *
            gd *
            _mut((m) => m.stormBoost))
        .clamp(0.0, 0.6);
    // Layer 2 — the seed only shuffles within those fair bounds.
    final radius = first
        ? 70.0
        : math.max(
            20.0,
            (baseRadius + _rng.nextDouble() * 10 + (breather ? 8 : 0)) *
                _mut((m) => m.radiusMult));
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
        _rng.nextDouble() <
            math.min(0.9, math.min(0.5, 0.30 + i * 0.0005) * _mut((m) => m.moverBoost));
    final ring = Ring(
      index: i,
      center: Vector2(x, -i * spacing),
      radius: radius,
      omega: (1.35 + _rng.nextDouble() * 0.5) *
          speedUp *
          _mut((m) => m.omegaMult) *
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
    // Pulsar bumpers — pinball pins between rings, deep space only (galaxy
    // 5+). All rng draws are guarded so the four handcrafted galaxies keep
    // byte-identical layouts for every existing seed.
    if (!first && profile.galaxy >= 4 && !storm && i > 3) {
      if (_rng.nextDouble() < math.min(0.8, 0.35 * _mut((m) => m.bumperBoost))) {
        final pr = _rings[_rings.length - 2];
        final t = 0.4 + _rng.nextDouble() * 0.2;
        final bx = (lerpDouble(pr.center.x, ring.center.x, t)! +
                (_rng.nextDouble() * 320 - 160))
            .clamp(30.0, size.x - 30.0);
        final by = lerpDouble(pr.center.y, ring.center.y, t)!;
        final p = Vector2(bx, by);
        final br = 13 + _rng.nextDouble() * 6;
        // Never overlap the rings it sits between — bounces stay fair.
        if (p.distanceTo(ring.center) > ring.radius + 34 &&
            p.distanceTo(pr.center) > pr.radius + 34) {
          _bumpers.add(Bumper(p, br));
        }
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
        galaxyIndex >= 0 &&
        galaxyIndex != profile.galaxy &&
        galaxyUnlocked(galaxyIndex)) {
      profile.galaxy = galaxyIndex;
      storage.save();
    }
    runSeed = seed ?? dailySeed;
    _resetSigils();
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
    // Live multiplayer: join this universe's room — real players, real time.
    live.connect(api.baseUrl, ws, api.playerName);
    _liveT = 0;
    state.value = RunState.running;
    music.setTheme(ws, galaxy.difficulty);
    music.setHeight(0);
    music.start();
    // Deep space carries a rule twist — announce it so nobody flies blind.
    final mu = mutation;
    if (mu != null) _showToast('MUTATION — ${mu.name}: ${mu.down}');
  }

  void goHome() {
    _resetSigils();
    _resetWorld();
    _ghosts = [];
    _rivals = [];
    live.close();
    music.stop();
    state.value = RunState.home;
    _pingT = 0; // re-check the server as soon as we're back home
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
      if (sigilOffer.value != null) return; // choosing a sigil — orbit is safe
      final r = _rings[_ringIndex];
      final dir = r.omega.sign == 0 ? 1.0 : r.omega.sign;
      _vel.setValues(-math.sin(_angle) * dir, math.cos(_angle) * dir);
      _vel.scale(flightSpeed * _sig((s) => s.speedMult));
      _flying = true;
      _flightDist = 0;
      r.flash = 1.0; // departed ring blinks goodbye
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
      if (r.flash > 0) r.flash = math.max(0, r.flash - dt * 1.8);
    }
    for (final b in _bumpers) {
      if (b.hitT > 0) b.hitT = math.max(0, b.hitT - dt * 1.5);
    }

    // Home screen: keep the server status dot honest (ping every 10 s).
    if (state.value == RunState.home) {
      _pingT -= dt;
      if (_pingT <= 0) {
        _pingT = 10;
        refreshServerStatus();
      }
    }

    if (_flying) {
      _pos.add(_vel * dt);
      _flightDist += _vel.length * dt;
      _checkBumpers();
      _checkCapture();
      if (_flying && _isMiss()) _fall();
    } else {
      final r = _rings[_ringIndex];
      _angle += r.omega * dt * _sig((s) => s.spinMult);
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
      // Live multiplayer: stream our position to the room (~10 Hz).
      _liveT += dt;
      if (_liveT >= 0.1) {
        _liveT = 0;
        live.send(_pos.x, _pos.y, height.value);
      }
      // Lifetime play time — the "proud of playing a lot" stat.
      _playAcc += dt;
      if (_playAcc >= 1) {
        final s = _playAcc.floor();
        _playAcc -= s;
        profile.playSeconds += s;
      }
      final targetY = _pos.y - size.y * 0.55;
      if (targetY < _camY) {
        _camY = lerpDouble(_camY, targetY, math.min(1, dt * 6))!;
      } else if (!_flying && _pos.y > _camY + size.y * 0.75) {
        // Player is below the view (e.g. rescued on a lower ring):
        // bring the camera back down onto them.
        _camY = lerpDouble(_camY, targetY, math.min(1, dt * 5))!;
      }
      _collectMotes(dt);
      _updateGhosts(dt);
      _updateRivals(dt);
    } else if (state.value == RunState.over) {
      // Spectator mode: after death, ghosts & rivals keep flying —
      // the camera follows the leader so you can watch the race go on.
      _updateGhosts(dt);
      _updateRivals(dt);
      double? leadY;
      for (final g in _ghosts) {
        if (!g.done) leadY = math.min(leadY ?? g.y, g.y);
      }
      for (final r in _rivals) {
        if (!r.done) leadY = math.min(leadY ?? r.y, r.y);
      }
      for (final p in live.players.values) {
        leadY = math.min(leadY ?? p.y, p.y);
      }
      if (leadY != null) {
        _camY = lerpDouble(_camY, leadY - size.y * 0.45, math.min(1, dt * 2))!;
      }
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
      // Income only while the run is live (spectating after death is visual).
      if (state.value != RunState.running) continue;
      final perSec = (g.dustVal * echoYield) / (g.path.length / 2 * 0.1);
      _echoFrac += perSec * dt * profile.globalMult * _sig((s) => s.echoMult);
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
      if (d < r.radius * precisionMult * _sig((s) => s.captureMult)) {
        // Perfect Arc = velocity line passes near the ring core
        // (impact parameter, docs/01 "through the center").
        final rel = r.center - _pos;
        final b = (_vel.x * rel.y - _vel.y * rel.x).abs() / _vel.length;
        _capture(r, perfect: b < r.radius * 0.34 * _sig((s) => s.perfectMult));
        return;
      }
    }
  }

  /// Pulsar bumpers: pinball physics. A bounce starts a fresh flight leg
  /// (_flightDist = 0) so bank shots never trigger the drift-away miss.
  void _checkBumpers() {
    for (final b in _bumpers) {
      if (b.hitT > 0) continue; // cooldown — no machine-gun rebounds
      if (_pos.distanceTo(b.pos) < b.r + 9) {
        final n = (_pos - b.pos)..normalize();
        final dot = _vel.dot(n);
        if (dot < 0) _vel.sub(n * (2 * dot)); // reflect v' = v - 2(v·n)n
        _vel.scale(1.1); // pinball kick
        const maxV = flightSpeed * 1.7;
        if (_vel.length > maxV) _vel.scale(maxV / _vel.length);
        _pos.setFrom(b.pos + n * (b.r + 10)); // unstick from the pin
        _flightDist = 0;
        b.hitT = 0.6;
        combo.value++;
        final gain = (4 *
                profile.globalMult *
                galaxy.reward *
                _sig((s) => s.dustMult))
            .round();
        runDust.value += gain;
        _floats.add(
            _FloatText(_pos.x, _pos.y - 20, 'BOUNCE! +$gain', Palette.violet, 13));
        _burst(Palette.violet, 10);
        return; // one bounce per frame
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
    // Sigil milestone: offer a pick-1-of-3 pact while safely orbiting.
    if (height.value >= _nextSigilAt && sigilOffer.value == null) {
      _offerSigils();
    }
    if (perfect) {
      perfects++;
      combo.value++;
      _floats.add(_FloatText(_pos.x, _pos.y - 30, 'PERFECT x2', Palette.coral, 17));
    } else if (skipped) {
      combo.value += 2 + sigils.fold(0, (a, s) => a + s.skipBonus);
      _floats.add(_FloatText(_pos.x, _pos.y - 48, 'SKIP! +combo', Palette.mint, 14));
    }
    final gain = (5 *
            (1 + 0.1 * _sig((s) => s.comboMult) * combo.value) *
            (perfect ? 2 : 1) *
            (skipped ? 2 : 1) *
            profile.globalMult *
            galaxy.reward *
            _sig((s) => s.dustMult))
        .round();
    runDust.value += gain;
    _floats.add(_FloatText(_pos.x, _pos.y - 12, '+$gain', Palette.gold, 13));
    _burst(perfect ? Palette.coral : starColor(), perfect ? 16 : 9);
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
      // Respawn safety: if the rescue ring is outside the current view,
      // snap the camera straight onto the player — never respawn off-screen.
      if (_pos.y > _camY + size.y || _pos.y < _camY) {
        _camY = _pos.y - size.y * 0.55;
      }
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
    if (state.value == RunState.over) return; // already ended — never bank twice
    _flying = false; // stop the flight; otherwise _fall() retriggers every frame
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
        final ni = gi + 1;
        // Lore beats: unlocking a Light gate = the end is in sight;
        // unlocking PAST a Light = you crossed into the next universe.
        _showToast(ni % universeLen == 0
            ? 'BEYOND ${galaxy.name} — UNIVERSE ${universeOf(ni)} AWAITS'
            : isLightGate(ni)
                ? '${galaxyAt(ni).name} UNLOCKED — the end of the story?'
                : 'NEW GALAXY UNLOCKED: ${galaxyAt(ni).name}');
      }
    }
    // Career rank — the permanent tryhard ladder (rank-up = a real moment).
    final newRank = rankIndex;
    if (newRank > profile.rankSeen) {
      profile.rankSeen = newRank;
      _showToast('RANK UP — ${rankName(newRank)}');
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
    api.submitScore(height.value, perfects, profile.prestige, profile.galaxy,
        galaxy.name,
        rank: rankIndex);
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
      if (d < magnetR * _sig((s) => s.magnetMult)) {
        m.pull = math.min(1, m.pull + dt * 4);
        m.pos.add((_pos - m.pos)..scale(m.pull * dt * 9));
      }
      if (d < 20) {
        m.collected = true;
        final g = (m.value *
                profile.globalMult *
                galaxy.reward *
                _sig((s) => s.dustMult) *
                _mut((mu) => mu.moteMult))
            .round();
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

  /* ---------- space sky ---------- */
  void _buildSky() {
    _stars.clear();
    _nebulae.clear();
    _skyGalaxy = profile.galaxy;
    _skyW = size.x;
    _skyH = size.y;
    final r = math.Random(galaxy.seedSalt + 1097);
    // Three parallax depths of stars — the deepest barely move.
    for (var layer = 0; layer < 3; layer++) {
      final par = [0.06, 0.14, 0.28][layer];
      final count = [70, 45, 25][layer];
      for (var i = 0; i < count; i++) {
        _stars.add(_Star(
          r.nextDouble() * size.x,
          r.nextDouble() * size.y,
          0.6 + layer * 0.5 + r.nextDouble() * 0.9,
          par,
          r.nextDouble() * math.pi * 2,
          r.nextDouble() < 0.15,
        ));
      }
    }
    // Soft nebula clouds in the galaxy's own colors.
    for (var i = 0; i < 5; i++) {
      _nebulae.add(_Nebula(
        r.nextDouble() * size.x,
        r.nextDouble() * size.y,
        size.x * (0.3 + r.nextDouble() * 0.45),
        0.04 + r.nextDouble() * 0.08,
        (i.isEven ? galaxy.ring : galaxy.accent)
            .withValues(alpha: 0.05 + r.nextDouble() * 0.05),
      ));
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

    // Deep space: nebulae + twinkling parallax starfield (per-galaxy sky).
    if (_skyGalaxy != profile.galaxy || _skyW != size.x || _skyH != size.y) {
      _buildSky();
    }
    for (final n in _nebulae) {
      final ny = (n.y - _camY * n.par) % (size.y + n.radius * 2) - n.radius;
      canvas.drawCircle(
        Offset(n.x, ny + n.radius * 0.5),
        n.radius,
        Paint()
          ..shader = Gradient.radial(
              Offset(n.x, ny + n.radius * 0.5), n.radius, [
            n.color,
            n.color.withValues(alpha: 0),
          ]),
      );
    }
    for (final s in _stars) {
      var sy = (s.y - _camY * s.par) % size.y;
      if (sy < 0) sy += size.y;
      final tw = 0.55 + 0.45 * math.sin(_time * (1.2 + s.par * 4) + s.phase);
      final c = s.tint ? galaxy.accent : const Color(0xFFEAF2FF);
      canvas.drawCircle(Offset(s.x, sy), s.size,
          Paint()..color = c.withValues(alpha: (0.25 + 0.5 * tw) * (0.5 + s.par)));
    }

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

    // pulsar bumpers — violet pins; freshly-hit ones flare
    for (final b in _bumpers) {
      if (b.pos.y < _camY - 60 || b.pos.y > _camY + size.y + 60) continue;
      final bp = 0.6 + 0.4 * math.sin(_time * 6 + b.pos.x);
      canvas.drawCircle(
          b.pos.toOffset(),
          b.r + 6,
          Paint()
            ..color = Palette.violet.withValues(alpha: 0.10 + 0.30 * b.hitT));
      canvas.drawCircle(
          b.pos.toOffset(),
          b.r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 + b.hitT * 3
            ..color = Palette.violet
                .withValues(alpha: math.min(1, 0.45 + 0.35 * bp + 0.3 * b.hitT)));
      canvas.drawCircle(b.pos.toOffset(), 4,
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9));
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
      if (r.flash > 0) {
        // Blink of the ring just left: a few quick pulses that swell and fade.
        final blink = 0.5 + 0.5 * math.sin(r.flash * math.pi * 5);
        canvas.drawCircle(
            r.center.toOffset(),
            r.radius + (1 - r.flash) * 6,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 + r.flash * 2.5
              ..color = galaxy.accent.withValues(alpha: r.flash * blink * 0.9));
      }
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

    // LIVE players — real people flying this universe right now.
    // Gold pulse + height tag so they read instantly as "alive".
    final pulse = 0.7 + 0.3 * math.sin(_time * 5);
    for (final p in live.players.values) {
      canvas.drawCircle(Offset(p.x, p.y), 12,
          Paint()..color = Palette.gold.withValues(alpha: 0.20 * pulse));
      canvas.drawCircle(Offset(p.x, p.y), 6,
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.95));
      canvas.drawCircle(Offset(p.x, p.y), 6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Palette.gold.withValues(alpha: 0.9));
      _drawText(canvas, '${p.name} ▲${p.h}', p.x, p.y - 16,
          Palette.gold.withValues(alpha: 0.9), 9);
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
    final tc = starColor();
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

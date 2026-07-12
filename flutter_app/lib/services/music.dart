import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Procedural, seed-generated music.
///
/// Every universe+galaxy composes its own track, derived deterministically
/// from the world seed: key, scale, drum groove, bassline and a signature
/// melody motif. Same seed = same music, every time. All notes are locked to
/// consonant pentatonic scales, so nothing can ever sound wrong — while BPM,
/// note density and dissonant stabs scale with run height and galaxy
/// difficulty. One recognizable game style, endless variation.
class MusicEngine {
  static const int _sr = 44100;

  SoLoud? _soloud;
  bool _ready = false;
  bool _running = false;
  bool enabled = true;

  AudioSource? _kickSrc;
  AudioSource? _snareSrc;
  AudioSource? _hatSrc;
  AudioSource? _openHatSrc;
  final List<AudioSource> _bassSrcs = []; // 12 chromatic saw notes from A1
  final List<AudioSource> _pluckSrcs = []; // 36 chromatic notes from A3
  final List<AudioSource> _stabSrcs = []; // 12 chromatic detuned stabs

  Timer? _timer;
  int _step = 0;
  int _bar = 0;
  int _bassNote = 0; // chromatic index of last bass hit (reused for pulses)
  int _arp = 0; // melody walk position, in scale degrees
  double _bpm = 96;
  double _targetBpm = 96;
  double _intensity = 0; // 0..1 from height (+ galaxy stress floor)
  double _stress = 0; // 0..1 from galaxy difficulty
  final math.Random _r = math.Random(); // live embellishments only

  /* ------ theme: composed deterministically from the world seed ------ */
  int _root = 0; // key, semitones above A
  List<int> _scale = const [0, 3, 5, 7, 10];
  List<bool> _kickPat = List.generate(16, (s) => s % 4 == 0);
  List<int> _bassPat = const [
    0, -1, -1, -1, 0, -1, -1, -1, 3, -1, -1, -1, 0, -1, -1, -1 //
  ];
  List<int> _motifA = const [
    2, -1, 4, -1, 5, -1, 4, -1, 2, -1, -1, 4, -1, 1, -1, -1 //
  ];
  List<int> _motifB = const [
    5, -1, 4, -1, 2, -1, 1, -1, 0, -1, -1, 2, -1, 4, -1, -1 //
  ];
  int _hatOff = 2; // open-hat offbeat position within each beat
  double _swing = 0;

  Future<void> init() async {
    if (kIsWeb) return; // web build stays silent; Android is the target
    try {
      final sl = SoLoud.instance;
      await sl.init();
      _soloud = sl;

      _kickSrc = await sl.loadMem('kick.wav', _wav(_kick()));
      _snareSrc = await sl.loadMem('snare.wav', _wav(_snare()));
      _hatSrc = await sl.loadMem('hat.wav', _wav(_hat()));
      _openHatSrc = await sl.loadMem('ohat.wav', _wav(_openHat()));

      // Chromatic banks: any key/scale can be played without re-synthesis.
      for (var i = 0; i < 12; i++) {
        final f = 55.0 * math.pow(2, i / 12.0); // A1..G#2
        _bassSrcs.add(await sl.loadMem('bass$i.wav', _wav(_sawBass(f))));
      }
      for (var i = 0; i < 36; i++) {
        final f = 220.0 * math.pow(2, i / 12.0); // A3..G#6
        _pluckSrcs.add(await sl.loadMem('pluck$i.wav', _wav(_pluck(f))));
      }
      for (var i = 0; i < 12; i++) {
        final f = 110.0 * math.pow(2, i / 12.0); // A2..G#3
        _stabSrcs.add(await sl.loadMem('stab$i.wav', _wav(_stab(f))));
      }
      _ready = true;
    } catch (_) {
      _ready = false; // never let audio break the game
    }
  }

  /// Compose this world's theme. Deterministic: the same universe+galaxy
  /// always plays the same track, and no two worlds sound alike.
  void setTheme(int seed, double difficulty) {
    _stress = ((difficulty - 1) / 1.5).clamp(0.0, 1.0);
    final g = math.Random(seed);

    _root = g.nextInt(12);
    // Pentatonic scales only — no wrong notes possible. Harder galaxies
    // unlock darker scales (in-sen, hirajoshi) with built-in tension.
    const calm = [
      [0, 3, 5, 7, 10], // minor
      [0, 2, 4, 7, 9], // major
      [0, 2, 5, 7, 10], // egyptian / suspended
      [0, 3, 5, 7, 9], // minor 6th
    ];
    const dark = [
      [0, 1, 5, 7, 10], // in-sen
      [0, 2, 3, 7, 8], // hirajoshi
    ];
    final pool = [...calm, if (_stress > 0.35) ...dark, if (_stress > 0.6) ...dark];
    _scale = pool[g.nextInt(pool.length)];

    // Groove: four-on-the-floor core + seeded syncopated kicks.
    _kickPat = List.generate(16, (s) => s % 4 == 0);
    final syncs = [3, 6, 7, 10, 11, 14]..shuffle(g);
    for (final s in syncs.take(_stress > 0.4 ? 2 : 1)) {
      if (g.nextDouble() < 0.6) _kickPat[s] = true;
    }
    _hatOff = g.nextBool() ? 2 : 3;
    _swing = g.nextDouble() * 0.12;

    // Bassline: root anchors the bar, seeded degrees answer it.
    _bassPat = List.filled(16, -1);
    _bassPat[0] = 0;
    _bassPat[4] = g.nextInt(_scale.length);
    _bassPat[8] = g.nextDouble() < 0.5 ? 0 : 3;
    _bassPat[12] = g.nextInt(_scale.length);
    for (final s in const [6, 10, 14]) {
      if (g.nextDouble() < 0.4) _bassPat[s] = g.nextInt(_scale.length);
    }

    // Signature motif: a small random walk stays singable — these are the
    // "perfect notes that go together" that make the world's hook.
    List<int> phrase() {
      final m = List.filled(16, -1);
      var note = 2 + g.nextInt(2 * _scale.length - 4); // mid register
      for (var s = 0; s < 16; s++) {
        if (s % 4 != 0 && g.nextDouble() > 0.45) continue;
        note = (note + g.nextInt(5) - 2).clamp(0, 2 * _scale.length - 1);
        m[s] = note;
      }
      return m;
    }

    _motifA = phrase();
    _motifB = phrase();
    _targetBpm = 96 + _stress * 18 + _intensity * 86;
  }

  /// Feed the current run height; updates target tempo + density.
  void setHeight(int h) {
    _intensity = (h / 110.0 + _stress * 0.35).clamp(0.0, 1.0);
    _targetBpm = 96 + _stress * 18 + _intensity * 86; // up to ~200 BPM
  }

  void start() {
    if (!_ready || _running || !enabled) return;
    _running = true;
    _step = 0;
    _bar = 0;
    _arp = 0;
    _bpm = _targetBpm = 96 + _stress * 18 + _intensity * 86;
    _schedule();
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void _schedule() {
    if (!_running) return;
    // Seeded swing: even 16ths stretch, odd ones snap back.
    final stepDur =
        60.0 / _bpm / 4.0 * (_step % 2 == 0 ? 1 + _swing : 1 - _swing);
    _timer = Timer(
      Duration(microseconds: (stepDur * 1e6).round()),
      _tick,
    );
  }

  void _play(AudioSource? src, double vol) {
    if (src == null) return;
    unawaited(_soloud!.play(src, volume: vol));
  }

  /// Map a scale degree (2 octaves of the pentatonic) to a chromatic pluck.
  int _pluckIdx(int degree) {
    final oct = degree ~/ _scale.length;
    var i = _root + _scale[degree % _scale.length] + 12 * oct;
    while (i >= _pluckSrcs.length) {
      i -= 12;
    }
    return i;
  }

  int _bassIdx(int degree) => (_root + _scale[degree % _scale.length]) % 12;

  void _tick() {
    if (_soloud == null || !_running) return;
    final s = _step;
    final inten = _intensity;

    // Drums: this world's seeded groove + live ghost-hat fills.
    if (_kickPat[s]) _play(_kickSrc, s % 4 == 0 ? 1.0 : 0.8);
    if (s == 4 || s == 12) _play(_snareSrc, 0.8);
    if (s % 2 == 0) _play(_hatSrc, 0.4);
    if (s % 4 == _hatOff) _play(_openHatSrc, 0.22 + inten * 0.2);
    if (_r.nextDouble() < inten * 0.6) _play(_hatSrc, 0.25);

    // Bassline: seeded groove; pulsing 8ths emerge as intensity rises.
    if (_bassSrcs.isNotEmpty) {
      final d = _bassPat[s];
      if (d >= 0) {
        _bassNote = _bassIdx(d);
        _play(_bassSrcs[_bassNote], s == 0 ? 0.85 : 0.7);
      } else if (s % 2 == 0 && inten > 0.35) {
        _play(_bassSrcs[_bassNote], 0.45 + inten * 0.25);
      }
    }

    // Melody: the motif is the hook (A A A B). Relaxed = sparse phrase;
    // stressed = the gaps fill with a scale-locked arp — busier and more
    // anxious, but never off-key.
    if (_pluckSrcs.isNotEmpty) {
      final motif = (_bar % 4 == 3) ? _motifB : _motifA;
      final d = motif[s];
      if (d >= 0 && _r.nextDouble() < 0.55 + inten * 0.45) {
        _arp = d;
        _play(_pluckSrcs[_pluckIdx(d)], 0.4 + inten * 0.25);
      } else if (inten > 0.6 && _r.nextDouble() < inten * 0.8) {
        _arp = (_arp + (_r.nextBool() ? 1 : -1))
            .clamp(0, 2 * _scale.length - 1);
        _play(_pluckSrcs[_pluckIdx(_arp)], 0.3 + inten * 0.2);
      }
    }

    // Dissonant stabs (root, minor 2nd, tritone at high stress) — only when
    // the galaxy itself is dangerous.
    if (_stress > 0.15 &&
        _stabSrcs.isNotEmpty &&
        (s == 7 || s == 15) &&
        _r.nextDouble() < _stress * 0.8) {
      final semi = _r.nextDouble() < 0.5 ? 0 : (_stress > 0.6 ? 6 : 1);
      _play(_stabSrcs[(_root + semi) % 12], 0.28 + _stress * 0.25);
    }

    _step = (s + 1) % 16;
    if (_step == 0) _bar++;
    _bpm += (_targetBpm - _bpm) * 0.08; // glide toward target tempo
    _schedule();
  }

  void dispose() {
    stop();
    _soloud?.deinit();
    _soloud = null;
    _ready = false;
  }

  /* ---------- synthesis (Int16 PCM mono @ 44.1 kHz) ---------- */

  Int16List _kick() {
    final n = (_sr * 0.22).round();
    final out = Int16List(n);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final f = 45 + (120 - 45) * math.exp(-t * 30); // pitch drop
      final env = math.exp(-t * 14);
      out[i] = _s16(math.sin(2 * math.pi * f * t) * env * 0.9);
    }
    return out;
  }

  Int16List _snare() {
    final n = (_sr * 0.16).round();
    final out = Int16List(n);
    final r = math.Random(7);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final env = math.exp(-t * 24);
      final noise = r.nextDouble() * 2 - 1;
      final tone = math.sin(2 * math.pi * 185 * t);
      out[i] = _s16((noise * 0.7 + tone * 0.3) * env * 0.6);
    }
    return out;
  }

  Int16List _hat() {
    final n = (_sr * 0.05).round();
    final out = Int16List(n);
    final r = math.Random(11);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final env = math.exp(-t * 90);
      out[i] = _s16((r.nextDouble() * 2 - 1) * env * 0.35);
    }
    return out;
  }

  /// Sawtooth bass (harmonic sum) — the buzzy electronic backbone.
  Int16List _sawBass(double freq) {
    final n = (_sr * 0.18).round();
    final out = Int16List(n);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final env = math.exp(-t * 11) * (1 - math.exp(-t * 400));
      var v = 0.0;
      for (var h = 1; h <= 7; h++) {
        v += math.sin(2 * math.pi * freq * h * t) / h;
      }
      out[i] = _s16(v * env * 0.42);
    }
    return out;
  }

  /// Open hat: longer noise decay on the offbeats — instant electro feel.
  Int16List _openHat() {
    final n = (_sr * 0.22).round();
    final out = Int16List(n);
    final r = math.Random(13);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final env = math.exp(-t * 18);
      out[i] = _s16((r.nextDouble() * 2 - 1) * env * 0.28);
    }
    return out;
  }

  /// Detuned dual-saw stab — dissonant, anxious, used in hard galaxies.
  Int16List _stab(double freq) {
    final n = (_sr * 0.30).round();
    final out = Int16List(n);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final env = math.exp(-t * 8) * (1 - math.exp(-t * 250));
      var v = 0.0;
      for (var h = 1; h <= 5; h++) {
        v += math.sin(2 * math.pi * freq * h * t) / h;
        v += math.sin(2 * math.pi * freq * 1.012 * h * t) / h; // detune beat
      }
      out[i] = _s16(v * env * 0.22);
    }
    return out;
  }

  Int16List _pluck(double freq) {
    final n = (_sr * 0.28).round();
    final out = Int16List(n);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final env = math.exp(-t * 7) * (1 - math.exp(-t * 300)); // fast attack
      final v = math.sin(2 * math.pi * freq * t) * 0.6 +
          math.sin(2 * math.pi * freq * 2 * t) * 0.2 +
          math.sin(2 * math.pi * freq * 3 * t) * 0.1;
      out[i] = _s16(v * env * 0.5);
    }
    return out;
  }

  int _s16(double v) => (v * 32000).round().clamp(-32768, 32767);

  Uint8List _wav(Int16List pcm) {
    final dataLen = pcm.length * 2;
    final buf = ByteData(44 + dataLen);
    void s(int off, String str) {
      for (var i = 0; i < str.length; i++) {
        buf.setUint8(off + i, str.codeUnitAt(i));
      }
    }

    s(0, 'RIFF');
    buf.setUint32(4, 36 + dataLen, Endian.little);
    s(8, 'WAVE');
    s(12, 'fmt ');
    buf.setUint32(16, 16, Endian.little); // fmt chunk size
    buf.setUint16(20, 1, Endian.little); // PCM
    buf.setUint16(22, 1, Endian.little); // mono
    buf.setUint32(24, _sr, Endian.little);
    buf.setUint32(28, _sr * 2, Endian.little); // byte rate
    buf.setUint16(32, 2, Endian.little); // block align
    buf.setUint16(34, 16, Endian.little); // bits
    s(36, 'data');
    buf.setUint32(40, dataLen, Endian.little);
    for (var i = 0; i < pcm.length; i++) {
      buf.setInt16(44 + i * 2, pcm[i], Endian.little);
    }
    return buf.buffer.asUint8List();
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Procedural, tempo-driven music.
///
/// A 16-step 4/4 sequencer built from short WAV samples synthesized in Dart
/// (no audio assets shipped). BPM and note density rise with the run height,
/// so the groove drives faster and thicker the higher (and harder) you climb.
/// The melody is a random walk over a minor-pentatonic scale — random, but it
/// can never land on a "wrong" note, which is what makes it feel addictive.
class MusicEngine {
  static const int _sr = 44100;

  SoLoud? _soloud;
  bool _ready = false;
  bool _running = false;
  bool enabled = true;

  AudioSource? _kickSrc;
  AudioSource? _snareSrc;
  AudioSource? _hatSrc;
  final List<AudioSource> _bassSrcs = [];
  final List<AudioSource> _pluckSrcs = [];

  Timer? _timer;
  int _step = 0;
  double _bpm = 92;
  double _targetBpm = 92;
  double _intensity = 0; // 0..1 from height
  final math.Random _r = math.Random();

  Future<void> init() async {
    if (kIsWeb) return; // web build stays silent; Android is the target
    try {
      final sl = SoLoud.instance;
      await sl.init();
      _soloud = sl;

      _kickSrc = await sl.loadMem('kick.wav', _wav(_kick()));
      _snareSrc = await sl.loadMem('snare.wav', _wav(_snare()));
      _hatSrc = await sl.loadMem('hat.wav', _wav(_hat()));

      // A minor pentatonic. Bass = low octave root notes for the downbeat groove.
      const semis = [0, 3, 5, 7, 10]; // minor pentatonic offsets
      for (final s in semis) {
        final f = 55.0 * math.pow(2, s / 12.0); // A1-ish register
        _bassSrcs.add(await sl.loadMem('bass$s.wav', _wav(_bass(f))));
      }
      // Melody spans two octaves starting at A3 (220 Hz).
      for (var oct = 0; oct < 2; oct++) {
        for (final s in semis) {
          final f = 220.0 * math.pow(2, (s + oct * 12) / 12.0);
          _pluckSrcs.add(await sl.loadMem('pluck$oct$s.wav', _wav(_pluck(f))));
        }
      }
      _ready = true;
    } catch (_) {
      _ready = false; // never let audio break the game
    }
  }

  /// Feed the current run height; updates target tempo + density.
  void setHeight(int h) {
    final i = (h / 110.0).clamp(0.0, 1.0);
    _intensity = i;
    _targetBpm = 92 + i * 88; // 92 -> 180 BPM
  }

  void start() {
    if (!_ready || _running || !enabled) return;
    _running = true;
    _step = 0;
    _bpm = _targetBpm = 92 + _intensity * 88;
    _schedule();
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void _schedule() {
    if (!_running) return;
    final stepDur = 60.0 / _bpm / 4.0; // one 16th note, seconds
    _timer = Timer(
      Duration(microseconds: (stepDur * 1e6).round()),
      _tick,
    );
  }

  void _play(AudioSource? src, double vol) {
    if (src == null) return;
    unawaited(_soloud!.play(src, volume: vol));
  }

  void _tick() {
    if (_soloud == null || !_running) return;
    final s = _step;
    final inten = _intensity;

    // Four-on-the-floor kick; extra syncopated kicks emerge at high intensity.
    if (s % 4 == 0) _play(_kickSrc, 1.0);
    if (inten > 0.5 && (s == 10 || s == 14) && _r.nextDouble() < inten) {
      _play(_kickSrc, 0.8);
    }
    // Backbeat snare.
    if (s == 4 || s == 12) _play(_snareSrc, 0.8);
    // Hats: steady 8ths, plus ghost 16ths that fill in as intensity climbs.
    if (s % 2 == 0) _play(_hatSrc, 0.4);
    if (_r.nextDouble() < inten * 0.6) _play(_hatSrc, 0.25);
    // Bass root on each downbeat.
    if (s % 4 == 0 && _bassSrcs.isNotEmpty) {
      _play(_bassSrcs[_r.nextInt(_bassSrcs.length)], 0.85);
    }
    // Melody: pentatonic random notes, more frequent + louder as you climb.
    final pluckChance = 0.15 + inten * 0.55;
    if (_pluckSrcs.isNotEmpty && _r.nextDouble() < pluckChance) {
      _play(_pluckSrcs[_r.nextInt(_pluckSrcs.length)], 0.5 + inten * 0.3);
    }

    _step = (s + 1) % 16;
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

  Int16List _bass(double freq) {
    final n = (_sr * 0.20).round();
    final out = Int16List(n);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final env = math.exp(-t * 9);
      final v = math.sin(2 * math.pi * freq * t) * 0.7 +
          math.sin(2 * math.pi * freq * 2 * t) * 0.15;
      out[i] = _s16(v * env * 0.7);
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

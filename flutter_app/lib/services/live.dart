import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Another player flying live in this universe right now.
class LivePlayer {
  LivePlayer(this.id, this.name);
  final String id;
  final String name;
  double x = 0, y = 0;
  int h = 0;
}

/// Live multiplayer room (WebSocket, one room per world seed — same key as
/// ghost racing). Offline-first: connection failures are silent and gameplay
/// never depends on the socket.
class LiveRoom {
  WebSocketChannel? _ch;
  String? _myId;

  /// id -> live player (never contains yourself).
  final Map<String, LivePlayer> players = {};

  void connect(String baseUrl, int seed, String name) {
    close();
    try {
      final base = Uri.parse(baseUrl);
      final uri = base.replace(
        scheme: base.scheme == 'https' ? 'wss' : 'ws',
        path: '/ws/room/$seed',
        queryParameters: {if (name.isNotEmpty) 'name': name},
      );
      final ch = WebSocketChannel.connect(uri);
      _ch = ch;
      ch.stream.listen(
        _onMessage,
        onError: (_) => _drop(ch),
        onDone: () => _drop(ch),
        cancelOnError: true,
      );
    } catch (_) {
      _ch = null; // offline: fine
    }
  }

  void _drop(WebSocketChannel ch) {
    if (_ch == ch) {
      _ch = null;
      _myId = null;
      players.clear();
    }
  }

  void _onMessage(dynamic msg) {
    try {
      final j = jsonDecode(msg as String) as Map<String, dynamic>;
      final you = j['you'];
      if (you is String) {
        _myId = you; // hello — learn our own id so we can filter the relay
        return;
      }
      final id = j['id'];
      if (id is! String || id == _myId) return;
      if (j['gone'] == true) {
        players.remove(id);
        return;
      }
      final p = players.putIfAbsent(
          id, () => LivePlayer(id, j['name'] as String? ?? 'star'));
      p.x = (j['x'] as num?)?.toDouble() ?? p.x;
      p.y = (j['y'] as num?)?.toDouble() ?? p.y;
      p.h = (j['h'] as num?)?.toInt() ?? p.h;
    } catch (_) {/* malformed frame: ignore */}
  }

  /// Stream our own position (~10 Hz from the game loop).
  void send(double x, double y, int h) {
    try {
      _ch?.sink.add(jsonEncode({'x': x, 'y': y, 'h': h}));
    } catch (_) {}
  }

  void close() {
    try {
      _ch?.sink.close();
    } catch (_) {}
    _ch = null;
    _myId = null;
    players.clear();
  }
}

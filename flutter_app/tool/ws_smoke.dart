// Smoke test for the live-room WebSocket protocol (run: dart tool/ws_smoke.dart)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final host = args.isEmpty ? 'localhost:8080' : args[0];
  final a = await WebSocket.connect('ws://$host/ws/room/12345?name=TestA');
  final b = await WebSocket.connect('ws://$host/ws/room/12345?name=TestB');
  final gotHello = Completer<void>();
  final gotPos = Completer<void>();
  final gotGone = Completer<void>();
  b.listen((msg) {
    final j = jsonDecode(msg as String) as Map<String, dynamic>;
    stdout.writeln('B <- $j');
    if (j['you'] != null && !gotHello.isCompleted) gotHello.complete();
    if (j['x'] != null && j['name'] == 'TestA' && !gotPos.isCompleted) {
      gotPos.complete();
    }
    if (j['gone'] == true && !gotGone.isCompleted) gotGone.complete();
  });
  await gotHello.future.timeout(const Duration(seconds: 5));
  a.add(jsonEncode({'x': 100.5, 'y': -900.25, 'h': 7}));
  await gotPos.future.timeout(const Duration(seconds: 5));
  await a.close();
  await gotGone.future.timeout(const Duration(seconds: 5));
  await b.close();
  stdout.writeln('WS SMOKE OK: hello + relay + leave all received');
  exit(0);
}

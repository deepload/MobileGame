import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:echo_orbit/game/echo_orbit_game.dart';
import 'package:echo_orbit/main.dart';
import 'package:echo_orbit/services/api.dart';
import 'package:echo_orbit/services/storage.dart';

void main() {
  testWidgets('home overlay renders with title and play button',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await Storage.load();
    final game = EchoOrbitGame(storage, Api());

    await tester.pumpWidget(EchoOrbitApp(game: game));
    await tester.pump();

    expect(find.text('ECHO ORBIT'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
  });
}

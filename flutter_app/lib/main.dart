import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/echo_orbit_game.dart';
import 'services/api.dart';
import 'services/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await Storage.load();
  // Self-heal: an old build defaulted to localhost — a private-server URL
  // saved back then would silently override the real master server forever.
  final saved = storage.serverUrl;
  if (saved != null &&
      (saved.contains('localhost') || saved.contains('127.0.0.1')) &&
      !Api.defaultUrl.contains('localhost')) {
    storage.setServerUrl(null);
  }
  final api = Api(baseUrl: storage.serverUrl, storage: storage);
  api.displayName = storage.playerName; // pilot name, pushed after auth
  api.init(); // fire-and-forget; game is fully offline-capable
  runApp(EchoOrbitApp(game: EchoOrbitGame(storage, api)));
}

class EchoOrbitApp extends StatelessWidget {
  const EchoOrbitApp({super.key, required this.game});
  final EchoOrbitGame game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECHO ORBIT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1026),
        fontFamily: 'Roboto',
      ),
      home: GameScreen(game: game),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.game});
  final EchoOrbitGame game;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  EchoOrbitGame get game => widget.game;

  @override
  void initState() {
    super.initState();
    game.toast.addListener(_onToast);
  }

  @override
  void dispose() {
    game.toast.removeListener(_onToast);
    super.dispose();
  }

  void _onToast() {
    final msg = game.toast.value;
    if (msg.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFFFFD166))),
        backgroundColor: const Color(0xEE0B1026),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        GameWidget(game: game),
        ValueListenableBuilder<RunState>(
          valueListenable: game.state,
          builder: (_, state, __) => switch (state) {
            RunState.home => HomeOverlay(game: game),
            RunState.running => RunHud(game: game),
            RunState.over => ResultsOverlay(game: game),
          },
        ),
      ]),
    );
  }
}

/* ---------------- shared widgets ---------------- */

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xEB0B1026),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x4D8E9BFF)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class BigButton extends StatelessWidget {
  const BigButton(this.label,
      {super.key, required this.onTap, this.color = const Color(0xFF5DF2C8),
      this.textColor = const Color(0xFF06281F), this.enabled = true});
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? onTap : null,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  const StatRow(this.label, this.value, {super.key, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFFC7D2FF), fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

/* ---------------- HOME ---------------- */

class HomeOverlay extends StatelessWidget {
  const HomeOverlay({super.key, required this.game});
  final EchoOrbitGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.profileVersion,
      builder: (context, _, __) {
        final p = game.profile;
        return Panel(
          child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(colors: [
                  Color(0xFF5DF2C8),
                  Color(0xFF8E9BFF),
                  Color(0xFFB388FF)
                ]).createShader(r),
                child: const Text('ECHO ORBIT',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: Colors.white)),
              ),
              const Text('Tap to leap orbit to orbit.\nYour best runs fly with you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8E9BFF), fontSize: 13)),
              const SizedBox(height: 6),
              // Pilot name — who you are on leaderboards & live multiplayer.
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _editName(context),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    game.hasCustomName || game.playerName.isNotEmpty
                        ? '★ ${game.playerName}   ✎'
                        : '★ Pilot login   ✎',
                    style: TextStyle(
                        color: game.hasCustomName
                            ? const Color(0xFFFFD166)
                            : const Color(0xFF8E9BFF),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5),
                  ),
                ),
              ),
              // Server status — master vs private, live connected dot.
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showServer(context),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: Text(
                    game.api.online
                        ? (game.api.isMaster
                            ? '● Master server connected'
                            : '● Private: ${_shortUrl(game.api.baseUrl)}')
                        : (game.api.isMaster
                            ? '● Master server offline'
                            : '● ${_shortUrl(game.api.baseUrl)} offline'),
                    style: TextStyle(
                        color: game.api.online
                            ? const Color(0xFF5DF2C8)
                            : const Color(0xFFE36588),
                        fontWeight: FontWeight.w700,
                        fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              StatRow('Best height', '${p.bestHeight}'),
              StatRow('Stardust', '${p.dust}',
                  valueColor: const Color(0xFFFFD166)),
              StatRow(
                  'Photons (permanent x${p.globalMult.toStringAsFixed(1)})',
                  '${p.photons}',
                  valueColor: const Color(0xFFB388FF)),
              StatRow('Echoes equipped',
                  '${p.echoes.length.clamp(0, game.echoSlots)} / ${game.echoSlots}',
                  valueColor: const Color(0xFF5DF2C8)),
              StatRow('Time played', _fmtPlayTime(p.playSeconds),
                  valueColor: const Color(0xFF8E9BFF)),
              _GalaxySelector(game: game),
              // Alpha: online play needs a REGISTERED pilot (name+password).
              // Offline, a local guest name is enough — offline-first.
              BigButton('PLAY', onTap: () {
                final api = game.api;
                final canFly = api.registered ||
                    (!api.online && game.hasCustomName);
                if (canFly) {
                  game.startRun();
                } else {
                  game.toast.value = 'Log in first, pilot!';
                  _editName(context);
                }
              }),
              BigButton(game.marketUnlocked ? 'MARKET' : 'MARKET 🔒',
                  color: const Color(0xFFFFD166),
                  textColor: const Color(0xFF3A2A00),
                  onTap: () {
                    if (game.marketUnlocked) {
                      _showMarket(context);
                    } else {
                      game.toast.value =
                          'Finish your first run to open the Market';
                    }
                  }),
              Row(children: [
                Expanded(
                    child: BigButton('Upgrades',
                        color: const Color(0x248E9BFF),
                        textColor: Colors.white,
                        onTap: () => _showUpgrades(context))),
                const SizedBox(width: 8),
                Expanded(
                    child: BigButton(
                        'Daily${p.dailyClaimed.every((c) => c) ? '' : ' ●'}',
                        color: const Color(0x248E9BFF),
                        textColor: Colors.white,
                        onTap: () => _showDailies(context))),
              ]),
              Row(children: [
                Expanded(
                    child: BigButton('Leaderboard',
                        color: const Color(0x248E9BFF),
                        textColor: Colors.white,
                        onTap: () => _showLeaderboard(context))),
                const SizedBox(width: 8),
                Expanded(
                    child: BigButton('Universes',
                        color: const Color(0x248E9BFF),
                        textColor: Colors.white,
                        onTap: () => _showUniverses(context))),
              ]),
              if (game.canPrestige)
                BigButton('SUPERNOVA',
                    color: const Color(0xFFB388FF),
                    textColor: Colors.white,
                    onTap: () => _showPrestige(context)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                TextButton(
                  onPressed: () => _confirmReset(context),
                  child: const Text('Reset progress',
                      style: TextStyle(
                          color: Color(0x998E9BFF),
                          fontSize: 11.5,
                          decoration: TextDecoration.underline)),
                ),
                TextButton(
                  onPressed: () => _showServer(context),
                  child: const Text('Private server',
                      style: TextStyle(
                          color: Color(0x998E9BFF),
                          fontSize: 11.5,
                          decoration: TextDecoration.underline)),
                ),
              ]),
            ],
          )),
        );
      },
    );
  }

  void _editName(BuildContext context) {
    final nameCtl = TextEditingController(
        text: game.hasCustomName ? game.playerName : '');
    final passCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141B3C),
        title: const Text('Pilot login',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'First time? This registers your pilot. Coming back (or on a new device)? Enter the same name and password.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFFC7D2FF))),
          const SizedBox(height: 10),
          TextField(
            controller: nameCtl,
            maxLength: 16,
            autofocus: !game.hasCustomName,
            decoration: const InputDecoration(
                labelText: 'Pilot name',
                hintText: 'e.g. NovaHunter',
                isDense: true,
                counterText: ''),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: passCtl,
            obscureText: true,
            autofocus: game.hasCustomName,
            decoration: const InputDecoration(
                labelText: 'Password', isDense: true),
            style: const TextStyle(fontSize: 14),
            onSubmitted: (_) {
              Navigator.pop(ctx);
              game.login(nameCtl.text, passCtl.text);
            },
          ),
          const Text('Letters, numbers, - _ and spaces · max 16',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF8E9BFF))),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              game.login(nameCtl.text, passCtl.text);
            },
            child: const Text('ENTER'),
          ),
        ],
      ),
    );
  }

  /// Strip the scheme for compact display ('http://1.2.3.4' -> '1.2.3.4').
  static String _shortUrl(String url) =>
      url.replaceFirst(RegExp(r'^https?://'), '');

  void _showServer(BuildContext context) {
    // Prefill only a real private override — never the master URL, so it
    // can't be accidentally saved as a "private server".
    final ctl =
        TextEditingController(text: game.api.isMaster ? '' : game.api.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141B3C),
        title: const Text('Game server',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
              'Now playing on: ${_shortUrl(game.api.baseUrl)}'
              '${game.api.isMaster ? ' (master)' : ' (private)'}\n\n'
              'Compete with friends on your own server: everyone enters the same URL and shares leaderboards, daily seeds and ghosts.',
              style:
                  const TextStyle(fontSize: 12.5, color: Color(0xFFC7D2FF))),
          const SizedBox(height: 10),
          TextField(
            controller: ctl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
                hintText: 'http://my-server:8080', isDense: true),
            style: const TextStyle(fontSize: 13.5),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await game.setServer('');
              game.toast.value = ok
                  ? 'Back on the master server'
                  : 'Master server saved — unreachable right now';
            },
            child: const Text('MASTER SERVER'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await game.setServer(ctl.text.trim());
              game.toast.value = ok
                  ? 'Connected to ${game.api.baseUrl}'
                  : 'Server saved — unreachable right now (offline play continues)';
            },
            child: const Text('CONNECT'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141B3C),
        title: const Text('Start a new game?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
            'This erases EVERYTHING: stardust, photons, upgrades, echoes, galaxies, records and history.\n\nThere is no undo.',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Keep my game')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE36588)),
            onPressed: () {
              Navigator.pop(ctx);
              game.resetProfile();
            },
            child: const Text('ERASE & RESTART'),
          ),
        ],
      ),
    );
  }

  void _showUniverses(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xF20B1026),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => UniversesSheet(game: game),
    );
  }

  /// "Proud of playing a lot" — lifetime time spent flying.
  String _fmtPlayTime(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s % 60}s';
    return '${s}s';
  }

  void _showMarket(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xF20B1026),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => MarketSheet(game: game),
    );
  }

  void _showUpgrades(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xF20B1026),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => UpgradesSheet(game: game),
    );
  }

  void _showDailies(BuildContext context) {
    game.checkDailyReset();
    final p = game.profile;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xF20B1026),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Daily challenges',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (var i = 0; i < dailyDefs.length; i++)
            ListTile(
              dense: true,
              leading: Text(p.dailyClaimed[i] ? '✅' : '◻',
                  style: const TextStyle(fontSize: 18)),
              title: Text(dailyDefs[i].label,
                  style: const TextStyle(fontSize: 13.5)),
              subtitle: LinearProgressIndicator(
                value: (p.dailyProg[i] / dailyDefs[i].target).clamp(0.0, 1.0),
                backgroundColor: const Color(0x268E9BFF),
                color: const Color(0xFF5DF2C8),
              ),
              trailing: const Text('+100',
                  style: TextStyle(
                      color: Color(0xFFFFD166), fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
    );
  }

  void _showPrestige(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141B3C),
        title: const Text('SUPERNOVA',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          StatRow('You will earn', '${game.novaGain} photons',
              valueColor: const Color(0xFFB388FF)),
          StatRow(
              'New multiplier',
              'x${(1 + (game.profile.photons + game.novaGain) * 0.1).toStringAsFixed(1)}',
              valueColor: const Color(0xFF5DF2C8)),
          const StatRow('Resets', 'upgrades · stardust · echoes',
              valueColor: Color(0xFFE36588)),
          const StatRow('Keeps', 'photons · records · dailies'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Not yet')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB388FF)),
            onPressed: () {
              Navigator.pop(ctx);
              game.goSupernova();
            },
            child: const Text('GO SUPERNOVA'),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xF20B1026),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => LeaderboardSheet(game: game),
    );
  }
}

/* ---------------- WEEKLY LEADERBOARD (champions + per-galaxy) ------------ */

class LeaderboardSheet extends StatefulWidget {
  const LeaderboardSheet({super.key, required this.game});
  final EchoOrbitGame game;

  @override
  State<LeaderboardSheet> createState() => _LeaderboardSheetState();
}

class _LeaderboardSheetState extends State<LeaderboardSheet> {
  /// -1 = CHAMPIONS (all galaxies, difficulty-weighted); >=0 = that galaxy.
  int _tab = -1;
  Future<List<ChampionEntry>?>? _champions;
  final Map<int, Future<List<LeaderboardEntry>?>> _boards = {};

  EchoOrbitGame get game => widget.game;

  @override
  void initState() {
    super.initState();
    _champions = game.api.fetchChampions();
  }

  /// Galaxies worth a tab: every unlocked one (the endless ladder stops at
  /// the first locked galaxy), the selected one always included.
  List<int> _galaxyTabs() {
    final tabs = <int>[];
    for (var i = 0; i < 30 && game.galaxyUnlocked(i); i++) {
      tabs.add(i);
    }
    if (!tabs.contains(game.profile.galaxy)) tabs.add(game.profile.galaxy);
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Column(children: [
          const Text('Weekly leaderboard',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          // Galaxy tabs — champions first, then one board per galaxy.
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip(-1, 'CHAMPIONS ★', const Color(0xFFFFD166)),
                for (final g in _galaxyTabs())
                  _chip(g, galaxyAt(g).name, galaxyAt(g).ring),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (_tab == -1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                'Height x galaxy difficulty (x10) + 5 per perfect orbit, '
                'summed over every galaxy flown this week.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: Color(0xFF8E9BFF)),
              ),
            )
          else
            Text(
              '${galaxyAt(_tab).name} — difficulty x${galaxyAt(_tab).difficulty.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF8E9BFF)),
            ),
          const SizedBox(height: 4),
          Expanded(child: _tab == -1 ? _championList() : _galaxyList(_tab)),
        ]),
      ),
    );
  }

  Widget _chip(int tab, String label, Color color) {
    final sel = _tab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: sel ? const Color(0xFF0B1026) : color)),
        selected: sel,
        selectedColor: color,
        backgroundColor: const Color(0x148E9BFF),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        showCheckmark: false,
        onSelected: (_) => setState(() {
          _tab = tab;
          if (tab >= 0) {
            _boards[tab] ??= game.api.fetchLeaderboard(tab);
          }
        }),
      ),
    );
  }

  Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8E9BFF))),
      );

  Widget _championList() {
    return FutureBuilder(
      future: _champions,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data;
        if (data == null) {
          return _empty('Offline — leaderboard syncs when connected.');
        }
        if (data.isEmpty) {
          return _empty(
              'No champions yet this week — finish a run and be the first!');
        }
        return ListView(children: [
          for (final (i, e) in data.indexed)
            ListTile(
              dense: true,
              leading: Text('${i + 1}',
                  style: const TextStyle(
                      color: Color(0xFFFFD166), fontWeight: FontWeight.w800)),
              title: Text(
                  '${e.name}${e.prestige > 0 ? '  ✦${e.prestige}' : ''}'),
              subtitle: Text(
                  '▲${e.height} · ${e.galaxies} ${e.galaxies == 1 ? 'galaxy' : 'galaxies'}'
                  ' (top: ${e.galaxyName.isNotEmpty ? e.galaxyName : galaxyAt(e.galaxy).name})'
                  ' · ★${e.perfects}',
                  style: const TextStyle(
                      fontSize: 10.5, color: Color(0xFF8E9BFF))),
              trailing: Text('${e.score} pts',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: Color(0xFFFFD166))),
            ),
        ]);
      },
    );
  }

  Widget _galaxyList(int g) {
    return FutureBuilder(
      future: _boards[g] ??= game.api.fetchLeaderboard(g),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data;
        if (data == null) {
          return _empty('Offline — leaderboard syncs when connected.');
        }
        if (data.isEmpty) {
          return _empty(
              'No scores in ${galaxyAt(g).name} this week — be the first!');
        }
        return ListView(children: [
          for (final (i, e) in data.indexed)
            ListTile(
              dense: true,
              leading: Text('${i + 1}',
                  style: const TextStyle(
                      color: Color(0xFFFFD166), fontWeight: FontWeight.w800)),
              title: Text(
                  '${e.name}${e.prestige > 0 ? '  ✦${e.prestige}' : ''}'),
              trailing: Text('▲ ${e.height}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ]);
      },
    );
  }
}

/* ---------------- GALAXY SELECTOR (lobby travel) ---------------- */

class _GalaxySelector extends StatelessWidget {
  const _GalaxySelector({required this.game});
  final EchoOrbitGame game;

  @override
  Widget build(BuildContext context) {
    final p = game.profile;
    final g = game.galaxy;
    final gi = p.galaxy;
    // Endless galaxy ladder — there is always a next one.
    final nextLocked = !game.galaxyUnlocked(gi + 1);
    final next = galaxyAt(gi + 1);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x148E9BFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: g.ring.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 26),
            color: gi > 0 ? Colors.white : const Color(0x338E9BFF),
            onPressed: () => game.selectGalaxy(gi - 1),
          ),
          Expanded(
            child: Column(children: [
              Text(g.name,
                  style: TextStyle(
                      color: g.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 2)),
              Text(
                  'difficulty x${g.difficulty.toStringAsFixed(1)} · rewards x${g.reward.toStringAsFixed(1)} · best ▲${p.galaxyBest[g.id] ?? 0}',
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF8E9BFF))),
              if (nextLocked)
                Text(
                    '🔒 ${next.name} — reach ▲${next.unlockHeight} here (${p.galaxyBest[g.id] ?? 0}/${next.unlockHeight})',
                    style: const TextStyle(
                        fontSize: 10.5, color: Color(0xFFFFD166))),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 26),
            color: !nextLocked ? Colors.white : const Color(0x338E9BFF),
            onPressed: () => game.selectGalaxy(gi + 1),
          ),
        ]),
      ),
    );
  }
}

/* ---------------- UNIVERSES (roguelite seeds) ---------------- */

class UniversesSheet extends StatefulWidget {
  const UniversesSheet({super.key, required this.game});
  final EchoOrbitGame game;

  @override
  State<UniversesSheet> createState() => _UniversesSheetState();
}

class _UniversesSheetState extends State<UniversesSheet> {
  final _seedCtl = TextEditingController();

  @override
  void dispose() {
    _seedCtl.dispose();
    super.dispose();
  }

  void _launch(int seed, {int? galaxyIndex}) {
    Navigator.pop(context);
    widget.game.startRun(seed: seed, galaxyIndex: galaxyIndex);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final hist = game.profile.history;
    return Padding(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Universes',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(
            'Every universe is generated from a seed.\nSame seed = same universe: race friends or beat yourself.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8E9BFF), fontSize: 12)),
        const SizedBox(height: 8),
        ListTile(
          dense: true,
          leading: const Text('🌌', style: TextStyle(fontSize: 20)),
          title: Text('Daily universe  #${game.dailySeed}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          subtitle: const Text('Everyone races this world today',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF8E9BFF))),
          trailing: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5DF2C8),
                foregroundColor: const Color(0xFF06281F)),
            onPressed: () => _launch(game.dailySeed),
            child: const Text('PLAY'),
          ),
        ),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _seedCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter a seed…',
                hintStyle: TextStyle(color: Color(0xFF8E9BFF), fontSize: 13),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13.5),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0x248E9BFF),
                foregroundColor: Colors.white),
            onPressed: () {
              final s = int.tryParse(_seedCtl.text.trim());
              if (s != null) _launch(s);
            },
            child: const Text('LAUNCH'),
          ),
        ]),
        if (hist.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Recent runs — tap to replay',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC7D2FF))),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final r in hist)
                  ListTile(
                    dense: true,
                    onTap: () => _launch(r.seed, galaxyIndex: r.galaxy),
                    leading: Text('▲${r.height}',
                        style: const TextStyle(
                            color: Color(0xFF5DF2C8),
                            fontWeight: FontWeight.w800)),
                    title: Text('#${r.seed} · ${galaxyAt(r.galaxy).name}',
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                        '✦ ${r.dust} · ${r.perfects} perfect · ${_fmtDate(r.dateMs)}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8E9BFF))),
                    trailing: const Icon(Icons.replay,
                        size: 18, color: Color(0xFF8E9BFF)),
                  ),
              ],
            ),
          ),
        ],
      ]),
    );
  }

  String _fmtDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

/* ---------------- UPGRADES ---------------- */

class UpgradesSheet extends StatefulWidget {
  const UpgradesSheet({super.key, required this.game});
  final EchoOrbitGame game;

  @override
  State<UpgradesSheet> createState() => _UpgradesSheetState();
}

class _UpgradesSheetState extends State<UpgradesSheet> {
  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final p = game.profile;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Upgrades   ✦ ${p.dust}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        for (final def in upgradeDefs)
          Builder(builder: (_) {
            final lvl = game.upgLevel(def.id);
            return ListTile(
              dense: true,
              title: Text('${def.name}  ·  Lv $lvl',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              subtitle: Text(
                  '${def.desc}\n${game.upgValue(def.id, lvl)} → ${game.upgValue(def.id, lvl + 1)}',
                  style: const TextStyle(
                      fontSize: 11.5, color: Color(0xFF8E9BFF))),
              trailing: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD166),
                  foregroundColor: const Color(0xFF3A2A00),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: p.dust < def.cost(lvl)
                    ? null
                    : () => setState(() => game.buyUpgrade(def)),
                child: Text('✦ ${def.cost(lvl)}'),
              ),
            );
          }),
      ])),
    );
  }
}

/* ---------------- MARKET (cosmetics — pure style) ---------------- */

class MarketSheet extends StatefulWidget {
  const MarketSheet({super.key, required this.game});
  final EchoOrbitGame game;

  @override
  State<MarketSheet> createState() => _MarketSheetState();
}

class _MarketSheetState extends State<MarketSheet> {
  Widget _swatch(Color c) => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 8)],
        ),
        child: const Center(
          child: SizedBox(
            width: 10,
            height: 10,
            child: DecoratedBox(
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            ),
          ),
        ),
      );

  Widget _equippedChip() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Text('EQUIPPED',
            style: TextStyle(
                color: Color(0xFF5DF2C8),
                fontSize: 11,
                fontWeight: FontWeight.w800)),
      );

  Widget _equipButton(String id) => OutlinedButton(
        style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0x668E9BFF)),
            padding: const EdgeInsets.symmetric(horizontal: 12)),
        onPressed: () => setState(() => widget.game.equipSkin(id)),
        child: const Text('Equip'),
      );

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final p = game.profile;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('MARKET',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 2)),
        const SizedBox(height: 2),
        Text('✦ ${p.dust} stardust   ·   ${p.photons} photons',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFFFFD166))),
        const SizedBox(height: 2),
        const Text('Star skins recolor you and your comet trail.\nPure style — zero pay-to-win.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8E9BFF), fontSize: 11.5)),
        const SizedBox(height: 6),
        // Default look: the prestige tier color.
        ListTile(
          dense: true,
          leading: _swatch(game.tierColor()),
          title: const Text('Prestige tier',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          subtitle: const Text('Your star\'s natural color — grows with Supernovas',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF8E9BFF))),
          trailing: p.skin.isEmpty ? _equippedChip() : _equipButton(''),
        ),
        for (final def in skinDefs)
          ListTile(
            dense: true,
            leading: _swatch(def.color),
            title: Text(def.name,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            subtitle: Text(def.desc,
                style:
                    const TextStyle(fontSize: 11.5, color: Color(0xFF8E9BFF))),
            trailing: game.ownsSkin(def.id)
                ? (p.skin == def.id ? _equippedChip() : _equipButton(def.id))
                : FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: def.premium
                          ? const Color(0xFFB388FF)
                          : const Color(0xFFFFD166),
                      foregroundColor: def.premium
                          ? Colors.white
                          : const Color(0xFF3A2A00),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: (def.premium
                            ? p.photons < def.cost
                            : p.dust < def.cost)
                        ? null
                        : () => setState(() => game.buySkin(def)),
                    child: Text(def.premium
                        ? '${def.cost} photons'
                        : '✦ ${def.cost}'),
                  ),
          ),
      ])),
    );
  }
}

/* ---------------- RUN HUD ---------------- */

class RunHud extends StatelessWidget {
  const RunHud({super.key, required this.game});
  final EchoOrbitGame game;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pill(ValueListenableBuilder<int>(
                    valueListenable: game.runDust,
                    builder: (_, d, __) => ValueListenableBuilder<int>(
                        valueListenable: game.echoDust,
                        builder: (_, e, __) => Text('✦ ${d + e}',
                            style: const TextStyle(
                                color: Color(0xFFFFD166),
                                fontWeight: FontWeight.w700))))),
                _pill(Text('x${game.profile.globalMult.toStringAsFixed(1)}',
                    style: const TextStyle(
                        color: Color(0xFF5DF2C8),
                        fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: game.height,
            builder: (_, h, __) => Text('$h',
                style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          ValueListenableBuilder<int>(
            valueListenable: game.combo,
            builder: (_, c, __) => Text(c > 1 ? 'COMBO x$c' : '',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF7E6B))),
          ),
        ]),
      ),
    );
  }

  Widget _pill(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x8C0B1026),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x408E9BFF)),
        ),
        child: child,
      );
}

/* ---------------- RESULTS ---------------- */

class ResultsOverlay extends StatefulWidget {
  const ResultsOverlay({super.key, required this.game});
  final EchoOrbitGame game;

  @override
  State<ResultsOverlay> createState() => _ResultsOverlayState();
}

class _ResultsOverlayState extends State<ResultsOverlay> {
  bool _adPlaying = false;
  int _adCount = 3;

  Future<void> _watchAd() async {
    setState(() {
      _adPlaying = true;
      _adCount = 3;
    });
    // Simulated rewarded ad; production uses a real opt-in rewarded network.
    // If the ad fails, the reward is granted anyway (docs/02).
    while (_adCount > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _adCount--);
    }
    widget.game.grantDoubleDust();
    if (mounted) setState(() => _adPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    if (_adPlaying) {
      return Panel(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Rewarded ad (simulated)',
              style: TextStyle(fontWeight: FontWeight.w700)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text('$_adCount', style: const TextStyle(fontSize: 44)),
          ),
          const Text('Never forced. Always optional.',
              style: TextStyle(color: Color(0xFF8E9BFF), fontSize: 12)),
        ]),
      );
    }
    final isRecord =
        game.height.value >= game.profile.bestHeight && game.height.value > 0;
    return Panel(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('RUN COMPLETE',
            style: TextStyle(color: Color(0xFF8E9BFF), fontSize: 13)),
        Text('${game.height.value}',
            style:
                const TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
        Text(isRecord ? '★ NEW RECORD' : 'best: ${game.profile.bestHeight}',
            style: const TextStyle(
                color: Color(0xFF5DF2C8),
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        const SizedBox(height: 8),
        StatRow('You collected', '✦ ${game.runDust.value}',
            valueColor: const Color(0xFFFFD166)),
        StatRow('Echo income', '✦ ${game.echoDust.value}',
            valueColor: const Color(0xFF5DF2C8)),
        StatRow('Perfect arcs', '${game.perfects}'),
        StatRow('Universe', '#${game.runSeed}',
            valueColor: const Color(0xFF8E9BFF)),
        StatRow('Galaxy', game.galaxy.name, valueColor: game.galaxy.accent),
        BigButton('RETRY THIS UNIVERSE',
            onTap: () => game.startRun(seed: game.runSeed)),
        Row(children: [
          Expanded(
              child: BigButton('Ad: x2 dust',
                  color: const Color(0xFFFFD166),
                  textColor: const Color(0xFF3A2A00),
                  enabled: !game.doubleUsed,
                  onTap: _watchAd)),
          const SizedBox(width: 8),
          Expanded(
              child: BigButton('Home',
                  color: const Color(0x248E9BFF),
                  textColor: Colors.white,
                  onTap: game.goHome)),
        ]),
      ]),
    );
  }
}

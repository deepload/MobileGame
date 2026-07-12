# ECHO ORBIT — Flutter + Flame app

Production-stack port of the core loop (see `/web/echo-orbit.html` for the full-meta feel prototype, and `/docs` for the design package).

## What's implemented
- Core loop: orbit → tap release → capture (with Perfect Arc detection via impact parameter) → infinite climb
- Save Ring rescue (first fall forgiven), combo, stardust motes with magnet
- Camera follow, particle/trail effects, altitude-shifting background
- Persistence (best height, stardust) via `shared_preferences`
- Home / Results overlays in Flutter widgets around the Flame canvas

Meta systems (upgrades, echoes, prestige, dailies, ads, IAP) live in the design docs and web prototype; port order is defined in `docs/05-roadmap.md` (M2–M4).

## Run it

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.22+).

```bash
cd flutter_app
flutter create . --platforms=android,ios,web   # generates platform folders (first time only)
flutter pub get
flutter run                    # pick a device / emulator
flutter run -d chrome          # web
```

## Structure

```
lib/
  main.dart                    # app shell, overlays (home, results)
  game/echo_orbit_game.dart    # FlameGame: world sim, rendering, input
  services/storage.dart        # local persistence
```

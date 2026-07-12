# ECHO ORBIT

*Tap to leap from orbit to orbit, forever upward. Your greatest runs never die — they fly beside you as Echoes and earn for you.*

A one-touch skill climber for Android, iOS, and Web. Flutter frontend, Rust backend, full design package.

## Try it now (zero install)

Open **`web/index.html`** in any browser. It's the prototype hub:

| Prototype | What it is |
|---|---|
| **Echo Orbit** (flagship) | The full game: core loop + upgrades, Echoes, Supernova prestige, daily challenges, simulated rewarded ads, live leaderboard when the server runs |
| Sky Stack | Rejected V0 concept — play it to feel why it was cut |
| Loop Garden | Ideation variant B |
| Tidal | Ideation variant C |

Everything works offline; progress saves locally.

## Run the backend (Rust)

Easiest — Docker (no Rust toolchain needed):

```bash
docker compose up -d      # builds + starts on http://localhost:8080
```

Or natively:

```bash
cd server
cargo run                 # listens on http://localhost:8080
```

Endpoints: anonymous auth, cloud save (monotonic merge), weekly leaderboard (with sanity anti-cheat), remote config + daily seed. Data persists to `server/data/store.json`. With the server running, the web game shows the live weekly leaderboard on its home screen and submits scores after each run.

## Run the Flutter app (production frontend)

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install):

```bash
cd flutter_app
flutter create . --platforms=android,ios,web   # first time only
flutter pub get
flutter run                                    # or: flutter run -d chrome
```

Full game: core loop, upgrades, Echo recording/replay, prestige, dailies, simulated rewarded ads, offline-first backend sync (`API_URL` dart-define to point at your server).

## Design package (`/docs`)

| File | Contents |
|---|---|
| `00-ideation.md` | First idea → investor critique → 3 variants → selection → refinement |
| `01-concept-gameplay.md` | Concept, engagement psychology, gameplay & progression loops, <30s tutorial |
| `02-economy-monetization.md` | Currencies, chests, ethical monetization, rewarded-ad placements |
| `03-ux-ui-art-sound.md` | UX doctrine, palette, sound design, all 12 screens |
| `04-tech-architecture.md` | Stack choice rationale, architecture, database schemas |
| `05-roadmap.md` | 6-month dev plan, 3-year roadmap |
| `06-analytics-kpis.md` | A/B testing system, KPI targets & alarms |
| `07-risks-growth.md` | Risk register, path to 10M+ downloads |

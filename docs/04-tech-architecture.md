# Stack Choice, 12. Database, 13. Architecture

## Stack decision

| Criterion | Flutter + Flame | Unity | React + Phaser | Godot |
|---|---|---|---|---|
| Android + iOS + Web from one codebase | Excellent | Good (web export heavy: 20–50 MB, slow boot) | Web-first, mobile via wrappers (perf/offline weaker) | Good, web export still maturing on mobile browsers |
| Battery / perf for 2D vector | Excellent (Impeller, no per-frame GC pressure with care) | Overkill runtime; higher idle drain | JS + DOM/canvas: worst battery of the four | Good |
| Binary size | ~12–18 MB | 35–80 MB | small web, but native shell adds up | ~25–40 MB |
| Cold start / instant resume | <2 s, state restore trivial | 3–6 s typical | fast web, weaker native lifecycle | 2–4 s |
| UI chrome (menus, shops, lists) | Best-in-class (Flutter widgets around the Flame canvas) | Painful (UI toolkit friction) | Good (React) | Mediocre |
| Localization tooling | ARB/intl, mature | Asset-based, manual | i18next, fine | gettext, fine |
| LiveOps / OTA config | Firebase Remote Config first-class | Fine | Fine | DIY |
| Licensing / fees | Free, BSD | Runtime fee history = platform risk | Free | Free, MIT |
| Team velocity for this scope | High (one Dart codebase, hot reload) | Low-medium | Medium (two ecosystems: game + native shells) | Medium |

**Choice: Flutter + Flame.**
Rationale: the game is 2D vector minimalism with heavy *UI* meta (shop, collections, challenges) — exactly Flutter's strength — and a light simulation core (closed-form orbits, no physics engine) — exactly what Flame handles at 60 fps with minimal battery. One codebase ships Android, iOS, and Web (CanvasKit). Unity is oversized and web-hostile for this scope; Phaser splits the stack; Godot's mobile-web export and UI tooling add risk without benefit.

**Prototype note:** a pure HTML5 prototype (`web/index.html`) exists for instant zero-install testing of feel and tuning; the Flutter app is the production target.

**Backend note:** the backend is implemented in **Rust (axum)** — see `/server`. It is a self-hostable reference implementation of the contract below (anonymous auth, cloud-save monotonic merge, weekly leaderboards with sanity anti-cheat, remote config + daily seed). Firebase remains a valid managed alternative for teams preferring zero-ops; the HTTP contract is identical either way.

## 13. Architecture

```
┌──────────────────────── Client (Flutter) ────────────────────────┐
│  Presentation                                                    │
│   ├─ Flame GameWidget (run scene: orbits, echoes, particles)     │
│   └─ Flutter widgets (home, shop, collections, settings)         │
│  Application                                                     │
│   ├─ Riverpod state (profile, economy, run session)              │
│   ├─ RunEngine  — deterministic sim, seeded RNG                  │
│   ├─ EchoRecorder/Player — path sampling @10 Hz, delta-encoded   │
│   ├─ EconomyService — earn/spend, guardrail asserts              │
│   └─ ChallengeService, EventService, AchievementService          │
│  Infrastructure                                                  │
│   ├─ LocalStore (drift/SQLite + secure prefs)   ← OFFLINE TRUTH  │
│   ├─ SyncQueue (pending ops, replays on connectivity)            │
│   ├─ Analytics facade (batched, offline-buffered)                │
│   └─ Ads facade (rewarded only; grants on failure)               │
└───────────────┬──────────────────────────────────────────────────┘
                │ HTTPS, opportunistic
┌───────────────▼───────────── Backend (thin, Firebase) ───────────┐
│  Auth (anonymous → optional Apple/Google link)                   │
│  Cloud Save: profile blob + version vector (last-write-wins       │
│              per-field, server max() for monotonic counters)     │
│  Leaderboards: weekly buckets, brackets of 50 (Cloud Functions)  │
│  Remote Config: tuning params, A/B assignments                   │
│  Analytics: BigQuery export → dashboards                         │
│  Receipt validation (Functions) for IAP                          │
└──────────────────────────────────────────────────────────────────┘
```

Key decisions:

- **Offline-first:** the device is the source of truth for progression; server only syncs, validates purchases, and hosts leaderboards. The game is 100% playable with radio off.
- **Determinism:** run simulation uses a seeded RNG (`seed = f(profileId, dayIndex, prestigeCount)`), so Echo replays align with ring layouts and desyncs are impossible.
- **Battery:** frame loop pauses on background & on home screen after 10 s idle (falls to 10 fps ambient); no physics engine — orbits are closed-form math; particle budget capped (200); Impeller renderer; dark palette is OLED-friendly.
- **Anti-cheat (leaderboards only):** run summaries carry a checksum of the input log; Functions spot-replay top-100 entries. Cheating can never affect another player's economy.
- **Modularity for LiveOps:** events, challenges, and pods are data-driven JSON delivered via Remote Config — no app release needed for a new event.

## 12. Database

### Local (SQLite via drift — offline truth)

```sql
profile(id, created_at, star_tier, photons, prisma, stardust,
        prestige_count, best_height, total_runs, settings_json)

upgrades(upgrade_id, level)                    -- 7 rows
photon_nodes(node_id, unlocked_at)             -- skill tree
echoes(slot, run_id, dust_value, height, path_blob, recorded_at)
runs(run_id, seed, height, dust_earned, perfects, combo_max,
     duration_ms, ended_at)                    -- ring buffer, last 200
challenges(challenge_id, kind, target, progress, expires_at, claimed)
streak(current, best, shields, last_day)
collections(card_id, count, first_at)
achievements(ach_id, progress, completed_at)
inventory(item_id, kind, equipped)             -- skins, boosters
pods(pod_id, rarity, opened_at, contents_json, pity_counter)
sync_queue(op_id, op_json, created_at)         -- pending server ops
run_state(json)                                -- instant-resume snapshot
```

### Cloud (Firestore)

```
users/{uid}
  profileBlob         (compressed, versioned; monotonic fields merged via max)
  purchases/{txId}    (validated receipts)
leaderboards/{week}/brackets/{bracketId}/entries/{uid}
  {height, checksum, star_tier, country}
referrals/{code} → {ownerUid, uses}
events/{eventId}    (config mirrored from Remote Config for audit)
```

Sync policy: push on app background + every 5 min while online; pull on boot. Conflicts: per-field merge, monotonic counters take `max`, inventories take union, settings take latest. Cloud save is optional but offered after first prestige ("protect your progress").

### Analytics events (→ BigQuery)

`run_start, run_end(height, dust, perfects, combo, duration, revived)`,
`upgrade_bought(id, level)`, `prestige(photons, count)`, `ad_offer_shown/accepted(placement)`,
`iap(sku, price_tier)`, `pod_opened(rarity, pity)`, `challenge_done(id)`,
`share(kind)`, `referral(step)`, `session(length, runs)` — all batched, anonymized, consent-gated.

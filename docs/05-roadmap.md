# 15. 6-Month Development Plan & 16. 3-Year Roadmap

## 15. Development plan — 6 months to global launch

Team: 2 Flutter/Flame devs, 1 game designer/economist, 1 artist/animator, 1 sound designer (part-time), 1 producer/QA, 1 data analyst (from M3), 1 marketer (from M4).

### M1 — Core feel ("the toy")
- RunEngine: orbits, tangent release, capture, save ring, dust, perfect arcs, combos.
- Feel-tuning sprint: 3 playtest rounds/week; exit criterion — testers replay ≥5 runs unprompted ("toy test").
- HTML5 feel-prototype used for rapid tuning in parallel.

### M2 — Meta loop
- Upgrades, economy v1, Echo record/replay, results screen, home orbit, local persistence + instant resume.
- Tutorial-as-first-run. Sound pass 1 (capture melody system).
- Exit: internal D1 proxy — testers return next day ≥ 50%.

### M3 — Depth & retention systems
- Supernova prestige + photon tree, daily/weekly challenges, streaks (with shields), achievements, collections + pods (visible odds + pity), skins/loadouts.
- Analytics pipeline live; Remote Config wiring; cloud save.
- **Closed alpha (200 players, 2 weeks):** measure D1/D7 proxies, tune economy guardrails.

### M4 — Monetization & polish
- Rewarded ad placements (all 6), season pass scaffold, shop, Supporter Pack, IAP + receipt validation, spend caps, parental gates, COPPA/GDPR-K audit.
- Performance pass: 60 fps on 2018-era devices, battery budget ≤ 3%/15 min session, cold start < 2 s.
- Localization: EN source + 12 languages (FIGS, PT-BR, DE, JA, KO, ZH-Hans, ZH-Hant, AR, RU, TR, ID).

### M5 — Soft launch (PH, NZ, CA, Nordics)
- Gates to proceed: **D1 ≥ 55%, D7 ≥ 30%, crash-free ≥ 99.7%, avg rating ≥ 4.6**, rewarded-ad opt-in ≥ 35%.
- Two economy A/B rounds + one FTUE A/B round (see doc 06).
- Leaderboards, friends, referral system; web build hardening (PWA, offline cache).
- If gates missed: M5 repeats with fixes (buffer is built in — feature-complete at M4).

### M6 — Global launch
- Marketing beats (see doc 07), featuring pitch to Apple/Google (strong case: original mechanic, ethical monetization, offline, small binary, 7+).
- Launch event "First Light" (2-week seasonal), creator kit published, community channels open.
- War-room fortnight: daily KPI review, hotfix lane, live-tuning via Remote Config only.

## 16. 3-year roadmap

### Year 1 — Deepen the solo game (make D30 → D180)
- **Q1:** Seasons 1–2; event archetypes (Meteor Rush, Nebula Bloom); photon tree branch 4; weekly "Gauntlet" fixed-seed challenge (same sky for everyone → shareable fair comparisons).
- **Q2:** **Echo Duels (async PvP):** race a friend's recorded run — no live netcode, offline-friendly, pure ghost racing. Clubs ("Constellations") with shared weekly goals.
- **Q3:** Biome skies (visual+modifier zones every 50 heights), star tier ladder extension, mastery achievements v2, tablet/web UX polish.
- **Q4:** Year-1 anniversary "Supernova Festival"; prestige layer 2 ("Galaxy Core") for veterans; creator tooling (replay export as video with one tap → TikTok/Shorts pipeline).

### Year 2 — Social gravity & platform expansion
- Club leagues, mentor system (veteran echo gifted to newcomers — onboarding *and* social flex), global community events ("the whole playerbase climbs one shared tower").
- Cross-progression polish; Play Pass / Apple Arcade conversations; desktop PWA & app-store web listing.
- UGC-lite: players compose "Sky Remixes" (pick modifiers, share a code) — content cost approaches zero.
- New engagement surface: home-screen widget (streak, daily, friend activity) — battery-free presence.

### Year 3 — Franchise & longevity
- "Echo Orbit: Zen" mode (endless no-fail meditative mode → broadens audience, press angle).
- Annual "Constellation World Cup" (bracketed gauntlet e-sport-lite, spectator replays).
- Companion mini-experiences (watchOS/Wear glance game feeding boosters back to main app).
- Evaluate sequel/spin-off vs. continued LiveOps using Y2 cohort LTV curves; target: ≥ 40% of Y1 MAU still monthly-active in Y3 (genre-topping longevity).

Content cadence (steady state): 6 seasons/year, monthly event, weekly gauntlet, daily challenges — 80% data-driven via Remote Config, no client release required.

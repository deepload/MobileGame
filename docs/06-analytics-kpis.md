# 17. A/B Testing System & 18. KPIs

## 17. A/B testing system

**Infrastructure:** Firebase Remote Config + Analytics → BigQuery. Deterministic assignment: `bucket = hash(uid, experimentId) % 100`. Sticky per experiment. New-user experiments assign at first open; existing-user experiments respect cohort age. Offline-safe: config cached at boot, experiments never block play.

**Governance:**
- One primary metric per experiment, declared before launch; guardrail metrics (crash rate, session length, rating prompts, spend) must not regress > 2%.
- Minimum sample: power analysis first (typically 10–20k users/arm for retention deltas of 2 pts); run ≥ 7 days (full weekly cycle); Bayesian evaluation (probability-of-best > 95% to ship).
- **Ethics rule:** experiments may never test dark patterns (hidden odds, tighter paywalls, forced ads). Monetization tests only vary *presentation and generosity upward*.
- Registry: every experiment logged (hypothesis, arms, result, decision) — institutional memory against re-testing.

**Launch-window experiment backlog (priority order):**

| # | Area | Hypothesis | Primary metric |
|---|---|---|---|
| 1 | FTUE | Assisted first 3 captures (×3 window) raises D1 | D1 |
| 2 | FTUE | Showing the first Echo at run 2 vs run 3 | D1, runs/session |
| 3 | Economy | First upgrade affordable after run 1 vs run 2 | D1 |
| 4 | Difficulty | Save Ring default 1 vs 2 charges | D7, frustration-quit rate* |
| 5 | Ads | "Double Down" offered only after above-median runs vs always | opt-in rate, D7 |
| 6 | Prestige | Supernova unlock at height 50 vs 40 | D14, prestige adoption |
| 7 | Pods | Pity at 10 vs 8 | pod-open rate, sentiment |
| 8 | Notifications | Daily reminder copy variants (progress-framed vs streak-framed) | DAU lift, opt-out rate |

*frustration-quit = session ending < 10 s after a fall, app not reopened same day.

## 18. KPIs

### North-star
**Weekly Returning Climbers** — players with ≥ 3 sessions in a week. Combines retention + habit in one number.

### Retention & engagement (targets)

| KPI | Target | Alarm |
|---|---|---|
| D1 / D7 / D30 | > 60% / > 35% / > 20% | < 50 / < 28 / < 15 |
| Sessions per DAU | ≥ 4 | < 2.5 |
| Avg session length | 7–12 min | < 4 min |
| Runs per session | ≥ 5 | < 3 |
| "One more run" rate (retry < 5 s after results) | ≥ 70% | < 50% |
| Streak ≥ 7 days share of MAU | ≥ 25% | — |
| Prestige adoption by D14 | ≥ 40% of retained | < 25% |

### Fun & frustration (the ones most teams don't track)

- Frustration-quit rate < 8% of sessions.
- Save-Ring rescue → continued-play conversion ≥ 90%.
- Perfect Arc rate per player over time (skill growth curve — must rise for weeks; plateau = add depth).
- Echo engagement: % of players who watch their echo finish (proxy: camera follows) — signature-mechanic health.

### Monetization (ethical envelope)

| KPI | Target | Note |
|---|---|---|
| Rewarded ad opt-in (DAU) | ≥ 40% | it's a *feature*, adoption = it feels good |
| Ads per opting DAU | 2–4 | cap 6 |
| Payer conversion D30 | 3–5% | |
| ARPDAU | $0.08–0.15 at launch | |
| Refund rate | < 0.5% | generosity check |
| Spend-cap hits | ~0 | if >0.1% of payers, review pricing |

### Sentiment & virality

- Store rating ≥ 4.8; reviews containing "generous/fair/relaxing/satisfying" tracked via text mining (target: 20% of reviews).
- K-factor ≥ 0.25 at launch (referrals + shares); share-card CTR ≥ 8%.
- Crash-free sessions ≥ 99.8%; ANR < 0.1%; cold start p95 < 2.5 s; battery ≤ 3%/15 min on reference device.

Dashboards: real-time ops (crashes, DAU, ad fill), daily cohort (retention curves per acquisition source), weekly economy (earn/sink 0.9–1.1), monthly sentiment. Every alarm has a named owner and a Remote-Config lever ready.

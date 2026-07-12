# 1–5. Concept, Addictiveness, Loops, Tutorial

## 1. Game concept

**ECHO ORBIT** — a one-touch skill climber.

A small star orbits a glowing ring. Tap anywhere: the star releases along its tangent and flies until the next ring's gravity captures it. Each ring climbed = +1 Height. The sky is infinite; rings get livelier with altitude (moving, shrinking, spinning faster, twin rings, storm rings full of bonus dust).

**The invention — Echoes:** your best past runs are recorded and replay *live* beside you as translucent ghost stars. They fly their old paths and collect stardust *for you* during your current run. Every good run permanently enriches all future runs. You climb with, race against, and profit from your past selves.

- Session: 30 s (bad run) to ~5 min (great run).
- Input: one thumb, tap anywhere. No drag, no aim, no menus mid-run.
- Fail state is forgiving: a Save Ring catches your first fall each run.
- Fully offline; instant resume mid-orbit.

## 2. Why it will be "addictive" (engagement by design, not dark patterns)

| Psychological driver | Implementation |
|---|---|
| **Competence** (I'm getting better) | Visible skill ceiling: Perfect Arcs, ring skips, combo chains. Your ghost is the calibrated benchmark — always beatable because it *is* you on a good day. |
| **Near-miss framing** | Falling triggers the Save Ring, converting failure into a rescue moment ("phew!") instead of punishment. The run ends only on the second mistake, when the player already feels responsible, not robbed. |
| **"One more run"** | Runs are short; the next goal is always <2 min away (next milestone height, daily challenge tick, upgrade 90% affordable). Game restarts in <1 s, no interstitials, no lives system, no energy gate. |
| **"I'm close to something"** | Three progress bars visible on the home screen at all times: next upgrade, daily challenge, next collection card. At least one is always ≥70% full (economy is tuned for this). |
| **"I unlock something"** | Unlock cadence: minutes 0–10 → every 1–2 min (upgrades); day 1–7 → daily (skins, echo slots, prestige); week 2+ → weekly (collections, events). |
| **Endowment & identity** | Echoes are literally the player's own play, made into a possession. Skins/trails/constellations personalize the star. |
| **Loss aversion, used ethically** | Nothing is ever taken away. Streaks pause (never reset to zero) with one "streak shield" per week, free. |
| **Variable reward, bounded** | Nebula Pods have visible odds and a pity counter (guaranteed rare ≤ 10 pods). Excitement without deception. |

**The anti-frustration contract** (printed inside the design, enforced in every feature): the player must never lose progress, never wait to play, never be interrupted by ads, never hit a paywall for power, never fail on their first mistake.

## 3. Gameplay loop (moment-to-moment, ~5–20 s per beat)

```
        ┌────────────────────────────────────────────┐
        ▼                                            │
  ORBIT (safe, readable, star circles the ring)      │
        │  player reads next ring's motion            │
        ▼                                            │
  TAP → RELEASE (commitment, tension)                │
        │  tangent flight, trail, dust pickups        │
        ▼                                            │
  CAPTURE (relief + reward)                          │
        ├─ normal: +dust, +1 height, soft pluck      │
        ├─ PERFECT ARC: flash, ×2 dust, combo +1     │
        ├─ RING SKIP: big combo, screen sparkle ─────┘
        │
        └─ MISS → SAVE RING catches you (1st fall)
                 → 2nd fall: run ends → RESULTS
                    (dust total × multipliers, records,
                     challenge progress, "+X from Echoes")
                    → one tap restarts
```

Tension micro-cycle: safety (orbit) → risk (flight) → relief (capture) → reward (dust/combo). ~6 cycles per minute. Combo raises stakes gradually; the player chooses risk (skips) for more reward.

## 4. Progression loop (session-to-session)

```
  Run earns STARDUST ──► permanent UPGRADES (magnet, guide,
        ▲                 save rings, echo slots, echo yield)
        │                          │ makes runs richer & higher
        │                          ▼
   ECHOES improve ◄── better runs get recorded as new Echoes
        │                          │
        │                          ▼
        │            Height 50+ ──► SUPERNOVA (prestige):
        │              reset upgrades, earn PHOTONS
        │              (permanent ×mult + skill tree + star tier)
        │                          │
        └──────────────────────────┘  each loop is faster & deeper

  Parallel long-term tracks:
  • Daily challenges (3/day) & Weekly challenge → pods, prisma
  • Collections: constellation cards from Nebula Pods
  • Achievements (200+, lifetime)
  • Seasonal events (6/year, cosmetic + event heights)
```

- **Short-term goals (this session):** beat height record, finish a daily, afford the next upgrade.
- **Medium-term (this week):** first/next Supernova, complete a constellation, weekly challenge, climb the friends leaderboard.
- **Long-term (months/years):** photon skill tree, star tier ladder (12 tiers), full collections, seasonal exclusives, mastery achievements (e.g., "20 Perfect Arcs in one run").

The loops interlock: skill → dust → upgrades → more Echo income → higher climbs → prestige → multipliers → new skill expression (busier skies). Progress never makes the core *easier and duller* — it makes the sky *richer*.

## 5. Tutorial (< 30 seconds, zero text walls)

The tutorial is the first run. No screens, no popups; contextual hints of ≤4 words.

| t | What happens | Teaching |
|---|---|---|
| 0–3 s | Game opens directly into orbit on Ring 1. Pulsing hint: **"TAP"** with a finger icon. | The only verb. |
| 3–6 s | First tap auto-assisted (capture window ×3). Capture fireworks, "+5 ✦". | Tap → fly → new ring → reward. |
| 6–12 s | Rings 2–4: dust motes placed exactly on the natural arc. "✦ = upgrades" flashes once near the dust counter. | Flight collects currency. |
| 12–18 s | Ring 5's core glows: hint **"through the center!"** → first Perfect Arc, slow-flash, ×2. | The skill dimension. |
| 18–24 s | A deliberately hard ring → player likely falls → **Save Ring** catches them: "Saved! 1 per run". | Failure is survivable; sets the rule honestly. |
| 24–30 s | Run ends around Height 8. Results screen shows one big button: **"UPGRADE: Aim Guide (affordable)"**. First upgrade is guaranteed affordable from run 1. | The meta loop, taught by doing. |

Second run: a translucent replay of run 1 flies alongside — banner: **"Your Echo. It earns for you."** The signature mechanic is *shown*, never explained. Total onboarding text: ~12 words, all iconizable, trivially translatable.

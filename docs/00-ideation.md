# Ideation — From First Idea to Final Concept

> Rule followed throughout: **never stop at the first idea.** Concept → harsh critique → 3 better versions → pick → refine until improvements become marginal.

---

## 1. Initial concept (V0): "Sky Stack"

One-touch timing game: blocks swing across the screen, tap to drop and stack them. Perfect drops keep the block full-size; misses shave it. Height = score. Meta layer: spend coins on permanent block width, slow-motion, and prestige "Demolish" resets for multipliers.

**Why it seemed good:** understood in 3 seconds, one-hand, 30s runs, infinite height, clean minimalist look.

## 2. Investor critique of V0 (deliberately harsh)

| # | Criticism | Severity |
|---|-----------|----------|
| 1 | **Derivative.** It is Ketchapp's *Stack* with an idle layer. Zero novelty = zero press, zero word-of-mouth, ASO death. | Fatal |
| 2 | **Shallow skill ceiling.** One timing window, no route choice, no expression. D30 > 20% impossible. | Fatal |
| 3 | **No spectacle.** Nothing to screenshot, nothing to share. Virality plan has no engine. | High |
| 4 | **Meta is bolted on.** Upgrades make the timing window bigger → game gets *less* interesting as you progress. Progression fights the fun. | High |
| 5 | **No emotional hook.** Nothing is "yours". No collection identity, no story of your own improvement. | Medium |

**Verdict: rejected.** Requirements for the next round: an original mechanic that (a) has a visible skill ceiling, (b) produces spectacle by itself, (c) has a meta layer that makes the game *more* interesting over time, (d) creates a personal, shareable artifact.

## 3. Three improved versions

### Version A — "Echo Orbit" (working title)
A tiny star orbits a glowing ring. **Tap to release** — it flies off along the tangent. Get captured by the next ring above. Climb an infinite sky of rings. The twist: **your best past runs replay beside you as ghost "Echoes"** that collect bonus stardust for you, live, during your run. You literally fly alongside your former selves; every run makes your future runs richer.

- Skill: release timing = trajectory choice; "Perfect Arc" through a ring's center; ring-skipping for combos.
- Meta that deepens play: upgrades add Echo slots, magnet radius, save rings — the sky gets *busier and more alive*, not easier and duller.
- Spectacle: 3 ghost stars + you, trails everywhere. A late-game screenshot looks like a comet shower.
- Emotional hook: the Echoes ARE you. Beating your ghost is the oldest, strongest motivator in games (time-trial ghosts), never done as a *cooperative economy* in a casual one-touch game.

### Version B — "Loop Garden"
Draw small loops with your thumb to capture drifting fireflies; captured light grows a zen garden that persists forever. Daily bloom cycles, collection of rare species.

- Strength: extremely relaxing, strong collection meta, beautiful.
- Weakness: drawing loops is a two-dimensional gesture — marginal for strict one-thumb reachability; skill expression is fuzzy; runs are hard to keep under 5 min; "understood in 10s" is borderline (capture rules need explaining).

### Version C — "Tidal"
Hold to pull the tide back, release to send a wave that pushes treasures up the beach. Distance physics, treasure collection, beach-building meta.

- Strength: novel verb (charging a wave), satisfying physics.
- Weakness: one-shot charge-and-release loop is closer to *Golf Orbit / Steve the Jumper* launcher games than it first appears; depth comes from watching, not doing; sessions risk becoming passive idle checking. Skill ceiling low.

## 4. Selection

| Criterion (weight) | A: Echo Orbit | B: Loop Garden | C: Tidal |
|---|---|---|---|
| Understood in <10s (×3) | 5 | 3 | 4 |
| Original mechanic (×3) | 5 | 4 | 3 |
| Skill ceiling / "I can do better" (×2) | 5 | 3 | 2 |
| One-hand strictness (×2) | 5 | 3 | 5 |
| Built-in spectacle & virality (×2) | 5 | 4 | 3 |
| Meta deepens (not dilutes) the core (×2) | 5 | 4 | 3 |
| Years-long durability (×2) | 4 | 4 | 3 |
| **Weighted total (max 80)** | **77** | **57** | **53** |

**Winner: Version A — Echo Orbit.**

## 5. Refinement rounds on Echo Orbit

### Round 1 — kill frustration
- **Problem:** missing a ring = instant death → rage, low D1.
- **Fix:** a **Save Ring** materializes and catches your first fall of every run (visibly, with a satisfying "phew" sound). Second fall ends the run. Upgradeable to 2–3 charges. Optional rewarded ad = one revive. Death is always the player's *second* mistake, never the first.
- **Fix:** generous capture tolerance + a subtle aim guide (short tangent line) that *grows* with an early upgrade — beginners get accuracy help fast.

### Round 2 — make every second rewarding
- **Problem:** dead air between rings.
- **Fix:** stardust motes line the space between rings along "intended" arcs — flight itself pays. Magnet upgrade widens collection. **Perfect Arc** (passing near the next ring's core) triggers slow flash + ×2 dust + combo counter. Ring-skip (jumping past a ring to a higher one) = big combo spike. Every action has a coin sound attached.

### Round 3 — make the meta a story
- **Problem:** upgrades as flat +% are forgettable.
- **Fix:** **Supernova prestige** — at Height 50+, collapse your star: the sky resets, you earn **Photons** (permanent ×multiplier + skill-tree points) and your star's core visibly changes color tier. Long-term identity: constellation **Collections** (cards from Nebula Pods), star **Skins & trails**, achievements. Echo slots are the marquee upgrades: going from 1 ghost to 3 ghosts is a visible, dramatic power-up.

### Round 4 — sharpen the hook sentence
> **"Climb the sky, one tap per orbit — and your past best runs fly with you, earning for you."**

Understood in one screenshot: a star orbiting a ring, dotted arc to the next ring, two translucent ghost stars mid-flight.

### Round 5 — stress-test vs. requirements (final check)
- One hand: single tap anywhere. ✔
- 30s–5min: rings/minute tuned so casual run ≈ 90s, great run ≈ 4min. ✔
- Offline: fully local sim; leaderboards sync later. ✔
- Instant resume: run state serialized every capture; app reopens mid-orbit. ✔
- Battery: 2D canvas/Flame vector rendering, pause on background, no physics engine (closed-form orbits + straight-line flight). ✔
- 7+: abstract, zero violence. ✔
- Translatable: ~200 short strings, no text in art, numbers are universal. ✔
- Not a copy: *Orbit-style* tap games exist, but **the cooperative-ghost economy (Echoes) is the invention** — no shipped title uses "your replays as live earning companions" as the core meta.

Further rounds produced only marginal ideas (weather skins, orchestral stingers) → **refinement stopped. Concept frozen.**

## 6. Final identity

- **Title:** **ECHO ORBIT**
- **Genre:** one-touch skill climber with a self-echo meta economy
- **Pitch:** *Tap to leap from orbit to orbit, forever upward. Your greatest runs never die — they fly beside you as Echoes and earn for you.*

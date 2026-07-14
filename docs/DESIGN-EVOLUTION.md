# ECHO ORBIT — THE EVOLUTION DOSSIER
## Reverse engineering · diagnosis · the systems that make the game begin at Galaxy 3

*Everything in Part I is computed from the actual code (`echo_orbit_game.dart`,
`storage.dart`, `main.rs`), not from memory or guesswork. Every proposal in
Parts III–IX respects the five invariants in the Constraint Box. Nothing here
replaces an existing mechanic — everything grows out of one.*

---

# PART I — REVERSE ENGINEERING THE GAME THAT EXISTS

## 1. The gameplay loop (as coded)

One verb: **tap**. The star orbits a spinning ring; tapping launches it on the
tangent, in the spin direction, at `560 px/s × speedMult`. There is no aiming —
direction is fully determined by *when* you tap. Capture happens when the
flight line enters any of the next 4 rings (`_checkCapture` scans
`_ringIndex+1 … +5`). A Perfect Arc is an impact parameter < 34% of the ring
radius. Miss = fall; a rescue re-attaches you to your last ring; out of
rescues = run over.

The loop, one level up: **orbit → read the alignment → tap → capture (or
skip 2–4 rings for +combo) → repeat**, punctuated by a pick-1-of-3 sigil at
heights 10, 24, 40, then every +25.

The loop, at the meta level: **run → bank dust → buy soft-asymptote upgrades →
unlock the next galaxy → prestige (Supernova) → photons → global mult**.

## 2. The dopamine loop

Per-second: capture flash + gold `+N` float + combo tick. Per-10-seconds:
breather ring (every 8th — the guaranteed exhale), storm cloud (13×3 motes),
skip celebration. Per-minute: sigil card. Per-run: galaxy-best, unlock toast,
rank-up toast. Per-day: daily seed, 3 dailies, weekly Champions.

This cadence is *excellent* for the first hour. Note what's missing above the
per-minute band once the shop and sigil pool are exhausted: **nothing new ever
fires between "sigil card" and "galaxy unlock"** — and unlock spacing grows
(`unlockHeight: 60 + k*12`) exactly as the player gets slower per attempt.

## 3. The frustration loop — and its hidden toothlessness

Fall → combo reset (the real sting) → rescue → re-climb. Death itself is
economically painless: `_endRun()` banks *everything* (`profile.dust +=
runDust + echoDust`). **Nothing is ever at stake mid-run.** There is no
push-your-luck anywhere in the economy — GLASS STAR is the only mechanic in
the entire game that makes the heart rate rise, which is why it's everyone's
most-remembered sigil. That's a diagnosis, not an accident.

## 4. The mastery curve

Skill = timing, and exactly one expressive decision: *skip or don't*. The
ceiling (chained 3–4-ring skips through movers at +70% spin) is genuinely
high. But the curve is one-dimensional: at height 300 you are making the same
decision as at height 10, just faster and smaller. The pilot guide's own
world-gen table proves it: from ▲25 to ▲200 the game changes by −10 px of
radius and +49 pp of spin. **The numbers change; the questions don't.**

## 5. The progression & economy curves

- Ring dust: `5 × (1 + 0.1·combo) × 2^perfect × 2^skip × globalMult × reward × sigils`
- Galaxy reward: `2.6 × 1.30^k` — exponential. Upgrade costs: `base × 1.7–2.2^level`
  with `l/(l+c)` effects — the shop is deliberately asymptotic.
- Consequence, verified in the numbers: by mid-Frost the shop is 80% solved
  (Keeper 3, Sense 3, Magnet 4 ≈ 6k dust ≈ two good Frost runs). After that,
  dust buys almost nothing you can feel. Skins are one-time sinks. Photons →
  `1 + 0.10×photons` is the only open-ended sink, and it's a flat number.

## 6. Player psychology profile

The game courts two players: the **racer** (daily seed, ghosts, live room,
Champions math, ranks — all superbly wired) and the **builder** (sigils,
upgrades, prestige). The racer's game is deep and honest. The builder's game
is shallow: 8 sigils, all pure stat multipliers, zero interactions, pool
exhausted by the third offer of the *first good run* (offers at ▲10/▲24/▲40
draw 9 cards from a pool of 8). The builder is the one who churns at Galaxy 3.

## 7. Where boredom sets in — the exact seam

"After Galaxy 3, around score 300" = height ~22 in FROST VEIL (score =
h × 1.38 × 10). At that exact moment, all of these run out simultaneously:

1. **Sigil pool exhausted** — every card seen, picks solved (GLASS+COMET for
   dust; STILL SKY never; GRAVITY KISS only when scared).
2. **Content complete** — storms, movers, breathers all seen by ▲15 of Lumen.
   Bumpers and mutations don't exist until galaxy 5 — *the two freshest
   systems in the game are gated behind the churn point*.
3. **Shop solved** — see §5.
4. **World is a 1D column** — `x` clamped to 28–72% of screen width, one ring
   per 175 px of altitude. There is never a *route* decision, only a timing one.
5. **No events, no secrets, no discovery** — the game has zero hidden rules to
   find. Players sense this fast; the "what happens if…?" well is dry.
6. **Difficulty = numbers** — smaller radius, faster spin. Exactly the fake
   difficulty the design philosophy (correctly) forbids going forward.

## 8. What is already GREAT (protect at all costs)

- **Determinism as religion.** Seeded universes, seeded sigil offers, guarded
  RNG draws (bumpers don't disturb handcrafted-galaxy layouts). This is a
  world-class foundation for fair racing that Isaac and Noita *wish* they had.
- **One-tap purity.** The whole game through one input.
- **The social layer** — echoes, ghost racing, live rooms, wrecks of rivals'
  runs are already 70% built in the netcode.
- **The lore ladder** — Lights every 12 galaxies, endless universes.
- **Closed-form orbits** — battery-cheap, deterministic, portable to a server.

---

## CONSTRAINT BOX — every idea below obeys all six

| # | Invariant | Source |
|---|---|---|
| C1 | One input: tap (variants of *when/whether*, never new buttons) | game identity |
| C2 | Seed-deterministic — same seed = same universe for every racer | fairness religion |
| C3 | No RNG-draw-order breakage on existing galaxies (gate new draws like bumpers are gated) | `_addRing` comments |
| C4 | Closed-form math only, no physics engine | docs/04, battery |
| C5 | Offline-first; server additions mirror client formulas | `main.rs` scoring |
| C6 | No gameplay power for money — photons stay cosmetic-adjacent | market design |

---

# PART II — PHILOSOPHY EXTRACTED FROM THE GREATS
*(not their mechanics — the reason those mechanics work, mapped to Echo Orbit)*

| Game | The philosophy | What it means here |
|---|---|---|
| Balatro | Depth = small pool × combinatorial interactions, not big pool | 8 sigils that multiply is shallow; 12 sigils that *trigger off each other* is bottomless |
| Slay the Spire | Every offer is a build question, not a stat question | A sigil should change *what you look for in the sky*, not your income rate |
| Hades | Failure must feed forward narratively and mechanically | Death should leave something in the world (wrecks) and advance something permanent (the Book of Light) |
| Isaac | Secrets make players evangelists — depth must be rumored, not listed | Ship hidden rules. Patch notes that say "???" |
| Noita | The world obeys rules, not scripts — players break the rules open | Weather, anomalies and comets must be *systems* that collide, never scripted set-pieces |
| Risk of Rain | Time itself is a pressure system | A run needs phases; the sky should *change state* as you climb |
| Vampire Survivors | The build must become visible on screen | A late-run star should *look* like its sigil stack |
| Outer Wilds | Knowledge is the only progression that never inflates | Some unlocks should be *learnable facts* (the comet schedule, the anomaly bands) |
| Nintendo | Introduce, develop, twist, pay off — every mechanic gets a full arc | Storms/movers/bumpers each deserve a twist tier, not a flat existence |
| FromSoft | The wall must be honorable — bosses, not stat walls | Light gates deserve guardians |

---

# PART III — THE FLAGSHIP SYSTEMS
*(full treatment; these are the load-bearing walls of the evolution)*

---

## SYSTEM 1 · CONSTELLATIONS — sigil fusion

**Purpose.** Convert the sigil system from 8 solved cards into a combinatorial
build space, at near-zero content cost.

**Gameplay.** Certain sigil *pairs* fuse on acquisition into a Constellation —
a new rule, not a stat. Examples:
- GLASS STAR + PHOENIX FEATHER → **REBORN GLASS**: rescues stay locked at 0,
  but your first death detonates every on-screen ring into motes and revives
  you once. (The pact and the feather argue; you get one miracle.)
- COMET HEART + WILD ARC → **METEOR**: skips no longer cap at 4 rings —
  capture scan extends 7 ahead, but plain (non-skip) captures pay 0.
- ECHO BLOOM + GOLD TIDE → **CHORUS**: your echoes physically collect motes
  along their paths this run.
- STILL SKY + GRAVITY KISS → **EVENT HORIZON**: rings near you slow *more*
  the closer you orbit (spin ×0.6 within 1 ring, ×1 beyond) — a positional
  rule from two "boring defensive" cards.

**Psychology.** The offer at ▲24 stops being "which stat" and becomes "am I
drafting toward METEOR?" — anticipation across picks, Balatro's engine.
**Difficulty to implement:** Medium — sigils already stack in a list;
fusion is a lookup table on `sigils`. **Replayability:** extreme — 12 base
sigils = 66 pairs; even 16 curated fusions gives months of "what fuses?"
rumor value. **Wow factor:** high — fusion moment gets a full-screen flare.
**Balance risk:** medium; fusions are seeded into the same fair offers (C2),
so racing stays even. **Exploit:** dust-printing pairs — cap fused dust mults
at ×3 total. **Interaction with existing:** consumes the existing pool;
Combo Keeper &co. untouched. **Visual:** the two sigil glyphs orbit each other
in the HUD, then bind with a line — a literal constellation. **Audio:** the
MusicEngine gains an instrument layer per fusion (it's already seeded and
height-driven). **Emotion:** "I *created* this."

---

## SYSTEM 2 · FORKS — the sky branches

**Purpose.** Kill the 1D column; add the route decision the game has never had.

**Gameplay.** From height 30, the ladder occasionally splits into two visible
columns for 8–12 rings before rejoining (seeded, C2/C3-safe: forks only
generate in galaxies ≥ 3 and roll from a *separate* `Random(worldSeed^height)`
so existing layouts stay byte-identical). Lanes have seeded personalities:
a storm-rich lane (income), a mover lane (combo food for skip builds), rarely
a **hollow lane** — dark, no motes, but with a secret (System 6). You choose a
lane with the same verb you already have: the ring you capture *is* the choice.

**Psychology.** Scouting ahead becomes a skill; ghosts visibly take the other
fork — instant "what did they know that I don't?" **Difficulty:** Hard —
world-gen and camera both assume one column (`x` clamp, `_isMiss` bounds).
**Replayability:** high; seeds now have *routes*, and route meta becomes
community content. **Wow:** first fork sighting is a genuine event.
**Balance risk:** lanes must be income-equal in expectation or racing solves
to one lane — enforce equal expected dust per lane, different *shape* of dust.
**Exploits:** lane-peeking via aim guide at extreme zoom — fine, that's skill.
**Visual:** the rejoin ring is a double ring. **Audio:** lanes pan the music
slightly left/right. **Emotion:** agency — "my run, my line."

---

## SYSTEM 3 · THE WEIGHT — mid-run stakes (banked vs carried dust)

**Purpose.** Give the economy a heartbeat; create the push-your-luck loop the
game structurally lacks (Part I §3) without ever taking anything from today's
players.

**Gameplay.** Dust collected during a run is *carried*, and carried dust is
now spendable mid-run at **Forge rings** (rare, seeded, visually distinct):
orbit one, and your next tap instead opens a 3-slot seeded offer — buy +1
rescue (cost escalates ×2 each purchase), reroll your next sigil offer, or
**corrupt** an owned sigil (System 4). Death still banks everything (the
current guarantee is sacred — C6-adjacent kindness), but *spent* dust is
gone, so every Forge is a real decision: convert income into survival/build,
or carry it home.

**Psychology.** Loss framing without loss — you never lose dust to death, you
only *choose* to spend it. This is the Slay-the-Spire campfire: rest or smith.
**Difficulty:** Medium. **Replayability:** high — Forge economies differ per
build. **Wow:** medium — its power is structural, felt over weeks.
**Balance risk:** rescue-buying could trivialize height — escalate cost
geometrically (×2.2, same constant as Save Ring) and cap at +3 per run.
**Interaction:** gives GLASS STAR a fascinating wrinkle (Forges can't sell
you rescues — they offer double dust conversion instead). **Visual:** anvil-
orange ring with sparks. **Audio:** deep forge hit on purchase. **Emotion:**
weight — carried dust finally *feels heavy*.

---

## SYSTEM 4 · CORRUPTION — push a sigil past its limit

**Purpose.** Build-defining risk with discovery baked in.

**Gameplay.** At a Forge, corrupt an owned sigil: its up doubles, its down
doubles, and it gains a **hidden third effect** revealed only when it first
triggers. Corrupted GLASS STAR (dust ×4, still no rescues) hides: *storm rings
detonate on capture, +30 dust each, screen-shake included*. Corrupted STILL
SKY hides: *movers freeze while you fly*. Hidden effects are deterministic per
sigil (not per seed) — they're *knowledge*, Outer-Wilds style: learnable,
shareable, wiki-able.

**Psychology.** "I can't believe this interaction exists" — manufactured
honestly. **Difficulty:** Low-Medium (effects are flags in existing code
paths). **Replayability:** 12 sigils × hidden effects = a discovery layer.
**Wow:** the first hidden trigger is the best moment of the month.
**Balance risk:** high by design — corruption is opt-in, costs carried dust,
and caps at 2 per run. **Visual:** corrupted glyphs drip violet. **Audio:**
the sigil's HUD chime plays a tritone lower. **Emotion:** transgression.

---## SYSTEM 5 · ANOMALY BANDS — the sky changes state

**Purpose.** Replace "numbers rise" with "rules bend" as the difficulty verb.
This is the direct answer to §7.6.

**Gameplay.** Every ~40 heights (seeded position ±10), a visible colored band
of sky 6–10 rings tall where one rule inverts. Launch set (all C4-cheap):
- **INVERSION** — rings spin the *other* way as you enter (re-read every tap).
- **DEEP FIELD** — rings drift on *two* axes (vertical bob added to movers).
- **SILENCE** — aim guide gone, music muffled to a heartbeat: pure feel.
- **LENSING** — flight legs curve gently toward ring cores (one attractor
  term, closed form) — skips get easier, perfects get *weirder*.
- **SHATTERGLASS** — every ring is capture-once (it cracks behind you): no
  rescue re-orbiting mid-band; rescues re-place you *below* the band.

Bands are forecast on the galaxy map (scouting!), never overlap Light gates,
and never spawn before ▲30 — **the tutorial galaxies stay pure** (C3).

**Psychology.** Risk of Rain's time pressure, spatialized: the run gets
*phases*. **Difficulty:** Medium per band; the framework is one `bandAt(h)`
function. **Replayability:** very high — bands × mutations × sigils is the
collision space Noita philosophy demands. **Wow:** the sky visibly changes
color; entering SILENCE the first time is a story players tell. **Balance
risk:** medium — bands multiply with mutations; forbid the two worst overlaps
(HYPERSPIN×INVERSION) in the generator. **Visual:** band edge = aurora
curtain. **Audio:** each band re-voices the seeded theme (SILENCE proves the
MusicEngine is a mechanic, not wallpaper). **Emotion:** awe, then focus.

---

## SYSTEM 6 · WRECKS — where pilots died, something remains

**Purpose.** Make other players' failures your content. 70% of the netcode
already exists (`submitGhost`, seeded universes).

**Gameplay.** Where a pilot died on *this seed today*, a wreck drifts near
that ring: reach it to salvage a fraction of their unbanked *carried* dust
(System 3 makes this meaningful) plus a **borrowed sigil** — one sigil from
their build, yours until the run ends. Offline fallback: your own past deaths
(`profile.history` already stores seed+height) leave wrecks. Cap: 3 wrecks
visible per run, nearest-first.

**Psychology.** Death gains an afterlife (Hades: failure feeds forward);
the daily seed becomes a shared battlefield with archaeology. **Difficulty:**
Medium — one new server endpoint mirroring the ghost one. **Replayability:**
high on dailies. **Wow:** salvaging a rival's GLASS STAR *by name* ("wreck of
KIRA — ▲61") is unforgettable. **Balance risk:** low — salvage is capped,
seeded, and identical for all (first-come is per-player, not global, so no
sniping). **Exploit:** suicide-farming your own wrecks — self-wrecks pay no
dust, only the borrowed sigil. **Visual:** a cracked star with the dead
pilot's trail color, name floating faint. **Audio:** a detuned echo of the
capture chime. **Emotion:** melancholy → greed → gratitude.

---

## SYSTEM 7 · THE WANDERER — a guardian at every Light

**Purpose.** Give the lore ladder teeth: an honorable wall (FromSoft) where
the story says one should be.

**Gameplay.** The last 15 rings of every Light-gate galaxy orbit a **rogue
planet** whose gravity bends every flight leg (single closed-form attractor,
C4). Its motion is a pure function of universe number (C2): Universe 1's
Wanderer sweeps a slow figure-eight; Universe 2's carries two moons that
eclipse rings; each Light's guardian is a *new pattern*, forever (procedural
boss = parameterized choreography, not stats). Crossing the final ring
through the Wanderer's wake = **crossing the Light** — the run banks with a
permanent, per-universe cosmetic star-core and a Book of Light chapter.

**Psychology.** The endless ladder gains punctuation — players speak of
"the Third Light's guardian" the way Isaac players speak of floors.
**Difficulty:** Hard (the one true boss-tech investment). **Replayability:**
every 12 galaxies, a new dance. **Wow:** maximal — it's the game's first
*entity*. **Balance risk:** attractor strength must respect reachability
(cap bend at 30° per leg). **Visual:** it eclipses the background sky.
**Audio:** the theme's bass line becomes its heartbeat, louder as it nears.
**Emotion:** dread, then the best victory the game can offer.

---

## SYSTEM 8 · COSMIC WEATHER — the daily sky has moods

**Purpose.** Differentiate days, not just seeds; give the galaxy map a reason
to be *read* before flying.

**Gameplay.** Each day, each galaxy rolls seeded weather (server publishes it
with the daily seed; offline mirrors the formula — C5): **solar wind** (all
flight legs drift +18 px/s in a shown direction — every jump slightly re-
aimed), **meteor shower** (extra mote streams between rings), **aurora**
(perfect window +20% during pulsing on-screen waves — *timing* your perfects
to the aurora), **magnetic storm** (bumpers spawn charged: bounces pay ×2 but
push harder). Weather is forecast for tomorrow — plan your hunting ground.

**Psychology.** The map becomes a daily read: mutation × weather × your build
= "where do I fly today?" — the Balatro shop-reading instinct, applied to a
world map. **Difficulty:** Medium. **Replayability:** high, compounding with
mutations. **Wow:** aurora nights are screenshot bait. **Balance risk:** low
(weather is global and fair; Champions scoring already normalizes by
difficulty — weather adds a shown ±5% score modifier server-side). **Visual:**
the home screen sky already *is* the galaxy sky — weather lives there too.
**Audio:** wind = white-noise swell under the theme. **Emotion:** ritual —
the morning weather check.

---

## SYSTEM 9 · RESONANCE — the music is a hidden mechanic

**Purpose.** The game already generates a seeded, height-driven soundtrack
(`MusicEngine.setTheme(worldSeed, difficulty)`). Make it *playable* — the
game's deepest secret, never explained anywhere in-game.

**Gameplay.** Captures that land on the beat build a hidden Resonance meter;
8 consecutive on-beat captures = **HARMONIC** — 4 seconds where every capture
is Perfect. No UI until first triggered; after that, a faint metronome star
pulses in the corner (knowledge = permanent, per Outer Wilds). The beat is
seeded ⇒ deterministic ⇒ race-fair; speedrunners will learn seeds *as songs*.

**Psychology.** The community's "???" — someone discovers it, the video gets
passed around, everyone re-hears the game. **Difficulty:** Low-Medium (the
beat clock exists; comparison is one timestamp check). **Replayability:**
re-flavors every run forever. **Wow:** among the highest per line of code in
this document. **Balance risk:** low (Perfect windows already exist; HARMONIC
just grants them). **Visual:** on-beat captures ripple in the galaxy accent.
**Audio:** it IS audio. **Emotion:** discovery, then flow-state.

---

## SYSTEM 10 · THE CROSSING — multiple endings at every Light

**Purpose.** Permanent, story-weight decisions; prestige gains a soul.

**Gameplay.** Beating a Wanderer offers a real choice, permanent per universe:
- **END THE STORY** — this universe closes forever (its galaxies lock into a
  golden "completed" state), pay-off: a large photon grant + that universe's
  Wanderer becomes a *companion glyph* (cosmetic orbiter on your star).
- **REFUSE THE LIGHT** — the universe stays open and *deepens*: its galaxies
  re-roll harder mutations with richer rewards (+1 sigil offer slot there,
  permanently, for you).

**Psychology.** The first genuinely irreversible decision in the game; forums
will argue about it, which is the point. **Difficulty:** Medium (state per
universe in `SaveData`). **Replayability:** doubles the meaning of the
endless ladder. **Wow:** high. **Balance risk:** the refuse path must not
strictly dominate — the photon grant on END should be roughly a month of
Supernova value. **Visual:** ending = the sky goes briefly, fully white.
**Audio:** the seeded theme resolves to its tonic for the only time ever.
**Emotion:** the bittersweetness the lore has been promising.

---

# PART IV — 50 QUICK WINS (each < 1 day, given this codebase)

1. Show each galaxy's mutation on the galaxy picker (data exists; UI doesn't).
2. Combo milestone flares at 10/20/30 with escalating bursts.
3. Near-miss feedback: ring edge shimmer when a capture misses by <6 px.
4. "PB pace" ghost tick: faint line at your best height, visible while climbing.
5. Storm-ring captures pay +1 combo (makes storms a choice, not just loot).
6. Show the seed on the death screen; tap to copy/replay it.
7. Rescue moment: 0.5 s slow-motion + heartbeat — make saves *felt*.
8. Sigil glyphs render around the star itself, not just the HUD (build visibility).
9. Daily death map: tiny markers where you died today on this seed.
10. Height ticks every 25 get galaxy-lore one-liners ("▲50 — the air thins").
11. "Rival beaten" toast when you pass a ghost's final height, by name.
12. Perfect streak counter with its own chime pitch rising per streak.
13. Bumper bounce chains announce themselves: "BANK ×2! ×3!".
14. End screen shows dust *sources* breakdown (rings/motes/echoes/bounces).
15. Sigil pick timer-free confirm: preview projected dust delta before choosing.
16. Mover rings get a faint motion-path arc so reading them is skill, not luck.
17. Photon count glows on the Supernova screen with projected gain slider.
18. Long-press (still one finger) on galaxy map shows full mutation math.
19. "First flight of the day" bonus ring: your first capture pays ×3.
20. Echo names: auto-name recordings by their run ("Frost ▲41, 2.1k dust").
21. Show WHICH upgrade level you're missing when a rescue would have helped.
22. Rank progress bar on home screen (points exist; bar doesn't).
23. Skip celebrations scale with rings skipped: SKIP! / DOUBLE! / IMPOSSIBLE!
24. Storm clouds visibly orbit their ring (they're static dots today).
25. Trail length grows subtly with combo (visible risk state at a glance).
26. Death screen: "furthest pilot on this seed today: KIRA ▲67" (data exists).
27. Breather rings marked with a soft halo — teach the rhythm explicitly.
28. Galaxy unlock preview: fly 10 rings of a locked galaxy as a taste, no rewards.
29. Live-room player count on the home screen ("3 pilots in LUMEN now").
30. Sigil offers show a 1-line synergy hint with your current build.
31. Post-run graph: height over time with rescue/sigil markers.
32. Daily challenge #3 rotates weekly instead of being fixed (list exists).
33. "Photograph mode" on death: hide UI, pan the sky, share the run card.
34. Mote magnet visual: faint field circle pulse when motes get pulled.
35. Named seeds: dailies get generated names ("THE HOLLOW CROWN") from the name tables.
36. Rescue re-entry invulnerability flash (0.5 s) — right now it feels abrupt.
37. Champions screen shows the *math* (height × difficulty × 10) per entry.
38. Universe map zoom-out on the galaxy picker: see all 12, Lights glowing.
39. Play-time milestone toasts (10 h, 50 h) — the stat exists, celebrate it.
40. Perfect window flash: draw the actual 34% core circle for 0.3 s after a perfect.
41. Ghost trails (not just dots) for rivals — reading their *lines* teaches routes.
42. Sound: unique capture chime per galaxy (seeded pitch set already exists).
43. Offline banner turns into "3 runs will sync" counter — trust the queue.
44. Skin preview orbits a demo ring in the market instead of a static swatch.
45. Show mutation up/down on the death screen when it killed you ("HYPERSPIN got you").
46. End-of-run "one more?" button re-rolls to a fresh seed with one tap.
47. Star Sense purchase preview: draws old vs new capture circle live.
48. Weekly "your rank percentile" line under the rank name.
49. Motes near the flight line sparkle brighter — subconscious aim feedback.
50. The FIRST LIGHT rank gets a one-time full-screen ceremony. It's rank 8; it deserves it.

# PART V — 50 MEDIUM FEATURES (each < 1 week)

1. +4 new base sigils (pool 8→12): one per archetype hole — echo-scaling, bumper-scaling, storm-scaling, rescue-scaling.
2. Sigil rarity tiers: common/rare/mythic, seeded odds by height (deeper = wilder offers).
3. Forge rings (System 3 core loop, single offer slot v1).
4. Wrecks v1: your own past deaths leave salvage (offline-only version of System 6).
5. Resonance v1 (System 9 — hidden, no UI).
6. Anomaly band v1: INVERSION only, galaxies 3+.
7. Weather v1: solar wind + meteor shower, client-computed from daily seed.
8. Mutation count 6→12: add rule-flavored ones (NO GUIDE, ECHO CHOIR: echoes ×3 but slots −1, MIRROR: layout mirrored).
9. Daily has its own leaderboard tab with ghost-replay of the top run.
10. Weekly seed: one fixed seed per week, separate board — the "speedrun category".
11. Sigil loadout memory: pin a "favorite build" that highlights matching offers.
12. Bumper evolutions in deep space: charged (pays ×2), phased (blinks), magnetic (curves you in).
13. Storm evolution: lightning arcs between adjacent storm rings — cross at the gap.
14. Mover evolution: figure-eight movers past ▲60 (read the crossing point).
15. Galaxy 5+ "hollow rings": no dust, but grant +1 combo — pure routing food.
16. Run modifiers on replay: replay any history seed with a chosen mutation stacked on.
17. Photon sink: "Star Cores" — cosmetic orbiters with per-core lore entries.
18. Book of Light v1: lore screen unlocking a chapter per Light crossed.
19. Spectate mode from home: watch the live room's current leader fly.
20. Friend rivalry: pick one name; their PBs annotate your runs everywhere.
21. Season ranks: Champions math per 4-week season with placement rewards (cosmetic).
22. Echo management screen: keep/retire/favorite echoes; see their routes drawn.
23. Sigil stats page: lifetime picks, win-with rates — let players see their own meta.
24. Colorblind-safe ring/storm/bumper palette toggle.
25. Haptics pass: capture/perfect/rescue/fusion each get distinct patterns.
26. Anomaly forecast on galaxy map (bands visible before flying — scouting).
27. Second daily challenge set for deep space (bumper bounces, band crossings).
28. "Ghost of yesterday-you" always available as an echo slot on dailies.
29. Market rotation: one skin per week is dust-discounted — a reason to check in.
30. Supernova keepsake: each prestige lets you keep ONE upgrade level permanently.
31. Galaxy mastery stars: 3 seeded objectives per galaxy (reach ▲X no rescues, etc.) paying photons.
32. Interactive tutorial replay: "flight school" scoring your perfects out of 10.
33. Live emotes: tap-pattern flares visible to the room (one input, C1-clean).
34. Wreck notifications: "KIRA salvaged your wreck on today's seed" — you get 10% back.
35. Run tags in history: auto-label runs (GLASS RUN, STORM HARVEST) from their stats.
36. Height-milestone banked checkpoints on dailies only: bank half your dust at ▲25/▲50 (daily-only rule spice).
37. Camera language: subtle zoom-out as combo rises (see more, risk more — visible tension).
38. New-galaxy discovery bonus: first-ever visit to each procedural galaxy pays photons ×galaxy/10.
39. Practice mode: replay the 5 rings around any death from history, free, no rewards.
40. Sigil "pass" reward: skipping an offer grants +5% dust for 25 rings — make refusal a build.
41. Server-side run verification v1: replay-check submitted paths against seed physics (anti-cheat).
42. Two-finger tap = ping your position to the live room (C1-compatible social verb).
43. Idle sky: home screen slowly replays your best echo behind the menu.
44. Galaxy-picker sort: by mutation synergy with your pinned build.
45. Monthly "eclipse day": all galaxies share one mutation globally — a community event day.
46. Achievements v1: 40 badges, each a *teaching* goal (cross a storm gap, 4-ring skip, HARMONIC).
47. End-run comparison: this run vs your PB run, ring by ring, as two lines.
48. Audio stems unlock: crossing a Light adds its instrument to home-screen music permanently.
49. Cloud save conflict UI: pick-a-profile screen instead of silent last-write.
50. Performance budget pass: cap particles/floats adaptively — keep 60 fps on old phones as content grows.

# PART VI — 50 MAJOR FEATURES (each < 1 month)

1. Constellations — full System 1 (16 curated fusions).
2. Forks — full System 2 (three lane personalities + hollow lanes).
3. The Weight — full System 3 (Forge economy, 3 offer slots, corruption hook).
4. Corruption — full System 4 (hidden third effects for all sigils).
5. Anomaly bands — full System 5 (all five bands + map forecast).
6. Wrecks — full System 6 (server endpoint, borrowed sigils, name display).
7. The Wanderer — full System 7 (first three universes' choreographies).
8. Weather — full System 8 (four weather types, forecast, score modifier).
9. Resonance + HARMONIC — full System 9.
10. The Crossing — full System 10 (both endings, companion glyphs).
11. Live races: scheduled on-the-hour starts on the daily seed, same room, countdown, podium.
12. Asynchronous duels: send a seed + your run; friend gets 24 h to answer; loser's star wears a dunce trail for a day.
13. Sigil crafting meta: dismantle unpicked offers into shards; shards pin one guaranteed card family next run.
14. Galaxy events: seeded week-long invasions ("the Swarm eats motes in EMBER — bounce them back") with community progress bar.
15. Ecosystem v1: motes flock, flee your approach vector, school toward storms — collection becomes herding.
16. Living planets: rare seeded planets between rings with orbiting moon-motes and a landing bonus (orbit 3 full turns = treasure).
17. Boss rush mode: all unlocked Wanderers back-to-back, one rescue total, photon prize.
18. Nemesis system: the ghost that beat you most often gets flagged, named, and framed — beat them for a unique cosmetic.
19. Cartographer meta: first player to fly each procedural galaxy gets their name on it, permanently, server-side ("Charted by KIRA").
20. Guild constellations: 5-pilot clubs; members' echoes populate each other's runs; weekly club ladder.
21. Story mode overlay: 12 authored "voyages" (fixed seed + fixed sigils + a twist rule each) teaching advanced tech, with lore.
22. Replay theater: full run replays from path data with scrubbing, shareable as a code (seed+path compress well).
23. Challenge forge: players author a challenge (seed + mutation + band + target) and share codes; weekly featured picks.
24. Infinite descent mode: after a Light, fly DOWN through collapsing rings — the same physics, reversed pacing (score = survival time).
25. Second currency faucet rework: photons earnable slowly by mastery stars — prestige becomes one *source*, not the only one.
26. Sigil personalities: mythic sigils comment (one-liners) on your play — refuse GLASS STAR three times and it starts taunting you.
27. Adaptive soundtrack v2: instruments per system state (band, weather, combo) — the audio literally is the HUD.
28. Ring architecture past ▲100: double rings, gear pairs (counter-rotating shared captures), gate rings needing entry from below.
29. Meteor riding: seeded comets cross the sky on schedule; intercept = ride 6–10 rings upward, drop-off marked ahead (learnable schedules).
30. The Observatory: home-screen building where discovered knowledge (band types seen, hidden effects found, comet schedules) is displayed as star charts — knowledge progression made visible.
31. Tournaments: bracketed weekend events on fixed seeds, spectate finals live in-app.
32. Ghost marketplace: hire a top pilot's echo for a day (dust fee, they earn a cut) — economy meets social.
33. Anti-build sigils ("build destroyers"): mythic pacts that delete a mechanic (NO MOTES EXIST — rings pay triple) and force re-learning.
34. Dynamic objectives: mid-run seeded bounties appear ("3 perfects in the next 10 rings → +1 rescue") — accept by flying, ignore by skipping.
35. Universe 2 identity: past the First Light, galaxies gain persistent scars from your choices (Crossing outcomes visible in the sky).
36. Colony motes: end-run overflow dust auto-invests into a slow idle "nursery" generating 1 photon/week per 50k — long-horizon sink.
37. Speedrun mode: in-run timer, splits at every 25, ghost of WR pace on dailies, verified board.
38. Accessibility suite: one-switch play (auto-launch on best window), slow-mode global toggle (own board), screen-reader menus.
39. Controller/desktop build: the one-verb design ports anywhere; Steam release of the same seeds = cross-platform racing.
40. Sigil draft gauntlet: pick 5 sigils from rotating packs BEFORE flying a gauntlet seed — pure build-skill mode.
41. Echo evolution: an echo that "wins" (outlives your run) levels up, growing its yield — your past selves have careers.
42. Planetfall events: once per universe, a seeded planet blocks the ladder entirely — orbit-hop across its moon field (a 30-ring set-piece).
43. The Undermarket: post-Light shop where photons buy *rule cosmetics* (your trail leaves readable text, your bursts spell your name) — flex without power.
44. Community goal seasons: global mote counter (every player's motes add up) unlocking a new anomaly band type for everyone when filled.
45. Rewind token: one per run past ▲50 — death offers "watch the last 5 s and re-fly from the previous breather, dust since then forfeited" (skill-preserving continue with a real cost).
46. Heat system: opt-in stacking difficulty toggles (Hades' Pact of Punishment) with per-heat leaderboards — the tryhard's endless axis that never touches base fairness.
47. Photo-real share cards: seed, route line, sigil glyphs, score — auto-composed, one tap to share (organic UA engine).
48. Localizations + region boards: the ladder is global, the pride is local.
49. Anti-cheat v2: server-side deterministic re-simulation of the full physics for top-100 entries (the closed-form design makes this CHEAP — flex it).
50. Live ops calendar tooling: weather/eclipse/tournament schedule authored server-side, mirrored offline — one JSON, whole-game cadence.

# PART VII — 25 REVOLUTIONARY SYSTEMS

1. **The Echo Civilization** — your retired echoes populate a persistent nebula city visible from the home screen; they build monuments from your career stats. A settlement you can't control, only feed.
2. **Seed genetics** — breed two history seeds: the child seed provably inherits ring-pattern traits of both parents (XOR-blend of generation params). Players become seed farmers hunting bloodlines.
3. **The Silent Pilot** — a learned model of YOUR tap timing flies beside you as your true ghost — not your path, your *habits*. Beating it means outgrowing yourself.
4. **Gravitational memory** — every capture you've EVER made on a seed leaves a faint permanent dent in that universe's rings (per-player). Grind a daily seed enough and you can *see* your mastery carved into it.
5. **The Whisper Network** — rare rings contain messages left by pilots who died there (curated, Dark-Souls style, from a phrase menu). The daily seed becomes an annotated mountain.
6. **Orbital decay realism** — stay on any ring too long and your orbit visibly, gently decays inward: perfection windows shift continuously, and camping becomes its own skill-test (kills AFK, adds a clock with zero UI).
7. **The Twin Star** — a permanent second star unlocked at Universe 2: it orbits YOUR star, and taps launch both on mirrored tangents. Every existing mechanic doubles in meaning with zero new content.
8. **Constellational sky-writing** — your run's full path is projected onto the galaxy map as a constellation; rare paths that resemble the seeded name-glyphs ("THE HOLLOW CROWN") pay a discovery bonus. The map reads your flying as handwriting.
9. **Deep time** — universes age in real time: a galaxy unvisited for 30 days drifts (mutation softens, dust accrues in nests). The ladder becomes a garden you rotate through.
10. **The Auditor** — one seeded ring per run KNOWS your stats and offers a personalized pact against your actual weakness ("you rescue-lean: fly 20 rings rescue-locked for ×3"). A boss that reads your save file.
11. **Fossil layers** — dailies stack: yesterday's seed is visible as a translucent layer behind today's; capturing "aligned" rings (same position both days) pays archaeology bonuses. Time becomes terrain.
12. **The Bartering Comet** — a merchant comet crosses rarely (seeded, scheduled); it takes trades, not dust: swap a sigil, trade 200 height of unlock progress for rescues, sell your aim guide for the run. An economy of *capabilities*.
13. **Symphonic seeds** — full System 9 extended: every seed IS a song; a seed-to-MIDI exporter lets players hear seeds before flying them, and pick their daily by ear.
14. **Weather fronts you can push** — live rooms share weather state; enough pilots flying one lane shifts the wind for everyone in-room. First mobile game where the crowd IS the physics.
15. **The Long Now run** — one special seed per account, flyable one ring per real hour (notification when your orbit stabilizes). A year-long run. Death is permanent. The board shows the world's slowest, highest climb.
16. **Sigil ecology** — sigils have seeded population dynamics per week: picks deplete a sigil's "wild population", making it rarer globally next week. The meta self-balances and seasons emerge without patches.
17. **Anti-seed** — every seed has a computable mirror seed (all spins reversed, layout mirrored). Boards pair them; true mastery = your delta between a seed and its anti-seed.
18. **The Passenger** — rescue a stranded NPC pilot mid-run; carrying them halves your capture window but they narrate the universe (procedural lore keyed to galaxy index) and disembark at a Light with permanent gifts.
19. **Ring-craft** — end-game photon sink: place ONE permanent custom ring into a procedural galaxy (position server-validated for fairness, visible to all, named). Players literally build the deep universe.
20. **Collapse events** — when the global community crosses a Light threshold, that universe visibly begins ending over one week (bands multiply, rewards triple) then archives forever into the Book. FOMO with narrative honesty.
21. **The Instrument** — a zen mode where rings are laid out to MAKE music from your captures (seed = composition); shareable recordings. The mechanic as an art tool.
22. **Quantum sigils** — mythic-tier cards that remain BOTH options until observed: pick the sealed card and it resolves at your next death/Light, retroactively applying whichever half would have scored better. Schrödinger's build.
23. **Mentor bonds** — a veteran links to a rookie; the rookie sees the mentor's ghost with input-timing flashes; the mentor earns photons from the rookie's rank-ups. Teaching as endgame.
24. **The Breach** — flying a 5+ ring skip through a Perfect Arc at HARMONIC tears a seeded rift: 10 rings of another galaxy's rules bleed through, then it heals. The three deepest mechanics, when mastered *simultaneously*, open doors.
25. **Universe inheritance** — before a Crossing "END", designate one galaxy trait (mutation, weather bias, one ring position) that carries into Universe N+1's generation for you alone. Your multiverse genuinely descends from your choices.

# PART VIII — 10 "INDIE GAME OF THE YEAR" IDEAS

1. **The game is a shared calendar.** One daily universe for every human playing, weather and all, with wrecks, whispers, fossils and live rooms making each date a *place*. Marketing writes itself: "Were you there on March 4th?"
2. **Knowledge is the endgame.** Ship Resonance, hidden corruptions, comet schedules and the Breach with ZERO documentation. The wiki-race becomes the community's game. (Outer Wilds' lesson: the only progression that can't inflate.)
3. **The Observatory as the trophy room of understanding** — the meta-screen where everything you've *learned* (not earned) is displayed. Completion = comprehension.
4. **Full-run determinism as a public flex**: every top score is one-tap-replayable BY ANYONE from seed+taps (a few hundred bytes). Cheating is mathematically impossible and the game says so. Trust as a feature.
5. **The Silent Pilot** (VII.3) as the emotional core: the game's final boss is a portrait of you. Press coverage guaranteed.
6. **Crossing ceremonies as community events**: the first pilot in the world to cross each new Light gets the crossing broadcast to every home screen, named. History with witnesses.
7. **A living OST** — the seeded music system surfaces as a real album: "the soundtrack is different in every universe, and yours is yours." Bandcamp release generated from the twelve Light seeds.
8. **One-verb accessibility story**: the entire endgame playable with a single switch. Roguelite depth with the most inclusive input scheme in the genre. Own that narrative.
9. **The Book of Light as an actual book** — the lore already maps every line to a real rule (PILOT-GUIDE Part III). Finish that conceit: the in-game book IS the manual IS the story, unlockable page by page through play.
10. **"The tutorial is three galaxies long"** — lean into the flip this document engineers: market the moment the sky first forks / the first band / the first Wanderer as *the game beginning*. Players who churned at Galaxy 3 are exactly the ones who'll come back for that trailer.

---

# PART IX — THE ROADMAP (what a director actually greenlights first)

The diagnosis (Part I §7) says the churn is caused by four simultaneous
exhaustions: **build variety, world variety, economy tension, discovery.**
One system per hole, ordered by impact-per-week:

| Phase | Ship | Hole it fills | Effort |
|---|---|---|---|
| 1 (2 weeks) | +4 sigils, mutation-on-picker, 10 quick wins, bumpers+mutations moved from galaxy 5 → **galaxy 3** | The freshest content currently sits *behind* the churn point. Move it before it. | S |
| 2 (1 month) | **Constellations** (System 1) + **Corruption** (System 4) | Build variety — the builder player's game | M |
| 3 (1 month) | **Anomaly bands** (System 5) + **Weather** (System 8) | World variety — difficulty becomes rules, not numbers | M |
| 4 (1 month) | **Forge/The Weight** (System 3) + **Wrecks** (System 6) | Economy tension + social content | M |
| 5 (6 weeks) | **Forks** (System 2), **Resonance** (System 9) | Routing skill + the secret | L |
| 6 (2 months) | **The Wanderer** (System 7) + **The Crossing** (System 10) | The endgame promise the lore already makes | L |

Success metric for the whole arc, measurable in the existing analytics
(`submitScore` already carries galaxy + height): **median career height in
galaxy 4+ doubles, and D30 retention of players who reached Frost Veil
triples.** If Phase 2 alone doesn't move sigil-pick entropy (it's loggable —
picks per offer), the fusions aren't wild enough; push further before adding
content breadth.

*The first three galaxies were always the tutorial. Now the game keeps its
promise.*

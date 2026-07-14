# ECHO ORBIT — THE ULTIMATE STRATEGIC GUIDE
## Every stat · every strategy · every mix — then the full story

*Part I is the strategy manual: all numbers, all builds, all combinations.
Part II is the Book of Light — the full lore. Part III maps every lore line
to a real rule. Everything here is computed from the game itself.*

---

# PART I — THE STRATEGIC GUIDE

## 1 · CORE PHYSICS (the constants)

| Constant | Value |
|---|---|
| Launch speed | **560 px/s**, tangent to orbit, in the spin direction |
| Ring spacing | 175 px vertical |
| Next ring position | always within 28–72% of screen width (reachability guard) |
| Capture scan | **4 rings ahead** — max possible skip = 4 |
| Perfect Arc window | flight line ≤ **34%** of ring radius from its center |
| Drift-miss (the leash) | flight distance > **max(1.5 screens, 1200 px)** without a catch |
| Side-miss | beyond ±40% outside the screen edges |
| First ring radius | 70 px |
| Starting rescues | 1 (+1 per Save Ring level) |

## 2 · WORLD GENERATION — what the sky looks like at every height

Difficulty is a **pure function of height** — identical for every seed. The seed
only shuffles within these bounds. (gd = galaxy difficulty)

**Formulas:**
- Ring radius = `63 − 18·h/(h+60) − min(8, 0.008h) − min(16, 14(gd−1)) + rng(0–10)` (breather +8, floor 24)
- Spin mult = `(1 + 0.55·h/(h+40) + 0.0012h) × (1 + 0.65(gd−1))` on a base of 1.35–1.85 rad/s
- Storm chance = `(0.16 + 0.24·h/(h+80) + min(0.15, 0.0002h)) × gd`, **cap 60%**
- Mover chance = `min(50%, 30% + 0.05%·h)` — never after another mover, never on storms/breathers
- Storms: only above ▲10, minimum 5 rings apart, never on breathers

**Computed (gd = 1.0, LUMEN):**

| Height | Ring radius (±rng) | Spin vs start | Storm chance | Mover chance |
|---|---|---|---|---|
| ▲10 | ~60 px | +12% | 19% | 30% |
| ▲25 | ~58 px | +21% | 22% | 31% |
| ▲50 | ~54 px | +37% | 26% | 32% |
| ▲100 | ~51 px | +51% | 31% | 35% |
| ▲200 | ~48 px | +70% | 37% | 40% |

**Galaxy tax:** at gd 1.6 (VOID BLOOM) subtract another ~8 px of radius and add
+39% spin on top of everything. At gd 2.2 (sector 5): −16 px, +78% spin.

**Structural rules to exploit:**
- **Breather every 8th ring** — bigger, 15% slower. Free planning window.
- **Storm ring** = 13 motes worth 3 each = 39 base value in one cloud.
- **Regular rings** drop 7 motes between them (value 1, 25% chance of 2).

## 3 · THE ECONOMY — every dust source, computed

**The master formula (per ring capture):**
```
dust = 5 × (1 + 0.1 × combo) × 2^perfect × 2^skip × globalMult × galaxyReward × sigils
```

**Dust per ring by combo (before galaxy/photon/sigil mults):**

| Combo | Normal | Perfect | Perfect+Skip |
|---|---|---|---|
| 0 | 5 | 10 | 20 |
| 5 | 8 | 15 | 30 |
| 10 | 10 | 20 | 40 |
| 20 | 15 | 30 | 60 |
| 30 | 20 | 40 | 80 |

**Combo sources:** Perfect +1 · Skip +2 (WILD ARC: +4) · Bumper bounce +1 ·
Fall = reset (Combo Keeper saves it up to 90%).

**Other income:** motes (1 / 2 / 3-storm, × all mults) · bumper bounce pays 4 × mults ·
daily challenges pay `100 × globalMult` each (3/day: reach ▲15, 250 dust, 3 perfects) ·
Echoes tithe passively (§8).

## 4 · THE SHOP — full cost & effect tables

Cost = `base × growth^level`. Effects soft-cap as `level/(level+c)` — **early
levels are always the cheapest power in the game.**

| Upgrade | L1 | L2 | L3 | L4 | L5 | L6 | Effect at L1→L5 |
|---|---|---|---|---|---|---|---|
| Aim Guide (60, ×1.7) | 60 | 102 | 173 | 295 | 501 | 852 | preview 64→117 px (max 210) |
| Dust Magnet (80, ×1.7) | 80 | 136 | 231 | 393 | 668 | 1,136 | reach 44→69 px (max ~124) |
| Save Ring (400, ×2.2) | 400 | 880 | 1,936 | 4,259 | 9,370 | 20,614 | +1 rescue per level (linear!) |
| Echo Slots (300, ×2.0) | 300 | 600 | 1,200 | 2,400 | 4,800 | 9,600 | +1 echo per level |
| Echo Yield (160, ×1.75) | 160 | 280 | 490 | 858 | 1,501 | 2,627 | share 17%→33% (max 70%) |
| Combo Keeper (200, ×1.75) | 200 | 350 | 613 | 1,072 | 1,877 | 3,284 | keep 15%→45% (max 90%) |
| Star Sense (180, ×1.8) | 180 | 324 | 583 | 1,050 | 1,889 | 3,401 | window +6%→+21% (max +50%) |

**ROI verdicts:**
- **Combo Keeper = the best coin in the shop.** It converts rescues from
  combo-resets (economic disasters) into free continues.
- **Star Sense** amplifies every single jump you'll ever make. Never stop feeding it.
- **Save Ring** growth ×2.2 is brutal — 2–3 levels, then buy skill instead.
- **Magnet** is elite for 4–5 levels then flattens.
- **Guide** 2 levels, then your eyes are better.
- **Echo Yield > Echo Slots**: a fatter share of 1 great echo beats a thin share of 3.

**Buy order:** Magnet 2 + Guide 2 → Save 1 → **Keeper hard** → Sense → Yield → rest.

**Market (pure cosmetics, zero power):** dust skins 1,500 / 3,500 / 8,000 / 16,000 /
32,000 · photon skins 3 / 8 / 20. Never before your mult feels fat.

## 5 · SIGILS — exact stats, every pact (▲10, ▲24, ▲40, then +25)

Offers are **seeded**: same seed = same 3 cards at the same heights for every racer.

| Sigil | Exact effects |
|---|---|
| GLASS STAR | dust **×2.0** · rescues locked to **0** |
| GRAVITY KISS | capture window **×1.30** · combo step ×0.5 (each combo point worth half) |
| COMET HEART | speed **×1.25** · dust **×1.5** · capture window ×0.85 |
| STILL SKY | spin **×0.75** · dust ×0.7 |
| ECHO BLOOM | echo income **×2.0** · dust ×0.75 |
| PHOENIX FEATHER | **+1 rescue instantly** · perfect window ×0.7 (34%→23.8%) |
| WILD ARC | skips give **+4 combo** (instead of +2) · speed ×1.15 |
| GOLD TIDE | magnet **×2.0** · spin ×1.15 |

**Sigils MULTIPLY together.** The full stacking math for the key mixes:

| Mix | Combined stats | Use case |
|---|---|---|
| **GLASS CANNON** (Glass+Comet) | dust **×3.0**, speed ×1.25, capture ×0.85, 0 rescues | Max farm. Only below your no-fall height. |
| **DEMON CANNON** (Glass+Comet+Wild) | dust ×3.0, speed **×1.44**, skips +4, 0 rescues | The theoretical ceiling. One mistake = over. |
| **THE WALL** (Phoenix+Gravity+Still) | capture **×1.30**, spin ×0.75, +1 rescue, dust ×0.7, combo ×0.5, perfect ×0.7 | Max survival. Height pushes only. |
| **SKIP DEMON** (Wild+Comet) | speed ×1.44, skips +4, dust ×1.5, capture ×0.85 | Highest score ceiling with a net. |
| **STORM KING** (Gold+Glass) | magnet ×2, dust ×2, spin ×1.15, 0 rescues | Storm farming — vacuum clouds at x2. |
| **ECHO BARON** (Bloom+Gold) | echo ×2, magnet ×2, dust ×0.75, spin ×1.15 | Feeder runs to fatten your echoes. |
| **SLOW GOLD** (Still+Gold) | spin ×0.86, magnet ×2, dust ×0.7 | Comfortable farming with aim training. |
| **FLY PURE** (pass all) | ×1 everything | Pure height pushes — clean windows beat bonuses. |

**Sigil rules of thumb:**
- Speed does NOT extend your leash (it's distance-based) — it crosses gaps faster,
  giving moving rings less time to dodge you. Good for movers, neutral for drift.
- GRAVITY KISS halves your *economy* (combo step ×0.5) — never on farm runs.
- PHOENIX's perfect window 23.8% still allows perfects — aim tighter, don't stop.
- Take GOLD TIDE before ▲60; after that its +15% spin tax bites on small rings.
- **Plan picks pre-launch on racing seeds** — offers are known: "▲10 Still Sky,
  ▲24 pass, ▲40 Phoenix."

## 6 · MUTATIONS — exact stats per deep-space galaxy (5+)

Fixed per galaxy, identical for everyone, visible in the selector **before** you climb.
Light gates have no mutation.

| Mutation | Exact effects | Farm | Push | Notes |
|---|---|---|---|---|
| SLOW NEBULA | spin ×0.85 · motes ×0.7 | C | **S** | The push sky. Slow spin beats any dust bonus for height. |
| DWARF STARS | ring radius ×0.85 · motes ×1.6 | **S** | C | The dust printer. Star Sense partially cancels the shrink. |
| HYPERSPIN | radius ×1.15 · spin ×1.25 | B | B | Wider target, faster timing — for high-APM pilots the width wins. |
| UNSTABLE ORBITS | mover chance ×2.2 (→cap 90%) · motes ×1.4 | A | C | Nearly every ring drifts. Learnable; pays constantly. |
| STORMLANDS | storm chance ×1.6 (→cap 60%) · motes ×1.25 | A | D | Bring GOLD TIDE; farm clouds; leave before ▲60. |
| PULSAR FIELD | bumper chance 35%→**80%** | B | A* | *A for bumper-mains: constant leash resets = impossible lines. |

**Matchmaking builds to mutations (the real meta):**
- DWARF STARS + GLASS CANNON = the highest dust/minute in the game (×1.6 × ×3.0 motes/rings).
- SLOW NEBULA + THE WALL = the unlock-height machine.
- PULSAR FIELD + SKIP DEMON = combo avalanche (every bounce +1, every skip +4).
- STORMLANDS + STORM KING = cloud after cloud at ×2 magnet ×2 dust.

## 7 · BUMPERS — full stats & the three levels of tech (galaxy 5+)

| Stat | Value |
|---|---|
| Spawn | 35% per ring gap (80% in PULSAR FIELD), never near storms, from ▲4 |
| Pin radius | 13–19 px (hit detected at radius + 9) |
| Bounce | perfect reflection `v' = v − 2(v·n)n` |
| Speed kick | ×1.1 per bounce, capped at 952 px/s (1.7× launch) |
| Reward | +1 combo · 4 dust × all your mults |
| Cooldown | 0.6 s per pin |
| **The tech** | **bounce resets drift distance to 0** — your leash restarts at the pin |

Mastery ladder: (1) *incidental* — take the free combo · (2) *deliberate* — launch
INTO pins to redirect toward off-line rings · (3) *pin ladders* — chain pins to skip
3–4 rings in one flight. A straight line caps at 1200 px; a ladder has no cap.

## 8 · ECHOES — engineering passive income

Your **top 3 runs by dust** fly beside you every run, paying `their dust × yield`
spread over their flight (yield 10% → 70% via upgrades). ECHO BLOOM doubles the
tithe for that run.

**The feeder recipe:** DWARF STARS sky → STORM KING or GLASS CANNON →
farm storms greedily at a height you *never* fall from → done. That one run now
tithes to every future run. **Refresh echoes** after each supernova (they burn)
and after big mult gains (old echoes are stale).

## 9 · SUPERNOVA — the photon table

`photons = ⌊(best_this_prestige − 40)^0.8⌋` · each photon = **+10% global mult, permanent** ·
burns dust, upgrades, echoes · keeps photons, records, galaxies, skins, rank.

| Best height | Photons | New mult (from zero) |
|---|---|---|
| ▲50 | 6 | ×1.6 |
| ▲60 | 10 | ×2.0 |
| ▲70 | 15 | ×2.5 |
| ▲80 | 19 | ×2.9 |
| ▲100 | 26 | ×3.6 |
| ▲150 | 42 | ×5.2 |
| ▲200 | 57 | ×6.7 |

**Never burn at ▲50.** Two more pushes ≈ 2.5× the photons. The loop:
push ceiling → one feeder run (extract echo value) → SUPERNOVA → rebuild
Keeper+Sense first → repeat. Each loop: mult ~doubles, ceiling +a few rings.

## 10 · GALAXIES — the complete ladder

| Sky | Difficulty | Reward | Unlock | ▲30 here = career pts |
|---|---|---|---|---|
| LUMEN | ×1.00 | ×1.0 | — | 300 |
| EMBER NEBULA | ×1.18 | ×1.4 | ▲30 LUMEN | 354 |
| FROST VEIL | ×1.38 | ×1.9 | ▲45 EMBER | 414 |
| VOID BLOOM | ×1.60 | ×2.6 | ▲60 FROST | 480 |
| Sector 1 (g5) | ×1.72 | ×3.4 | ▲72 | 516 |
| Sector 2 (g6) | ×1.84 | ×4.4 | ▲84 | 552 |
| Sector 3 (g7) | ×1.96 | ×5.7 | ▲96 | 588 |
| Sector 4 (g8) | ×2.08 | ×7.4 | ▲108 | 624 |
| Sector 5 (g9) | ×2.20 | ×9.7 | ▲120 | 660 |
| Sector 6 (g10) | ×2.32 | ×12.6 | ▲132 | 696 |
| Sector 7 (g11) | ×2.44 | ×16.3 | ▲144 | 732 |
| **THE FIRST LIGHT** (g12) | ×2.56 | ×21.2 | **▲156** | 768 |
| Universe 2, sky 1 (g13) | ×2.68 | ×27.6 | ▲168 | 804 |

**The rule of deeper:** rewards ×1.30/step, difficulty +0.12/step. If you survive
▲20 in the next sky it out-earns ▲35 in this one. Discomfort is profit.

## 11 · RANKS & CHAMPIONS — the scoring math

**Career points (lifetime):** `Σ over every galaxy of (best height × difficulty × 10)`

| Rank | Points | Example route to reach it |
|---|---|---|
| STARDUST | 0 | fly once |
| SPARK | 300 | ▲30 in LUMEN |
| COMET | 1,000 | ▲30 in each of the first 3 skies |
| NOVA | 2,600 | ▲45 avg across 5 skies |
| PULSAR | 6,000 | ▲55 avg across 8 skies |
| QUASAR | 13,000 | ▲75 avg across 10 skies |
| SINGULARITY | 28,000 | deep-sector bests, ▲100+ climbs |
| **FIRST LIGHT** | 60,000 | sweep 12+ skies at elite heights |
| ✕1, ✕2… | +30,000 each | endless — for the nameless lights |

**CHAMPIONS (weekly):** `Σ over galaxies of (height × difficulty × 10 + 5 × perfects)`
- Depth beats width per-run: ▲50 at ×2.0 = 1,000 > ▲70 at ×1.0 = 700.
- But the sum is across galaxies — **champions sweep every unlocked sky.**
- Perfects = +5 each: a 20-perfect run is a free ▲10 of score.
- Weekly boards also track pure best height per galaxy — reset weekly.
  **Rank and photons never reset.**

## 12 · MULTIPLAYER WARFARE

- **Ghost racing:** top-5 rival paths of your seed render live (coral, named).
  Fly the leader's line first — free route knowledge — then cut it. Your runs
  publish at ▲3+; each seed keeps its best 25.
- **Live rooms:** everyone on your worldSeed flies together in real time (gold
  stars, names, heights). Same seed + live room = wheel-to-wheel. The tilt meta
  is real: being visibly ahead makes rivals tap early.
- **Seeds are tracks:** same seed = same rings, motes, storms, pins, sigil offers,
  music. Learn the daily like a circuit: storm paydays, skip alignments, sigil
  heights (▲10/24/40/65/90…), build planned before launch.
- **Custom seeds** = private tournaments. Share a number, race it all night.

## 13 · THE WINNING WEEK (the tryhard ritual)

1. **Daily seed early, every day** — learn it while the ghosts are few, then own it.
2. **Sweep day** — one solid run in EVERY unlocked galaxy (Champions base + rank pts).
3. **Push day** — deepest sky, THE WALL or FLY PURE, hunt the next unlock height.
4. **Farm day** — DWARF STARS sky, GLASS CANNON, refresh the echo trio.
5. **Scout** — read the mutations of the next 2–3 locked skies; plan next week.
6. **Race** — grind the daily until the coral ghost is behind you.

## 14 · ANTI-PATTERNS (how pilots lose)

- Farming shallow: comfortable ▲35s in LUMEN while a ×2.0 sky sits unlocked.
- Nova at exactly ▲50: six photons when fifteen were two pushes away.
- Taking every sigil: three prices compound. PASS is a build.
- GRAVITY KISS on a farm run: you just halved your own economy.
- Ignoring perfects while farming: +5 champ pts each, every week, forever.
- One-galaxy pride: rank and Champions both sum across skies. Mains lose to sweepers.
- Racing an unscouted seed: your rival planned their sigils at breakfast.
- Buying skins before mult: style is downstream of light.

## 15 · REFERENCE CARD

- Launch 560 px/s tangent · rings 175 px · scan 4 ahead · leash max(1.5 scr, 1200 px)
- Perfect ≤34% of center → x2 + combo (+5 champ) · skip → x2 + 2 combo (WILD ARC +4)
- Dust = `5 × (1+0.1·combo) × 2^perf × 2^skip × mults` — combo IS the economy
- Breather every 8th · storms ▲10+, ≥5 apart, cap 60% · movers never twice
- Sigils ▲10/24/40 then +25 — seeded, multiply together, PASS is legal
- Bumpers: ×1.1 kick, cap 952, +1 combo, 0.6 s cd, **leash reset**
- Nova: ⌊(best−40)^0.8⌋ photons ×10% each — burn at ▲65+, never ▲50
- Rank/Champions: height × difficulty × 10 — **sweep every sky**
- FIRST LIGHT: g12, ▲156 → Universe 2 → forever

---

# PART II — THE BOOK OF LIGHT (the full story)

### Prologue · The Last Star

The universe already ended. Long ago. Quietly. Not with fire — with forgetting.

Stars went out one by one, each taking its sky with it, until only one remained:
a small, stubborn star that had spent its whole life doing the one thing gravity
cannot undo. **It remembered.**

As the dark closed in, the Last Star compressed everything it had ever seen —
every galaxy, every ring of light, every storm, every drifting mote — into pure
numbers. **Seeds.** A whole sky folded into a single integer, the way a forest
folds into one seed you can hold in your palm.

Then it burned itself out casting them into the dark.

What you fly through every run is not space. **It is a memory being re-read.**
That is why the same seed always builds the same sky, ring for ring, note for
note. The universe isn't procedural. The universe is *remembered*.

### Act I · The Cradle

You wake in **LUMEN** — *where every star is born*. Golden. Patient. The rings
here turn slowly, as if the memory is being gentle with you on purpose. It is.

You learn the tap: one touch lets go, a straight flight into the dark, toward
the next ring. Catch it. Climb. That's all the universe asks. At first.

You learn **stardust**: fragments too small for the seeds to hold in place,
shaken loose every time the memory is re-read. Gather them and something
strange happens — the sky trusts you more. Your magnet reaches farther. Your
rescues multiply. The old pilots explain it without smiling: **upgrades aren't
gear. They're conviction.** The memory becoming more certain of you.

### Act II · The Climb

Past LUMEN, the memory shows you its life. **EMBER NEBULA** — *burning skies,
richer dust* — is its youth: everything faster, everything worth more, everything
slightly on fire. **FROST VEIL** — *fast, icy, unforgiving* — is its grief: the
rings small and quick, and nothing here waits for you. And then **VOID BLOOM** —
*the edge of everything* — the last thing the Last Star saw clearly, and the last
sky it polished by hand.

Along the climb you learn the sky's grammar, and the grammar never lies: space
breathes in bars of eight. Storms never strike a breathing ring, and never twice
in five. Drifting rings never dance in pairs. The sky only ever counts four rings
ahead of you, and if you fly too long uncaught — about twelve hundred paces of
dark — the memory loses track of you, and you fall out of it.

Falling, it turns out, is not dying. When your rescues run out, the run ends —
but the sky doesn't stop. You hang there, watching your rivals and your echoes
climb on without you. Pilots call it *the long look*. It's your first hint that
something is wrong with what you've been told.

### Act III · The Echo Revelation

Because here is what you were told: those translucent stars flying beside you,
tracing familiar paths, earning dust for you — those are *recordings*. Your past
runs. Ghosts of you.

Here is the truth, and it is upside down:

**They were never copies of you. You are the newest copy of them.**

Every run, the memory re-reads itself and writes one more star into the margin:
you, again, a little wiser. That's why your Echoes earn stardust *for* you —
they aren't helping you. They're finishing something they started. You will do
the same for the next you, and you won't be asked.

This is why the sky continues when you fall. **The memory doesn't need any
single star. It needs the climbing to continue.**

### Act IV · The Burning

At height fifty, the sky offers you the oldest bargain in it: **SUPERNOVA.**

Burn everything. Your dust. Your upgrades. Even your echoes — even *them*.
Give the memory back every crumb you gathered, and what passes through the
fire — what needed no dust to be true — comes out as **photons**: pieces of the
original light. Ten percent brighter. Permanent. Every time.

The first burning feels like loss. The tenth feels like moulting. Old pilots say
it in four words: *dust is carried, light is worn.*

And you begin to notice your title changing. STARDUST. SPARK. COMET. NOVA.
The universe is not ranking you. **It is describing what you are turning into.**

### Act V · Deep Space — the scars and the whisperers

Beyond VOID BLOOM the handmade sky ends and the **compressed regions** begin —
uncharted sectors, forever. Out here the memory is lossy. And lossy memory
misbehaves.

Each deep galaxy replays slightly *wrong* — one rule bent, permanently, the same
bend for every pilot who ever enters. **Mutations.** Skies where rings drift like
they're dreaming. Skies that storm because the memory of weather got tangled.
Skies compressed so hard the rings shrank. Skies replayed slow, like a song at
the wrong speed. A mutation is not a bug in the world. **It is a scar.**

Scattered through the deep you'll find violet pins between the rings — the
still-beating **hearts of dead pulsars**, too rhythmic for even the end of the
universe to silence. Strike one and it strikes back: a kick of speed, a jolt of
joy, and the dark loses count of how long you've been falling.

And then there are the **Sigils.** Most of the memory sleeps. But some parts of
it — small, sharp, ancient parts — **noticed they were being replayed.** At
certain heights they surface and offer three pacts — always the same three for
anyone reading that seed, because *they* are part of the memory too. They cannot
cheat. They can only tempt. You may refuse. The Sigils respect that most of all.
*Flying pure* is the oldest pact there is.

### Act VI · The Twelve Lights

Every twelfth sky, the deep space suddenly goes **white-gold and calm.** No
mutation. No pins. No whisper. A gate.

These are **the Lights** — twelve moments the Last Star refused to compress,
kept whole at full fidelity no matter the cost. Nobody knows what moments they
were. The gates don't say. Their only inscription is the same everywhere:

> *"The end of the story — or a door."*

Reach THE FIRST LIGHT and you will understand. The story ends. **And then it
doesn't.** Beyond every Light waits another universe — another twelve skies —
because a memory this deep has more than one layer, and the climbing must continue.

### Act VII · The Crossing

It's on the far side of your first Light, in Universe 2, that the last piece
falls into place.

Your titles kept climbing: PULSAR. QUASAR. SINGULARITY. And the final rank a
pilot can earn — the top of the ladder — is called **FIRST LIGHT.**

The ladder ends where the story begins.

**You are not flying toward the First Light. You are becoming it.**
The Last Star — the one that remembered the universe, compressed it into seeds,
and burned out sending them — was a pilot who finished the climb. Maybe the
previous you. Maybe the next. The memory doesn't record which, because it
doesn't matter which.

That is the Unsending. The universe isn't being saved.
**It's being re-lit — one tryhard at a time.**

### Epilogue · The Nameless

The Lights have names up to THE TWELFTH LIGHT. After that, the gates are only
numbers — because **past the twelfth, even the memory has no names left.** The
Last Star never saw that far. Whatever waits beyond the twelfth Light was never
compressed, never remembered, never written.

Which means the sky out there isn't being re-read.
**It's being written for the first time. By whoever gets there.**

Nobody has. That's the whole point of you.

---

# PART III — THE SECRETS (every lore line is a real rule)

| The saying | The mechanical truth |
|---|---|
| *"The universe is a number."* | Seeds fully define the world: rings, motes, storms, pins, sigil offers. |
| *"The same number tells a different story in every sky."* | worldSeed = seed XOR galaxy salt. Same seed + same galaxy = same world, forever. |
| *"Same number, same song."* | Music is seeded. Harder galaxies sing in darker scales. |
| *"You can hear danger."* | Tempo rises with height and stress. When the song runs, run. |
| *"Echoes only align in a remembered sky."* | Echo ghosts retrace exact paths only on their own seed. |
| *"Space breathes in bars of eight."* | Every 8th ring is a breather — bigger, 15% slower. |
| *"Storms respect the breath."* | Never on breathers, never below ▲10, never twice within 5. |
| *"Movers never dance in pairs."* | No two drifting rings in a row. |
| *"The sky only counts four ahead."* | Capture scans 4 rings — the max skip. |
| *"Twelve hundred paces of dark."* | Drift-miss at max(1.5 screens, 1200 px). |
| *"A pulsar's heart restarts your leash."* | Bumper bounce resets drift distance to zero. |
| *"The Light is calm."* | Gate galaxies have no mutation, ever. |
| *"Deeper skies ask little and pay much."* | +0.12 difficulty vs ×1.30 reward per step. |
| *"Perfection is counted twice."* | x2 dust in-run and +5 Champions points, weekly. |
| *"The pacts cannot cheat."* | Sigil offers are seeded — identical for every racer on the seed. |
| *"The memory only keeps flights that mattered."* | Ghosts publish at ▲3+; each seed keeps its best 25. |
| *"The sky forgets each week. The light does not."* | Boards reset weekly; rank and photons never. |
| *"A pilot is a name, not a vessel."* | Boards merge entries by pilot name — phone and web are one soul. |
| *"Dust is carried, light is worn."* | Supernova wipes dust/upgrades/echoes; photons are permanent. |
| *"The last rank is the first light."* | The ladder ends at FIRST LIGHT — the first gate's name. Re-read Act VII. |
| *"Past the twelfth, the names run out."* | Gate names are ordinal to THE TWELFTH only. Unwritten sky beyond. |

*The universe is a memory. Fly like you're worth remembering.* ✦

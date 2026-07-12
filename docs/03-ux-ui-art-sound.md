# 9–11, 14. UX/UI, Art Direction, Sound, Screens

## 9. UX/UI

**Doctrine:** the game is the menu. No loading screens after boot (<2 s cold start). Every screen reachable in ≤2 taps. All interactive elements in the bottom 60% of the screen (thumb zone). Portrait only.

- **One-input philosophy:** in-run, the entire screen is the button. Menus use large (≥56 dp) bottom-anchored targets.
- **Instant resume:** app state serialized on every ring capture and on background; reopening drops you into your orbit within 1 s.
- **No interruptions:** no popups during runs, ever. News/offers live behind a small satellite icon on the home orbit, never modal.
- **Progress ambient display:** home screen shows the three "almost there" bars (upgrade, daily, collection) orbiting as satellites — glanceable, tap to expand.
- **Feedback stack:** every positive event = sound + particle + number popup + (optional) 10 ms haptic tick. Every negative event = soft, brief, never shaming (fall = gentle slide-whistle down + Save Ring "whoosh" rescue).
- **Accessibility:** color-blind safe palette (shape + brightness never color-only), reduced-motion mode, left/right-hand agnostic, font scaling, no reading required to play (icons + numbers).
- **Localization-ready:** all strings externalized (ARB), no text baked into art, number/date formatting via ICU, pseudo-locale test in CI. ~200 strings total.

## 10. Graphic palette & art direction

**Style:** "luminous minimalism" — flat vector shapes, additive glow, generous negative space. Zero textures → tiny binary, GPU-cheap, timeless.

| Role | Color | Hex |
|---|---|---|
| Deep space background (top) | Ink navy | `#0B1026` |
| Background (bottom gradient) | Twilight indigo | `#1B2350` |
| Primary accent / player star | Aurora mint | `#5DF2C8` |
| Secondary accent / perfect arcs | Solar coral | `#FF7E6B` |
| Rings (neutral) | Moon lavender | `#8E9BFF` |
| Stardust / rewards | Warm gold | `#FFD166` |
| Premium (Prisma) | Iris violet | `#B388FF` |
| UI text on dark | Starlight | `#EAF2FF` |
| Danger/fall (soft) | Dusk rose | `#E36588` |

- Background hue shifts subtly with altitude (navy → violet → pre-dawn teal at extreme heights) — altitude becomes *felt*.
- Motion language: everything eases (cubic out), captures "pop" with 6–10 particles, echo ghosts at 35% opacity with dashed trails.
- Seasonal reskins change accents + particles only (cheap to produce, instantly recognizable in screenshots).

## 11. Sound design

**Goal:** the game should be pleasant *heard from across a room* — reviews mention "satisfying".

- **SFX (synthesized, <300 KB total):**
  - Capture: soft marimba pluck — pitch rises with combo along a pentatonic scale (combos literally play a melody; breaking a combo never plays a "wrong" note, the scale just restarts).
  - Perfect Arc: crystal chime + 80 ms shimmer.
  - Dust pickup: tiny glass tick (rate-limited so streams of dust become a gentle arpeggio).
  - Save Ring: reverse-cymbal "whoosh" + relieved two-note motif.
  - Fall: muted slide, never harsh.
  - Supernova: big warm swell → silence → single deep bell. (The one dramatic sound in the game.)
- **Music:** generative ambient pad in D major, 60–70 BPM, intensity layers keyed to altitude; ducks −6 dB under SFX. Loops are chord-cycle based (no seam). Relaxing but forward-moving.
- All audio optional; separate music/SFX sliders; respects device silent mode.

## 14. Application screens

| # | Screen | Content | Reached by |
|---|---|---|---|
| 1 | **Home / Orbit Idle** | Your star orbiting Ring 1 (tap = play instantly), dust & prisma counters, 3 progress satellites, small icons: shop, collections, settings, leaderboard | App open |
| 2 | **Run (HUD)** | Height, combo, dust this run, echo indicators; nothing else | Tap from Home |
| 3 | **Results** | Height + record delta, dust breakdown (you / echoes / combo), challenge ticks, buttons: Retry (huge), Double Down (ad), Upgrade shortcut | Run end |
| 4 | **Upgrades** | 7 upgrade cards with cost/next-effect, photon tree tab after first prestige | Bottom sheet from Home/Results |
| 5 | **Supernova** | Cinematic prestige confirm: photons preview, what resets / what stays (explicit list) | Home when Height ≥ 50 reached |
| 6 | **Collections** | Constellation cards grid, set bonuses (cosmetic), pod opening | Home icon |
| 7 | **Challenges** | 3 dailies, 1 weekly, streak calendar with shield status | Home satellite |
| 8 | **Events** | Current seasonal event map + event leaderboard | Home banner (non-modal) |
| 9 | **Shop** | Season pass, cosmetics, pods, Supporter Pack; visible odds page | Home icon |
| 10 | **Leaderboards / Friends** | Weekly height ladder (brackets of 50), friends list, challenge-a-friend, referral | Home icon |
| 11 | **Settings** | Audio, haptics, reduced motion, language, cloud save, parental info, privacy | Home icon |
| 12 | **Skins / Loadout** | Star core, trail, ring theme, sound set, echo loadout picker | Collections tab |

Flow rule: Home → any screen → Home is always one back-gesture. In-run there are zero exits except pause (tap top corner) → resume/quit.

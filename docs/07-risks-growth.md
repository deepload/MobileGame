# 19. Project Risks & 20. Path to 10M+ Downloads

## 19. Risks (probability × impact, with mitigations)

| Risk | P | I | Mitigation |
|---|---|---|---|
| **Core loop tests "nice but not sticky"** | M | Fatal | M1 "toy test" gate before any meta work; feel-first prototype; kill/pivot criteria written in advance (testers replay ≥5 runs unprompted or we iterate the verb, not the meta). |
| **Echo mechanic confuses players** | M | High | Show, don't tell (run-2 reveal); A/B the reveal timing; echoes are pure bonus — game works if ignored, so confusion degrades to a normal climber, not a broken game. |
| **Clone risk** (mechanic is copyable in weeks) | H | M | Speed + brand + LiveOps moat; the echo *economy* (recordings, tuning, prestige interplay) is deep-copy-hard; file design marks; ship weekly gauntlet fast (community lock-in). |
| **UA costs kill growth** (hypercasual CPI inflation) | H | High | Product built for organic (K-factor, shareable replays, featuring-friendly ethics); soft-launch proves LTV > CPI before scaling spend; web/PWA as zero-CPI channel. |
| **Retention great, revenue weak** (generosity overshoot) | M | M | Season pass is the lever (retroactive = late-cohort friendly); Supporter Pack captures goodwill; raise pod/cosmetic breadth, never tighten the free experience. |
| **Ad network kid-safety violation** | L | High | Certified kid-safe mediation only, allowlist of networks, quarterly audit, contractual penalties. |
| **Platform policy shifts** (privacy, ad IDs, fees) | M | M | Monetization mix not ad-dependent (target ≤ 55% and falling); first-party analytics; web build as platform hedge. |
| **Flutter/Flame web performance on low-end phones** | M | M | HTML5 prototype already proves the loop runs in pure canvas; web targets CanvasKit with quality fallbacks; mobile apps are the primary channel. |
| **Team scope creep** (20-system design, 5-person team) | H | High | M-gates with exit criteria; everything after M3 is Remote-Config data, not code; season content is reskins by design. |
| **Cheating poisons leaderboards** | M | L | Checksummed input logs, server spot-replay of top ranks, bracket-of-50 design limits blast radius; economy is never PvP-coupled. |
| **Single-point key-person loss** | L | M | Docs-first culture (this package), weekly design snapshots, bus-factor ≥ 2 on engine and economy. |

## 20. How to exceed 10M downloads

**Philosophy:** paid UA ignites; only product-led virality and platform leverage reach 10M for a small team.

### 1. Built-into-the-product growth (the compounding engine)
- **One-tap replay export:** any run renders as a 10–20 s vertical video (star + echoes + trails, big height number, subtle logo). TikTok/Shorts/Reels-native. The game *manufactures* content.
- **Ghost Challenge links:** "Race my Echo" deep link — recipient plays *against the sender's actual recorded run* in the web version instantly, no install (PWA), then converts to app. This is the K-factor workhorse (target CTR→install ≥ 25% because the challenge is personal).
- **Weekly Gauntlet:** identical seed worldwide → fair comparisons → screenshot culture ("Height 214 on this week's sky — beat it").
- **Referrals:** both sides get a Nebula Pod + exclusive trail at friend's first prestige (rewards deep engagement, not installs — fraud-resistant).

### 2. Platform featuring (free distribution at scale)
- The pitch Apple/Google editorial teams want: original mechanic, ethical monetization (no forced ads, spend caps, visible odds), offline, <20 MB, 7+, 13 languages, accessibility features. Each of these is a checkbox on their featuring rubrics — the game is *designed to be featurable*.
- Target: launch feature + seasonal re-features (6 chances/year with each season).

### 3. Creators & community
- Creator kit at launch: replay exporter, seed-sharing, press kit, custom gauntlet codes for streamers ("play my sky").
- Speedrun/high-score angle seeded with 20 mid-size skill-game creators (not mega-influencers — better CPM and authenticity).
- Community events: "Global Climb" (all players' heights sum toward a world goal, everyone gets the reward) — news-worthy, screenshot-friendly.

### 4. Web as a funnel, not just a port
- PWA plays instantly from any link (ghost challenges, Reddit, Discord). Zero-friction taste → app install prompt at the natural peak (after first Save-Ring rescue). Web-to-app conversion is a tracked KPI (target ≥ 15%).

### 5. Paid UA (disciplined, last)
- Only after soft launch proves D7 > 30% and LTV(180) > 3×CPI. Creative = real gameplay (the genre punishes fake ads with retention collapse — and it's unethical anyway). Scale in waves per region, always behind featuring beats.

### 6. Localization & regional beats
- 13 languages at launch; region-tuned events (Lunar New Year, Diwali, Ramadan-friendly night themes) — each is a store-featuring opportunity in its region.

**Model to 10M (24 months, conservative):** soft launch 100k → global launch + featuring 1.5M (M1–M3) → K-factor 0.25–0.35 compounding + seasonal re-features + creators ≈ 350–500k/mo organic → paid UA layered where LTV allows (+100–200k/mo) → web funnel 10–15% incremental. Cumulative crosses 10M around month 20–24; upside case (one viral replay-format hit) pulls it under 12.

# 6–8. Economy, Monetization, Rewarded Ads

## 6. Complete economy

### Currencies

| Currency | Type | Earned by | Spent on | Notes |
|---|---|---|---|---|
| **Stardust ✦** | Free, soft | Runs (rings, dust motes, combos), Echo income, challenges, achievements, pods | Permanent upgrades, common skins | Inflates by design; sinks scale with prestige. |
| **Photons ◉** | Free, prestige | Supernova (prestige) only: `floor((maxHeight-40)^0.8)` per collapse | Photon skill tree, star tiers | The long-term power currency. **Cannot be bought.** |
| **Prisma ◆** | Premium | IAP; also drip-earned free (weeklies, events, achievements ≈ 60/week free) | Cosmetics, Nebula Pods, QoL (extra loadout slots), season pass | **Never buys power.** All Prisma items are cosmetic or convenience. |

### Earning rates (launch tuning, A/B-tested later)

- Base: 5 ✦ per ring; Perfect Arc ×2; combo adds +10% per step (cap ×3).
- Dust motes: 1–3 ✦ each, ~15 per screen-height.
- Echo income: each equipped Echo yields `(its run's dust) × echoYield%` live during your run. echoYield starts 10%, upgradeable to 40%. 1→3 Echo slots via upgrades, 4th via photon tree.
- Typical minute of play (day 1): ~150 ✦. (day 30, post-prestige ×4, 3 echoes): ~3 000 ✦ — numbers grow visibly but upgrade costs grow at matched pace (cost curve ×1.6/level).

### Sinks

- **Upgrades (Stardust):** Aim Guide, Dust Magnet, Save Ring charges (max 3), Echo Slots, Echo Yield, Combo Keeper, Launch Precision. Costs: `base × 1.6^level`.
- **Photon skill tree (Photons):** 3 branches — *Fortune* (dust mult), *Grace* (bigger capture windows, extra save), *Legacy* (echo power, 4th slot, echo perfect-arc replication).
- **Cosmetics (Prisma/Stardust):** star cores, trails, ring themes, capture effects, sound sets.

### Chests — "Nebula Pods"

- Contain: skin shards, Stardust bundles, boosters, constellation cards.
- **Visible drop rates in-game.** Pity: guaranteed Rare+ every 10 pods, Epic+ every 30.
- Sources: daily challenge (1/day free), weekly (premium pod), events, rewarded ad (1/day), Prisma purchase.

### Multipliers & temporary boosters

- Permanent: photon global multiplier (from prestige), star tier bonus.
- Temporary: 2× dust booster (4 h, from ads/pods/events), Combo Shield (one dropped combo forgiven, consumable), Storm Lure (more storm rings next run).
- Stacking rule: additive within a type, multiplicative across types, always displayed as one clear "×N.N" on the HUD — no hidden math.

### Balance guardrails

- A player who never pays and never watches ads reaches every gameplay feature; pace difference vs. ad-watchers ≤ 25%.
- No currency ever hits zero-usefulness; Stardust overflow feeds an auto-converting "Dust → cosmetic shards" endgame sink.
- Weekly economy review dashboard: earn/sink ratio per cohort must stay in 0.9–1.1.

## 7. Monetization (ethical, generosity-first)

**Principles:** no forced ads, no energy/lives, no pay-for-power, no dark timers, no FOMO pressure on children, all odds visible, spend caps.

| Stream | Content | Price points | Share of revenue (target) |
|---|---|---|---|
| Rewarded ads (opt-in only) | See §8 | — | ~55% at launch |
| **Season Pass "Star Voyage"** | 60 tiers of cosmetics/pods/prisma; free track always present; tiers earned by normal play (~20 min/day completes it); **retroactive**: buying it late instantly grants everything already earned | $4.99 / season (8 weeks) | ~30% |
| Cosmetic IAP | Skins, trails, themes, sound sets; bundles | $1.99–$9.99 | ~10% |
| **Supporter Pack** | One-time: removes ad *buttons* being needed — grants the daily ad rewards automatically forever + exclusive trail "Patron's Comet" | $9.99 one-time | ~5% |
| Prisma packs | For cosmetics/pods only | $0.99–$19.99, **monthly spend cap $50 default** (raisable only via age-gated setting) | — |

**Perceived generosity mechanics** (deliberate): daily free pod, free prisma drip, retroactive pass, streak shields, refunds on skin overlap (never duplicate-scam), "we saved your combo" moments. Target: players *describe* the game as generous in reviews — that sentence is a KPI (review text mining).

**Kid safety (7+):** no chat, no real-money trading, purchases behind platform parental gates, ad networks filtered to certified kid-safe inventory, COPPA/GDPR-K compliant (no behavioral ad targeting for under-13 flags).

## 8. Rewarded ads (100% optional)

| Placement | Offer | Frequency cap | Why players love it |
|---|---|---|---|
| **Second Chance** | Revive after final fall, keep combo | 1/run | Saves a great run at its emotional peak. |
| **Double Down** | ×2 the dust of the run just finished | 1/run | Shown only after good runs (> personal median) — feels like a bonus, not a toll. |
| **Bonus Pod** | 1 extra Nebula Pod | 1/day | Daily ritual. |
| **Warp Boost** | 4 h ×2 dust booster | 2/day | Session extender. |
| **Daily+ ** | Upgrade today's daily reward one rarity tier | 1/day | Compounds the login habit. |
| **Echo Overdrive** | Next run: echoes earn double | 1/day | Reinforces the signature mechanic. |

Rules: never interstitial, never auto-play, button always says the exact reward, ad failure (no fill/offline) grants the reward anyway (goodwill > pennies), global cap 6 rewarded ads/day, all placements disabled by Supporter Pack (rewards granted automatically).

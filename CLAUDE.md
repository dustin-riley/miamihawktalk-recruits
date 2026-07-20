# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A **Discourse theme component** that replaces the default onebox on 247Sports
player links with a rich recruit card. It reads `/redhawks-recruit.json`, which
the `discourse-redhawks-schedule` plugin serves.

No build step, no package manager, no test runner. The source files are the
deliverable.

## Deploy

```bash
git push origin main
```

Then **Admin → Customize → Themes → Components → MiamiHawkTalk Recruits →
Update**, and hard-refresh. No rebuild, no downtime.

## How the swap works

`api.decorateCookedElement` finds 247 player links, then
`helper.renderGlimmer(el, RecruitCard, data, { append: false })` replaces the
onebox's contents. `append: false` is load-bearing: it compiles to
`{{#in-element}}` without `insertBefore`, which clears the target first.
`append: true` would render the card *underneath* the old onebox.

**Fetch first, render second.** The card replaces the onebox only once data has
arrived, so a reader with no JavaScript — or a failed fetch — keeps Discourse's
own onebox rather than an empty box.

## Two layouts, one data layer

`RecruitCard` computes **every** value and holds **no** markup of its own. It
picks a layout from the `card_layout` setting and passes itself down as
`@card`:

| `card_layout` | Component | Shape |
|---|---|---|
| `editorial` (default) | `recruit-editorial.gjs` | No frame — an accent rule down the left edge, a commitment banner, and offer chips |
| `stat_block` | `recruit-stat-block.gjs` | Framed card: ~88px rail (photo, stacked ratings, stars) plus a body of identity and three summary stats. No school list at all |

Layouts are **presentation only**. A getter belongs on `RecruitCard`, never in
a layout, so the two can never disagree about what the data means. Editorial is
the `{{else}}` branch on purpose: an unrecognised `card_layout` must fall back
to it, because the onebox's contents are already cleared by the time the card
renders and "no branch matched" would leave an empty box.

Red (`var(--tertiary)`) means **Miami specifically**, not "commitment
generally". A recruit committed to Ohio State gets the neutral treatment.

**Absent and zero must never render identically.** Use the `has*` getters
(`hasRating247`, `hasComposite`, `hasStars`, `hasOfferCount`,
`hasNationalRank`) rather than gating a template on the bare value — these all
return `null` for "247 reported nothing", and `{{#if}}` on the value itself
would hide a real 0. This bug class has recurred here.

## Chips are offered schools only

`offerChips` filters to `offered === true`, sorts via `sortOffers` (Miami
pinned first when `pin_miami_first`), and caps at `CHIP_LIMIT` in
`recruit-card.gjs`. A chip therefore *means* "offered" with no second visual
class. `hiddenOfferCount` prefers the server's `offer_count` over the list
length, falling back to the length when the count is absent. Chips exist in the
editorial layout only.

## Onebox chrome suppression

`common.scss` strips Discourse's border/padding/background from
`aside.onebox[data-mht-recruit-rendered]`. It keys on **`-rendered`**, which the
api-initializer sets only on the success path — `data-mht-recruit` is the
duplicate-fetch guard, set *before* the fetch and therefore present on failures
too. Keying on that one would strip the frame from a failed fetch and leave the
reader a chromeless box. Do not "simplify" it.

## Translations must go through `themePrefix`

Keys sit directly under `en:` with no `js:` level. A bare `i18n("offers")`
renders the literal `[en.offers]` on screen for every user.

## Colours come from the parent theme

Use `var(--primary)`, `var(--tertiary)`, `var(--primary-medium)`,
`var(--primary-low)`. **Never hardcode a colour** — the parent theme ships light
and dark schemes and a literal hex breaks one of them.

## Verifying changes

No unit tests. Verification is the running site, in **both** colour schemes,
logged in **and** logged out, on mobile, and in **both** `card_layout` values.
The usable width inside a post on a 390px phone is ~326px — that is the number
every wrapping and truncation decision here is sized against.

Planned work lives in `../BACKLOG.md`, not here.

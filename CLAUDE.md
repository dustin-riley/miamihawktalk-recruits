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

## Translations must go through `themePrefix`

Keys sit directly under `en:` with no `js:` level. A bare `i18n("offers")`
renders the literal `[en.offers]` on screen for every user.

## Colours come from the parent theme

Use `var(--primary)`, `var(--tertiary)`, `var(--primary-medium)`,
`var(--primary-low)`. **Never hardcode a colour** — the parent theme ships light
and dark schemes and a literal hex breaks one of them.

## Verifying changes

No unit tests. Verification is the running site, in **both** colour schemes,
logged in **and** logged out, and on mobile. The offers list needs
`overscroll-behavior: contain` or scrolling to its end captures the page scroll.

Planned work lives in `../BACKLOG.md`, not here.

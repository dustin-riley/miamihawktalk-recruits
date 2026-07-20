import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { isMiamiTeam, relativeAge, sortOffers } from "../lib/recruit-data";

// Five chips is two rows at 326px — the usable width inside a Discourse post
// on a 390px phone — where eight is four rows and taller than the player's
// entire identity block. Miami is pinned first by sortOffers, so the cap
// never hides the row a reader came for.
const CHIP_LIMIT = 5;

export default class RecruitCard extends Component {
  get recruit() {
    return this.args.data.recruit;
  }

  get layout() {
    return settings.card_layout;
  }

  // "QB · 2027 · Cincinnati Elder" — every part optional, joined only if present.
  get subtitle() {
    const r = this.recruit;
    return [r.position, r.class_year, r.high_school].filter(Boolean).join(" · ");
  }

  // "Cincinnati, OH · 6-1.5, 170" — the parser has always extracted city,
  // height and weight; the card discarded all three until now.
  get metaLine() {
    const r = this.recruit;
    const size = [r.height, r.weight].filter(Boolean).join(", ");
    return [r.city, size].filter(Boolean).join(" · ");
  }

  // "QB #67 · OH #52"
  get rankLine() {
    const ranks = Array.isArray(this.recruit.ranks) ? this.recruit.ranks : [];
    return ranks.map((rank) => `${rank.label} #${rank.value}`).join(" · ");
  }

  get nationalRank() {
    const ranks = Array.isArray(this.recruit.ranks) ? this.recruit.ranks : [];
    const natl = ranks.find((r) => /natl|national/i.test(String(r.label || "")));
    return natl && Number.isFinite(natl.value) ? natl.value : null;
  }

  // Finite checks throughout, never truthiness: a rating of 0 is a real
  // value and must render, where `if (rating)` would silently hide it.
  get hasRating247() {
    return Number.isFinite(this.recruit.rating);
  }

  get hasComposite() {
    return Number.isFinite(this.recruit.composite_rating);
  }

  get hasAnyRating() {
    return this.hasRating247 || this.hasComposite || this.hasStars;
  }

  // ".8600" — the leading zero is dropped because the number only ever sits
  // under a "Composite" label, where the 0-1 scale is not in question, and
  // the four significant digits are what readers compare.
  //
  // toFixed(4) can only produce a leading "0" when the value is below 1, so
  // the strip is anchored safely: a composite of exactly 0 renders ".0000"
  // rather than vanishing, keeping "absent" (null, row hidden) and "zero"
  // visually distinct.
  get compositeText() {
    if (!this.hasComposite) {
      return null;
    }
    return this.recruit.composite_rating.toFixed(4).replace(/^0/, "");
  }

  // An absent `stars` must never be depicted as an empty five-star row, so the
  // row itself is conditional on this rather than always rendering starsText.
  get hasStars() {
    return Number.isFinite(this.recruit.stars);
  }

  // Plain text, not markup — no htmlSafe, so this can never inject. Clamped
  // to the 0-5 scale so an out-of-range value can't render more than 5 glyphs.
  get starsText() {
    const raw = this.recruit.stars;
    const filled = Number.isFinite(raw) ? Math.min(5, Math.max(0, Math.floor(raw))) : 0;
    return "★".repeat(filled) + "☆".repeat(5 - filled);
  }

  get commitmentTeam() {
    return this.recruit.committed_to || null;
  }

  get committedToMiami() {
    return isMiamiTeam(this.commitmentTeam);
  }

  // Distinct from committedToMiami: a recruit can hold a Miami offer while
  // committed elsewhere, and the stat block reports those as different states.
  get miamiOffered() {
    const offers = Array.isArray(this.recruit.offers) ? this.recruit.offers : [];
    return offers.some((o) => isMiamiTeam(o.team) && o.offered === true);
  }

  get offerCount() {
    return Number.isFinite(this.recruit.offer_count) ? this.recruit.offer_count : null;
  }

  // Chips are offered schools only. A chip therefore means "offered" with no
  // second visual class needed — which is the whole point, since an
  // interest-only school is only meaningful inside the complete list, and
  // any cap sorted offers-first would drop it anyway.
  get offeredSchools() {
    const offers = Array.isArray(this.recruit.offers) ? this.recruit.offers : [];
    const offered = offers.filter((o) => o && o.offered === true);
    return sortOffers(offered, settings.pin_miami_first);
  }

  get offerChips() {
    return this.offeredSchools.slice(0, CHIP_LIMIT).map((offer) => ({
      team: offer.team,
      isMiami: isMiamiTeam(offer.team),
    }));
  }

  // Prefers the server's full count over the list length: the list is what we
  // parsed, the count is what 247 reported, and on a fallback render the two
  // legitimately differ. Falls back to the list length when the count is
  // absent, so a missing `offer_count` never silently zeroes the overflow.
  get hiddenOfferCount() {
    const total = this.offerCount === null ? this.offeredSchools.length : this.offerCount;
    return Math.max(0, total - this.offerChips.length);
  }

  get age() {
    return relativeAge(this.recruit.fetched_at);
  }

  // --- Legacy getters, used only by the <template> below ---------------------
  // Task 6 replaces that template with the two new layouts and deletes these.
  // Until then they must stay: removing them now breaks the rendered card.

  // An absent rating and a zero rating mean different things: omit the whole
  // cluster rather than rendering 0 or NR.
  get hasRating() {
    return Number.isFinite(this.recruit.rating) || Number.isFinite(this.recruit.stars);
  }

  // Same finite check as hasRating — a rating of 0 must render the 247 number,
  // not hide it the way a plain truthiness check on `0` would.
  get hasCompositeRating() {
    return Number.isFinite(this.recruit.rating);
  }

  // null (no offers section on the page) renders no panel at all. An empty
  // array would render an empty bordered box.
  //
  // The Miami flag is computed here rather than called from the template:
  // invoking a plain function in a template subexpression relies on Ember's
  // function-as-helper behaviour, and a precomputed property needs no such
  // assumption.
  get offers() {
    if (this.recruit.offers === null || this.recruit.offers === undefined) {
      return null;
    }
    const sorted = sortOffers(this.recruit.offers, settings.pin_miami_first);
    if (!sorted.length) {
      return null;
    }
    return sorted.map((offer) => ({
      ...offer,
      isMiami: isMiamiTeam(offer.team),
    }));
  }

  <template>
    <div class="mht-recruit">
      <div class="mht-recruit__head">
        {{#if this.recruit.photo}}
          <img class="mht-recruit__photo" src={{this.recruit.photo}} alt="" loading="lazy" />
        {{/if}}

        <div class="mht-recruit__identity">
          <a class="mht-recruit__name" href={{@data.url}} target="_blank" rel="noopener noreferrer">
            {{this.recruit.name}}
          </a>
          {{#if this.subtitle}}
            <div class="mht-recruit__subtitle">{{this.subtitle}}</div>
          {{/if}}
          {{#if this.rankLine}}
            <div class="mht-recruit__ranks">{{this.rankLine}}</div>
          {{/if}}
        </div>

        {{#if this.hasRating}}
          <div class="mht-recruit__rating">
            {{#if this.hasStars}}
              <div class="mht-recruit__stars">{{this.starsText}}</div>
            {{/if}}
            {{#if this.hasCompositeRating}}
              <div class="mht-recruit__rating-247">{{this.recruit.rating}}</div>
            {{/if}}
          </div>
        {{/if}}
      </div>

      {{#if this.offers}}
        <ul class="mht-recruit__offers">
          {{#each this.offers as |offer|}}
            <li
              class="mht-recruit__offer
                {{if offer.isMiami 'mht-recruit__offer--miami'}}"
            >
              <span class="mht-recruit__team">{{offer.team}}</span>
              {{#if offer.status}}
                <span class="mht-recruit__status">{{offer.status}}</span>
              {{/if}}
            </li>
          {{/each}}
        </ul>
      {{/if}}

      <div class="mht-recruit__footer">
        <a href={{@data.url}} target="_blank" rel="noopener noreferrer">
          {{i18n (themePrefix "source")}}
        </a>
        {{#if this.age}}
          · {{i18n (themePrefix "updated") age=this.age}}
        {{/if}}
      </div>
    </div>
  </template>
}

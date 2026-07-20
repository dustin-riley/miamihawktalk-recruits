import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { isMiamiTeam, relativeAge, sortOffers } from "../lib/recruit-data";

export default class RecruitCard extends Component {
  get recruit() {
    return this.args.data.recruit;
  }

  // "QB · 2027 · Cincinnati Elder" — every part optional, joined only if present.
  get subtitle() {
    const r = this.recruit;
    return [r.position, r.class_year, r.high_school].filter(Boolean).join(" · ");
  }

  // "QB #67 · OH #52"
  get rankLine() {
    const ranks = Array.isArray(this.recruit.ranks) ? this.recruit.ranks : [];
    return ranks.map((rank) => `${rank.label} #${rank.value}`).join(" · ");
  }

  // An absent rating and a zero rating mean different things: omit the whole
  // cluster rather than rendering 0 or NR.
  get hasRating() {
    return Number.isFinite(this.recruit.rating) || Number.isFinite(this.recruit.stars);
  }

  // Same finite check as hasRating — a rating of 0 must render the composite
  // number, not hide it the way a plain truthiness check on `0` would.
  get hasCompositeRating() {
    return Number.isFinite(this.recruit.rating);
  }

  // An absent `stars` must never be depicted as an empty five-star row, so the
  // row itself is conditional on this rather than always rendering starsText.
  get hasStars() {
    return Number.isFinite(this.recruit.stars);
  }

  // Plain text, not markup — no htmlSafe, so this can never inject. Clamped to
  // the 0-5 scale so an out-of-range value can't render more than 5 glyphs.
  get starsText() {
    const raw = this.recruit.stars;
    const filled = Number.isFinite(raw) ? Math.min(5, Math.max(0, Math.floor(raw))) : 0;
    return "★".repeat(filled) + "☆".repeat(5 - filled);
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

  get age() {
    return relativeAge(this.recruit.fetched_at);
  }

  get listStyle() {
    return htmlSafe(`max-height: ${settings.offers_max_height}px`);
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
              <div class="mht-recruit__composite">{{this.recruit.rating}}</div>
            {{/if}}
          </div>
        {{/if}}
      </div>

      {{#if this.offers}}
        <ul class="mht-recruit__offers" style={{this.listStyle}}>
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

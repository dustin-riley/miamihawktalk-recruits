import Component from "@glimmer/component";
import { isMiamiTeam, relativeAge, sortOffers } from "../lib/recruit-data";
import RecruitEditorial from "./recruit-editorial";

// Five chips is two rows at 326px — the usable width inside a Discourse post
// on a 390px phone — where eight is four rows and taller than the player's
// entire identity block. Miami is pinned first by sortOffers, so the cap
// never hides the row a reader came for.
const CHIP_LIMIT = 5;

export default class RecruitCard extends Component {
  get recruit() {
    return this.args.data.recruit;
  }

  // The layouts receive the whole component as @card and never see @data, so
  // the source URL has to be reachable as a card property like everything
  // else — @card.url is what both templates link to.
  get url() {
    return this.args.data.url;
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

  // Mirrors the truthy checks the offers-label markup itself branches on
  // (offerCount, then rankLine) so the label's own gate can never drift out
  // of sync with what it decides to render. Without this, a recruit with
  // neither a reported offer count nor a rank line still gets an empty
  // &__offers-label div — roughly a line-box of dead space above the chips.
  get hasOffersLabel() {
    return Boolean(this.offerCount) || Boolean(this.rankLine);
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

  <template>
    <RecruitEditorial @card={{this}} />
  </template>
}

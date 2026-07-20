import Component from "@glimmer/component";
import { isMiamiTeam, relativeAge, sortOffers } from "../lib/recruit-data";
import RecruitEditorial from "./recruit-editorial";
import RecruitStatBlock from "./recruit-stat-block";

// Five chips is two rows at 326px — the usable width inside a Discourse post
// on a 390px phone — where eight is four rows and taller than the player's
// entire identity block. Miami is pinned first by sortOffers, so the cap
// never hides the row a reader came for.
const CHIP_LIMIT = 5;

// The one implementation behind both star rows. 247's `stars` and the
// composite's `composite_stars` are separate numbers that the card shows side
// by side precisely so a divergence between them is visible — which only works
// if the *rendering* of the two is identical, so a difference on screen can
// only ever mean a difference in the data. Two near-copies of this would be
// free to drift in their clamping or their glyphs and quietly invent one.
//
// Plain text, never htmlSafe, so it cannot inject. Clamped to the 0-5 scale so
// an out-of-range value can't render more than five glyphs. A non-finite input
// yields five hollow stars, which reads as "zero stars" — a false claim about a
// named teenager — so callers must gate on the matching has* getter and never
// render this unconditionally.
function starRow(raw) {
  const filled = Number.isFinite(raw)
    ? Math.min(5, Math.max(0, Math.floor(raw)))
    : 0;
  return "★".repeat(filled) + "☆".repeat(5 - filled);
}

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

  get isStatBlock() {
    return this.layout === "stat_block";
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

  // Presence, not truthiness — the same discipline as hasRating247. Both of
  // these getters return null for "247 reported nothing" and a number
  // otherwise, so a template gating on the bare value would collapse a
  // genuine 0 into the absent case and render the two identically.
  get hasNationalRank() {
    return this.nationalRank !== null;
  }

  get hasOfferCount() {
    return this.offerCount !== null;
  }

  // Finite checks throughout, never truthiness: a rating of 0 is a real
  // value and must render, where `if (rating)` would silently hide it.
  get hasRating247() {
    return Number.isFinite(this.recruit.rating);
  }

  get hasComposite() {
    return Number.isFinite(this.recruit.composite_rating);
  }

  // Each rating owns its own star row, so a rating's cell has two independent
  // reasons to exist: the number, or the stars. Both are needed because the
  // server can report one without the other — `rating` demands an integer
  // .rank-block where `stars` only needs a .stars-block, so a section carrying
  // a decimal rank-block yields stars with a null rating. Gating the cell on
  // the number alone would silently drop a real star row.
  get showRating247() {
    return this.hasRating247 || this.hasStars;
  }

  get showComposite() {
    return this.hasComposite || this.hasCompositeStars;
  }

  get hasAnyRating() {
    return this.showRating247 || this.showComposite;
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
  // Number.isFinite, not truthiness: the server returns nil rather than 0 for
  // "no stars found", but that is the server's contract, not this card's, and a
  // 0 arriving here must render as a real value rather than vanish. Do not
  // "simplify" this to `Boolean(this.recruit.stars)`.
  get hasStars() {
    return Number.isFinite(this.recruit.stars);
  }

  // The 247 section's star row. Shares starRow with the composite's below so
  // the two can never drift — see the comment on it.
  get starsText() {
    return starRow(this.recruit.stars);
  }

  // The composite's own star count, new alongside `composite_rating`. Absent
  // independently of `stars`: the server reads it from the Composite section
  // with no fallback, so a single-section page (enrolled players) yields stars
  // but no composite_stars, and the composite cell must then show its number
  // with no star row rather than a hollow one.
  get hasCompositeStars() {
    return Number.isFinite(this.recruit.composite_stars);
  }

  get compositeStarsText() {
    return starRow(this.recruit.composite_stars);
  }

  get commitmentTeam() {
    return this.recruit.committed_to || null;
  }

  get committedToMiami() {
    return isMiamiTeam(this.commitmentTeam);
  }

  // The server sends `offers: null` when the 247 page had no offers section at
  // all — an enrolled player, or a parse that found nothing — as distinct from
  // an empty list, which means "we looked and there are none". Only the latter
  // supports the negative claim "Miami has not offered". Absence of data about
  // a named teenager must never render as a statement about them, so every
  // consumer of miamiOffered has to gate on this first.
  get hasOfferData() {
    return Array.isArray(this.recruit.offers);
  }

  // hasOfferData is not enough to support a negative claim. The server builds
  // `offers` from the player page first — which shows only about five of a
  // recruit's schools — then replaces it with the full list from the interests
  // page. When that second fetch fails, `offers` is left holding the truncated
  // five and is still an array, so hasOfferData is true on a list that is a
  // sample rather than an answer. Sa'Nir Brooks (17 schools) renders as five.
  //
  // `offer_count` is the marker for the difference: RecruitAssembler.merge sets
  // it inside the one branch that assigns the full interests rows, and never
  // anywhere else, so its presence means "this list is the complete one" and
  // its absence means "these rows are whatever the player page happened to
  // show". That coupling lives on the server and is not visible from here,
  // which is why it is written down. Nothing may derive "Miami has not offered"
  // from an incomplete list.
  get offersComplete() {
    return this.hasOfferData && this.hasOfferCount;
  }

  // Distinct from committedToMiami: a recruit can hold a Miami offer while
  // committed elsewhere, and the stat block reports those as different states.
  // False when offers is null — which is why this is never read on its own;
  // pair it with hasOfferData to tell "no offer" from "we don't know".
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

  // The count 247 reported minus the chips shown. Null — not 0 — when the
  // server sent no `offer_count`, because that is the degraded path where the
  // rows are a truncated sample (see offersComplete) and the true remainder is
  // unknowable from here. Falling back to offeredSchools.length would compute
  // 0 and drop the overflow link entirely, presenting five schools as if they
  // were all of them: the exact lie by omission this card exists to fix.
  get hiddenOfferCount() {
    if (this.offerCount === null) {
      return null;
    }
    return Math.max(0, this.offerCount - this.offerChips.length);
  }

  // The overflow link renders whenever there is any chance of more — always on
  // the degraded path, since a truncated list can never be shown to be whole.
  // The template picks a numberless label in that case rather than inventing a
  // remainder.
  get hasHiddenOffers() {
    if (this.hiddenOfferCount === null) {
      return this.offerChips.length > 0;
    }
    return this.hiddenOfferCount > 0;
  }

  get age() {
    return relativeAge(this.recruit.fetched_at);
  }

  // Editorial is the {{else}} branch deliberately: an unrecognised or empty
  // card_layout value must fall back to the default layout rather than
  // render nothing at all — and by then the initializer has already cleared
  // the onebox's contents, so "nothing" would mean an empty box.
  <template>
    {{#if this.isStatBlock}}
      <RecruitStatBlock @card={{this}} />
    {{else}}
      <RecruitEditorial @card={{this}} />
    {{/if}}
  </template>
}

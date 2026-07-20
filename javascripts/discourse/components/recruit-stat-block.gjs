import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

// Presentation only, like RecruitEditorial: every value arrives computed on
// @card so the two layouts can never disagree about what the data means. The
// getters here are label/branching choices specific to this layout, not data.
export default class RecruitStatBlock extends Component {
  // Three states, not two: a recruit can hold a Miami offer while committed
  // elsewhere, and collapsing that into "no" would misreport it. Order
  // matters — committedToMiami is the strongest claim and is tested first,
  // because a Miami commit almost always also carries a Miami offer and would
  // otherwise be downgraded to "Offered".
  get miamiLabel() {
    if (this.args.card.committedToMiami) {
      return i18n(themePrefix("miami_committed"));
    }
    if (this.args.card.miamiOffered) {
      return i18n(themePrefix("miami_offered"));
    }
    return i18n(themePrefix("miami_none"));
  }

  // Red means Miami, never "commitment generally" — so the Miami stat's value
  // only takes the accent colour when Miami is actually in play. Rendering
  // "No offer" in tertiary would read as an alert and, worse, would spend the
  // one colour this component reserves for Miami on the absence of Miami.
  get hasMiamiInterest() {
    return Boolean(
      this.args.card.committedToMiami || this.args.card.miamiOffered
    );
  }

  // This layout has no school list and no commitment banner, so a commitment
  // to another school would otherwise be invisible — and a reader seeing the
  // Miami stat read "Offered" with nothing else on the card would reasonably
  // take the recruit for uncommitted. A Miami commitment needs no line: the
  // flooded rail and the "Committed" stat already say it, and repeating it
  // here is the only case where this line would be redundant.
  get otherCommitment() {
    const card = this.args.card;
    return card.committedToMiami ? null : card.commitmentTeam;
  }

  <template>
    <div
      class="mht-recruit mht-recruit--stat-block
        {{if @card.committedToMiami 'mht-recruit--committed'}}"
    >
      <div class="mht-recruit__rail">
        {{#if @card.recruit.photo}}
          <img
            class="mht-recruit__photo"
            src={{@card.recruit.photo}}
            alt=""
            loading="lazy"
          />
        {{/if}}
        {{#if @card.hasRating247}}
          <div class="mht-recruit__stat">
            <b>{{@card.recruit.rating}}</b>
            <span>{{i18n (themePrefix "rating_247")}}</span>
          </div>
        {{/if}}
        {{#if @card.hasComposite}}
          <div class="mht-recruit__stat">
            <b>{{@card.compositeText}}</b>
            <span>{{i18n (themePrefix "rating_composite")}}</span>
          </div>
        {{/if}}
        {{#if @card.hasStars}}
          <div class="mht-recruit__stars">{{@card.starsText}}</div>
        {{/if}}
      </div>

      <div class="mht-recruit__body">
        <a
          class="mht-recruit__name"
          href={{@card.url}}
          target="_blank"
          rel="noopener noreferrer"
        >{{@card.recruit.name}}</a>
        {{#if @card.subtitle}}
          <div class="mht-recruit__subtitle">{{@card.subtitle}}</div>
        {{/if}}
        {{#if @card.metaLine}}
          <div class="mht-recruit__meta">{{@card.metaLine}}</div>
        {{/if}}
        {{#if this.otherCommitment}}
          <div class="mht-recruit__commit-line">
            {{i18n (themePrefix "committed_to") team=this.otherCommitment}}
          </div>
        {{/if}}

        <div class="mht-recruit__stats">
          {{! hasOfferCount / hasNationalRank, never the bare numbers: a
              reported count of 0 is a real, publishable fact and must render
              as "0 Offers", where {{#if @card.offerCount}} would hide it and
              make it indistinguishable from 247 not reporting one at all. }}
          {{#if @card.hasOfferCount}}
            <div class="mht-recruit__stat">
              <b>{{@card.offerCount}}</b>
              <span>{{i18n (themePrefix "stat_offers")}}</span>
            </div>
          {{/if}}
          {{#if @card.hasNationalRank}}
            <div class="mht-recruit__stat">
              <b>{{@card.nationalRank}}</b>
              <span>{{i18n (themePrefix "stat_national")}}</span>
            </div>
          {{/if}}
          <div
            class="mht-recruit__stat mht-recruit__stat--miami
              {{if this.hasMiamiInterest 'mht-recruit__stat--miami-yes'}}"
          >
            <b>{{this.miamiLabel}}</b>
            <span>{{i18n (themePrefix "stat_miami")}}</span>
          </div>
        </div>

        <div class="mht-recruit__footer">
          <a
            href={{@card.url}}
            target="_blank"
            rel="noopener noreferrer"
          >{{i18n (themePrefix "source")}}</a>
          {{#if @card.age}}
            · {{i18n (themePrefix "updated") age=@card.age}}
          {{/if}}
        </div>
      </div>
    </div>
  </template>
}

import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

// Presentation only. Every value arrives computed on @card so the two layouts
// can never disagree about what the data means — only about how it looks.
export default class RecruitEditorial extends Component {
  <template>
    <div
      class="mht-recruit mht-recruit--editorial
        {{if @card.committedToMiami 'mht-recruit--committed'}}"
    >
      <div class="mht-recruit__head">
        {{#if @card.recruit.photo}}
          <img
            class="mht-recruit__photo"
            src={{@card.recruit.photo}}
            alt=""
            loading="lazy"
          />
        {{/if}}

        <div class="mht-recruit__identity">
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
        </div>

        {{#if @card.hasAnyRating}}
          <div class="mht-recruit__rating">
            <div class="mht-recruit__rating-pair">
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
            </div>
            {{#if @card.hasStars}}
              <div class="mht-recruit__stars">{{@card.starsText}}</div>
            {{/if}}
          </div>
        {{/if}}
      </div>

      {{#if @card.commitmentTeam}}
        <div
          class="mht-recruit__commit
            {{if @card.committedToMiami 'mht-recruit__commit--miami'}}"
        >
          ★
          {{i18n (themePrefix "committed_to") team=@card.commitmentTeam}}
        </div>
      {{/if}}

      {{#if @card.offerChips}}
        <div class="mht-recruit__offers">
          {{!-- Block-comment form is required, not {{! }}: that one ends at
              the FIRST "}}", so a comment mentioning template syntax
              terminates early and leaks its own tail as visible text.
              The separator is inside the count branch, not between two
              independent {{#if}}s: with only a rank line the brief's shape
              rendered a dangling leading "· ". --}}
          {{#if @card.hasOffersLabel}}
            <div class="mht-recruit__offers-label">
              {{#if @card.offerCount}}
                {{i18n (themePrefix "offers") count=@card.offerCount}}
                {{#if @card.rankLine}}
                  · {{@card.rankLine}}
                {{/if}}
              {{else if @card.rankLine}}
                {{@card.rankLine}}
              {{/if}}
            </div>
          {{/if}}
          <div class="mht-recruit__chips">
            {{#each @card.offerChips as |chip|}}
              <span
                class="mht-recruit__chip
                  {{if chip.isMiami 'mht-recruit__chip--miami'}}"
              >{{chip.team}}</span>
            {{/each}}
            {{! hasHiddenOffers, not the bare count: when the server sent no
                offer_count the chips are a truncated sample and the remainder
                is unknown, so the link still has to render — it just renders
                without a number rather than claiming one. Dropping it there
                would show five schools as though they were the whole list. }}
            {{#if @card.hasHiddenOffers}}
              <a
                class="mht-recruit__chip mht-recruit__chip--more"
                href={{@card.url}}
                target="_blank"
                rel="noopener noreferrer"
              >{{#if @card.hasOfferCount}}{{i18n
                    (themePrefix "more_offers")
                    count=@card.hiddenOfferCount
                  }}{{else}}{{i18n (themePrefix "more_offers_unknown")}}{{/if}}</a>
            {{/if}}
          </div>
        </div>
      {{/if}}

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
  </template>
}

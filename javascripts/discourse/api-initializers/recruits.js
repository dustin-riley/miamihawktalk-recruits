import { apiInitializer } from "discourse/lib/api";
import RecruitCard from "../components/recruit-card";
import { fetchRecruit, slugFrom } from "../lib/recruit-data";

// Verified against Discourse v2026.7.0-latest:
// - api.decorateCookedElement(callback, opts) — callback gets (element, helper)
// - helper.renderGlimmer(target, component, data, { append })
//   append: false compiles to {{#in-element}} with no insertBefore, which
//   REPLACES the target's content. append: true (the default) appends.
export default apiInitializer((api) => {
  api.decorateCookedElement((element, helper) => {
    if (!helper) {
      return;
    }

    const links = element.querySelectorAll('a[href*="247sports.com/player/"]');

    for (const link of links) {
      const slug = slugFrom(link.getAttribute("href"));
      if (!slug) {
        continue;
      }

      // Replace the whole onebox when Discourse made one; otherwise fall back
      // to the bare link, which happens for inline (non-standalone) links.
      const target = link.closest("aside.onebox") || link;

      // Guard against a post containing the same recruit twice.
      if (target.dataset.mhtRecruit) {
        continue;
      }
      target.dataset.mhtRecruit = slug;

      // Fetch first, render second: a failure must leave the onebox untouched.
      fetchRecruit(slug).then((recruit) => {
        if (!recruit || !target.isConnected) {
          return;
        }
        helper.renderGlimmer(
          target,
          RecruitCard,
          { recruit, url: link.href },
          { append: false }
        );
      });
    }
  });
});

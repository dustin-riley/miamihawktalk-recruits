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

      // Only swap a real onebox. A mid-sentence (non-oneboxed) 247 link has
      // no `aside.onebox` ancestor — leave it exactly as Discourse rendered
      // it rather than mounting a block-level card's contents (including its
      // own inner <a> tags) as children of the bare inline <a>. That would
      // both break markup (nested/invalid anchors, block content bursting
      // out of inline text flow) and, on re-decoration, compound: the card's
      // freshly-rendered inner links would match this same broad selector,
      // find no onebox ancestor either, and fall back to targeting
      // themselves with no dataset guard, nesting another card inside the
      // already-broken one on every subsequent pass. Do not restore a
      // `|| link` fallback here.
      const target = link.closest("aside.onebox");
      if (!target) {
        continue;
      }

      // Guard against a post containing the same recruit twice.
      if (target.dataset.mhtRecruit) {
        continue;
      }
      target.dataset.mhtRecruit = slug;

      // Fetch first, render second: a failure must leave the onebox untouched.
      fetchRecruit(slug)
        .then((recruit) => {
          if (!recruit || !target.isConnected) {
            return;
          }
          helper.renderGlimmer(
            target,
            RecruitCard,
            { recruit, url: link.href },
            { append: false }
          );
        })
        .catch(() => {
          // Silent: the reader's correct outcome is the untouched onebox.
        });
    }
  });
});

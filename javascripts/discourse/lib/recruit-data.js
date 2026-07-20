const ENDPOINT = "/redhawks-recruit.json";

// Matches the plugin's RecruitSource::SLUG. Trailing slash optional because
// people paste both forms.
const PLAYER_HREF = /247sports\.com\/player\/([a-z0-9-]+-\d+)\/?/i;

export function slugFrom(href) {
  const match = PLAYER_HREF.exec(String(href || ""));
  return match ? match[1].toLowerCase() : null;
}

// Resolves null on every failure path. The caller's contract is "null means
// leave the existing onebox alone", so a network error, a 404 and a malformed
// payload are all the same outcome: the reader keeps what Discourse rendered.
export async function fetchRecruit(slug) {
  try {
    const response = await fetch(`${ENDPOINT}?slug=${encodeURIComponent(slug)}`, {
      headers: { Accept: "application/json" },
    });
    if (!response.ok) {
      return null;
    }
    const payload = await response.json();
    if (!payload || typeof payload.recruit !== "object" || payload.recruit === null) {
      return null;
    }
    return { ...payload.recruit, fetched_at: payload.fetched_at };
  } catch {
    return null;
  }
}

export function relativeAge(iso) {
  const then = Date.parse(iso);
  if (isNaN(then)) {
    return null;
  }
  const minutes = Math.floor((Date.now() - then) / 60000);
  if (minutes < 1) {
    return "just now";
  }
  if (minutes < 60) {
    return `${minutes}m`;
  }
  const hours = Math.floor(minutes / 60);
  return hours < 24 ? `${hours}h` : `${Math.floor(hours / 24)}d`;
}

// Miami first, then the rest in the order 247 lists them. The full list is
// preserved — this only moves the row readers came for off the bottom.
export function sortOffers(offers, pinMiami = true) {
  if (!Array.isArray(offers)) {
    return [];
  }
  if (!pinMiami) {
    return offers.slice();
  }
  const isMiami = (o) => /^miami \(oh\)/i.test(String(o?.team || ""));
  return [...offers.filter(isMiami), ...offers.filter((o) => !isMiami(o))];
}

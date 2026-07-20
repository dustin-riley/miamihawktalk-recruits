const ENDPOINT = "/redhawks-recruit.json";

// Matches the plugin's RecruitSource::SLUG. Trailing slash optional because
// people paste both forms.
const PLAYER_PATH = /^\/player\/([a-z0-9-]+-\d+)\/?/i;

// A regex can't safely express "this is really 247sports.com" — something
// like `evil-247sports.com` or `247sports.com.attacker.net` satisfies almost
// any string match you'd write, and `?u=247sports.com/player/...` on a
// stranger's host satisfies it too. The URL parser gives us the actual host,
// which is the one thing a crafted string can't spoof.
const ALLOWED_HOSTS = new Set(["247sports.com", "www.247sports.com"]);

export function slugFrom(href) {
  let url;
  try {
    // Cooked posts always hand us an absolute href, but this also runs
    // against hand-typed/pasted strings, so a bad parse must fall through to
    // null rather than throw and take the caller down with it.
    url = new URL(String(href || ""));
  } catch {
    return null;
  }
  if (!ALLOWED_HOSTS.has(url.hostname.toLowerCase())) {
    return null;
  }
  const match = PLAYER_PATH.exec(url.pathname);
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
    // typeof null === "object" and typeof [] === "object", so both need an
    // explicit check — an array would otherwise spread into {"0":.., "1":..}
    // instead of resolving null, same discipline as the sibling module.
    if (
      !payload ||
      typeof payload.recruit !== "object" ||
      payload.recruit === null ||
      Array.isArray(payload.recruit)
    ) {
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
  // Duration tokens only — "<1m", "5m", "3h", "2d" — never prose. The i18n
  // string "updated %{age} ago" owns the tense, so returning "just now" here
  // rendered "updated just now ago". Keeping the grammar in the string means
  // it lives in one place instead of being special-cased in the template too.
  if (minutes < 1) {
    return "<1m";
  }
  if (minutes < 60) {
    return `${minutes}m`;
  }
  const hours = Math.floor(minutes / 60);
  return hours < 24 ? `${hours}h` : `${Math.floor(hours / 24)}d`;
}

// Single source of truth for "is this offer Miami (OH)?" — used by sortOffers
// below and by the component's highlight logic, so sort order and highlight
// marking can never drift apart.
export function isMiamiTeam(team) {
  return /^miami \(oh\)/i.test(String(team || ""));
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
  const isMiami = (o) => isMiamiTeam(o?.team);
  return [...offers.filter(isMiami), ...offers.filter((o) => !isMiami(o))];
}

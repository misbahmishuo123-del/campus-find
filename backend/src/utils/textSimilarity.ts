// Simple, dependency-free text similarity helpers.

function tokenize(text: string): string[] {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .filter((t) => t.length > 1);
}

// Jaccard similarity over word tokens: 0..1
export function tokenSimilarity(a: string, b: string): number {
  const setA = new Set(tokenize(a));
  const setB = new Set(tokenize(b));
  if (setA.size === 0 || setB.size === 0) return 0;
  let intersection = 0;
  setA.forEach((t) => {
    if (setB.has(t)) intersection++;
  });
  const union = setA.size + setB.size - intersection;
  return union === 0 ? 0 : intersection / union;
}

function bigrams(s: string): Set<string> {
  const clean = s.toLowerCase().replace(/\s+/g, "").trim();
  const out = new Set<string>();
  for (let i = 0; i < clean.length - 1; i++) {
    out.add(clean.slice(i, i + 2));
  }
  return out;
}

// Sorensen-Dice coefficient over character bigrams: 0..1
export function diceSimilarity(a: string, b: string): number {
  const bgA = bigrams(a);
  const bgB = bigrams(b);
  if (bgA.size === 0 || bgB.size === 0) return 0;
  let intersection = 0;
  bgA.forEach((g) => {
    if (bgB.has(g)) intersection++;
  });
  return (2 * intersection) / (bgA.size + bgB.size);
}

// Combine token overlap and character similarity for robustness.
export function textSimilarity(a: string, b: string): number {
  if (!a || !b) return 0;
  const token = tokenSimilarity(a, b);
  const dice = diceSimilarity(a, b);
  return Math.max(token, dice * 0.9);
}

// Normalized similarity for short strings like locations.
export function locationSimilarity(a: string, b: string): number {
  if (!a || !b) return 0;
  const x = a.toLowerCase().trim();
  const y = b.toLowerCase().trim();
  if (x === y) return 1;
  if (x.includes(y) || y.includes(x)) return 0.85;
  return diceSimilarity(x, y);
}

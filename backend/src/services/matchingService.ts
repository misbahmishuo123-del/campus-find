import { IItem } from "../models/Item";
import {
  textSimilarity,
  locationSimilarity,
} from "../utils/textSimilarity";

export interface MatchBreakdown {
  category: number; // 25
  location: number; // 25
  dateTime: number; // 20
  description: number; // 20
  colorBrand: number; // 10
  total: number; // 100
  label: string;
}

export interface ScoredMatch {
  item: IItem;
  score: MatchBreakdown;
}

export function matchLabel(total: number): string {
  if (total >= 80) return "Strong possible match";
  if (total >= 60) return "Possible match";
  if (total >= 40) return "Weak match";
  return "No meaningful match";
}

function daysBetween(a: Date, b: Date): number {
  const ms = Math.abs(a.getTime() - b.getTime());
  return ms / (1000 * 60 * 60 * 24);
}

// Score how similar two items are on the 100-point scale.
// IMPORTANT: this is only a *possible* match signal — never proof of ownership.
export function scoreMatch(a: IItem, b: IItem): MatchBreakdown {
  // Category: exact match = 25, otherwise similarity fallback.
  const catA = (a.category || "").toLowerCase().trim();
  const catB = (b.category || "").toLowerCase().trim();
  const category =
    catA && catA === catB ? 25 : Math.round(textSimilarity(catA, catB) * 15);

  // Location: up to 25.
  const location = Math.round(
    locationSimilarity(a.location || "", b.location || "") * 25
  );

  // Date/time: up to 20, decaying with day difference.
  let dateTime = 0;
  if (a.date && b.date) {
    const diff = daysBetween(new Date(a.date), new Date(b.date));
    dateTime = Math.max(0, Math.round(20 - diff * 4));
  }

  // Description similarity: up to 20.
  const description = Math.round(
    textSimilarity(a.description || "", b.description || "") * 20
  );

  // Color / brand: 5 + 5.
  const color =
    a.color && b.color
      ? Math.round(textSimilarity(a.color, b.color) * 5)
      : 0;
  const brand =
    a.brand && b.brand
      ? Math.round(textSimilarity(a.brand, b.brand) * 5)
      : 0;
  const colorBrand = color + brand;

  const total = category + location + dateTime + description + colorBrand;

  return {
    category,
    location,
    dateTime,
    description,
    colorBrand,
    total,
    label: matchLabel(total),
  };
}

// Rank a list of candidate items against a target item.
export function rankMatches(target: IItem, candidates: IItem[]): ScoredMatch[] {
  return candidates
    .map((item) => ({ item, score: scoreMatch(target, item) }))
    .filter((m) => m.score.total >= 40) // only surface weak-and-better
    .sort((x, y) => y.score.total - x.score.total);
}

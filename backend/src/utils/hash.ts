import bcrypt from "bcryptjs";

// Normalize a verification answer so that comparison is forgiving of
// case / spacing differences but still secret.
export function normalizeAnswer(answer: string): string {
  return answer.trim().toLowerCase().replace(/\s+/g, " ");
}

export async function hashAnswer(answer: string): Promise<string> {
  return bcrypt.hash(normalizeAnswer(answer), 10);
}

export async function compareAnswer(
  answer: string,
  hash: string
): Promise<boolean> {
  return bcrypt.compare(normalizeAnswer(answer), hash);
}

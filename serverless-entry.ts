import { createApp } from "./backend/src/app";
import { connectDB } from "./backend/src/config/db";

const app = createApp();
let dbPromise: Promise<void> | null = null;

function ensureDb(): Promise<void> {
  if (!dbPromise) {
    dbPromise = (async () => {
      for (let attempt = 1; attempt <= 3; attempt++) {
        try {
          await connectDB();
          return;
        } catch (err) {
          console.error(
            "[vercel] MongoDB connect attempt " + attempt + " failed:",
            err && (err as Error).message ? (err as Error).message : err
          );
          if (attempt < 3) await new Promise((r) => setTimeout(r, 1000));
        }
      }
    })().catch((err) => {
      dbPromise = null;
      throw err;
    });
  }
  return dbPromise;
}

export default async function handler(req: any, res: any): Promise<void> {
  try {
    await ensureDb();
  } catch (err) {
    console.error("[vercel] db connect error:", err && (err as Error).message ? (err as Error).message : err);
  }
  app(req, res);
}

// Vercel serverless entry point (repo root = project root).
// Loads the Express app lazily on first request so any startup failure is
// returned as a readable JSON error instead of an opaque 500 crash.
let appPromise: Promise<unknown> | null = null;

function loadApp(): Promise<unknown> {
  if (!appPromise) {
    appPromise = (async () => {
      const { connectDB } = await import("../backend/src/config/db");
      const { createApp } = await import("../backend/src/app");
      connectDB().catch((err) => {
        console.error("[vercel] MongoDB connect failed:", err.message);
      });
      return createApp();
    })();
  }
  return appPromise;
}

export default async function handler(req: unknown, res: any): Promise<void> {
  try {
    const app = (await loadApp()) as (r: unknown, s: unknown) => void;
    app(req, res);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: "startup_failed",
      detail: err instanceof Error ? err.message : String(err),
    });
  }
}

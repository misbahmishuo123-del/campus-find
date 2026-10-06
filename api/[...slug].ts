// Vercel serverless entry point (repo root = project root).
// Loads the Express app lazily on first request so any startup failure is
// returned as a readable JSON error instead of an opaque 500 crash.

// Keep the function process alive: on Node 16+ an unhandled rejection or
// uncaught exception would otherwise terminate the invocation and surface as
// FUNCTION_INVOCATION_FAILED with no useful message.
process.on("unhandledRejection", (reason) => {
  console.error("[vercel] unhandledRejection:", reason);
});
process.on("uncaughtException", (err) => {
  console.error("[vercel] uncaughtException:", err.message);
});

let appPromise: Promise<unknown> | null = null;

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function connectWithRetries(): Promise<void> {
  const { connectDB } = await import("../backend/src/config/db");
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      await connectDB();
      return;
    } catch (err) {
      console.error(
        `[vercel] MongoDB connect attempt ${attempt} failed:`,
        err instanceof Error ? err.message : err
      );
      if (attempt < 3) await sleep(1000);
    }
  }
}

function loadApp(): Promise<unknown> {
  if (!appPromise) {
    appPromise = (async () => {
      const { createApp } = await import("../backend/src/app");
      // Fire-and-forget with retries; Mongoose buffers commands until ready.
      void connectWithRetries();
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

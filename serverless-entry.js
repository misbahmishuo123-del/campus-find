// Vercel serverless entry for CampusFind.
// Nothing runs at module load that can throw: the backend is required lazily
// inside the handler, and any init/db error is returned as readable JSON
// instead of crashing the function (which surfaces as FUNCTION_INVOCATION_FAILED).

let app = null;
let initError = null;

function safeInit() {
  if (app || initError) return;
  try {
    const { createApp } = require("./backend/src/app");
    app = createApp();
  } catch (e) {
    initError = e;
  }
}

let dbPromise = null;
function ensureDb() {
  if (!dbPromise) {
    dbPromise = (async () => {
      const { connectDB } = require("./backend/src/config/db");
      for (let attempt = 1; attempt <= 3; attempt++) {
        try {
          await connectDB();
          return { ok: true };
        } catch (err) {
          const msg = err && err.message ? err.message : String(err);
          console.error("[vercel] MongoDB connect attempt " + attempt + " failed:", msg);
          if (attempt === 3) return { ok: false, error: msg };
          await new Promise((r) => setTimeout(r, 800));
        }
      }
    })();
  }
  return dbPromise;
}

function describe(e) {
  return {
    message: e && e.message ? e.message : String(e),
    stack: e && e.stack ? String(e.stack).split("\n").slice(0, 8) : null,
  };
}

module.exports = async function handler(req, res) {
  safeInit();

  if (initError) {
    res.status(200).json({
      success: false,
      stage: "init",
      error: describe(initError),
      env: {
        hasMongoUri: !!process.env.MONGODB_URI,
        mongoUriShape: process.env.MONGODB_URI ? String(process.env.MONGODB_URI).slice(0, 14) + "..." : null,
        hasJwtSecret: !!process.env.JWT_SECRET,
        node: process.version,
      },
    });
    return;
  }

  const db = await ensureDb();
  if (!db.ok) {
    res.status(200).json({ success: false, stage: "db", error: db.error });
    return;
  }

  app(req, res);
};

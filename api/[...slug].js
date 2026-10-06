module.exports = async function handler(req, res) {
  const diag = { stage: "start" };
  try {
    diag.stage = "require-app";
    const { createApp } = require("../backend/src/app");
    diag.stage = "require-db";
    const { connectDB } = require("../backend/src/config/db");
    diag.stage = "connect-db";
    try {
      await connectDB();
      diag.db = "connected";
    } catch (e) {
      diag.db = "failed: " + (e && e.message ? e.message : String(e));
    }
    diag.stage = "serve";
    const app = createApp();
    return app(req, res);
  } catch (err) {
    res.status(200).json({
      success: false,
      diag,
      error: err && err.message ? err.message : String(err),
      stack: err && err.stack ? String(err.stack).split("\n").slice(0, 6) : null,
      env: {
        hasMongoUri: !!process.env.MONGODB_URI,
        hasJwtSecret: !!process.env.JWT_SECRET,
        node: process.version,
      },
    });
  }
};

const { createApp } = require("../backend/src/app");
const { connectDB } = require("../backend/src/config/db");

const app = createApp();
let dbPromise = null;

function ensureDb() {
  if (!dbPromise) {
    dbPromise = (async () => {
      for (let attempt = 1; attempt <= 3; attempt++) {
        try {
          await connectDB();
          return;
        } catch (err) {
          console.error(
            "[vercel] MongoDB connect attempt " + attempt + " failed:",
            err && err.message ? err.message : err
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

module.exports = async function handler(req, res) {
  try {
    await ensureDb();
  } catch (err) {
    console.error("[vercel] db connect error:", err && err.message ? err.message : err);
  }
  app(req, res);
};

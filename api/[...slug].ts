import { createApp } from "../backend/src/app";
import { connectDB } from "../backend/src/config/db";

// Vercel serverless entry point (repo root = project root, so no Root
// Directory setting is needed). Runs the same Express app as
// backend/src/server.ts but without .listen(); Vercel invokes this handler
// per request. Kick off the DB connection once per cold start; Mongoose
// buffers commands until the connection is ready.
connectDB().catch((err) => {
  console.error("[vercel] MongoDB connect failed:", err.message);
});

const app = createApp();

export default app;

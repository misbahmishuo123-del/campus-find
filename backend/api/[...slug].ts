import { createApp } from "../src/app";
import { connectDB } from "../src/config/db";

// Vercel serverless entry point. Runs the same Express app as src/server.ts
// but without .listen() (Vercel invokes the exported handler per request).
// Kick off the DB connection once per cold start; Mongoose buffers commands
// until the connection is ready.
connectDB().catch((err) => {
  console.error("[vercel] MongoDB connect failed:", err.message);
});

const app = createApp();

export default app;

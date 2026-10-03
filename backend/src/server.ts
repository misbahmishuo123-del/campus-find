import { createApp } from "./app";
import { connectDB } from "./config/db";
import { env } from "./config/env";

async function bootstrap() {
  try {
    await connectDB();
  } catch (err: any) {
    console.error("[server] Failed to connect to MongoDB:", err.message);
    console.error(
      "[server] Check your MONGODB_URI and make sure this machine's IP is allowed in MongoDB Atlas Network Access."
    );
    process.exit(1);
  }

  const app = createApp();
  const server = app.listen(env.port, () => {
    console.log(`[server] CampusFind API listening on http://localhost:${env.port}`);
    console.log(`[server] Health check: http://localhost:${env.port}/api/health`);
  });

  const shutdown = () => {
    console.log("[server] Shutting down...");
    server.close(() => process.exit(0));
  };
  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

bootstrap();

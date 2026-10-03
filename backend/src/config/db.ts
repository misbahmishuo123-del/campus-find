import mongoose from "mongoose";
import { env } from "./env";

let connected = false;

export async function connectDB(): Promise<void> {
  mongoose.connection.on("connected", () => {
    connected = true;
    console.log("[db] MongoDB connected");
  });
  mongoose.connection.on("error", (err) => {
    console.error("[db] MongoDB connection error:", err.message);
  });
  mongoose.connection.on("disconnected", () => {
    connected = false;
    console.warn("[db] MongoDB disconnected");
  });

  await mongoose.connect(env.mongoUri, {
    serverSelectionTimeoutMS: 15000,
  });
}

export function isDBConnected(): boolean {
  return connected && mongoose.connection.readyState === 1;
}

export async function disconnectDB(): Promise<void> {
  await mongoose.disconnect();
}

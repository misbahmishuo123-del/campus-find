import dotenv from "dotenv";

dotenv.config();

function required(name: string, fallback?: string): string {
  const value = process.env[name] ?? fallback;
  if (value === undefined) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export const env = {
  port: parseInt(process.env.PORT || "5000", 10),
  mongoUri: required("MONGODB_URI"),
  jwtSecret: required("JWT_SECRET", "dev_only_insecure_secret_change_me"),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || "7d",
  geminiApiKey: process.env.GEMINI_API_KEY || "",
  universityEmailDomain: (process.env.UNIVERSITY_EMAIL_DOMAIN || "").trim(),
};

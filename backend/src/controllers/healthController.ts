import { Request, Response } from "express";
import { isDBConnected } from "../config/db";

// GET /api/health
export function health(_req: Request, res: Response) {
  const dbUp = isDBConnected();
  res.status(dbUp ? 200 : 503).json({
    success: true,
    message: "CampusFind API is running",
    database: dbUp ? "connected" : "disconnected",
    timestamp: new Date().toISOString(),
  });
}

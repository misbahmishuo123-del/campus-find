import { Request, Response, NextFunction } from "express";
import { ApiError } from "../utils/asyncHandler";

export function notFoundHandler(
  req: Request,
  _res: Response,
  next: NextFunction
) {
  next(new ApiError(404, `Route not found: ${req.method} ${req.originalUrl}`));
}

export function errorHandler(
  err: any,
  _req: Request,
  res: Response,
  _next: NextFunction
) {
  // Mongoose duplicate key -> 409
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue || {})[0] || "field";
    return res
      .status(409)
      .json({ success: false, message: `Duplicate value for ${field}` });
  }

  // Mongoose validation -> 400
  if (err.name === "ValidationError") {
    const messages = Object.values(err.errors || {}).map(
      (e: any) => e.message
    );
    return res
      .status(400)
      .json({ success: false, message: messages.join(", ") });
  }

  // Mongoose bad ObjectId -> 400
  if (err.name === "CastError") {
    return res
      .status(400)
      .json({ success: false, message: `Invalid ${err.path}: ${err.value}` });
  }

  const statusCode = err.statusCode || 500;
  const message = err.message || "Internal server error";

  if (statusCode >= 500) {
    console.error("[error]", err);
  }

  res.status(statusCode).json({ success: false, message });
}

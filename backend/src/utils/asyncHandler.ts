import { Request, Response, NextFunction, RequestHandler } from "express";

type AsyncFn = (
  req: Request,
  res: Response,
  next: NextFunction
) => Promise<any>;

export const asyncHandler =
  (fn: AsyncFn): RequestHandler =>
  (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };

export class ApiError extends Error {
  statusCode: number;
  constructor(statusCode: number, message: string) {
    super(message);
    this.statusCode = statusCode;
  }
}

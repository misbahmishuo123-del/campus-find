import { Request, Response, NextFunction } from "express";
import { verifyToken, JwtPayload } from "../utils/jwt";
import { User, IUser } from "../models/User";
import { ApiError, asyncHandler } from "../utils/asyncHandler";

// Attach the authenticated user to the request.
declare global {
  namespace Express {
    interface Request {
      user?: IUser;
    }
  }
}

function extractToken(req: Request): string | null {
  const header = req.headers.authorization || "";
  if (header.startsWith("Bearer ")) {
    return header.slice(7).trim();
  }
  return null;
}

export const authenticate = asyncHandler(
  async (req: Request, _res: Response, next: NextFunction) => {
    const token = extractToken(req);
    if (!token) {
      throw new ApiError(401, "Not authenticated: missing token");
    }

    let payload: JwtPayload;
    try {
      payload = verifyToken(token);
    } catch {
      throw new ApiError(401, "Not authenticated: invalid or expired token");
    }

    const user = await User.findById(payload.sub);
    if (!user) {
      throw new ApiError(401, "Not authenticated: user no longer exists");
    }

    req.user = user;
    next();
  }
);

export function authorize(...roles: string[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(new ApiError(401, "Not authenticated"));
    }
    if (roles.length && !roles.includes(req.user.role)) {
      return next(
        new ApiError(403, "Forbidden: insufficient permissions for this role")
      );
    }
    next();
  };
}

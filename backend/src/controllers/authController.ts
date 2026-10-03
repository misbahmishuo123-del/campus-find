import { Request, Response } from "express";
import { User } from "../models/User";
import { signToken } from "../utils/jwt";
import { asyncHandler, ApiError } from "../utils/asyncHandler";
import { env } from "../config/env";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function validateEmail(email: string): void {
  if (!EMAIL_REGEX.test(email)) {
    throw new ApiError(400, "Please provide a valid email address");
  }
  const domain = env.universityEmailDomain;
  if (domain) {
    const parts = email.toLowerCase().split("@");
    if (parts[1] !== domain.toLowerCase()) {
      throw new ApiError(
        400,
        `Registration email must belong to the university domain (@${domain})`
      );
    }
  }
}

export const register = asyncHandler(async (req: Request, res: Response) => {
  const { name, email, password, role, phone, department, campusId } = req.body;

  if (!name || !email || !password) {
    throw new ApiError(400, "name, email and password are required");
  }
  if (String(password).length < 6) {
    throw new ApiError(400, "Password must be at least 6 characters");
  }
  validateEmail(String(email));

  // Clients may only self-register as student or staff.
  // Admin accounts are created out-of-band (seed / by another admin).
  const requestedRole = ["student", "staff"].includes(role) ? role : "student";

  const existing = await User.findOne({ email: email.toLowerCase() });
  if (existing) {
    throw new ApiError(409, "An account with this email already exists");
  }

  const user = await User.create({
    name,
    email: email.toLowerCase(),
    password,
    role: requestedRole,
    phone,
    department,
    campusId,
  });

  const token = signToken({
    sub: user._id.toString(),
    role: user.role,
    name: user.name,
  });

  res.status(201).json({
    success: true,
    message: "Registration successful",
    data: { token, user },
  });
});

export const login = asyncHandler(async (req: Request, res: Response) => {
  const { email, password } = req.body;
  if (!email || !password) {
    throw new ApiError(400, "email and password are required");
  }

  const user = await User.findOne({ email: email.toLowerCase() }).select(
    "+password"
  );
  if (!user) {
    throw new ApiError(401, "Invalid email or password");
  }

  const ok = await user.comparePassword(password);
  if (!ok) {
    throw new ApiError(401, "Invalid email or password");
  }

  const token = signToken({
    sub: user._id.toString(),
    role: user.role,
    name: user.name,
  });

  res.json({
    success: true,
    message: "Login successful",
    data: { token, user },
  });
});

export const me = asyncHandler(async (req: Request, res: Response) => {
  // req.user is populated by the authenticate middleware.
  res.json({ success: true, data: { user: req.user } });
});

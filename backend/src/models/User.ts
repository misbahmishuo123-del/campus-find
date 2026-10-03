import mongoose, { Document, Schema, Model } from "mongoose";
import bcrypt from "bcryptjs";

export type UserRole = "student" | "staff" | "admin";

export interface IUser extends Document {
  name: string;
  email: string;
  password: string;
  role: UserRole;
  phone?: string;
  department?: string;
  campusId?: string;
  createdAt: Date;
  updatedAt: Date;
  comparePassword(candidate: string): Promise<boolean>;
}

const UserSchema = new Schema<IUser>(
  {
    name: { type: String, required: true, trim: true },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: { type: String, required: true, select: false },
    role: {
      type: String,
      enum: ["student", "staff", "admin"],
      default: "student",
      required: true,
    },
    phone: { type: String, trim: true },
    department: { type: String, trim: true },
    campusId: { type: String, trim: true },
  },
  { timestamps: true }
);

// Hash password before save (only when it was modified).
UserSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

UserSchema.methods.comparePassword = function (
  candidate: string
): Promise<boolean> {
  return bcrypt.compare(candidate, this.password);
};

// Never leak the password hash in JSON responses.
UserSchema.set("toJSON", {
  transform: (_doc, ret: any) => {
    delete ret.password;
    delete ret.__v;
    return ret;
  },
});

export const User: Model<IUser> = mongoose.model<IUser>("User", UserSchema);

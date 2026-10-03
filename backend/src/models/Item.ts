import mongoose, { Document, Schema, Model } from "mongoose";

export type ItemType = "lost" | "found";
export type ItemStatus =
  | "active"
  | "matched"
  | "claimed"
  | "verified"
  | "returned"
  | "closed";
export type ClaimStatus = "none" | "pending" | "approved" | "rejected";

export interface IItem extends Document {
  type: ItemType;
  title: string;
  category: string;
  description: string;
  color?: string;
  brand?: string;
  location: string;
  date: Date;
  time?: string;
  imageUrl?: string;
  createdBy: mongoose.Types.ObjectId;
  campusId?: string;
  buildingId?: string;
  status: ItemStatus;
  claimStatus: ClaimStatus;
  verification?: {
    question: string;
    // Hashed answer. Never returned by public APIs.
    answerHash?: string;
  };
  returnedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const ItemSchema = new Schema<IItem>(
  {
    type: { type: String, enum: ["lost", "found"], required: true },
    title: { type: String, required: true, trim: true },
    category: { type: String, required: true, trim: true, lowercase: true },
    description: { type: String, required: true, trim: true },
    color: { type: String, trim: true, lowercase: true },
    brand: { type: String, trim: true },
    location: { type: String, required: true, trim: true },
    date: { type: Date, required: true },
    time: { type: String, trim: true },
    imageUrl: { type: String, trim: true },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    campusId: { type: String, trim: true },
    buildingId: { type: String, trim: true },
    status: {
      type: String,
      enum: ["active", "matched", "claimed", "verified", "returned", "closed"],
      default: "active",
    },
    claimStatus: {
      type: String,
      enum: ["none", "pending", "approved", "rejected"],
      default: "none",
    },
    verification: {
      question: { type: String, trim: true, default: "" },
      answerHash: { type: String, select: false },
    },
    returnedAt: { type: Date },
  },
  { timestamps: true }
);

// Text index for simple, reliable search.
ItemSchema.index({ title: "text", description: "text", category: "text" });
ItemSchema.index({ type: 1, status: 1, createdAt: -1 });

ItemSchema.set("toJSON", {
  transform: (_doc, ret: any) => {
    delete ret.__v;
    // Defense-in-depth: never expose the hashed verification answer.
    if (ret.verification) {
      delete ret.verification.answerHash;
    }
    return ret;
  },
});

export const Item: Model<IItem> = mongoose.model<IItem>("Item", ItemSchema);

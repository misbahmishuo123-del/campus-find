import mongoose, { Document, Schema, Model } from "mongoose";

export type ClaimStatus = "pending" | "approved" | "rejected";

export interface IClaim extends Document {
  itemId: mongoose.Types.ObjectId;
  claimantId: mongoose.Types.ObjectId;
  reason: string;
  // Hashed verification answer provided by the claimant.
  verificationAnswerHash?: string;
  // Whether the claimant's answer matched the item's secret answer.
  verificationMatched?: boolean;
  status: ClaimStatus;
  adminNotes?: string;
  reviewedBy?: mongoose.Types.ObjectId;
  reviewedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const ClaimSchema = new Schema<IClaim>(
  {
    itemId: { type: Schema.Types.ObjectId, ref: "Item", required: true },
    claimantId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    reason: { type: String, required: true, trim: true },
    verificationAnswerHash: { type: String, select: false },
    verificationMatched: { type: Boolean },
    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
    },
    adminNotes: { type: String, trim: true },
    reviewedBy: { type: Schema.Types.ObjectId, ref: "User" },
    reviewedAt: { type: Date },
  },
  { timestamps: true }
);

ClaimSchema.index({ itemId: 1, claimantId: 1 }, { unique: true });

ClaimSchema.set("toJSON", {
  transform: (_doc, ret: any) => {
    delete ret.__v;
    delete ret.verificationAnswerHash;
    return ret;
  },
});

export const Claim: Model<IClaim> = mongoose.model<IClaim>(
  "Claim",
  ClaimSchema
);

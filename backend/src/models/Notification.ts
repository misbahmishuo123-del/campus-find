import mongoose, { Document, Schema, Model } from "mongoose";

export interface INotification extends Document {
  userId: mongoose.Types.ObjectId;
  title: string;
  message: string;
  type: string;
  itemId?: mongoose.Types.ObjectId;
  claimId?: mongoose.Types.ObjectId;
  read: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const NotificationSchema = new Schema<INotification>(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    title: { type: String, required: true, trim: true },
    message: { type: String, required: true, trim: true },
    type: { type: String, default: "info", trim: true },
    itemId: { type: Schema.Types.ObjectId, ref: "Item" },
    claimId: { type: Schema.Types.ObjectId, ref: "Claim" },
    read: { type: Boolean, default: false },
  },
  { timestamps: true }
);

NotificationSchema.index({ userId: 1, createdAt: -1 });

NotificationSchema.set("toJSON", {
  transform: (_doc, ret: any) => {
    delete ret.__v;
    return ret;
  },
});

export const Notification: Model<INotification> = mongoose.model<INotification>(
  "Notification",
  NotificationSchema
);

import mongoose, { Document, Schema, Model } from "mongoose";

export interface IAuditLog extends Document {
  actorId?: mongoose.Types.ObjectId;
  action: string;
  entityType: string;
  entityId?: mongoose.Types.ObjectId;
  meta?: Record<string, any>;
  createdAt: Date;
}

const AuditLogSchema = new Schema<IAuditLog>(
  {
    actorId: { type: Schema.Types.ObjectId, ref: "User" },
    action: { type: String, required: true, trim: true },
    entityType: { type: String, required: true, trim: true },
    entityId: { type: Schema.Types.ObjectId },
    meta: { type: Schema.Types.Mixed },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

AuditLogSchema.index({ entityType: 1, entityId: 1, createdAt: -1 });

AuditLogSchema.set("toJSON", {
  transform: (_doc, ret: any) => {
    delete ret.__v;
    return ret;
  },
});

export const AuditLog: Model<IAuditLog> = mongoose.model<IAuditLog>(
  "AuditLog",
  AuditLogSchema
);

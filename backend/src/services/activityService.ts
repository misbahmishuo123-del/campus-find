import { Notification } from "../models/Notification";
import { AuditLog } from "../models/AuditLog";

export async function createNotification(params: {
  userId: any;
  title: string;
  message: string;
  type?: string;
  itemId?: any;
  claimId?: any;
}) {
  return Notification.create({
    userId: params.userId,
    title: params.title,
    message: params.message,
    type: params.type || "info",
    itemId: params.itemId,
    claimId: params.claimId,
  });
}

export async function createAuditLog(params: {
  actorId?: any;
  action: string;
  entityType: string;
  entityId?: any;
  meta?: Record<string, any>;
}) {
  return AuditLog.create({
    actorId: params.actorId,
    action: params.action,
    entityType: params.entityType,
    entityId: params.entityId,
    meta: params.meta,
  });
}

import { Request, Response } from "express";
import { Notification } from "../models/Notification";
import { asyncHandler, ApiError } from "../utils/asyncHandler";

// GET /api/notifications
export const myNotifications = asyncHandler(
  async (req: Request, res: Response) => {
    const notifications = await Notification.find({ userId: req.user!._id })
      .sort({ createdAt: -1 })
      .limit(100);
    const unread = await Notification.countDocuments({
      userId: req.user!._id,
      read: false,
    });
    res.json({ success: true, data: { notifications, unread } });
  }
);

// PATCH /api/notifications/:id/read
export const markRead = asyncHandler(async (req: Request, res: Response) => {
  const note = await Notification.findOne({
    _id: req.params.id,
    userId: req.user!._id,
  });
  if (!note) throw new ApiError(404, "Notification not found");
  note.read = true;
  await note.save();
  res.json({ success: true, data: { notification: note } });
});

// PATCH /api/notifications/read-all
export const markAllRead = asyncHandler(async (req: Request, res: Response) => {
  await Notification.updateMany(
    { userId: req.user!._id, read: false },
    { read: true }
  );
  res.json({ success: true, message: "All notifications marked as read" });
});

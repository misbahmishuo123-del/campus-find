import { Router } from "express";
import {
  myNotifications,
  markRead,
  markAllRead,
} from "../controllers/notificationController";
import { authenticate } from "../middleware/auth";

const router = Router();
router.use(authenticate);

router.get("/", myNotifications);
router.patch("/read-all", markAllRead);
router.patch("/:id/read", markRead);

export default router;

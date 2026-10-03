import { Router } from "express";
import { health } from "../controllers/healthController";
import authRoutes from "./authRoutes";
import itemRoutes from "./itemRoutes";
import userRoutes from "./userRoutes";
import adminRoutes from "./adminRoutes";
import notificationRoutes from "./notificationRoutes";

const router = Router();

router.get("/health", health);
router.use("/auth", authRoutes);
router.use("/items", itemRoutes);
router.use("/notifications", notificationRoutes);
router.use("/admin", adminRoutes);

// /api/my-reports and /api/my-claims live at the API root.
router.use("/", userRoutes);

export default router;

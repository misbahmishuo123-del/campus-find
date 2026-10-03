import { Router } from "express";
import {
  listClaims,
  getClaim,
  reviewClaim,
  markReturned,
  getStats,
} from "../controllers/adminController";
import { authenticate, authorize } from "../middleware/auth";

const router = Router();

router.use(authenticate, authorize("admin"));

router.get("/stats", getStats);
router.get("/claims", listClaims);
router.get("/claims/:claimId", getClaim);
router.patch("/claims/:claimId", reviewClaim);
router.patch("/items/:id/return", markReturned);

export default router;

import { Router } from "express";
import { myReports } from "../controllers/itemController";
import { myClaims } from "../controllers/claimController";
import { authenticate } from "../middleware/auth";

const router = Router();
router.use(authenticate);

router.get("/my-reports", myReports);
router.get("/my-claims", myClaims);

export default router;

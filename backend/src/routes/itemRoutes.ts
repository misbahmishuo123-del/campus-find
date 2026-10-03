import { Router } from "express";
import {
  createItem,
  listItems,
  getItem,
  getItemMatches,
  updateItem,
  deleteItem,
} from "../controllers/itemController";
import { createClaim } from "../controllers/claimController";
import { authenticate } from "../middleware/auth";

const router = Router();

router.use(authenticate);

router.post("/", createItem);
router.get("/", listItems);
router.get("/:id", getItem);
router.get("/:id/matches", getItemMatches);
router.patch("/:id", updateItem);
router.delete("/:id", deleteItem);

// Submit a claim on an item.
router.post("/:id/claim", createClaim);

export default router;

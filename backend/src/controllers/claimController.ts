import { Request, Response } from "express";
import { Item } from "../models/Item";
import { Claim } from "../models/Claim";
import { asyncHandler, ApiError } from "../utils/asyncHandler";
import { hashAnswer, compareAnswer } from "../utils/hash";
import {
  createNotification,
  createAuditLog,
} from "../services/activityService";

// POST /api/items/:id/claim
export const createClaim = asyncHandler(async (req: Request, res: Response) => {
  const { reason, verificationAnswer } = req.body;

  const item = await Item.findById(req.params.id).select(
    "+verification.answerHash"
  );
  if (!item) throw new ApiError(404, "Item not found");

  if (item.createdBy.toString() === req.user!._id.toString()) {
    throw new ApiError(400, "You cannot claim your own item");
  }
  if (item.status === "returned" || item.status === "closed") {
    throw new ApiError(400, `This item is already ${item.status}`);
  }
  if (!reason || String(reason).trim().length < 5) {
    throw new ApiError(400, "Please provide a reason for your claim");
  }

  const existing = await Claim.findOne({
    itemId: item._id,
    claimantId: req.user!._id,
  });
  if (existing) {
    throw new ApiError(409, "You have already submitted a claim for this item");
  }

  // Securely compare the hidden verification answer if one was set.
  let verificationMatched: boolean | undefined;
  let answerHash: string | undefined;
  if (verificationAnswer) {
    answerHash = await hashAnswer(String(verificationAnswer));
    if (item.verification?.answerHash) {
      verificationMatched = await compareAnswer(
        String(verificationAnswer),
        item.verification.answerHash
      );
    }
  }

  const claim = await Claim.create({
    itemId: item._id,
    claimantId: req.user!._id,
    reason,
    verificationAnswerHash: answerHash,
    verificationMatched,
    status: "pending",
  });

  // Reflect the pending claim on the item (does NOT confirm ownership).
  item.claimStatus = "pending";
  if (item.status === "active" || item.status === "matched") {
    item.status = "claimed";
  }
  await item.save();

  await createNotification({
    userId: item.createdBy,
    title: "New claim on your item",
    message: `Someone submitted a claim for "${item.title}". Security will verify it.`,
    type: "claim",
    itemId: item._id,
    claimId: claim._id,
  });
  await createNotification({
    userId: req.user!._id,
    title: "Claim submitted",
    message: `Your claim for "${item.title}" has been submitted and is pending review.`,
    type: "claim",
    itemId: item._id,
    claimId: claim._id,
  });
  await createAuditLog({
    actorId: req.user!._id,
    action: "claim.create",
    entityType: "claim",
    entityId: claim._id,
    meta: { itemId: item._id },
  });

  res.status(201).json({
    success: true,
    message: "Claim submitted. Ownership must be verified by university staff.",
    data: { claim },
  });
});

// GET /api/my-claims
export const myClaims = asyncHandler(async (req: Request, res: Response) => {
  const claims = await Claim.find({ claimantId: req.user!._id })
    .populate("itemId")
    .sort({ createdAt: -1 });
  res.json({ success: true, data: { claims } });
});

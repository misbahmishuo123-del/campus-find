import { Request, Response } from "express";
import { Claim } from "../models/Claim";
import { Item } from "../models/Item";
import { User } from "../models/User";
import { asyncHandler, ApiError } from "../utils/asyncHandler";
import {
  createNotification,
  createAuditLog,
} from "../services/activityService";
import { rankMatches } from "../services/matchingService";

// GET /api/admin/claims
export const listClaims = asyncHandler(async (req: Request, res: Response) => {
  const { status } = req.query as Record<string, string>;
  const filter: any = {};
  if (status && ["pending", "approved", "rejected"].includes(status)) {
    filter.status = status;
  }
  const claims = await Claim.find(filter)
    .populate({ path: "itemId", populate: { path: "createdBy", select: "name email role" } })
    .populate("claimantId", "name email role department")
    .sort({ createdAt: -1 });
  res.json({ success: true, data: { claims } });
});

// GET /api/admin/claims/:claimId
export const getClaim = asyncHandler(async (req: Request, res: Response) => {
  const claim = await Claim.findById(req.params.claimId)
    .populate("claimantId", "name email role department phone")
    .populate({ path: "itemId", populate: { path: "createdBy", select: "name email role department" } });
  if (!claim) throw new ApiError(404, "Claim not found");

  const item = claim.itemId as any;
  let possibleMatches: any[] = [];
  if (item && item.type) {
    const oppositeType = item.type === "lost" ? "found" : "lost";
    const candidates = await Item.find({
      type: oppositeType,
      _id: { $ne: item._id },
    }).limit(100);
    possibleMatches = rankMatches(item as any, candidates)
      .slice(0, 5)
      .map((m) => ({ item: m.item, score: m.score }));
  }

  res.json({
    success: true,
    data: {
      claim,
      verificationQuestion: item?.verification?.question || null,
      verificationMatched: claim.verificationMatched ?? null,
      possibleMatches,
    },
  });
});

// PATCH /api/admin/claims/:claimId
export const reviewClaim = asyncHandler(async (req: Request, res: Response) => {
  const { status, adminNotes } = req.body;
  if (!["approved", "rejected"].includes(status)) {
    throw new ApiError(400, "status must be 'approved' or 'rejected'");
  }

  const claim = await Claim.findById(req.params.claimId);
  if (!claim) throw new ApiError(404, "Claim not found");

  // An admin must never approve their own claim.
  if (claim.claimantId.toString() === req.user!._id.toString()) {
    throw new ApiError(403, "You cannot review a claim you submitted");
  }
  if (claim.status !== "pending") {
    throw new ApiError(400, `This claim has already been ${claim.status}`);
  }

  const item = await Item.findById(claim.itemId);
  if (!item) throw new ApiError(404, "The claimed item no longer exists");

  claim.status = status;
  claim.adminNotes = adminNotes;
  claim.reviewedBy = req.user!._id;
  claim.reviewedAt = new Date();
  await claim.save();

  if (status === "approved") {
    item.claimStatus = "approved";
    item.status = "verified";
    await item.save();
    await createNotification({
      userId: claim.claimantId,
      title: "Claim approved",
      message: `Your claim for "${item.title}" was approved by security.`,
      type: "claim",
      itemId: item._id,
      claimId: claim._id,
    });
  } else {
    item.claimStatus = "rejected";
    // Return the item to an available state.
    item.status = "active";
    await item.save();
    await createNotification({
      userId: claim.claimantId,
      title: "Claim rejected",
      message: `Your claim for "${item.title}" was rejected after review.`,
      type: "claim",
      itemId: item._id,
      claimId: claim._id,
    });
  }

  await createNotification({
    userId: item.createdBy,
    title: status === "approved" ? "Claim approved on your item" : "Claim rejected",
    message: `The claim on "${item.title}" was ${status} by security.`,
    type: "claim",
    itemId: item._id,
    claimId: claim._id,
  });

  await createAuditLog({
    actorId: req.user!._id,
    action: `claim.${status}`,
    entityType: "claim",
    entityId: claim._id,
    meta: { itemId: item._id, adminNotes },
  });

  res.json({ success: true, message: `Claim ${status}`, data: { claim } });
});

// PATCH /api/admin/items/:id/return
export const markReturned = asyncHandler(async (req: Request, res: Response) => {
  const item = await Item.findById(req.params.id);
  if (!item) throw new ApiError(404, "Item not found");
  if (item.status === "returned") {
    throw new ApiError(400, "Item is already marked as returned");
  }

  item.status = "returned";
  item.returnedAt = new Date();
  await item.save();

  await createNotification({
    userId: item.createdBy,
    title: "Item returned",
    message: `Your item "${item.title}" has been marked as returned.`,
    type: "returned",
    itemId: item._id,
  });

  // Notify the approved claimant, if any.
  const approvedClaim = await Claim.findOne({
    itemId: item._id,
    status: "approved",
  });
  if (approvedClaim) {
    await createNotification({
      userId: approvedClaim.claimantId,
      title: "Item returned",
      message: `The item "${item.title}" you claimed has been marked as returned.`,
      type: "returned",
      itemId: item._id,
      claimId: approvedClaim._id,
    });
  }

  await createAuditLog({
    actorId: req.user!._id,
    action: "item.returned",
    entityType: "item",
    entityId: item._id,
  });

  res.json({ success: true, message: "Item marked as returned", data: { item } });
});

// GET /api/admin/stats
export const getStats = asyncHandler(async (_req: Request, res: Response) => {
  const [
    totalUsers,
    totalItems,
    lostItems,
    foundItems,
    activeItems,
    returnedItems,
    totalClaims,
    pendingClaims,
    approvedClaims,
    rejectedClaims,
  ] = await Promise.all([
    User.countDocuments(),
    Item.countDocuments(),
    Item.countDocuments({ type: "lost" }),
    Item.countDocuments({ type: "found" }),
    Item.countDocuments({ status: { $in: ["active", "matched", "claimed"] } }),
    Item.countDocuments({ status: "returned" }),
    Claim.countDocuments(),
    Claim.countDocuments({ status: "pending" }),
    Claim.countDocuments({ status: "approved" }),
    Claim.countDocuments({ status: "rejected" }),
  ]);

  res.json({
    success: true,
    data: {
      users: totalUsers,
      items: {
        total: totalItems,
        lost: lostItems,
        found: foundItems,
        active: activeItems,
        returned: returnedItems,
      },
      claims: {
        total: totalClaims,
        pending: pendingClaims,
        approved: approvedClaims,
        rejected: rejectedClaims,
      },
    },
  });
});

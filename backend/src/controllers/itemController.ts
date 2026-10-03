import { Request, Response } from "express";
import { Item, IItem } from "../models/Item";
import { asyncHandler, ApiError } from "../utils/asyncHandler";
import { hashAnswer } from "../utils/hash";
import { rankMatches } from "../services/matchingService";
import {
  createNotification,
  createAuditLog,
} from "../services/activityService";

const CATEGORIES = [
  "electronics",
  "documents",
  "clothing",
  "accessories",
  "books",
  "keys",
  "wallet",
  "bags",
  "jewelry",
  "sports",
  "other",
];

// POST /api/items
export const createItem = asyncHandler(async (req: Request, res: Response) => {
  const {
    type,
    title,
    category,
    description,
    color,
    brand,
    location,
    date,
    time,
    imageUrl,
    campusId,
    buildingId,
    verificationQuestion,
    verificationAnswer,
  } = req.body;

  if (!["lost", "found"].includes(type)) {
    throw new ApiError(400, "type must be 'lost' or 'found'");
  }
  if (!title || !description || !location || !date) {
    throw new ApiError(
      400,
      "title, description, location and date are required"
    );
  }
  const cat = String(category || "other").toLowerCase().trim();

  const item: any = {
    type,
    title,
    category: cat,
    description,
    color: color ? color.toLowerCase() : undefined,
    brand,
    location,
    date: new Date(date),
    time,
    imageUrl,
    campusId,
    buildingId,
    createdBy: req.user!._id,
    status: "active",
    claimStatus: "none",
  };

  // Optional hidden verification (secret answer is hashed, never returned).
  if (verificationAnswer) {
    item.verification = {
      question:
        verificationQuestion ||
        "Describe a detail only the true owner would know.",
      answerHash: await hashAnswer(String(verificationAnswer)),
    };
  }

  const created = await Item.create(item);

  await createAuditLog({
    actorId: req.user!._id,
    action: "item.create",
    entityType: "item",
    entityId: created._id,
    meta: { type: created.type },
  });

  // Notify owners of opposite-type items that a possible match appeared.
  await notifyPossibleMatches(created);

  const populated = await created.populate(
    "createdBy",
    "name email role department"
  );
  res.status(201).json({ success: true, data: { item: populated } });
});

async function notifyPossibleMatches(newItem: IItem): Promise<void> {
  const oppositeType = newItem.type === "lost" ? "found" : "lost";
  // Look at opposite-type items reported by *other* users that are still open.
  const candidates = await Item.find({
    type: oppositeType,
    status: { $in: ["active", "matched"] },
    createdBy: { $ne: newItem.createdBy },
  }).limit(200);

  const matches = rankMatches(newItem, candidates).filter(
    (m) => m.score.total >= 60
  );

  const notified = new Set<string>();
  for (const m of matches.slice(0, 5)) {
    const ownerId = (m.item.createdBy as any)?._id || m.item.createdBy;
    const key = ownerId?.toString();
    if (!key || notified.has(key) || key === newItem.createdBy.toString()) {
      continue;
    }
    notified.add(key);
    await createNotification({
      userId: ownerId,
      title: "Possible match found",
      message: `A possible match was found for your ${m.item.type} item "${m.item.title}".`,
      type: "match",
      itemId: m.item._id,
    });
    // Flag the older item as "matched" if it is still active.
    if (m.item.status === "active") {
      await Item.findByIdAndUpdate(m.item._id, { status: "matched" });
    }
  }
}

// GET /api/items
export const listItems = asyncHandler(async (req: Request, res: Response) => {
  const {
    type,
    category,
    location,
    color,
    brand,
    status,
    q,
    page = "1",
    limit = "20",
  } = req.query as Record<string, string>;

  const filter: any = {};
  if (type && ["lost", "found"].includes(type)) filter.type = type;
  if (category) filter.category = category.toLowerCase();
  if (location)
    filter.location = { $regex: location.trim(), $options: "i" };
  if (color) filter.color = color.toLowerCase();
  if (brand) filter.brand = { $regex: brand.trim(), $options: "i" };
  if (status) filter.status = status;
  if (q) {
    filter.$or = [
      { title: { $regex: q.trim(), $options: "i" } },
      { description: { $regex: q.trim(), $options: "i" } },
      { category: { $regex: q.trim(), $options: "i" } },
    ];
  }

  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));

  const [items, total] = await Promise.all([
    Item.find(filter)
      .populate("createdBy", "name email role department")
      .sort({ createdAt: -1 })
      .skip((pageNum - 1) * limitNum)
      .limit(limitNum),
    Item.countDocuments(filter),
  ]);

  res.json({
    success: true,
    data: { items, total, page: pageNum, pages: Math.ceil(total / limitNum) },
  });
});

// GET /api/items/:id
export const getItem = asyncHandler(async (req: Request, res: Response) => {
  const item = await Item.findById(req.params.id).populate(
    "createdBy",
    "name email role department"
  );
  if (!item) throw new ApiError(404, "Item not found");
  res.json({ success: true, data: { item } });
});

// GET /api/items/:id/matches
export const getItemMatches = asyncHandler(
  async (req: Request, res: Response) => {
    const item = await Item.findById(req.params.id);
    if (!item) throw new ApiError(404, "Item not found");

    const oppositeType = item.type === "lost" ? "found" : "lost";
    const candidates = await Item.find({
      type: oppositeType,
      _id: { $ne: item._id },
      status: { $ne: "returned" },
    })
      .populate("createdBy", "name email role department")
      .limit(200);

    const matches = rankMatches(item, candidates).map((m) => ({
      item: m.item,
      score: m.score,
    }));

    res.json({
      success: true,
      data: { itemId: item._id, matches },
    });
  }
);

// PATCH /api/items/:id
export const updateItem = asyncHandler(async (req: Request, res: Response) => {
  const item = await Item.findById(req.params.id);
  if (!item) throw new ApiError(404, "Item not found");

  const isOwner = item.createdBy.toString() === req.user!._id.toString();
  if (!isOwner && req.user!.role !== "admin") {
    throw new ApiError(403, "You can only edit your own item");
  }

  const editable = [
    "title",
    "category",
    "description",
    "color",
    "brand",
    "location",
    "date",
    "time",
    "imageUrl",
    "campusId",
    "buildingId",
  ];
  for (const field of editable) {
    if (req.body[field] !== undefined) {
      (item as any)[field] = req.body[field];
    }
  }
  // Status changes by non-admins are limited; admin can set any status.
  if (req.body.status && req.user!.role === "admin") {
    item.status = req.body.status;
  }

  const saved = await item.save();
  await createAuditLog({
    actorId: req.user!._id,
    action: "item.update",
    entityType: "item",
    entityId: saved._id,
  });

  await saved.populate("createdBy", "name email role department");
  res.json({ success: true, data: { item: saved } });
});

// DELETE /api/items/:id
export const deleteItem = asyncHandler(async (req: Request, res: Response) => {
  const item = await Item.findById(req.params.id);
  if (!item) throw new ApiError(404, "Item not found");

  const isOwner = item.createdBy.toString() === req.user!._id.toString();
  if (!isOwner && req.user!.role !== "admin") {
    throw new ApiError(403, "You can only delete your own item");
  }

  await item.deleteOne();
  await createAuditLog({
    actorId: req.user!._id,
    action: "item.delete",
    entityType: "item",
    entityId: item._id,
  });

  res.json({ success: true, message: "Item deleted" });
});

// GET /api/my-reports
export const myReports = asyncHandler(async (req: Request, res: Response) => {
  const items = await Item.find({ createdBy: req.user!._id }).sort({
    createdAt: -1,
  });
  res.json({ success: true, data: { items } });
});

export { CATEGORIES };

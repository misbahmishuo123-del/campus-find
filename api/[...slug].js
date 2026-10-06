var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// serverless-entry.ts
var serverless_entry_exports = {};
__export(serverless_entry_exports, {
  default: () => handler
});
module.exports = __toCommonJS(serverless_entry_exports);

// backend/src/app.ts
var import_express7 = __toESM(require("express"));
var import_cors = __toESM(require("cors"));

// backend/src/routes/index.ts
var import_express6 = require("express");

// backend/src/config/db.ts
var import_mongoose = __toESM(require("mongoose"));

// backend/src/config/env.ts
var import_dotenv = __toESM(require("dotenv"));
import_dotenv.default.config();
function required(name, fallback) {
  const value = process.env[name] ?? fallback;
  if (value === void 0) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}
var env = {
  port: parseInt(process.env.PORT || "5000", 10),
  mongoUri: required("MONGODB_URI"),
  jwtSecret: required("JWT_SECRET", "dev_only_insecure_secret_change_me"),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || "7d",
  geminiApiKey: process.env.GEMINI_API_KEY || "",
  universityEmailDomain: (process.env.UNIVERSITY_EMAIL_DOMAIN || "").trim()
};

// backend/src/config/db.ts
var connected = false;
async function connectDB() {
  import_mongoose.default.connection.on("connected", () => {
    connected = true;
    console.log("[db] MongoDB connected");
  });
  import_mongoose.default.connection.on("error", (err) => {
    console.error("[db] MongoDB connection error:", err.message);
  });
  import_mongoose.default.connection.on("disconnected", () => {
    connected = false;
    console.warn("[db] MongoDB disconnected");
  });
  await import_mongoose.default.connect(env.mongoUri, {
    serverSelectionTimeoutMS: 15e3
  });
}
function isDBConnected() {
  return connected && import_mongoose.default.connection.readyState === 1;
}

// backend/src/controllers/healthController.ts
function health(_req, res) {
  const dbUp = isDBConnected();
  res.status(dbUp ? 200 : 503).json({
    success: true,
    message: "CampusFind API is running",
    database: dbUp ? "connected" : "disconnected",
    timestamp: (/* @__PURE__ */ new Date()).toISOString()
  });
}

// backend/src/routes/authRoutes.ts
var import_express = require("express");

// backend/src/models/User.ts
var import_mongoose2 = __toESM(require("mongoose"));
var import_bcryptjs = __toESM(require("bcryptjs"));
var UserSchema = new import_mongoose2.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true
    },
    password: { type: String, required: true, select: false },
    role: {
      type: String,
      enum: ["student", "staff", "admin"],
      default: "student",
      required: true
    },
    phone: { type: String, trim: true },
    department: { type: String, trim: true },
    campusId: { type: String, trim: true }
  },
  { timestamps: true }
);
UserSchema.pre("save", async function(next) {
  if (!this.isModified("password")) return next();
  const salt = await import_bcryptjs.default.genSalt(10);
  this.password = await import_bcryptjs.default.hash(this.password, salt);
  next();
});
UserSchema.methods.comparePassword = function(candidate) {
  return import_bcryptjs.default.compare(candidate, this.password);
};
UserSchema.set("toJSON", {
  transform: (_doc, ret) => {
    delete ret.password;
    delete ret.__v;
    return ret;
  }
});
var User = import_mongoose2.default.model("User", UserSchema);

// backend/src/utils/jwt.ts
var import_jsonwebtoken = __toESM(require("jsonwebtoken"));
function signToken(payload) {
  return import_jsonwebtoken.default.sign(payload, env.jwtSecret, {
    expiresIn: env.jwtExpiresIn
  });
}
function verifyToken(token) {
  return import_jsonwebtoken.default.verify(token, env.jwtSecret);
}

// backend/src/utils/asyncHandler.ts
var asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};
var ApiError = class extends Error {
  constructor(statusCode, message) {
    super(message);
    this.statusCode = statusCode;
  }
};

// backend/src/controllers/authController.ts
var EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
function validateEmail(email) {
  if (!EMAIL_REGEX.test(email)) {
    throw new ApiError(400, "Please provide a valid email address");
  }
  const domain = env.universityEmailDomain;
  if (domain) {
    const parts = email.toLowerCase().split("@");
    if (parts[1] !== domain.toLowerCase()) {
      throw new ApiError(
        400,
        `Registration email must belong to the university domain (@${domain})`
      );
    }
  }
}
var register = asyncHandler(async (req, res) => {
  const { name, email, password, role, phone, department, campusId } = req.body;
  if (!name || !email || !password) {
    throw new ApiError(400, "name, email and password are required");
  }
  if (String(password).length < 6) {
    throw new ApiError(400, "Password must be at least 6 characters");
  }
  validateEmail(String(email));
  const requestedRole = ["student", "staff"].includes(role) ? role : "student";
  const existing = await User.findOne({ email: email.toLowerCase() });
  if (existing) {
    throw new ApiError(409, "An account with this email already exists");
  }
  const user = await User.create({
    name,
    email: email.toLowerCase(),
    password,
    role: requestedRole,
    phone,
    department,
    campusId
  });
  const token = signToken({
    sub: user._id.toString(),
    role: user.role,
    name: user.name
  });
  res.status(201).json({
    success: true,
    message: "Registration successful",
    data: { token, user }
  });
});
var login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    throw new ApiError(400, "email and password are required");
  }
  const user = await User.findOne({ email: email.toLowerCase() }).select(
    "+password"
  );
  if (!user) {
    throw new ApiError(401, "Invalid email or password");
  }
  const ok = await user.comparePassword(password);
  if (!ok) {
    throw new ApiError(401, "Invalid email or password");
  }
  const token = signToken({
    sub: user._id.toString(),
    role: user.role,
    name: user.name
  });
  res.json({
    success: true,
    message: "Login successful",
    data: { token, user }
  });
});
var me = asyncHandler(async (req, res) => {
  res.json({ success: true, data: { user: req.user } });
});

// backend/src/middleware/auth.ts
function extractToken(req) {
  const header = req.headers.authorization || "";
  if (header.startsWith("Bearer ")) {
    return header.slice(7).trim();
  }
  return null;
}
var authenticate = asyncHandler(
  async (req, _res, next) => {
    const token = extractToken(req);
    if (!token) {
      throw new ApiError(401, "Not authenticated: missing token");
    }
    let payload;
    try {
      payload = verifyToken(token);
    } catch {
      throw new ApiError(401, "Not authenticated: invalid or expired token");
    }
    const user = await User.findById(payload.sub);
    if (!user) {
      throw new ApiError(401, "Not authenticated: user no longer exists");
    }
    req.user = user;
    next();
  }
);
function authorize(...roles) {
  return (req, _res, next) => {
    if (!req.user) {
      return next(new ApiError(401, "Not authenticated"));
    }
    if (roles.length && !roles.includes(req.user.role)) {
      return next(
        new ApiError(403, "Forbidden: insufficient permissions for this role")
      );
    }
    next();
  };
}

// backend/src/routes/authRoutes.ts
var router = (0, import_express.Router)();
router.post("/register", register);
router.post("/login", login);
router.get("/me", authenticate, me);
var authRoutes_default = router;

// backend/src/routes/itemRoutes.ts
var import_express2 = require("express");

// backend/src/models/Item.ts
var import_mongoose3 = __toESM(require("mongoose"));
var ItemSchema = new import_mongoose3.Schema(
  {
    type: { type: String, enum: ["lost", "found"], required: true },
    title: { type: String, required: true, trim: true },
    category: { type: String, required: true, trim: true, lowercase: true },
    description: { type: String, required: true, trim: true },
    color: { type: String, trim: true, lowercase: true },
    brand: { type: String, trim: true },
    location: { type: String, required: true, trim: true },
    date: { type: Date, required: true },
    time: { type: String, trim: true },
    imageUrl: { type: String, trim: true },
    createdBy: {
      type: import_mongoose3.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },
    campusId: { type: String, trim: true },
    buildingId: { type: String, trim: true },
    status: {
      type: String,
      enum: ["active", "matched", "claimed", "verified", "returned", "closed"],
      default: "active"
    },
    claimStatus: {
      type: String,
      enum: ["none", "pending", "approved", "rejected"],
      default: "none"
    },
    verification: {
      question: { type: String, trim: true, default: "" },
      answerHash: { type: String, select: false }
    },
    returnedAt: { type: Date }
  },
  { timestamps: true }
);
ItemSchema.index({ title: "text", description: "text", category: "text" });
ItemSchema.index({ type: 1, status: 1, createdAt: -1 });
ItemSchema.set("toJSON", {
  transform: (_doc, ret) => {
    delete ret.__v;
    if (ret.verification) {
      delete ret.verification.answerHash;
    }
    return ret;
  }
});
var Item = import_mongoose3.default.model("Item", ItemSchema);

// backend/src/utils/hash.ts
var import_bcryptjs2 = __toESM(require("bcryptjs"));
function normalizeAnswer(answer) {
  return answer.trim().toLowerCase().replace(/\s+/g, " ");
}
async function hashAnswer(answer) {
  return import_bcryptjs2.default.hash(normalizeAnswer(answer), 10);
}
async function compareAnswer(answer, hash) {
  return import_bcryptjs2.default.compare(normalizeAnswer(answer), hash);
}

// backend/src/utils/textSimilarity.ts
function tokenize(text) {
  return text.toLowerCase().replace(/[^a-z0-9\s]/g, " ").split(/\s+/).filter((t) => t.length > 1);
}
function tokenSimilarity(a, b) {
  const setA = new Set(tokenize(a));
  const setB = new Set(tokenize(b));
  if (setA.size === 0 || setB.size === 0) return 0;
  let intersection = 0;
  setA.forEach((t) => {
    if (setB.has(t)) intersection++;
  });
  const union = setA.size + setB.size - intersection;
  return union === 0 ? 0 : intersection / union;
}
function bigrams(s) {
  const clean = s.toLowerCase().replace(/\s+/g, "").trim();
  const out = /* @__PURE__ */ new Set();
  for (let i = 0; i < clean.length - 1; i++) {
    out.add(clean.slice(i, i + 2));
  }
  return out;
}
function diceSimilarity(a, b) {
  const bgA = bigrams(a);
  const bgB = bigrams(b);
  if (bgA.size === 0 || bgB.size === 0) return 0;
  let intersection = 0;
  bgA.forEach((g) => {
    if (bgB.has(g)) intersection++;
  });
  return 2 * intersection / (bgA.size + bgB.size);
}
function textSimilarity(a, b) {
  if (!a || !b) return 0;
  const token = tokenSimilarity(a, b);
  const dice = diceSimilarity(a, b);
  return Math.max(token, dice * 0.9);
}
function locationSimilarity(a, b) {
  if (!a || !b) return 0;
  const x = a.toLowerCase().trim();
  const y = b.toLowerCase().trim();
  if (x === y) return 1;
  if (x.includes(y) || y.includes(x)) return 0.85;
  return diceSimilarity(x, y);
}

// backend/src/services/matchingService.ts
function matchLabel(total) {
  if (total >= 80) return "Strong possible match";
  if (total >= 60) return "Possible match";
  if (total >= 40) return "Weak match";
  return "No meaningful match";
}
function daysBetween(a, b) {
  const ms = Math.abs(a.getTime() - b.getTime());
  return ms / (1e3 * 60 * 60 * 24);
}
function scoreMatch(a, b) {
  const catA = (a.category || "").toLowerCase().trim();
  const catB = (b.category || "").toLowerCase().trim();
  const category = catA && catA === catB ? 25 : Math.round(textSimilarity(catA, catB) * 15);
  const location = Math.round(
    locationSimilarity(a.location || "", b.location || "") * 25
  );
  let dateTime = 0;
  if (a.date && b.date) {
    const diff = daysBetween(new Date(a.date), new Date(b.date));
    dateTime = Math.max(0, Math.round(20 - diff * 4));
  }
  const description = Math.round(
    textSimilarity(a.description || "", b.description || "") * 20
  );
  const color = a.color && b.color ? Math.round(textSimilarity(a.color, b.color) * 5) : 0;
  const brand = a.brand && b.brand ? Math.round(textSimilarity(a.brand, b.brand) * 5) : 0;
  const colorBrand = color + brand;
  const total = category + location + dateTime + description + colorBrand;
  return {
    category,
    location,
    dateTime,
    description,
    colorBrand,
    total,
    label: matchLabel(total)
  };
}
function rankMatches(target, candidates) {
  return candidates.map((item) => ({ item, score: scoreMatch(target, item) })).filter((m) => m.score.total >= 40).sort((x, y) => y.score.total - x.score.total);
}

// backend/src/models/Notification.ts
var import_mongoose4 = __toESM(require("mongoose"));
var NotificationSchema = new import_mongoose4.Schema(
  {
    userId: { type: import_mongoose4.Schema.Types.ObjectId, ref: "User", required: true },
    title: { type: String, required: true, trim: true },
    message: { type: String, required: true, trim: true },
    type: { type: String, default: "info", trim: true },
    itemId: { type: import_mongoose4.Schema.Types.ObjectId, ref: "Item" },
    claimId: { type: import_mongoose4.Schema.Types.ObjectId, ref: "Claim" },
    read: { type: Boolean, default: false }
  },
  { timestamps: true }
);
NotificationSchema.index({ userId: 1, createdAt: -1 });
NotificationSchema.set("toJSON", {
  transform: (_doc, ret) => {
    delete ret.__v;
    return ret;
  }
});
var Notification = import_mongoose4.default.model(
  "Notification",
  NotificationSchema
);

// backend/src/models/AuditLog.ts
var import_mongoose5 = __toESM(require("mongoose"));
var AuditLogSchema = new import_mongoose5.Schema(
  {
    actorId: { type: import_mongoose5.Schema.Types.ObjectId, ref: "User" },
    action: { type: String, required: true, trim: true },
    entityType: { type: String, required: true, trim: true },
    entityId: { type: import_mongoose5.Schema.Types.ObjectId },
    meta: { type: import_mongoose5.Schema.Types.Mixed }
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);
AuditLogSchema.index({ entityType: 1, entityId: 1, createdAt: -1 });
AuditLogSchema.set("toJSON", {
  transform: (_doc, ret) => {
    delete ret.__v;
    return ret;
  }
});
var AuditLog = import_mongoose5.default.model(
  "AuditLog",
  AuditLogSchema
);

// backend/src/services/activityService.ts
async function createNotification(params) {
  return Notification.create({
    userId: params.userId,
    title: params.title,
    message: params.message,
    type: params.type || "info",
    itemId: params.itemId,
    claimId: params.claimId
  });
}
async function createAuditLog(params) {
  return AuditLog.create({
    actorId: params.actorId,
    action: params.action,
    entityType: params.entityType,
    entityId: params.entityId,
    meta: params.meta
  });
}

// backend/src/controllers/itemController.ts
var createItem = asyncHandler(async (req, res) => {
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
    verificationAnswer
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
  const item = {
    type,
    title,
    category: cat,
    description,
    color: color ? color.toLowerCase() : void 0,
    brand,
    location,
    date: new Date(date),
    time,
    imageUrl,
    campusId,
    buildingId,
    createdBy: req.user._id,
    status: "active",
    claimStatus: "none"
  };
  if (verificationAnswer) {
    item.verification = {
      question: verificationQuestion || "Describe a detail only the true owner would know.",
      answerHash: await hashAnswer(String(verificationAnswer))
    };
  }
  const created = await Item.create(item);
  await createAuditLog({
    actorId: req.user._id,
    action: "item.create",
    entityType: "item",
    entityId: created._id,
    meta: { type: created.type }
  });
  await notifyPossibleMatches(created);
  const populated = await created.populate(
    "createdBy",
    "name email role department"
  );
  res.status(201).json({ success: true, data: { item: populated } });
});
async function notifyPossibleMatches(newItem) {
  const oppositeType = newItem.type === "lost" ? "found" : "lost";
  const candidates = await Item.find({
    type: oppositeType,
    status: { $in: ["active", "matched"] },
    createdBy: { $ne: newItem.createdBy }
  }).limit(200);
  const matches = rankMatches(newItem, candidates).filter(
    (m) => m.score.total >= 60
  );
  const notified = /* @__PURE__ */ new Set();
  for (const m of matches.slice(0, 5)) {
    const ownerId = m.item.createdBy?._id || m.item.createdBy;
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
      itemId: m.item._id
    });
    if (m.item.status === "active") {
      await Item.findByIdAndUpdate(m.item._id, { status: "matched" });
    }
  }
}
var listItems = asyncHandler(async (req, res) => {
  const {
    type,
    category,
    location,
    color,
    brand,
    status,
    q,
    page = "1",
    limit = "20"
  } = req.query;
  const filter = {};
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
      { category: { $regex: q.trim(), $options: "i" } }
    ];
  }
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const [items, total] = await Promise.all([
    Item.find(filter).populate("createdBy", "name email role department").sort({ createdAt: -1 }).skip((pageNum - 1) * limitNum).limit(limitNum),
    Item.countDocuments(filter)
  ]);
  res.json({
    success: true,
    data: { items, total, page: pageNum, pages: Math.ceil(total / limitNum) }
  });
});
var getItem = asyncHandler(async (req, res) => {
  const item = await Item.findById(req.params.id).populate(
    "createdBy",
    "name email role department"
  );
  if (!item) throw new ApiError(404, "Item not found");
  res.json({ success: true, data: { item } });
});
var getItemMatches = asyncHandler(
  async (req, res) => {
    const item = await Item.findById(req.params.id);
    if (!item) throw new ApiError(404, "Item not found");
    const oppositeType = item.type === "lost" ? "found" : "lost";
    const candidates = await Item.find({
      type: oppositeType,
      _id: { $ne: item._id },
      status: { $ne: "returned" }
    }).populate("createdBy", "name email role department").limit(200);
    const matches = rankMatches(item, candidates).map((m) => ({
      item: m.item,
      score: m.score
    }));
    res.json({
      success: true,
      data: { itemId: item._id, matches }
    });
  }
);
var updateItem = asyncHandler(async (req, res) => {
  const item = await Item.findById(req.params.id);
  if (!item) throw new ApiError(404, "Item not found");
  const isOwner = item.createdBy.toString() === req.user._id.toString();
  if (!isOwner && req.user.role !== "admin") {
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
    "buildingId"
  ];
  for (const field of editable) {
    if (req.body[field] !== void 0) {
      item[field] = req.body[field];
    }
  }
  if (req.body.status && req.user.role === "admin") {
    item.status = req.body.status;
  }
  const saved = await item.save();
  await createAuditLog({
    actorId: req.user._id,
    action: "item.update",
    entityType: "item",
    entityId: saved._id
  });
  await saved.populate("createdBy", "name email role department");
  res.json({ success: true, data: { item: saved } });
});
var deleteItem = asyncHandler(async (req, res) => {
  const item = await Item.findById(req.params.id);
  if (!item) throw new ApiError(404, "Item not found");
  const isOwner = item.createdBy.toString() === req.user._id.toString();
  if (!isOwner && req.user.role !== "admin") {
    throw new ApiError(403, "You can only delete your own item");
  }
  await item.deleteOne();
  await createAuditLog({
    actorId: req.user._id,
    action: "item.delete",
    entityType: "item",
    entityId: item._id
  });
  res.json({ success: true, message: "Item deleted" });
});
var myReports = asyncHandler(async (req, res) => {
  const items = await Item.find({ createdBy: req.user._id }).sort({
    createdAt: -1
  });
  res.json({ success: true, data: { items } });
});

// backend/src/models/Claim.ts
var import_mongoose6 = __toESM(require("mongoose"));
var ClaimSchema = new import_mongoose6.Schema(
  {
    itemId: { type: import_mongoose6.Schema.Types.ObjectId, ref: "Item", required: true },
    claimantId: { type: import_mongoose6.Schema.Types.ObjectId, ref: "User", required: true },
    reason: { type: String, required: true, trim: true },
    verificationAnswerHash: { type: String, select: false },
    verificationMatched: { type: Boolean },
    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending"
    },
    adminNotes: { type: String, trim: true },
    reviewedBy: { type: import_mongoose6.Schema.Types.ObjectId, ref: "User" },
    reviewedAt: { type: Date }
  },
  { timestamps: true }
);
ClaimSchema.index({ itemId: 1, claimantId: 1 }, { unique: true });
ClaimSchema.set("toJSON", {
  transform: (_doc, ret) => {
    delete ret.__v;
    delete ret.verificationAnswerHash;
    return ret;
  }
});
var Claim = import_mongoose6.default.model(
  "Claim",
  ClaimSchema
);

// backend/src/controllers/claimController.ts
var createClaim = asyncHandler(async (req, res) => {
  const { reason, verificationAnswer } = req.body;
  const item = await Item.findById(req.params.id).select(
    "+verification.answerHash"
  );
  if (!item) throw new ApiError(404, "Item not found");
  if (item.createdBy.toString() === req.user._id.toString()) {
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
    claimantId: req.user._id
  });
  if (existing) {
    throw new ApiError(409, "You have already submitted a claim for this item");
  }
  let verificationMatched;
  let answerHash;
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
    claimantId: req.user._id,
    reason,
    verificationAnswerHash: answerHash,
    verificationMatched,
    status: "pending"
  });
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
    claimId: claim._id
  });
  await createNotification({
    userId: req.user._id,
    title: "Claim submitted",
    message: `Your claim for "${item.title}" has been submitted and is pending review.`,
    type: "claim",
    itemId: item._id,
    claimId: claim._id
  });
  await createAuditLog({
    actorId: req.user._id,
    action: "claim.create",
    entityType: "claim",
    entityId: claim._id,
    meta: { itemId: item._id }
  });
  res.status(201).json({
    success: true,
    message: "Claim submitted. Ownership must be verified by university staff.",
    data: { claim }
  });
});
var myClaims = asyncHandler(async (req, res) => {
  const claims = await Claim.find({ claimantId: req.user._id }).populate("itemId").sort({ createdAt: -1 });
  res.json({ success: true, data: { claims } });
});

// backend/src/routes/itemRoutes.ts
var router2 = (0, import_express2.Router)();
router2.use(authenticate);
router2.post("/", createItem);
router2.get("/", listItems);
router2.get("/:id", getItem);
router2.get("/:id/matches", getItemMatches);
router2.patch("/:id", updateItem);
router2.delete("/:id", deleteItem);
router2.post("/:id/claim", createClaim);
var itemRoutes_default = router2;

// backend/src/routes/userRoutes.ts
var import_express3 = require("express");
var router3 = (0, import_express3.Router)();
router3.use(authenticate);
router3.get("/my-reports", myReports);
router3.get("/my-claims", myClaims);
var userRoutes_default = router3;

// backend/src/routes/adminRoutes.ts
var import_express4 = require("express");

// backend/src/controllers/adminController.ts
var listClaims = asyncHandler(async (req, res) => {
  const { status } = req.query;
  const filter = {};
  if (status && ["pending", "approved", "rejected"].includes(status)) {
    filter.status = status;
  }
  const claims = await Claim.find(filter).populate({ path: "itemId", populate: { path: "createdBy", select: "name email role" } }).populate("claimantId", "name email role department").sort({ createdAt: -1 });
  res.json({ success: true, data: { claims } });
});
var getClaim = asyncHandler(async (req, res) => {
  const claim = await Claim.findById(req.params.claimId).populate("claimantId", "name email role department phone").populate({ path: "itemId", populate: { path: "createdBy", select: "name email role department" } });
  if (!claim) throw new ApiError(404, "Claim not found");
  const item = claim.itemId;
  let possibleMatches = [];
  if (item && item.type) {
    const oppositeType = item.type === "lost" ? "found" : "lost";
    const candidates = await Item.find({
      type: oppositeType,
      _id: { $ne: item._id }
    }).limit(100);
    possibleMatches = rankMatches(item, candidates).slice(0, 5).map((m) => ({ item: m.item, score: m.score }));
  }
  res.json({
    success: true,
    data: {
      claim,
      verificationQuestion: item?.verification?.question || null,
      verificationMatched: claim.verificationMatched ?? null,
      possibleMatches
    }
  });
});
var reviewClaim = asyncHandler(async (req, res) => {
  const { status, adminNotes } = req.body;
  if (!["approved", "rejected"].includes(status)) {
    throw new ApiError(400, "status must be 'approved' or 'rejected'");
  }
  const claim = await Claim.findById(req.params.claimId);
  if (!claim) throw new ApiError(404, "Claim not found");
  if (claim.claimantId.toString() === req.user._id.toString()) {
    throw new ApiError(403, "You cannot review a claim you submitted");
  }
  if (claim.status !== "pending") {
    throw new ApiError(400, `This claim has already been ${claim.status}`);
  }
  const item = await Item.findById(claim.itemId);
  if (!item) throw new ApiError(404, "The claimed item no longer exists");
  claim.status = status;
  claim.adminNotes = adminNotes;
  claim.reviewedBy = req.user._id;
  claim.reviewedAt = /* @__PURE__ */ new Date();
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
      claimId: claim._id
    });
  } else {
    item.claimStatus = "rejected";
    item.status = "active";
    await item.save();
    await createNotification({
      userId: claim.claimantId,
      title: "Claim rejected",
      message: `Your claim for "${item.title}" was rejected after review.`,
      type: "claim",
      itemId: item._id,
      claimId: claim._id
    });
  }
  await createNotification({
    userId: item.createdBy,
    title: status === "approved" ? "Claim approved on your item" : "Claim rejected",
    message: `The claim on "${item.title}" was ${status} by security.`,
    type: "claim",
    itemId: item._id,
    claimId: claim._id
  });
  await createAuditLog({
    actorId: req.user._id,
    action: `claim.${status}`,
    entityType: "claim",
    entityId: claim._id,
    meta: { itemId: item._id, adminNotes }
  });
  res.json({ success: true, message: `Claim ${status}`, data: { claim } });
});
var markReturned = asyncHandler(async (req, res) => {
  const item = await Item.findById(req.params.id);
  if (!item) throw new ApiError(404, "Item not found");
  if (item.status === "returned") {
    throw new ApiError(400, "Item is already marked as returned");
  }
  item.status = "returned";
  item.returnedAt = /* @__PURE__ */ new Date();
  await item.save();
  await createNotification({
    userId: item.createdBy,
    title: "Item returned",
    message: `Your item "${item.title}" has been marked as returned.`,
    type: "returned",
    itemId: item._id
  });
  const approvedClaim = await Claim.findOne({
    itemId: item._id,
    status: "approved"
  });
  if (approvedClaim) {
    await createNotification({
      userId: approvedClaim.claimantId,
      title: "Item returned",
      message: `The item "${item.title}" you claimed has been marked as returned.`,
      type: "returned",
      itemId: item._id,
      claimId: approvedClaim._id
    });
  }
  await createAuditLog({
    actorId: req.user._id,
    action: "item.returned",
    entityType: "item",
    entityId: item._id
  });
  res.json({ success: true, message: "Item marked as returned", data: { item } });
});
var getStats = asyncHandler(async (_req, res) => {
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
    rejectedClaims
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
    Claim.countDocuments({ status: "rejected" })
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
        returned: returnedItems
      },
      claims: {
        total: totalClaims,
        pending: pendingClaims,
        approved: approvedClaims,
        rejected: rejectedClaims
      }
    }
  });
});

// backend/src/routes/adminRoutes.ts
var router4 = (0, import_express4.Router)();
router4.use(authenticate, authorize("admin"));
router4.get("/stats", getStats);
router4.get("/claims", listClaims);
router4.get("/claims/:claimId", getClaim);
router4.patch("/claims/:claimId", reviewClaim);
router4.patch("/items/:id/return", markReturned);
var adminRoutes_default = router4;

// backend/src/routes/notificationRoutes.ts
var import_express5 = require("express");

// backend/src/controllers/notificationController.ts
var myNotifications = asyncHandler(
  async (req, res) => {
    const notifications = await Notification.find({ userId: req.user._id }).sort({ createdAt: -1 }).limit(100);
    const unread = await Notification.countDocuments({
      userId: req.user._id,
      read: false
    });
    res.json({ success: true, data: { notifications, unread } });
  }
);
var markRead = asyncHandler(async (req, res) => {
  const note = await Notification.findOne({
    _id: req.params.id,
    userId: req.user._id
  });
  if (!note) throw new ApiError(404, "Notification not found");
  note.read = true;
  await note.save();
  res.json({ success: true, data: { notification: note } });
});
var markAllRead = asyncHandler(async (req, res) => {
  await Notification.updateMany(
    { userId: req.user._id, read: false },
    { read: true }
  );
  res.json({ success: true, message: "All notifications marked as read" });
});

// backend/src/routes/notificationRoutes.ts
var router5 = (0, import_express5.Router)();
router5.use(authenticate);
router5.get("/", myNotifications);
router5.patch("/read-all", markAllRead);
router5.patch("/:id/read", markRead);
var notificationRoutes_default = router5;

// backend/src/routes/index.ts
var router6 = (0, import_express6.Router)();
router6.get("/health", health);
router6.use("/auth", authRoutes_default);
router6.use("/items", itemRoutes_default);
router6.use("/notifications", notificationRoutes_default);
router6.use("/admin", adminRoutes_default);
router6.use("/", userRoutes_default);
var routes_default = router6;

// backend/src/middleware/errorHandler.ts
function notFoundHandler(req, _res, next) {
  next(new ApiError(404, `Route not found: ${req.method} ${req.originalUrl}`));
}
function errorHandler(err, _req, res, _next) {
  if (err.code === 11e3) {
    const field = Object.keys(err.keyValue || {})[0] || "field";
    return res.status(409).json({ success: false, message: `Duplicate value for ${field}` });
  }
  if (err.name === "ValidationError") {
    const messages = Object.values(err.errors || {}).map(
      (e) => e.message
    );
    return res.status(400).json({ success: false, message: messages.join(", ") });
  }
  if (err.name === "CastError") {
    return res.status(400).json({ success: false, message: `Invalid ${err.path}: ${err.value}` });
  }
  const statusCode = err.statusCode || 500;
  const message = err.message || "Internal server error";
  if (statusCode >= 500) {
    console.error("[error]", err);
  }
  res.status(statusCode).json({ success: false, message });
}

// backend/src/app.ts
function createApp() {
  const app2 = (0, import_express7.default)();
  app2.use((0, import_cors.default)());
  app2.use(import_express7.default.json({ limit: "1mb" }));
  app2.use(import_express7.default.urlencoded({ extended: true }));
  app2.get("/", (_req, res) => {
    res.json({
      success: true,
      message: "CampusFind API",
      docs: "/api/health"
    });
  });
  app2.use("/api", routes_default);
  app2.use(notFoundHandler);
  app2.use(errorHandler);
  return app2;
}

// serverless-entry.ts
var app = createApp();
var dbPromise = null;
function ensureDb() {
  if (!dbPromise) {
    dbPromise = (async () => {
      for (let attempt = 1; attempt <= 3; attempt++) {
        try {
          await connectDB();
          return;
        } catch (err) {
          console.error(
            "[vercel] MongoDB connect attempt " + attempt + " failed:",
            err && err.message ? err.message : err
          );
          if (attempt < 3) await new Promise((r) => setTimeout(r, 1e3));
        }
      }
    })().catch((err) => {
      dbPromise = null;
      throw err;
    });
  }
  return dbPromise;
}
async function handler(req, res) {
  try {
    await ensureDb();
  } catch (err) {
    console.error("[vercel] db connect error:", err && err.message ? err.message : err);
  }
  app(req, res);
}
module.exports = module.exports.default || module.exports;

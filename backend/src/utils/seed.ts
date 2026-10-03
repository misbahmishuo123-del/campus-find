/**
 * DEVELOPMENT-ONLY seed script.
 *
 * Creates a demo admin, a demo student, and sample lost/found items so the
 * full workflow can be demonstrated. The credentials below are NOT secrets —
 * they exist only to make local demos easy. Change or remove them for real use.
 *
 * Run with:  npm run seed
 */
import mongoose from "mongoose";
import { connectDB, disconnectDB } from "../config/db";
import { User } from "../models/User";
import { Item } from "../models/Item";
import { Claim } from "../models/Claim";
import { Notification } from "../models/Notification";
import { AuditLog } from "../models/AuditLog";
import { hashAnswer } from "./hash";

// DEVELOPMENT ONLY demo credentials.
const DEMO_ADMIN = {
  name: "Security Admin",
  email: "admin@campusfind.edu",
  password: "Admin@123",
  role: "admin" as const,
  department: "Campus Security",
};
const DEMO_STUDENT = {
  name: "Sara Student",
  email: "sara@student.campusfind.edu",
  password: "Student@123",
  role: "student" as const,
  department: "Computer Science",
};

const DEMO_FINDER = {
  name: "Ali Finder",
  email: "ali@student.campusfind.edu",
  password: "Student@123",
  role: "student" as const,
  department: "Engineering",
};

function daysAgo(n: number): Date {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
}

async function seed() {
  await connectDB();
  console.log("[seed] Connected. Clearing demo collections...");

  await Promise.all([
    User.deleteMany({ email: { $in: [DEMO_ADMIN.email, DEMO_STUDENT.email, DEMO_FINDER.email] } }),
    Item.deleteMany({}),
    Claim.deleteMany({}),
    Notification.deleteMany({}),
    AuditLog.deleteMany({}),
  ]);

  const admin = await User.create(DEMO_ADMIN);
  const student = await User.create(DEMO_STUDENT);
  const finder = await User.create(DEMO_FINDER);
  console.log("[seed] Created demo users.");

  const lostWallet = await Item.create({
    type: "lost",
    title: "Black leather wallet",
    category: "wallet",
    description: "Black leather bifold wallet with student ID card and a few notes inside.",
    color: "black",
    brand: "guess",
    location: "Main Library, 2nd floor",
    date: daysAgo(2),
    time: "14:30",
    createdBy: student._id,
    status: "active",
    verification: {
      question: "What is written on the ID card inside the wallet?",
      answerHash: await hashAnswer("Sara Khan"),
    },
  });

  const foundWallet = await Item.create({
    type: "found",
    title: "Wallet found near library",
    category: "wallet",
    description: "Found a black leather wallet on a study table, contains an ID card.",
    color: "black",
    location: "Main Library, 2nd floor",
    date: daysAgo(2),
    time: "15:10",
    createdBy: finder._id,
    status: "matched",
  });

  await Item.create({
    type: "lost",
    title: "Blue Casio calculator",
    category: "electronics",
    description: "Blue Casio fx-991 scientific calculator with a name sticker on the back.",
    color: "blue",
    brand: "casio",
    location: "Engineering Block, Lab 3",
    date: daysAgo(5),
    createdBy: student._id,
    status: "active",
  });

  await Item.create({
    type: "found",
    title: "Set of keys with red keychain",
    category: "keys",
    description: "Bunch of keys with a red car keychain, found in the parking lot.",
    color: "silver",
    location: "North Parking Lot",
    date: daysAgo(1),
    createdBy: finder._id,
    status: "active",
  });

  console.log("[seed] Created sample items (including a matched lost/found pair).");

  // A sample pending claim from the finder on the lost wallet is intentionally
  // NOT created, so the demo can walk through submitting and approving one.
  void lostWallet;
  void foundWallet;
  void admin;

  await disconnectDB();
  console.log("[seed] Done.");
  console.log("----------------------------------------------------");
  console.log("DEVELOPMENT ONLY demo logins:");
  console.log(`  admin   -> ${DEMO_ADMIN.email} / ${DEMO_ADMIN.password}`);
  console.log(`  student -> ${DEMO_STUDENT.email} / ${DEMO_STUDENT.password}`);
  console.log(`  student -> ${DEMO_FINDER.email} / ${DEMO_FINDER.password}`);
  console.log("----------------------------------------------------");
  process.exit(0);
}

seed().catch(async (err) => {
  console.error("[seed] Failed:", err);
  await mongoose.disconnect();
  process.exit(1);
});

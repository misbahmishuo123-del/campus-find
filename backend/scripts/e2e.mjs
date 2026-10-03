const BASE = "http://localhost:5000/api";
let pass = 0, fail = 0;
function check(name, cond, extra) {
  if (cond) { pass++; console.log(`  PASS  ${name}`); }
  else { fail++; console.log(`  FAIL  ${name} ${extra ? "-> " + JSON.stringify(extra) : ""}`); }
}
async function api(method, path, body, token) {
  const headers = { "Content-Type": "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(BASE + path, {
    method, headers, body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, ...json };
}
const stamp = Date.now().toString().slice(-7);

(async () => {
  console.log("\nTEST 1: Register students");
  const ownerR = await api("POST", "/auth/register", {
    name: "Owner Student", email: `owner${stamp}@student.campusfind.edu`,
    password: "Student@123", role: "student", department: "CS",
  });
  check("register owner (201)", ownerR.status === 201, ownerR);
  const finderR = await api("POST", "/auth/register", {
    name: "Finder Student", email: `finder${stamp}@student.campusfind.edu`,
    password: "Student@123", role: "student",
  });
  check("register finder (201)", finderR.status === 201, finderR);
  const ownerToken = ownerR.data?.token;
  const finderToken = finderR.data?.token;
  check("no password hash in response", !JSON.stringify(ownerR).includes("$2a$"), null);

  console.log("\nTEST: role escalation blocked (client cannot self-assign admin)");
  const adminTry = await api("POST", "/auth/register", {
    name: "Hacker", email: `hack${stamp}@student.campusfind.edu`,
    password: "Student@123", role: "admin",
  });
  check("admin role not granted", adminTry.data?.user?.role !== "admin", adminTry.data?.user);

  console.log("\nTEST: duplicate email rejected");
  const dup = await api("POST", "/auth/register", {
    name: "Dup", email: `owner${stamp}@student.campusfind.edu`,
    password: "Student@123", role: "student",
  });
  check("duplicate -> 409", dup.status === 409, dup);

  console.log("\nTEST 2: Login");
  const login = await api("POST", "/auth/login", {
    email: `owner${stamp}@student.campusfind.edu`, password: "Student@123",
  });
  check("login ok", login.status === 200 && !!login.data?.token, login);
  const badLogin = await api("POST", "/auth/login", {
    email: `owner${stamp}@student.campusfind.edu`, password: "wrongpass",
  });
  check("bad password -> 401", badLogin.status === 401, badLogin);
  const me = await api("GET", "/auth/me", null, login.data?.token);
  check("GET /auth/me ok", me.status === 200 && !!me.data?.user, me);

  console.log("\nTEST 3: Create LOST item (owner)");
  const lost = await api("POST", "/items", {
    type: "lost", title: "Black leather wallet", category: "wallet",
    description: "Black leather bifold wallet containing my student ID card.",
    color: "black", brand: "guess", location: "Main Library, 2nd floor",
    date: new Date().toISOString(), time: "14:30",
    verificationQuestion: "What name is on the ID inside?", verificationAnswer: "Owner Student",
  }, ownerToken);
  check("create lost (201)", lost.status === 201, lost);
  const lostId = lost.data?.item?._id;
  check("verification answer hash not returned", !JSON.stringify(lost).includes("answerHash"), null);

  console.log("\nTEST 4: Create FOUND item (finder, with a secret verification question)");
  const found = await api("POST", "/items", {
    type: "found", title: "Wallet found near library", category: "wallet",
    description: "Found a black leather wallet on a study table with an ID card inside.",
    color: "black", location: "Main Library, 2nd floor",
    date: new Date().toISOString(), time: "15:10",
    verificationQuestion: "What name is on the ID inside?", verificationAnswer: "Owner Student",
  }, finderToken);
  check("create found (201)", found.status === 201, found);
  const foundId = found.data?.item?._id;

  console.log("\nTEST: unauthenticated item access blocked");
  const noAuth = await api("GET", "/items", null, null);
  check("no token -> 401", noAuth.status === 401, noAuth);

  console.log("\nTEST 8 (search): Search & filter items");
  const search = await api("GET", "/items?type=found&category=wallet", null, ownerToken);
  check("search found wallets ok", search.status === 200 && Array.isArray(search.data?.items), search.status);
  const textSearch = await api("GET", "/items?q=leather", null, ownerToken);
  check("text search returns results", textSearch.data?.items?.length >= 1, textSearch.data?.total);

  console.log("\nTEST 5: Possible match");
  const matches = await api("GET", `/items/${lostId}/matches`, null, ownerToken);
  check("matches endpoint ok", matches.status === 200, matches.status);
  const top = matches.data?.matches?.[0];
  check("found wallet is top possible match", top?.item?._id === foundId, top?.item?._id);
  check("match score is meaningful (>=60)", (top?.score?.total ?? 0) >= 60, top?.score);
  check("label says 'possible' not 'confirmed'", /[Pp]ossible|Strong|Weak/.test(top?.score?.label || ""), top?.score?.label);

  console.log("\nTEST 6: Submit claim (owner claims the found item, with correct secret answer)");
  const claim = await api("POST", `/items/${foundId}/claim`, {
    reason: "This is my wallet that I lost in the library today.",
    verificationAnswer: "owner student",
  }, ownerToken);
  check("claim submitted (201)", claim.status === 201, claim);
  const claimId = claim.data?.claim?._id;
  const dupClaim = await api("POST", `/items/${foundId}/claim`, {
    reason: "Duplicate attempt", verificationAnswer: "x",
  }, ownerToken);
  check("duplicate claim -> 409", dupClaim.status === 409, dupClaim);
  const selfClaim = await api("POST", `/items/${foundId}/claim`, {
    reason: "Finder tries to claim own item",
  }, finderToken);
  check("cannot claim own item -> 400", selfClaim.status === 400, selfClaim);

  console.log("\nTEST: my-claims & my-reports");
  const myClaims = await api("GET", "/my-claims", null, ownerToken);
  check("my-claims returns the claim", myClaims.data?.claims?.some(c => c._id === claimId), myClaims.data?.claims?.length);
  const myReports = await api("GET", "/my-reports", null, ownerToken);
  check("my-reports returns lost item", myReports.data?.items?.some(i => i._id === lostId), myReports.data?.items?.length);

  console.log("\nTEST 7: Login as admin");
  const adminLogin = await api("POST", "/auth/login", {
    email: "admin@campusfind.edu", password: "Admin@123",
  });
  check("admin login ok", adminLogin.status === 200 && !!adminLogin.data?.token, adminLogin);
  const adminToken = adminLogin.data?.token;

  console.log("\nTEST: role-based authorization (student cannot access admin routes)");
  const forbidden = await api("GET", "/admin/claims", null, ownerToken);
  check("student -> admin route = 403", forbidden.status === 403, forbidden);

  console.log("\nTEST 8: Admin reviews claim");
  const adminClaims = await api("GET", "/admin/claims", null, adminToken);
  check("admin lists claims", adminClaims.status === 200 && adminClaims.data?.claims?.length >= 1, adminClaims.status);
  const detail = await api("GET", `/admin/claims/${claimId}`, null, adminToken);
  check("claim detail ok", detail.status === 200, detail.status);
  check("admin sees verification matched = true", detail.data?.verificationMatched === true, detail.data?.verificationMatched);
  check("secret answer hash NOT exposed to admin", !JSON.stringify(detail).includes("$2a$") && !JSON.stringify(detail).includes("answerHash"), null);

  console.log("\nTEST 9: Admin approves claim");
  const approve = await api("PATCH", `/admin/claims/${claimId}`, {
    status: "approved", adminNotes: "Verification answer matched. Ownership confirmed by security.",
  }, adminToken);
  check("approve ok", approve.status === 200, approve);
  const foundAfter = await api("GET", `/items/${foundId}`, null, adminToken);
  check("item status -> verified", foundAfter.data?.item?.status === "verified", foundAfter.data?.item?.status);

  console.log("\nTEST 9b: cannot approve twice");
  const reApprove = await api("PATCH", `/admin/claims/${claimId}`, { status: "approved" }, adminToken);
  check("re-approve -> 400", reApprove.status === 400, reApprove);

  console.log("\nTEST 10: Mark item returned");
  const returned = await api("PATCH", `/admin/items/${foundId}/return`, {}, adminToken);
  check("mark returned ok", returned.status === 200, returned);
  check("item status -> returned", returned.data?.item?.status === "returned", returned.data?.item?.status);
  check("returnedAt set", !!returned.data?.item?.returnedAt, null);

  console.log("\nTEST 11: Notifications & admin stats");
  const notes = await api("GET", "/notifications", null, ownerToken);
  check("owner has notifications", notes.data?.notifications?.length >= 1, notes.data?.notifications?.length);
  const titles = notes.data?.notifications?.map(n => n.title).join(" | ");
  check("owner notified about approval/return", /approved|returned|match/i.test(titles), titles);
  const stats = await api("GET", "/admin/stats", null, adminToken);
  check("admin stats ok", stats.status === 200 && stats.data?.items?.total >= 2, stats.data);

  console.log("\n================ RESULT ================");
  console.log(`  ${pass} passed, ${fail} failed`);
  console.log("========================================\n");
  process.exit(fail === 0 ? 0 : 1);
})();

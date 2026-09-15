import { db } from "@/lib/db";

export async function GET() {
  try {
    await db.$queryRaw`SELECT 1`;
    const tenantCount = await db.tenant.count();
    return Response.json({ ok: true, database: "connected", schema: "ready", tenants: tenantCount });
  } catch (error) {
    console.error("[HEALTH_DB_ERROR]", error);
    return Response.json(
      { ok: false, database: "error", message: error instanceof Error ? error.message : "Unknown database error" },
      { status: 503 },
    );
  }
}

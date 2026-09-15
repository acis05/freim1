import Link from "next/link";
import AppShell from "@/components/AppShell";
import { db } from "@/lib/db";
import { requireRoles } from "@/lib/auth";
import { JobStatus, Role } from "@prisma/client";
import { redirect } from "next/navigation";

const jobCreatorRoles: Role[] = [Role.ADMIN, Role.SUPERVISOR, Role.MANAGER];

export default async function NewJobPage() {
  const user = await requireRoles(jobCreatorRoles);
  const customers = await db.customer.findMany({
    where: { tenantId: user.tenantId, active: true },
    orderBy: { name: "asc" },
  });

  async function createJob(formData: FormData) {
    "use server";
    const actor = await requireRoles(jobCreatorRoles);
    const customerId = String(formData.get("customerId") || "");
    const customer = await db.customer.findFirst({
      where: { id: customerId, tenantId: actor.tenantId, active: true },
    });
    if (!customer) throw new Error("Customer tidak valid untuk company ini");

    const jobNo = String(formData.get("jobNo") || "").trim().toUpperCase();
    const serviceType = String(formData.get("serviceType") || "").trim();
    if (!jobNo || !serviceType) throw new Error("Job No dan Service wajib diisi");

    const duplicate = await db.job.findFirst({
      where: { tenantId: actor.tenantId, jobNo },
      select: { id: true },
    });
    if (duplicate) throw new Error(`Job No ${jobNo} sudah ada`);

    const numberOrNull = (value: FormDataEntryValue | null) => {
      const text = String(value || "").trim();
      if (!text) return null;
      const n = Number(text);
      if (!Number.isFinite(n) || n < 0) throw new Error("Nilai revenue/cost tidak valid");
      return n;
    };
    const dateOrNull = (value: FormDataEntryValue | null) => {
      const text = String(value || "").trim();
      return text ? new Date(text) : null;
    };

    const row = await db.job.create({
      data: {
        tenantId: actor.tenantId,
        jobNo,
        customerId,
        serviceType,
        blAwb: String(formData.get("blAwb") || "").trim() || null,
        pol: String(formData.get("pol") || "").trim() || null,
        pod: String(formData.get("pod") || "").trim() || null,
        etd: dateOrNull(formData.get("etd")),
        eta: dateOrNull(formData.get("eta")),
        revenue: numberOrNull(formData.get("revenue")),
        vendorCost: numberOrNull(formData.get("vendorCost")),
        status: JobStatus.OPEN,
      },
    });

    await db.auditLog.create({
      data: {
        tenantId: actor.tenantId,
        userId: actor.id,
        entityType: "Job",
        entityId: row.id,
        action: "CREATED",
        detail: jobNo,
      },
    });

    redirect(`/jobs/${row.id}`);
  }

  return (
    <AppShell title="New Job / Shipment">
      <div className="page-actions">
        <Link className="btn secondary" href="/jobs">← Back to Jobs</Link>
      </div>

      {customers.length === 0 ? (
        <div className="card">
          <h3>Customer belum tersedia</h3>
          <p className="muted">Job harus terhubung ke customer. Buat customer terlebih dahulu sebelum membuat Job No.</p>
          {user.role === Role.ADMIN ? (
            <Link className="btn" href="/admin/customers">Create Customer</Link>
          ) : (
            <div className="alert info">Hubungi Admin company untuk membuat master customer.</div>
          )}
        </div>
      ) : (
        <div className="card form">
          <div className="alert info">Buat Job No baru untuk shipment. Setelah disimpan Anda akan langsung masuk ke halaman Job Costing.</div>
          <form action={createJob}>
            <div className="row">
              <div className="field"><label>Job No *</label><input name="jobNo" placeholder="JKT-2609-0001" required /></div>
              <div className="field"><label>Customer *</label><select name="customerId" required><option value="">Select customer</option>{customers.map(c => <option key={c.id} value={c.id}>{c.code} - {c.name}</option>)}</select></div>
            </div>
            <div className="row">
              <div className="field"><label>Service *</label><input name="serviceType" placeholder="Import Sea / Export Air / Domestic" required /></div>
              <div className="field"><label>BL / AWB</label><input name="blAwb" placeholder="BL / AWB Number" /></div>
            </div>
            <div className="row">
              <div className="field"><label>POL / Origin</label><input name="pol" placeholder="Shanghai" /></div>
              <div className="field"><label>POD / Destination</label><input name="pod" placeholder="Jakarta" /></div>
            </div>
            <div className="row">
              <div className="field"><label>ETD</label><input type="date" name="etd" /></div>
              <div className="field"><label>ETA</label><input type="date" name="eta" /></div>
            </div>
            <div className="row">
              <div className="field"><label>Revenue (IDR)</label><input type="number" min="0" name="revenue" placeholder="0" /></div>
              <div className="field"><label>Initial Cost Estimate (IDR)</label><input type="number" min="0" name="vendorCost" placeholder="0" /></div>
            </div>
            <button className="btn">Create Job</button>
          </form>
        </div>
      )}
    </AppShell>
  );
}

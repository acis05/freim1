import Link from "next/link";
import AppShell from "@/components/AppShell";
import { db } from "@/lib/db";
import { requireUser } from "@/lib/auth";
import { rupiah, dateID } from "@/lib/format";
import { Role } from "@prisma/client";

const jobCreatorRoles: Role[] = [Role.ADMIN, Role.SUPERVISOR, Role.MANAGER];

export default async function Jobs() {
  const u = await requireUser();
  const jobs = await db.job.findMany({
    where: { tenantId: u.tenantId },
    include: {
      customer: true,
      reimbursements: { where: { status: "PAID" } },
      advances: { where: { status: "SETTLED" } },
      vendorBills: { where: { status: { not: "CANCELLED" } } },
      costEstimates: true,
    },
    orderBy: { createdAt: "desc" },
  });
  const canCreate = jobCreatorRoles.includes(u.role);

  return (
    <AppShell title="Jobs / Shipment">
      {canCreate && (
        <div className="page-actions">
          <Link className="btn" href="/jobs/new">+ New Job</Link>
        </div>
      )}
      <div className="table-wrap">
        <table>
          <thead><tr><th>Job No</th><th>Customer</th><th>Service</th><th>Route</th><th>ETA</th><th>Revenue</th><th>Estimate</th><th>Actual</th><th>GP</th><th>Status</th></tr></thead>
          <tbody>
            {jobs.map(j => {
              const est = j.costEstimates.length ? j.costEstimates.reduce((s, x) => s + Number(x.amount), 0) : Number(j.vendorCost || 0);
              const bills = j.vendorBills.reduce((s, x) => s + Number(x.amount), 0);
              const reimb = j.reimbursements.reduce((s, x) => s + Number(x.totalAmount), 0);
              const adv = j.advances.reduce((s, x) => s + Number(x.actualAmount || 0), 0);
              const actual = (bills || Number(j.vendorCost || 0)) + reimb + adv;
              const gp = Number(j.revenue || 0) - actual;
              return <tr key={j.id}><td><Link className="link" href={`/jobs/${j.id}`}><b>{j.jobNo}</b></Link></td><td>{j.customer.name}</td><td>{j.serviceType}</td><td>{j.pol || "-"} → {j.pod || "-"}</td><td>{dateID(j.eta)}</td><td>{rupiah(j.revenue)}</td><td>{rupiah(est)}</td><td>{rupiah(actual)}</td><td className={gp >= 0 ? "metric-positive" : "metric-negative"}>{rupiah(gp)}</td><td><span className="badge">{j.status}</span></td></tr>;
            })}
            {jobs.length === 0 && <tr><td colSpan={10}><div style={{padding:"22px 4px"}}><b>Belum ada Job / Shipment.</b><div className="muted" style={{marginTop:6}}>{canCreate ? "Klik + New Job untuk membuat shipment pertama." : "Hubungi Supervisor, Manager, atau Admin untuk membuat Job baru."}</div></div></td></tr>}
          </tbody>
        </table>
      </div>
    </AppShell>
  );
}

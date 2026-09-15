# Freim Apps
## Railway build hotfix (2026-09-13)

This revision fixes Prisma P1012 during `prisma generate`: all Prisma enum values are now declared one value per line. The project also pins Node 22.x and npm 10.x for a more predictable Railpack build.

If the previous Railway deployment failed during `prisma generate`, no database migration was executed yet. Push this revision and redeploy; a database reset is not required.
 — Multi-Tenant SaaS

**Freight & Reimbursement Management** untuk perusahaan freight forwarding.

Versi ini dirancang untuk dijual ke banyak perusahaan menggunakan **satu aplikasi + satu PostgreSQL database** dengan model shared-schema multi-tenant. Setiap record bisnis memiliki `tenantId`, setiap query transaksi/master di-scope ke tenant session, dan file upload disimpan di folder tenant terpisah.

## Branding
Logo Freim Apps yang dipilih sudah dimasukkan ke:
- Login
- Sidebar
- Platform Admin
- Browser/app icon

File brand berada di `public/brand/`.

## Fitur

### Multi-tenant SaaS
- `Tenant / Company Workspace`
- Company Code saat login
- Tenant status: ACTIVE / SUSPENDED / CANCELLED
- Plan: TRIAL / STARTER / BUSINESS / ENTERPRISE
- Max user per tenant
- Trial expiry
- Self-service company registration
- Platform Admin untuk melihat tenant, mengganti plan, status, dan user limit
- Email boleh sama pada tenant berbeda
- Document number unik per tenant
- Receipt duplicate detection hanya dibandingkan di tenant yang sama
- Storage receipt/invoice terpisah `/data/uploads/<tenantId>/...`
- File route memverifikasi tenant dari session sebelum mengirim file

### Reimbursement
- Multi-item claim
- Job No / shipment relation
- Expense category
- Vendor master atau manual vendor
- Receipt JPG/PNG/WEBP/PDF
- Duplicate receipt fingerprint SHA-256
- Tiered configurable approval
- Finance verification
- Ready to pay / paid

### Cash Advance
- Request
- Approval
- Finance payout
- Settlement
- Employee return / company owes
- Finance close

### Forwarding Job Costing
- Customer
- Job No
- Service type
- BL/AWB
- POL/POD
- ETD/ETA
- Revenue
- Cost estimate per category/vendor
- Vendor Bills actual
- Paid reimbursement
- Settled advance actual
- Cost variance
- Gross profit & margin

### Vendor AP
- Vendor master
- Vendor invoice / due date
- Upload invoice
- SUBMITTED → VERIFIED → PAID
- Payment reference
- Outstanding AP dashboard

### Admin per Company
- Users/Employees
- Departments
- Branches
- Customers
- Vendors
- Jobs
- Expense Categories
- Approval Rules
- Company Settings
- CSV/XLS/XLSX import Customers & Jobs

### Reports
- Job Costing Excel
- Reimbursement Excel
- Export otomatis hanya berisi data tenant login

## Arsitektur tenant

```text
PostgreSQL
└── Tenant
    ├── Users
    ├── Departments / Branches
    ├── Customers / Vendors
    ├── Jobs
    ├── Reimbursements
    ├── Cash Advances
    ├── Vendor Bills
    ├── Approval Rules
    └── Audit Logs
```

Ini menggunakan **shared database + shared schema + tenantId isolation**. Model ini sederhana dan ekonomis untuk SaaS awal karena tidak membutuhkan satu database per customer.

> Untuk kontrak enterprise dengan requirement compliance yang lebih tinggi, Anda dapat menambah PostgreSQL Row Level Security (RLS) atau menawarkan dedicated database sebagai tier enterprise. Source saat ini melakukan tenant isolation di application layer dan memvalidasi foreign IDs terhadap tenant aktif.

## Demo / seed
Tidak ada insecure demo tenant yang dibuat secara default.

Platform Admin hanya dibuat jika variables berikut diisi:

```text
PLATFORM_ADMIN_EMAIL=owner@example.com
PLATFORM_ADMIN_PASSWORD=<strong-password>
```

Untuk membuat demo tenant opsional:

```text
SEED_DEMO=true
```

Demo login bila diaktifkan:

```text
Company Code: DEMO
Email: admin@demo.local
Password: demo123
```

Jangan gunakan `SEED_DEMO=true` di production publik.

# Deploy GitHub → Railway

## 1. Push source ke GitHub
Extract ZIP dan push **isi folder** ke root repository.

```bash
git init
git add .
git commit -m "Freim Apps multi-tenant"
git branch -M main
git remote add origin https://github.com/YOUR-ORG/YOUR-REPO.git
git push -u origin main
```

## 2. Buat Railway Project
1. New Project → Deploy from GitHub Repo.
2. Pilih repo Freim Apps.
3. Add Service → PostgreSQL.

## 3. Variables web service
Gunakan Reference Variable untuk `DATABASE_URL` dari PostgreSQL service.

```text
DATABASE_URL=${{Postgres.DATABASE_URL}}
APP_SECRET=<random-string-panjang-min-32-karakter>
STORAGE_DIR=/data/uploads
TRIAL_DAYS=14
ALLOW_SELF_REGISTER=true
PLATFORM_ADMIN_EMAIL=<your-platform-email>
PLATFORM_ADMIN_PASSWORD=<very-strong-password>
SEED_DEMO=false
```

## 4. Railway Volume
Tambahkan persistent volume ke **web service** dan mount:

```text
/data
```

Aplikasi menyimpan receipt dan vendor invoice ke `/data/uploads/<tenantId>/...`.

## 5. Deploy
`railway.json` sudah mengatur:

```text
Build       : npm run build
Pre-deploy  : npx prisma migrate deploy
              npm run db:seed
Start       : npm run start (Next.js binds to Railway PORT)
Healthcheck : /api/health
```

Setelah deploy, Settings → Networking → Generate Domain.

## 6. Masuk Platform Admin

```text
https://YOUR-DOMAIN/platform/login
```

Gunakan `PLATFORM_ADMIN_EMAIL` dan `PLATFORM_ADMIN_PASSWORD`.

Jika `ALLOW_SELF_REGISTER=true`, tenant baru bisa dibuat sendiri dari:

```text
/register-company
```

User tenant login melalui:

```text
/login
```

dengan **Company Code + Email + Password**.

# Local development

```bash
docker compose up -d
cp .env.example .env
npm install
npx prisma migrate deploy
npm run db:seed
npm run dev
```

Buka `http://localhost:3000`.

# PostgreSQL migration
Initial multi-tenant migration tersedia di:

```text
prisma/migrations/20260913010000_init_multitenant/migration.sql
```

Project ini adalah **fresh multi-tenant edition**. Jika Anda sudah mempunyai database single-tenant v4 berisi data production, jangan langsung menjalankan migration ini di database tersebut. Data v4 perlu dimigrasikan ke satu tenant terlebih dahulu dengan migration/backfill khusus.

# Security / tenant isolation checklist
Source sudah menerapkan:
- Tenant ID pada seluruh tabel bisnis utama
- Tenant-scoped query untuk dashboard, transaction, finance, reports dan admin
- Foreign-ID validation untuk Job, Vendor, Category, Department, Branch
- Tenant-scoped duplicate receipt lookup
- Tenant-scoped exports
- Tenant-scoped file storage dan authorization
- Tenant user limits
- Suspended tenant tidak dapat login
- Trial expiry check
- HTTP-only signed session cookie

Sebelum go-live massal, tetap lakukan:
- penetration test / security review
- backup PostgreSQL
- backup file volume
- rate limiting di edge/reverse proxy
- email verification / password reset provider
- HTTPS only
- monitoring/error tracking
- billing integration jika subscription berbayar otomatis

# Billing
Versi ini menyediakan **plan/status/maxUsers** dan Platform Admin, tetapi belum terikat payment gateway. Ini sengaja supaya deployment pertama tetap sederhana. Stripe/Xendit/Midtrans dapat ditambahkan berikutnya untuk automatic subscription, invoice SaaS, dan auto-suspend.

# Struktur utama

```text
app/
  login/
  register-company/
  platform/
    login/
    tenants/
  dashboard/
  jobs/
  reimbursements/
  advances/
  approvals/
  finance/
  vendor-bills/
  reports/
  admin/
  api/
components/
lib/
prisma/
public/brand/
templates/
railway.json
```

## Hotfix 2026-09-15 — Railway TypeScript Role.includes
Build Railway yang sudah melewati Prisma dapat gagal pada `app/jobs/[id]/page.tsx` karena TypeScript menginfer array enum role terlalu sempit saat `.includes(user.role)` dipakai. Source revisi ini mengetik daftar role secara eksplisit sebagai `Role[]` pada Job Detail dan role-gated views terkait.

## Runtime database diagnostics (FIX 3)
`/api/health` sekarang benar-benar mengakses PostgreSQL dan menghitung tabel `Tenant`. Jika health endpoint mengembalikan HTTP 503, cek `DATABASE_URL` dan migration.

Jika registration gagal, cari `[REGISTER_COMPANY_ERROR]` di Railway Deploy Logs. Jika login gagal karena database, cari `[TENANT_LOGIN_ERROR]`.

Pada Railway web service, `DATABASE_URL` harus menjadi reference variable ke PostgreSQL service, contoh `${{Postgres.DATABASE_URL}}`. Pre-deploy sekarang menjalankan migration + seed dalam satu command agar urutannya eksplisit.

## FIX 4 - Runtime migration fallback
Railway service baru dapat mengabaikan legacy Config as Code (`railway.json`). Agar fresh PostgreSQL tetap otomatis memiliki schema, `npm start` pada FIX 4 menjalankan:

```text
npm run db:deploy
npm run db:seed
next start
```

Dengan demikian tabel multi-tenant dibuat sebelum web server menerima request, walaupun Pre-Deploy Command belum dikonfigurasi di Railway Dashboard.

Untuk production yang lebih matang, tetap disarankan mengisi **Settings -> Deploy -> Pre-deploy Command** dengan:

```bash
npx prisma migrate deploy && npm run db:seed
```

Setelah itu migration di `start` dapat dipindahkan kembali ke pre-deploy-only jika memakai beberapa replica.

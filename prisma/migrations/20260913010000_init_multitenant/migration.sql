CREATE TYPE "Role" AS ENUM ('EMPLOYEE','SUPERVISOR','MANAGER','FINANCE','ADMIN','MANAGEMENT');
CREATE TYPE "TenantStatus" AS ENUM ('ACTIVE','SUSPENDED','CANCELLED');
CREATE TYPE "Plan" AS ENUM ('TRIAL','STARTER','BUSINESS','ENTERPRISE');
CREATE TYPE "ReimbursementStatus" AS ENUM ('DRAFT','SUBMITTED','APPROVED','REJECTED','REVISION_REQUIRED','FINANCE_REVIEW','READY_TO_PAY','PAID','CANCELLED');
CREATE TYPE "JobStatus" AS ENUM ('OPEN','COMPLETED','CANCELLED');
CREATE TYPE "AdvanceStatus" AS ENUM ('DRAFT','SUBMITTED','APPROVED','PAID','SETTLEMENT_SUBMITTED','SETTLED','REJECTED');
CREATE TYPE "ApprovalDecision" AS ENUM ('APPROVED','REJECTED','REVISION');
CREATE TYPE "ApprovalEntity" AS ENUM ('REIMBURSEMENT','CASH_ADVANCE');
CREATE TYPE "VendorBillStatus" AS ENUM ('DRAFT','SUBMITTED','VERIFIED','PAID','CANCELLED');

CREATE TABLE "Tenant" (
  "id" TEXT NOT NULL, "code" TEXT NOT NULL, "slug" TEXT NOT NULL, "name" TEXT NOT NULL,
  "legalName" TEXT, "taxId" TEXT, "address" TEXT, "plan" "Plan" NOT NULL DEFAULT 'TRIAL',
  "status" "TenantStatus" NOT NULL DEFAULT 'ACTIVE', "maxUsers" INTEGER NOT NULL DEFAULT 10,
  "trialEndsAt" TIMESTAMP(3), "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL, CONSTRAINT "Tenant_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Tenant_code_key" ON "Tenant"("code");
CREATE UNIQUE INDEX "Tenant_slug_key" ON "Tenant"("slug");

CREATE TABLE "PlatformAdmin" (
  "id" TEXT NOT NULL, "email" TEXT NOT NULL, "name" TEXT NOT NULL, "passwordHash" TEXT NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL, CONSTRAINT "PlatformAdmin_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "PlatformAdmin_email_key" ON "PlatformAdmin"("email");

CREATE TABLE "Department" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "code" TEXT NOT NULL, "name" TEXT NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL, CONSTRAINT "Department_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Department_tenantId_code_key" ON "Department"("tenantId","code");
CREATE INDEX "Department_tenantId_active_idx" ON "Department"("tenantId","active");

CREATE TABLE "Branch" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "code" TEXT NOT NULL, "name" TEXT NOT NULL,
  "city" TEXT, "active" BOOLEAN NOT NULL DEFAULT true, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL, CONSTRAINT "Branch_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Branch_tenantId_code_key" ON "Branch"("tenantId","code");
CREATE INDEX "Branch_tenantId_active_idx" ON "Branch"("tenantId","active");

CREATE TABLE "User" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "employeeNo" TEXT, "name" TEXT NOT NULL,
  "email" TEXT NOT NULL, "passwordHash" TEXT NOT NULL, "role" "Role" NOT NULL DEFAULT 'EMPLOYEE',
  "departmentId" TEXT, "branchId" TEXT, "bankName" TEXT, "bankAccount" TEXT, "bankAccountName" TEXT,
  "active" BOOLEAN NOT NULL DEFAULT true, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL, CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "User_tenantId_email_key" ON "User"("tenantId","email");
CREATE UNIQUE INDEX "User_tenantId_employeeNo_key" ON "User"("tenantId","employeeNo");
CREATE INDEX "User_tenantId_role_active_idx" ON "User"("tenantId","role","active");

CREATE TABLE "Customer" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "code" TEXT NOT NULL, "name" TEXT NOT NULL,
  "taxId" TEXT, "address" TEXT, "active" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Customer_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Customer_tenantId_code_key" ON "Customer"("tenantId","code");
CREATE INDEX "Customer_tenantId_active_idx" ON "Customer"("tenantId","active");

CREATE TABLE "Vendor" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "code" TEXT NOT NULL, "name" TEXT NOT NULL,
  "taxId" TEXT, "address" TEXT, "bankName" TEXT, "bankAccount" TEXT, "bankAccountName" TEXT,
  "active" BOOLEAN NOT NULL DEFAULT true, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL, CONSTRAINT "Vendor_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Vendor_tenantId_code_key" ON "Vendor"("tenantId","code");
CREATE INDEX "Vendor_tenantId_active_idx" ON "Vendor"("tenantId","active");

CREATE TABLE "Job" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "jobNo" TEXT NOT NULL, "customerId" TEXT NOT NULL,
  "serviceType" TEXT NOT NULL, "blAwb" TEXT, "pol" TEXT, "pod" TEXT, "etd" TIMESTAMP(3), "eta" TIMESTAMP(3),
  "revenue" DECIMAL(18,2), "vendorCost" DECIMAL(18,2), "status" "JobStatus" NOT NULL DEFAULT 'OPEN',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Job_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Job_tenantId_jobNo_key" ON "Job"("tenantId","jobNo");
CREATE INDEX "Job_tenantId_status_idx" ON "Job"("tenantId","status");

CREATE TABLE "ExpenseCategory" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "code" TEXT NOT NULL, "name" TEXT NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL, CONSTRAINT "ExpenseCategory_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "ExpenseCategory_tenantId_code_key" ON "ExpenseCategory"("tenantId","code");
CREATE INDEX "ExpenseCategory_tenantId_active_idx" ON "ExpenseCategory"("tenantId","active");

CREATE TABLE "ApprovalRule" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "entityType" "ApprovalEntity" NOT NULL,
  "minAmount" DECIMAL(18,2) NOT NULL DEFAULT 0, "maxAmount" DECIMAL(18,2), "approverRole" "Role" NOT NULL,
  "priority" INTEGER NOT NULL DEFAULT 0, "active" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "ApprovalRule_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "ApprovalRule_tenantId_entityType_active_priority_idx" ON "ApprovalRule"("tenantId","entityType","active","priority");

CREATE TABLE "Reimbursement" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "claimNo" TEXT NOT NULL, "userId" TEXT NOT NULL,
  "jobId" TEXT, "status" "ReimbursementStatus" NOT NULL DEFAULT 'DRAFT',
  "requiredApprover" "Role" NOT NULL DEFAULT 'SUPERVISOR', "totalAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "notes" TEXT, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Reimbursement_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Reimbursement_tenantId_claimNo_key" ON "Reimbursement"("tenantId","claimNo");
CREATE INDEX "Reimbursement_tenantId_status_idx" ON "Reimbursement"("tenantId","status");
CREATE INDEX "Reimbursement_tenantId_userId_idx" ON "Reimbursement"("tenantId","userId");
CREATE INDEX "Reimbursement_tenantId_jobId_idx" ON "Reimbursement"("tenantId","jobId");

CREATE TABLE "ReimbursementItem" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "reimbursementId" TEXT NOT NULL, "categoryId" TEXT NOT NULL,
  "vendorId" TEXT, "expenseDate" TIMESTAMP(3) NOT NULL, "vendor" TEXT, "description" TEXT NOT NULL,
  "amount" DECIMAL(18,2) NOT NULL, "receiptUrl" TEXT, "receiptHash" TEXT,
  "duplicateSuspected" BOOLEAN NOT NULL DEFAULT false, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ReimbursementItem_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "ReimbursementItem_tenantId_receiptHash_idx" ON "ReimbursementItem"("tenantId","receiptHash");
CREATE INDEX "ReimbursementItem_tenantId_reimbursementId_idx" ON "ReimbursementItem"("tenantId","reimbursementId");

CREATE TABLE "Approval" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "reimbursementId" TEXT, "cashAdvanceId" TEXT,
  "entityType" "ApprovalEntity" NOT NULL, "approverId" TEXT NOT NULL, "decision" "ApprovalDecision" NOT NULL,
  "note" TEXT, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Approval_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "Approval_tenantId_entityType_idx" ON "Approval"("tenantId","entityType");

CREATE TABLE "Payment" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "reimbursementId" TEXT NOT NULL,
  "paidAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "bank" TEXT, "referenceNo" TEXT, "proofUrl" TEXT,
  "amount" DECIMAL(18,2) NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Payment_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Payment_reimbursementId_key" ON "Payment"("reimbursementId");
CREATE INDEX "Payment_tenantId_paidAt_idx" ON "Payment"("tenantId","paidAt");

CREATE TABLE "CashAdvance" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "advanceNo" TEXT NOT NULL, "userId" TEXT NOT NULL,
  "jobId" TEXT, "purpose" TEXT NOT NULL, "amount" DECIMAL(18,2) NOT NULL, "actualAmount" DECIMAL(18,2),
  "neededAt" TIMESTAMP(3), "status" "AdvanceStatus" NOT NULL DEFAULT 'DRAFT',
  "requiredApprover" "Role" NOT NULL DEFAULT 'SUPERVISOR', "settlementNote" TEXT,
  "settlementReceiptUrl" TEXT, "settledAt" TIMESTAMP(3), "paymentReference" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "CashAdvance_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "CashAdvance_tenantId_advanceNo_key" ON "CashAdvance"("tenantId","advanceNo");
CREATE INDEX "CashAdvance_tenantId_status_idx" ON "CashAdvance"("tenantId","status");
CREATE INDEX "CashAdvance_tenantId_userId_idx" ON "CashAdvance"("tenantId","userId");

CREATE TABLE "JobCostEstimate" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "jobId" TEXT NOT NULL, "category" TEXT NOT NULL,
  "description" TEXT, "vendorId" TEXT, "amount" DECIMAL(18,2) NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "JobCostEstimate_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "JobCostEstimate_tenantId_jobId_idx" ON "JobCostEstimate"("tenantId","jobId");

CREATE TABLE "VendorBill" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "billNo" TEXT NOT NULL, "vendorId" TEXT NOT NULL,
  "jobId" TEXT, "invoiceNo" TEXT, "invoiceDate" TIMESTAMP(3), "dueDate" TIMESTAMP(3), "description" TEXT,
  "amount" DECIMAL(18,2) NOT NULL, "status" "VendorBillStatus" NOT NULL DEFAULT 'DRAFT', "invoiceUrl" TEXT,
  "paidAt" TIMESTAMP(3), "paymentReference" TEXT, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL, CONSTRAINT "VendorBill_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "VendorBill_tenantId_billNo_key" ON "VendorBill"("tenantId","billNo");
CREATE INDEX "VendorBill_tenantId_status_dueDate_idx" ON "VendorBill"("tenantId","status","dueDate");
CREATE INDEX "VendorBill_tenantId_jobId_idx" ON "VendorBill"("tenantId","jobId");

CREATE TABLE "AuditLog" (
  "id" TEXT NOT NULL, "tenantId" TEXT NOT NULL, "userId" TEXT, "entityType" TEXT NOT NULL,
  "entityId" TEXT NOT NULL, "action" TEXT NOT NULL, "detail" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "AuditLog_tenantId_entityType_createdAt_idx" ON "AuditLog"("tenantId","entityType","createdAt");

ALTER TABLE "Department" ADD CONSTRAINT "Department_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Branch" ADD CONSTRAINT "Branch_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "User" ADD CONSTRAINT "User_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "User" ADD CONSTRAINT "User_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "User" ADD CONSTRAINT "User_branchId_fkey" FOREIGN KEY ("branchId") REFERENCES "Branch"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Customer" ADD CONSTRAINT "Customer_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Vendor" ADD CONSTRAINT "Vendor_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Job" ADD CONSTRAINT "Job_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Job" ADD CONSTRAINT "Job_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ExpenseCategory" ADD CONSTRAINT "ExpenseCategory_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ApprovalRule" ADD CONSTRAINT "ApprovalRule_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Reimbursement" ADD CONSTRAINT "Reimbursement_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Reimbursement" ADD CONSTRAINT "Reimbursement_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Reimbursement" ADD CONSTRAINT "Reimbursement_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "Job"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "ReimbursementItem" ADD CONSTRAINT "ReimbursementItem_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ReimbursementItem" ADD CONSTRAINT "ReimbursementItem_reimbursementId_fkey" FOREIGN KEY ("reimbursementId") REFERENCES "Reimbursement"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ReimbursementItem" ADD CONSTRAINT "ReimbursementItem_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "ExpenseCategory"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ReimbursementItem" ADD CONSTRAINT "ReimbursementItem_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "Vendor"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Approval" ADD CONSTRAINT "Approval_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Approval" ADD CONSTRAINT "Approval_reimbursementId_fkey" FOREIGN KEY ("reimbursementId") REFERENCES "Reimbursement"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Approval" ADD CONSTRAINT "Approval_cashAdvanceId_fkey" FOREIGN KEY ("cashAdvanceId") REFERENCES "CashAdvance"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Approval" ADD CONSTRAINT "Approval_approverId_fkey" FOREIGN KEY ("approverId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_reimbursementId_fkey" FOREIGN KEY ("reimbursementId") REFERENCES "Reimbursement"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CashAdvance" ADD CONSTRAINT "CashAdvance_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CashAdvance" ADD CONSTRAINT "CashAdvance_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "CashAdvance" ADD CONSTRAINT "CashAdvance_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "Job"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "JobCostEstimate" ADD CONSTRAINT "JobCostEstimate_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "JobCostEstimate" ADD CONSTRAINT "JobCostEstimate_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "Job"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "JobCostEstimate" ADD CONSTRAINT "JobCostEstimate_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "Vendor"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "VendorBill" ADD CONSTRAINT "VendorBill_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "VendorBill" ADD CONSTRAINT "VendorBill_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "Vendor"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "VendorBill" ADD CONSTRAINT "VendorBill_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "Job"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

import { ApprovalEntity,Role } from "@prisma/client";
import { db } from "@/lib/db";
export async function approverForAmount(tenantId:string,amount:number,entityType:ApprovalEntity){const rules=await db.approvalRule.findMany({where:{tenantId,entityType,active:true},orderBy:[{priority:"asc"},{minAmount:"asc"}]});const r=rules.find(x=>amount>=Number(x.minAmount)&&(x.maxAmount==null||amount<=Number(x.maxAmount)));if(r)return r.approverRole;if(amount<=5_000_000)return Role.SUPERVISOR;if(amount<=20_000_000)return Role.MANAGER;return Role.MANAGEMENT}

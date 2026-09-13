import { cookies } from "next/headers";
import { SignJWT,jwtVerify } from "jose";
import { redirect } from "next/navigation";
import { db } from "@/lib/db";
import { Role } from "@prisma/client";
const key=new TextEncoder().encode(process.env.APP_SECRET||"dev-secret-change-me-minimum-32-chars");
export async function createSession(userId:string,tenantId:string){const token=await new SignJWT({userId,tenantId,type:"tenant"}).setProtectedHeader({alg:"HS256"}).setIssuedAt().setExpirationTime("12h").sign(key);(await cookies()).set("session",token,{httpOnly:true,sameSite:"lax",secure:process.env.NODE_ENV==="production",path:"/",maxAge:43200})}
export async function clearSession(){(await cookies()).delete("session")}
export async function currentUser(){try{const token=(await cookies()).get("session")?.value;if(!token)return null;const {payload}=await jwtVerify(token,key);if(payload.type!=="tenant"||!payload.userId||!payload.tenantId)return null;return db.user.findFirst({where:{id:String(payload.userId),tenantId:String(payload.tenantId),active:true},include:{tenant:true,department:true,branch:true}})}catch{return null}}
export async function requireUser(){const u=await currentUser();if(!u)redirect("/login");if(u.tenant.status!=="ACTIVE")redirect("/login?blocked=1");if(u.tenant.plan==="TRIAL"&&u.tenant.trialEndsAt&&u.tenant.trialEndsAt<new Date())redirect("/login?expired=1");return u}
export async function requireRoles(roles:Role[]){const u=await requireUser();if(!roles.includes(u.role))redirect("/dashboard");return u}

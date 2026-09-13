import { cookies } from "next/headers";
import { SignJWT,jwtVerify } from "jose";
import { redirect } from "next/navigation";
import { db } from "@/lib/db";
const key=new TextEncoder().encode(process.env.APP_SECRET||"dev-secret-change-me-minimum-32-chars");
export async function createPlatformSession(id:string){const token=await new SignJWT({platformAdminId:id,type:"platform"}).setProtectedHeader({alg:"HS256"}).setIssuedAt().setExpirationTime("12h").sign(key);(await cookies()).set("platform_session",token,{httpOnly:true,sameSite:"lax",secure:process.env.NODE_ENV==="production",path:"/",maxAge:43200})}
export async function clearPlatformSession(){(await cookies()).delete("platform_session")}
export async function requirePlatformAdmin(){try{const token=(await cookies()).get("platform_session")?.value;if(!token)redirect("/platform/login");const {payload}=await jwtVerify(token,key);const admin=await db.platformAdmin.findFirst({where:{id:String(payload.platformAdminId||""),active:true}});if(!admin)redirect("/platform/login");return admin}catch{redirect("/platform/login")}}

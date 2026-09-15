import { db } from "@/lib/db";
import { createSession } from "@/lib/auth";
import { compare } from "bcryptjs";
import { redirect } from "next/navigation";
import { normalizeCode } from "@/lib/format";

export default async function Login({searchParams}:{searchParams:Promise<{error?:string;blocked?:string;expired?:string;server?:string}>}){
  const q=await searchParams;
  async function login(fd:FormData){
    "use server";
    const code=normalizeCode(String(fd.get("companyCode")||""));
    const email=String(fd.get("email")||"").trim().toLowerCase();
    const pass=String(fd.get("password")||"");
    try {
      const tenant=await db.tenant.findUnique({where:{code}});
      if(!tenant||tenant.status!=="ACTIVE") redirect("/login?blocked=1");
      if(tenant.plan==="TRIAL"&&tenant.trialEndsAt&&tenant.trialEndsAt<new Date()) redirect("/login?expired=1");
      const user=await db.user.findUnique({where:{tenantId_email:{tenantId:tenant.id,email}}});
      if(!user||!user.active||!await compare(pass,user.passwordHash)) redirect("/login?error=1");
      await createSession(user.id,tenant.id);
      redirect("/dashboard");
    } catch(error) {
      if(error instanceof Error && error.message==="NEXT_REDIRECT") throw error;
      console.error("[TENANT_LOGIN_ERROR]",error);
      redirect("/login?server=1");
    }
  }
  return <div className="login-wrap"><div className="auth-card"><img className="auth-logo" src="/brand/freim-logo.png" alt="Freim Apps"/><p className="muted" style={{textAlign:"center"}}>Freight & Reimbursement Management</p>{q.error&&<div className="alert">Company code, email, atau password salah.</div>}{q.blocked&&<div className="alert">Company tidak aktif atau Company Code tidak ditemukan.</div>}{q.expired&&<div className="alert">Masa trial sudah berakhir. Hubungi administrator Freim Apps.</div>}{q.server&&<div className="alert">Server belum dapat mengakses database. Cek Railway Deploy Logs untuk kode <b>[TENANT_LOGIN_ERROR]</b>.</div>}<form action={login}><div className="field"><label>Company Code</label><input name="companyCode" placeholder="CONTOH: ACME" required/></div><div className="field"><label>Email</label><input name="email" type="email" required/></div><div className="field"><label>Password</label><input name="password" type="password" required/></div><button className="btn" style={{width:"100%"}}>Login</button></form><div className="split" style={{marginTop:16,fontSize:13}}><a className="link" href="/register-company">Daftarkan perusahaan</a><a className="muted" href="/platform/login">Platform admin</a></div></div></div>;
}
